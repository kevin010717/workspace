#!/usr/bin/env sh
# magisk-root-tool.sh
# Magisk Root Tool - extract / patch / flash 合并版
#
# 功能：
#   1. 从当前设备提取 boot/init_boot
#   2. 调用 Magisk boot_patch.sh 修补镜像
#   3. 用 dd 写回当前设备分区
#   4. 或用 fastboot 在外部环境刷入
#
# 注意：
#   - 刷错 boot/init_boot 可能导致无法开机。
#   - 请确认镜像来自当前系统同版本。
#   - Android 13+ 新设备通常是 init_boot，旧设备通常是 boot。
#   - 本脚本不负责解锁 bootloader，不自动刷 vbmeta。

set -u

SCRIPT_NAME="magisk-root-tool"
WORKDIR="${MAGISK_ROOT_WORKDIR:-$HOME/root_flash_work}"
ME_UID="$(id -u 2>/dev/null || echo 0)"
ME_GID="$(id -g 2>/dev/null || echo 0)"

LAST_PART=""
LAST_ORIGINAL=""
LAST_PATCHED=""

info() { printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
ok() { printf '\033[1;32m[ OK ]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
err() { printf '\033[1;31m[ERR ]\033[0m %s\n' "$*" >&2; }
line() { printf '%s\n' '------------------------------------------------------------'; }

pause() {
  printf '\n按回车继续...'
  IFS= read -r _dummy || true
}

sq() {
  printf "'%s'" "$(printf "%s" "$1" | sed "s/'/'\\\\''/g")"
}

ask() {
  _prompt="$1"
  _default="${2:-}"

  if [ -n "$_default" ]; then
    printf '%s [%s]: ' "$_prompt" "$_default" >&2
  else
    printf '%s: ' "$_prompt" >&2
  fi

  IFS= read -r _ans || _ans=""

  if [ -z "$_ans" ]; then
    printf '%s\n' "$_default"
  else
    printf '%s\n' "$_ans"
  fi
}

yes_no() {
  _prompt="$1"
  _default="${2:-n}"

  while :; do
    if [ "$_default" = "y" ]; then
      printf '%s [Y/n]: ' "$_prompt"
    else
      printf '%s [y/N]: ' "$_prompt"
    fi

    IFS= read -r _yn || _yn=""
    [ -z "$_yn" ] && _yn="$_default"

    case "$_yn" in
      y|Y|yes|YES) return 0 ;;
      n|N|no|NO) return 1 ;;
      *) echo "请输入 y 或 n" ;;
    esac
  done
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    err "缺少命令：$1"
    return 1
  }
}

has_su() {
  command -v su >/dev/null 2>&1 && su -c id >/dev/null 2>&1
}

root_sh() {
  su -c "$1"
}

ensure_workdir() {
  mkdir -p "$WORKDIR" 2>/dev/null || true

  if command -v su >/dev/null 2>&1; then
    su -c "mkdir -p $(sq "$WORKDIR") 2>/dev/null || true" >/dev/null 2>&1 || true
    su -c "chmod 700 $(sq "$WORKDIR") 2>/dev/null || true" >/dev/null 2>&1 || true
    su -c "chown $ME_UID:$ME_GID $(sq "$WORKDIR") 2>/dev/null || true" >/dev/null 2>&1 || true
  fi

  if [ ! -d "$WORKDIR" ]; then
    err "工作目录创建失败：$WORKDIR"
    return 1
  fi

  return 0
}

fix_owner() {
  _path="$1"
  if has_su; then
    root_sh "chown $ME_UID:$ME_GID $(sq "$_path") 2>/dev/null || true" >/dev/null 2>&1 || true
  fi
}

sha_file() {
  _file="$1"

  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$_file" 2>/dev/null | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$_file" 2>/dev/null | awk '{print $1}'
  else
    echo "no-sha256-tool"
  fi
}

latest_file() {
  _pattern="$1"
  ls -t $_pattern 2>/dev/null | head -n 1
}

get_android_slot_suffix() {
  _slot="$(getprop ro.boot.slot_suffix 2>/dev/null || true)"

  if [ -z "$_slot" ] && has_su; then
    _slot="$(root_sh 'getprop ro.boot.slot_suffix' 2>/dev/null || true)"
  fi

  printf '%s\n' "$_slot" | tr -d '\r\n'
}

