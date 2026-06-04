import curses

items = [f"file_{i:03d}.txt" for i in range(1, 301)]


def safe_addnstr(win, y, x, text, n, attr=0):
    try:
        win.addnstr(y, x, text, n, attr)
    except curses.error:
        pass


def main(stdscr):
    curses.curs_set(0)
    stdscr.keypad(True)
    curses.use_default_colors()

    selected = 0
    offset = 0

    while True:
        stdscr.erase()

        height, width = stdscr.getmaxyx()

        if height < 3 or width < 10:
            stdscr.erase()
            safe_addnstr(stdscr, 0, 0, "Terminal too small", max(1, width - 1))
            stdscr.refresh()
            key = stdscr.getch()
            if key in (ord("q"), 27):
                break
            continue

        list_height = height - 1

        if selected < offset:
            offset = selected
        elif selected >= offset + list_height:
            offset = selected - list_height + 1

        visible = items[offset:offset + list_height]
        draw_width = max(1, width - 1)

        for i, item in enumerate(visible):
            real_index = offset + i
            line = f" {real_index + 1:03d}  {item}"

            if real_index == selected:
                safe_addnstr(stdscr, i, 0, line.ljust(draw_width), draw_width, curses.A_REVERSE)
            else:
                safe_addnstr(stdscr, i, 0, line.ljust(draw_width), draw_width)

        status = " ↑/↓ or j/k scroll | PgUp/PgDn page | g top | G bottom | q quit "
        safe_addnstr(stdscr, height - 1, 0, status.ljust(draw_width), draw_width, curses.A_BOLD)

        stdscr.refresh()

        key = stdscr.getch()

        if key in (ord("q"), 27):
            break
        elif key in (curses.KEY_DOWN, ord("j")):
            selected = min(selected + 1, len(items) - 1)
        elif key in (curses.KEY_UP, ord("k")):
            selected = max(selected - 1, 0)
        elif key == curses.KEY_NPAGE:
            selected = min(selected + list_height, len(items) - 1)
        elif key == curses.KEY_PPAGE:
            selected = max(selected - list_height, 0)
        elif key == ord("g"):
            selected = 0
        elif key == ord("G"):
            selected = len(items) - 1


if __name__ == "__main__":
    curses.wrapper(main)
