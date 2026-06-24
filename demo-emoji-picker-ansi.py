#!/usr/bin/env python3
import os
import re
import sys
import tty
import time
import json
import shutil
import select
import termios
import urllib.request
import subprocess
from pathlib import Path

EMOJI_URL = "https://www.unicode.org/Public/emoji/latest/emoji-test.txt"
CACHE_DIR = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "emoji-browser"
CACHE_FILE = CACHE_DIR / "emoji-test-latest.txt"

GROUP_SHORT = {
    "Smileys & Emotion": "Smile",
    "People & Body": "People",
    "Animals & Nature": "Animal",
    "Food & Drink": "Food",
    "Travel & Places": "Travel",
    "Activities": "Act",
    "Objects": "Obj",
    "Symbols": "Sym",
    "Flags": "Flag",
}

RESET = "\x1b[0m"
BOLD = "\x1b[1m"
DIM = "\x1b[2m"

FG_WHITE = "\x1b[97m"
FG_MUTED = "\x1b[38;5;245m"
FG_TITLE = "\x1b[38;5;141m"
FG_YELLOW = "\x1b[38;5;221m"
FG_GREEN = "\x1b[38;5;121m"

BG_TAB = "\x1b[48;5;93m"
BG_SELECTED = "\x1b[48;5;27m"

CLEAR = "\x1b[2J\x1b[H"
ALT_ON = "\x1b[?1049h"
ALT_OFF = "\x1b[?1049l"
HIDE_CURSOR = "\x1b[?25l"
SHOW_CURSOR = "\x1b[?25h"

KEY_LABELS = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]


class State:
    def __init__(self, groups, by_group):
        self.groups = groups
        self.by_group = by_group
        self.group_index = 0
        self.selected = 0
        self.cols = 8
        self.cell_width = 12
        self.query = ""
        self.search_mode = False
        self.stable_only = False
        self.status = "←/→/↑/↓ move · enter copy · / search · c clear · s stable · +/- cols · [] width · q quit"


def ensure_data():
    CACHE_DIR.mkdir(parents=True, exist_ok=True)

    if not CACHE_FILE.exists() or CACHE_FILE.stat().st_size == 0:
        print("Downloading emoji list...")
        urllib.request.urlretrieve(EMOJI_URL, CACHE_FILE)

    return CACHE_FILE


def parse_emoji_file(path):
    groups = []
    by_group = {}

    group = None
    subgroup = None

    line_re = re.compile(r"#\s+(\S+)\s+E[0-9.]+\s+(.+)$")

    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.rstrip("\n")

            if line.startswith("# group: "):
                group = line.replace("# group: ", "", 1)

                # Component 是肤色、发型等组合零件，默认隐藏
                if group == "Component":
                    group = None
                    continue

                if group not in by_group:
                    groups.append(group)
                    by_group[group] = []
                continue

            if line.startswith("# subgroup: "):
                subgroup = line.replace("# subgroup: ", "", 1)
                continue

            if not group:
                continue

            if "; fully-qualified" not in line:
                continue

            m = line_re.search(line)
            if not m:
                continue

            emoji = m.group(1)
            name = m.group(2)

            by_group[group].append({
                "emoji": emoji,
                "name": name,
                "group": group,
                "subgroup": subgroup or "",
            })

    return groups, by_group


def is_complex_emoji(s):
    if "\u200d" in s:
        return True

    if "\ufe0f" in s:
        return True

    for ch in s:
        if 0x1F3FB <= ord(ch) <= 0x1F3FF:
            return True

    return False


def filtered_items(st):
    group = st.groups[st.group_index]
    items = st.by_group[group]

    if st.stable_only:
        items = [x for x in items if not is_complex_emoji(x["emoji"])]

    q = st.query.strip().lower()

    if q:
        items = [
            x for x in items
            if q in x["name"].lower()
            or q in x["subgroup"].lower()
            or q in x["emoji"]
        ]

    return items


def terminal_size():
    size = shutil.get_terminal_size((100, 30))
    return size.columns, size.lines