find_block_for_partition() {
  _part="$1"
  _slot="$(get_android_slot_suffix)"

  if [ -n "$_slot" ]; then
    _names="${_part}${_slot} $_part"
  else
    _names="$_part"
  fi

  _cmd="
    for name in $_names; do
      for d in /dev/block/by-name /dev/block/bootdevice/by-name /dev/block/platform/*/by-name /dev/block/platform/*/*/by-name; do
        [ -d \"\$d\" ] || continue
        if [ -e \"\$d/\$name\" ]; then
          readlink -f \"\$d/\$name\" 2>/dev/null || echo \"\$d/\$name\"
          exit 0
        fi
      done
    done
    exit 1
  "

  if has_su; then
    root_sh "$_cmd" 2>/dev/null | head -n 1
  else
    sh -c "$_cmd" 2>/dev/null | head -n 1
  fi
}

partition_exists() {
  [ -n "$(find_block_for_partition "$1" 2>/dev/null || true)" ]
}

suggest_partition() {
  if partition_exists init_boot; then
    echo "init_boot"
  else
    echo "boot"
  fi
}

choose_partition() {
  _suggest="$(suggest_partition)"

  {
    line
    echo "选择目标分区："
    echo "1) init_boot  Android 13+ 新设备常见"
    echo "2) boot       旧设备或无 init_boot 的设备常见"
    echo "3) 手动输入分区名"
    line
  } >&2

  _choice="$(ask "请选择" "1")"

  case "$_choice" in
    1) printf '%s\n' "init_boot" ;;
    2) printf '%s\n' "boot" ;;
    3) ask "输入分区名，例如 boot / init_boot" "$_suggest" ;;
    *) printf '%s\n' "$_suggest" ;;
  esac
}

choose_image_path() {
  _default="$1"

  while :; do
    _p="$(ask "输入镜像路径" "$_default")"

    if [ -f "$_p" ]; then
      printf '%s\n' "$_p"
      return 0
    fi

    err "文件不存在：$_p"
  done
}

guess_part_from_image_name() {
  _img="$1"

  case "$_img" in
    *init_boot*) echo "init_boot" ;;
    *boot*) echo "boot" ;;
    *) suggest_partition ;;
  esac
}

extract_current_partition() {
  ensure_workdir || return 1

  if ! has_su; then
    err "当前没有 su root 权限，不能从本机分区提取镜像。"
    return 1
  fi

  _part="${1:-}"
  [ -n "$_part" ] || _part="$(choose_partition)"

  _block="$(find_block_for_partition "$_part" || true)"

  if [ -z "$_block" ]; then
    err "找不到分区块设备：$_part"
    err "可检查：su -c 'ls -l /dev/block/by-name /dev/block/bootdevice/by-name 2>/dev/null | grep boot'"
    return 1
  fi

  _ts="$(date +%Y%m%d-%H%M%S)"
  _out="$WORKDIR/original_${_part}_${_ts}.img"

  line
  info "准备提取分区"
  echo "分区：$_part"
  echo "块设备：$_block"
  echo "输出：$_out"
  line

  yes_no "确认开始提取？" y || return 1

  root_sh "mkdir -p $(sq "$WORKDIR")"

  if root_sh "dd if=$(sq "$_block") of=$(sq "$_out") bs=4M && sync"; then
    fix_owner "$_out"

    if [ ! -s "$_out" ]; then
      err "提取失败：输出文件为空或不存在：$_out"
      return 1
    fi

    LAST_PART="$_part"
    LAST_ORIGINAL="$_out"

    ok "提取完成：$_out"
    echo "大小：$(wc -c < "$_out" 2>/dev/null || echo unknown) bytes"
    echo "SHA256: $(sha_file "$_out")"
    return 0
  fi

  err "提取失败"
  return 1
}

