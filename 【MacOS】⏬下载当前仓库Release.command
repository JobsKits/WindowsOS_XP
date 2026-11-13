#!/bin/zsh
# shell: zsh
# 快捷入口：从自身位置计算绝对路径，完整移动仓库后仍可运行。
SHORTCUT_SOURCE="${(%):-%x}"
TARGET_SCRIPT=""
# 定位与本快捷入口同仓的 MacOS 实施脚本。
resolve_download_entry() {
  local shortcut_path="${SHORTCUT_SOURCE:A}"
  TARGET_SCRIPT="${shortcut_path:h}/MacOS/【MacOS】⏬下载当前仓库Release.command/【MacOS】⏬下载当前仓库Release.command"
}
# 保留原参数及退出码，由实施入口统一展示自述并确认。
launch_download_entry() {
  if [[ ! -f "$TARGET_SCRIPT" || -L "$TARGET_SCRIPT" ]]; then
    print -u2 -r -- "✖ 找不到有效的下载脚本：$TARGET_SCRIPT；请保留本仓完整目录结构。"
    exit 1
  fi
  exec /bin/zsh "$TARGET_SCRIPT" "$@"
}
# 只转交本平台入口，不在快捷方式里复制业务或重复确认。
main() {
  resolve_download_entry # 按快捷入口位置计算实施脚本的绝对路径。
  launch_download_entry "$@" # 交给本仓 MacOS 下载器并保留真实退出码。
}
main "$@"