def layout(st):
    width, height = terminal_size()

    left = 4
    top = 5

    max_cols = max(1, (width - left - 2) // st.cell_width)
    cols = max(1, min(st.cols, max_cols))

    rows = max(1, height - 8)
    page_size = max(1, cols * rows)

    return width, height, left, top, cols, rows, page_size


def normalize(st):
    items = filtered_items(st)

    if not items:
        st.selected = 0
        return

    if st.selected < 0:
        st.selected = 0

    if st.selected >= len(items):
        st.selected = len(items) - 1


def draw_at(buf, row, col, text):
    if row < 1:
        row = 1
    if col < 1:
        col = 1
    buf.append(f"\x1b[{row};{col}H{text}")


def trim_text(s, max_len):
    if max_len <= 0:
        return ""
    if len(s) <= max_len:
        return s
    return s[:max_len - 1] + "…"


def render(st):
    normalize(st)

    width, height, left, top, cols, rows, page_size = layout(st)
    items = filtered_items(st)

    buf = []
    buf.append(CLEAR)
    buf.append(HIDE_CURSOR)

    # 顶部分类
    x = 2
    for i, group in enumerate(st.groups[:10]):
        label = f" {KEY_LABELS[i]} {GROUP_SHORT.get(group, group)} "

        if i == st.group_index:
            draw_at(buf, 1, x, BG_TAB + FG_WHITE + BOLD + label + RESET)
        else:
            draw_at(buf, 1, x, FG_MUTED + label + RESET)

        x += len(label) + 1

    # 标题
    total_pages = 1
    page = 1

    if items:
        total_pages = max(1, (len(items) + page_size - 1) // page_size)
        page = st.selected // page_size + 1

    mode = "stable" if st.stable_only else "all"
    group_name = st.groups[st.group_index]

    title = (
        f"{group_name} · {len(items)} emoji · "
        f"page {page}/{total_pages} · cols {cols} · width {st.cell_width} · {mode}"
    )

    draw_at(buf, 3, 2, FG_TITLE + BOLD + trim_text(title, width - 4) + RESET)

    # 网格：关键点，每个 emoji 都单独定位绘制
    if not items:
        draw_at(buf, top, left, FG_YELLOW + "No emoji found." + RESET)
    else:
        start = (st.selected // page_size) * page_size
        end = min(len(items), start + page_size)

        for i in range(start, end):
            local = i - start
            r = local // cols
            c = local % cols

            y = top + r
            x = left + c * st.cell_width

            item = items[i]
            emoji = item["emoji"]

            # emoji 的坐标固定，不让它参与后续排版
            emoji_x = x + max(1, st.cell_width // 2 - 1)

            if i == st.selected:
                # 先画整格背景
                draw_at(buf, y, x, BG_SELECTED + (" " * st.cell_width) + RESET)
                # 再画 emoji
                draw_at(buf, y, emoji_x, BG_SELECTED + FG_WHITE + BOLD + emoji + RESET)
            else:
                draw_at(buf, y, emoji_x, emoji)

    # 底部信息
    info_row = max(1, height - 2)
    status_row = max(1, height - 1)

    if items:
        current = items[st.selected]
        info = f'{current["emoji"]}  {current["name"]}  [{current["subgroup"]}]'
        draw_at(buf, info_row, 2, FG_YELLOW + BOLD + trim_text(info, width - 4) + RESET)

    if st.search_mode:
        draw_at(buf, status_row, 2, FG_GREEN + BOLD + "Search: " + trim_text(st.query, width - 12) + RESET)
    else:
        draw_at(buf, status_row, 2, FG_MUTED + trim_text(st.status, width - 4) + RESET)

    sys.stdout.write("".join(buf))
    sys.stdout.flush()


def read_key(fd):
    ch = os.read(fd, 1)

    if not ch:
        return ""

    if ch == b"\x03":
        return "ctrl_c"

    if ch in (b"\r", b"\n"):
        return "enter"

    if ch in (b"\x7f", b"\b"):
        return "backspace"

    if ch == b"\x1b":
        # 读取 ESC 序列，避免单独 ESC 卡住
        if not select.select([fd], [], [], 0.03)[0]:
            return "esc"

        seq = os.read(fd, 1)

        if seq != b"[":
            return "esc"

        if not select.select([fd], [], [], 0.03)[0]:
            return "esc"

        code = os.read(fd, 1)

        if code == b"A":
            return "up"
        if code == b"B":
            return "down"
        if code == b"C":
            return "right"
        if code == b"D":
            return "left"

        if code in (b"5", b"6"):
            if select.select([fd], [], [], 0.03)[0]:
                os.read(fd, 1)
            return "pgup" if code == b"5" else "pgdown"

        return "esc"

    try:
        return ch.decode("utf-8")
    except UnicodeDecodeError:
        return ""


def copy_to_clipboard(text):
    commands = [
        ["pbcopy"],
        ["wl-copy"],
        ["xclip", "-selection", "clipboard"],
        ["xsel", "--clipboard", "--input"],
        ["clip.exe"],
    ]

    for cmd in commands:
        if shutil.which(cmd[0]):
            try:
                subprocess.run(
                    cmd,
                    input=text.encode("utf-8"),
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                    check=True,
                )
                return True
            except Exception:
                pass

    return False


def handle_key(st, key):
    if st.search_mode:
        if key == "ctrl_c":
            return False

        if key == "esc":
            st.search_mode = False
            st.status = "search cancelled"
            return True

        if key == "enter":
            st.search_mode = False
            st.selected = 0
            st.status = f"search: {st.query}" if st.query else "search cleared"
            return True

        if key == "backspace":
            st.query = st.query[:-1]
            st.selected = 0
            return True

        if len(key) == 1 and key.isprintable():
            st.query += key
            st.selected = 0
            return True

        return True

    if key in ("ctrl_c", "q", "esc"):
        return False

    if key in KEY_LABELS:
        idx = KEY_LABELS.index(key)
        if idx < len(st.groups):
            st.group_index = idx
            st.selected = 0
            st.query = ""
            st.status = f"category: {GROUP_SHORT.get(st.groups[idx], st.groups[idx])}"
        return True

    if key == "right":
        st.selected += 1
    elif key == "left":
        st.selected -= 1
    elif key == "down":
        _, _, _, _, cols, _, _ = layout(st)
        st.selected += cols
    elif key == "up":
        _, _, _, _, cols, _, _ = layout(st)
        st.selected -= cols
    elif key == "pgdown":
        *_, page_size = layout(st)
        st.selected += page_size
    elif key == "pgup":
        *_, page_size = layout(st)
        st.selected -= page_size
    elif key == "/":
        st.search_mode = True
        st.status = "search mode"
    elif key == "c":
        st.query = ""
        st.selected = 0
        st.status = "search cleared"
    elif key == "s":
        st.stable_only = not st.stable_only
        st.selected = 0
        st.status = "stable mode on" if st.stable_only else "stable mode off"
    elif key in ("+", "="):
        st.cols = min(16, st.cols + 1)
        st.status = f"cols: {st.cols}"
    elif key in ("-", "_"):
        st.cols = max(3, st.cols - 1)
        st.status = f"cols: {st.cols}"
    elif key == "]":
        st.cell_width = min(24, st.cell_width + 1)
        st.status = f"cell width: {st.cell_width}"
    elif key == "[":
        st.cell_width = max(8, st.cell_width - 1)
        st.status = f"cell width: {st.cell_width}"
    elif key == "enter" or key == " ":
        items = filtered_items(st)
        if items:
            emoji = items[st.selected]["emoji"]
            if copy_to_clipboard(emoji):
                st.status = f"copied: {emoji}"
            else:
                st.status = f"selected: {emoji} · clipboard command not found"

    normalize(st)
    return True


def main():
    path = ensure_data()
    groups, by_group = parse_emoji_file(path)
    st = State(groups, by_group)

    fd = sys.stdin.fileno()
    old = termios.tcgetattr(fd)

    try:
        tty.setraw(fd)

        sys.stdout.write(ALT_ON + HIDE_CURSOR)
        sys.stdout.flush()

        while True:
            render(st)
            key = read_key(fd)

            if not handle_key(st, key):
                break

    finally:
        sys.stdout.write(RESET + SHOW_CURSOR + ALT_OFF)
        sys.stdout.flush()
        termios.tcsetattr(fd, termios.TCSADRAIN, old)


if __name__ == "__main__":
    main()