extract_from_firmware_file() {
  ensure_workdir || return 1

  _src="$(choose_image_path "")"
  _part="$(choose_partition)"
  _ts="$(date +%Y%m%d-%H%M%S)"
  _outdir="$WORKDIR/extract_${_ts}"

  mkdir -p "$_outdir"

  line
  info "从固件文件提取：$_part"
  echo "输入：$_src"
  echo "输出目录：$_outdir"
  line

  case "$_src" in
    *.img)
      _out="$WORKDIR/original_${_part}_${_ts}.img"
      cp "$_src" "$_out"
      LAST_PART="$_part"
      LAST_ORIGINAL="$_out"
      ok "已复制镜像：$_out"
      echo "SHA256: $(sha_file "$_out")"
      return 0
      ;;

    *.zip)
      need_cmd unzip || return 1

      if unzip -l "$_src" | grep -Eq "(^|[[:space:]])${_part}\.img$"; then
        unzip -p "$_src" "*${_part}.img" > "$_outdir/${_part}.img" || return 1
      elif unzip -l "$_src" | grep -q "payload.bin"; then
        unzip -p "$_src" "*payload.bin" > "$_outdir/payload.bin" || return 1

        if ! command -v payload-dumper-go >/dev/null 2>&1; then
          err "ZIP 里是 payload.bin，但当前没有 payload-dumper-go。"
          err "请先安装 payload-dumper-go，或手动提取 ${_part}.img 后再选直接镜像。"
          return 1
        fi

        payload-dumper-go -o "$_outdir" -p "$_part" "$_outdir/payload.bin" || return 1
      else
        err "ZIP 里没有找到 ${_part}.img 或 payload.bin"
        return 1
      fi
      ;;

    *payload.bin)
      if ! command -v payload-dumper-go >/dev/null 2>&1; then
        err "需要 payload-dumper-go 才能解析 payload.bin。"
        return 1
      fi

      payload-dumper-go -o "$_outdir" -p "$_part" "$_src" || return 1
      ;;

    *)
      err "不支持的输入类型。支持：.img / .zip / payload.bin"
      return 1
      ;;
  esac

  _found="$(find "$_outdir" -type f -name "${_part}.img" | head -n 1)"

  if [ -z "$_found" ]; then
    err "提取命令执行了，但没找到 ${_part}.img"
    return 1
  fi

  _out="$WORKDIR/original_${_part}_${_ts}.img"
  cp "$_found" "$_out"

  LAST_PART="$_part"
  LAST_ORIGINAL="$_out"

  ok "提取完成：$_out"
  echo "SHA256: $(sha_file "$_out")"
}

find_magisk_boot_patch() {
  for p in \
    /data/adb/magisk/boot_patch.sh \
    /debug_ramdisk/.magisk/mirror/data/adb/magisk/boot_patch.sh; do
    if [ -f "$p" ]; then
      echo "$p"
      return 0
    fi
  done

  if has_su; then
    root_sh '
      for p in /data/adb/magisk/boot_patch.sh /debug_ramdisk/.magisk/mirror/data/adb/magisk/boot_patch.sh; do
        [ -f "$p" ] && echo "$p" && exit 0
      done
      exit 1
    ' 2>/dev/null | head -n 1
  fi
}

