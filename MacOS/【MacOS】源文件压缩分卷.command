#!/bin/zsh
# 脚本自述：
# - 快捷入口：相对路径转交同平台功能包，保留参数与退出码。
# - 运行提示：整仓移动后仍可使用；由实施脚本展示自述并确认。
# shell: zsh

SHORTCUT_SOURCE="${(%):-%x}"
TARGET_SCRIPT="./split.command/split.command"

# 先以快捷入口为基准定位，再使用相对路径访问功能包。
launch_companion() {
  setopt NO_NOMATCH
  local shortcut_directory="${SHORTCUT_SOURCE:A:h}"
  cd -- "$shortcut_directory" || return 1
  if [[ ! -f "$TARGET_SCRIPT" || -L "$TARGET_SCRIPT" ]]; then
    print -u2 -r -- "✖ 找不到有效的配套脚本：$TARGET_SCRIPT；请保留本仓完整目录结构。"
    return 1
  fi
  exec /bin/zsh "$TARGET_SCRIPT" "$@"
}

# 快捷入口只转交实施脚本，不重复业务和确认。
main() {
  launch_companion "$@"
}

main "$@"