find_magisk_patched_output() {
  _cmd="
    for f in \
      $(sq "$WORKDIR")/new-boot.img \
      $(sq "$WORKDIR")/new-init_boot.img \
      $(sq "$WORKDIR")/magisk_patched*.img \
      /data/adb/magisk/new-boot.img \
      /data/adb/magisk/new-init_boot.img \
      /data/adb/magisk/magisk_patched*.img \
      ./new-boot.img \
      ./new-init_boot.img \
      ./magisk_patched*.img; do
      [ -f \"\$f\" ] && echo \"\$f\" && exit 0
    done

    find $(sq "$WORKDIR") /data/adb/magisk /data/local/tmp /sdcard/Download \
      -maxdepth 2 -type f \
      \( -name 'new-boot.img' -o -name 'new-init_boot.img' -o -name 'magisk_patched*.img' \) \
      2>/dev/null | head -n 1
  "

  if has_su; then
    root_sh "$_cmd" 2>/dev/null | head -n 1
  else
    sh -c "$_cmd" 2>/dev/null | head -n 1
  fi
}

patch_image_with_magisk() {
  ensure_workdir || return 1

  _default="${1:-}"
  [ -n "$_default" ] || _default="$(latest_file "$WORKDIR/original_*.img")"

  _src="$(choose_image_path "$_default")"

  _part="${2:-}"
  [ -n "$_part" ] || _part="$(guess_part_from_image_name "$_src")"

  if ! has_su; then
    err "没有 su root 权限，无法直接调用 /data/adb/magisk/boot_patch.sh。"
    err "如果是首次 root，请在 Magisk App 里手动 Patch，然后用 fastboot flash。"
    return 1
  fi

  _patcher="$(find_magisk_boot_patch || true)"

  if [ -z "$_patcher" ]; then
    err "找不到 Magisk boot_patch.sh。"
    err "常见路径：/data/adb/magisk/boot_patch.sh"
    return 1
  fi

  _ts="$(date +%Y%m%d-%H%M%S)"
  _input="$WORKDIR/input_${_part}_${_ts}.img"
  _patched="$WORKDIR/patched_${_part}_${_ts}.img"

  cp "$_src" "$_input"

  rm -f "$WORKDIR/new-boot.img" "$WORKDIR/new-init_boot.img" "$WORKDIR"/magisk_patched*.img 2>/dev/null || true
  if has_su; then
    root_sh "rm -f /data/adb/magisk/new-boot.img /data/adb/magisk/new-init_boot.img /data/adb/magisk/magisk_patched*.img 2>/dev/null || true" >/dev/null 2>&1 || true
  fi

  line
  info "准备用 Magisk 修补镜像"
  echo "原始镜像：$_src"
  echo "临时输入副本：$_input"
  echo "目标分区：$_part"
  echo "Magisk patcher：$_patcher"
  echo "输出镜像：$_patched"
  line

  yes_no "确认开始修补？" y || return 1

  _cmd="
    cd $(sq "$WORKDIR") &&
    export KEEPVERITY=true &&
    export KEEPFORCEENCRYPT=true &&
    export PATCHVBMETAFLAG=false &&
    export RECOVERYMODE=false &&
    sh $(sq "$_patcher") $(sq "$_input")
  "

  if ! root_sh "$_cmd"; then
    err "Magisk 修补失败"
    return 1
  fi

  _out="$(find_magisk_patched_output || true)"

  if [ -z "$_out" ]; then
    err "Magisk 日志显示可能已 Repack，但脚本没有找到输出镜像。"
    err "请手动检查："
    err "  ls -l $WORKDIR"
    err "  su -c 'ls -l /data/adb/magisk | grep -E \"new-.*img|magisk_patched.*img\"'"
    err "  su -c 'find /data/adb/magisk /data/local/tmp /sdcard/Download -maxdepth 2 -name \"*.img\"'"
    return 1
  fi

  info "找到 Magisk 输出镜像：$_out"

  if has_su; then
    root_sh "cp -f $(sq "$_out") $(sq "$_patched") && chmod 0644 $(sq "$_patched")"
  else
    cp -f "$_out" "$_patched"
  fi

  fix_owner "$_patched"

  if [ ! -f "$_patched" ]; then
    err "复制修补镜像失败：$_patched"
    return 1
  fi

  LAST_PART="$_part"
  LAST_PATCHED="$_patched"

  ok "修补完成：$_patched"
  echo "SHA256: $(sha_file "$_patched")"
}

flash_on_device_dd() {
  ensure_workdir || return 1

  if ! has_su; then
    err "没有 su root 权限，不能在本机 dd 写分区。"
    return 1
  fi

  _default="${1:-}"
  [ -n "$_default" ] || _default="$(latest_file "$WORKDIR/patched_*.img")"

  _img="$(choose_image_path "$_default")"

  _part="${2:-}"
  [ -n "$_part" ] || _part="$(guess_part_from_image_name "$_img")"

  _block="$(find_block_for_partition "$_part" || true)"

  if [ -z "$_block" ]; then
    err "找不到目标分区块设备：$_part"
    return 1
  fi

  _ts="$(date +%Y%m%d-%H%M%S)"
  _backup="$WORKDIR/backup_before_flash_${_part}_${_ts}.img"
  _slot="$(get_android_slot_suffix)"

  line
  warn "危险操作：即将用 dd 写入分区"
  echo "当前 slot：${_slot:-unknown/single}"
  echo "目标分区：$_part"
  echo "块设备：$_block"
  echo "待刷镜像：$_img"
  echo "刷前备份：$_backup"
  line
  warn "请确认镜像来自当前系统同版本，并且分区选择正确。"
  line

  printf '如果确认刷入，请输入 FLASH：'
  IFS= read -r _confirm || _confirm=""

  [ "$_confirm" = "FLASH" ] || {
    warn "已取消"
    return 1
  }

  root_sh "mkdir -p $(sq "$WORKDIR")"

  info "先备份当前分区..."

  if ! root_sh "dd if=$(sq "$_block") of=$(sq "$_backup") bs=4M && sync"; then
    err "备份失败，已停止刷入。"
    return 1
  fi

  fix_owner "$_backup"

  ok "备份完成：$_backup"

  info "开始刷入..."

  if root_sh "dd if=$(sq "$_img") of=$(sq "$_block") bs=4M && sync"; then
    ok "刷入完成。"
    echo "备份文件：$_backup"

    if yes_no "现在重启设备？" n; then
      root_sh reboot
    else
      warn "未重启。建议确认无误后手动 reboot。"
    fi

    return 0
  fi

  err "刷入失败。备份文件：$_backup"
  return 1
}

fastboot_current_slot() {
  fastboot getvar current-slot 2>&1 | awk -F': ' '/current-slot/ {gsub(/\r/, "", $2); print $2; exit}'
}

flash_by_fastboot() {
  ensure_workdir || return 1
  need_cmd fastboot || return 1

  _default="${1:-}"
  [ -n "$_default" ] || _default="$(latest_file "$WORKDIR/patched_*.img")"

  _img="$(choose_image_path "$_default")"

  _part="${2:-}"
  [ -n "$_part" ] || _part="$(guess_part_from_image_name "$_img")"

  line
  echo "fastboot 刷入准备"
  echo "待刷镜像：$_img"
  echo "目标分区基名：$_part"
  line

  if command -v adb >/dev/null 2>&1; then
    if yes_no "设备当前在 Android 系统里，是否 adb reboot bootloader？" n; then
      adb reboot bootloader || return 1
      echo "等待设备进入 fastboot..."
      sleep 5
    fi
  fi

  echo "fastboot devices："
  fastboot devices || return 1

  _slot="$(fastboot_current_slot || true)"

  if [ -n "$_slot" ]; then
    _target_default="${_part}_${_slot}"
  else
    _target_default="$_part"
  fi

  _target="$(ask "输入 fastboot 目标分区名" "$_target_default")"

  line
  warn "即将执行：fastboot flash $_target $_img"
  warn "请确认 bootloader 已解锁。"
  line

  printf '如果确认刷入，请输入 FLASH：'
  IFS= read -r _confirm || _confirm=""

  [ "$_confirm" = "FLASH" ] || {
    warn "已取消"
    return 1
  }

  if fastboot flash "$_target" "$_img"; then
    ok "fastboot 刷入完成。"

    if yes_no "现在 fastboot reboot？" y; then
      fastboot reboot
    fi

    return 0
  fi

  err "fastboot 刷入失败。可重试并改为 ${_part} 或 ${_part}_a/${_part}_b。"
  return 1
}

full_extract_patch_flash_dd() {
  _part="$(choose_partition)"
  extract_current_partition "$_part" || return 1
  patch_image_with_magisk "$LAST_ORIGINAL" "$_part" || return 1
  flash_on_device_dd "$LAST_PATCHED" "$_part" || return 1
}

full_firmware_patch_fastboot() {
  extract_from_firmware_file || return 1
  patch_image_with_magisk "$LAST_ORIGINAL" "$LAST_PART" || return 1
  flash_by_fastboot "$LAST_PATCHED" "$LAST_PART" || return 1
}

show_status() {
  ensure_workdir || return 1

  line
  echo "$SCRIPT_NAME 状态"
  line
  echo "工作目录：$WORKDIR"
  echo "当前用户：$(id 2>/dev/null || true)"
  echo "su root：$(has_su && echo yes || echo no)"
  echo "Android slot：$(get_android_slot_suffix || true)"
  echo "建议分区：$(suggest_partition 2>/dev/null || echo unknown)"
  echo "boot 块设备：$(find_block_for_partition boot 2>/dev/null || echo not-found)"
  echo "init_boot 块设备：$(find_block_for_partition init_boot 2>/dev/null || echo not-found)"
  echo "Magisk patcher：$(find_magisk_boot_patch 2>/dev/null || echo not-found)"
  echo "最新原始镜像：$(latest_file "$WORKDIR/original_*.img" || true)"
  echo "最新修补镜像：$(latest_file "$WORKDIR/patched_*.img" || true)"
  line
}

main_menu() {
  ensure_workdir || exit 1

  while :; do
    clear 2>/dev/null || true

    echo "Magisk Root Tool - extract / patch / flash 合并版"
    line
    echo "工作目录：$WORKDIR"
    echo "1) 查看环境/分区状态"
    echo "2) Extract：从当前设备分区提取 boot/init_boot（需要已 root）"
    echo "3) Extract：从 .img / payload.bin / OTA ZIP 提取镜像"
    echo "4) Patch：用 Magisk 修补镜像（需要已安装 Magisk 且有 su）"
    echo "5) Flash：本机 dd 写回当前 slot（需要已 root，危险）"
    echo "6) Flash：fastboot 刷入修补镜像（PC/外部 fastboot 环境）"
    echo "7) 全流程：当前设备 extract -> patch -> dd flash"
    echo "8) 全流程：固件文件 extract -> patch -> fastboot flash"
    echo "0) 退出"
    line

    _c="$(ask "选择" "1")"

    case "$_c" in
      1) show_status; pause ;;
      2) extract_current_partition; pause ;;
      3) extract_from_firmware_file; pause ;;
      4) patch_image_with_magisk; pause ;;
      5) flash_on_device_dd; pause ;;
      6) flash_by_fastboot; pause ;;
      7) full_extract_patch_flash_dd; pause ;;
      8) full_firmware_patch_fastboot; pause ;;
      0) exit 0 ;;
      *) warn "无效选择"; pause ;;
    esac
  done
}

main_menu
