# WindowsOS_XP

![Jobs出品，必属精品](https://picsum.photos/1500/400)

<!-- jobs-toc:start -->
<!-- jobs-toc:source {"v":2,"token":"[toc]"} -->
<details>
<summary>📚 目录（点击展开 / 收起）</summary>

- [🔥 前言](#%E5%89%8D%E8%A8%80)
- [一、下载当前仓库 Release](#repository-release)
  - [【MacOS】⏬下载当前仓库Release.command](#jobs-toc-heading-3)
  - [【WindowsOS】⏬下载当前仓库Release.cmd](#jobs-toc-heading-4)
- [二、双端分卷工具](#portable-tools)
  - [MacOS 分卷与合并](#jobs-toc-heading-6)
  - [WindowsOS 分卷与合并](#jobs-toc-heading-7)

</details>
<!-- jobs-toc:end -->

---

## 🔥 <span id="前言">前言</span>

Jobs 维护的系统镜像资料与双端分卷工具。镜像附件位于 [**GitHub Releases**](https://github.com/JobsKits/WindowsOS_XP/releases)；分卷工具源码在本 Git 仓库，克隆后即可按平台说明使用。

## 一、<span id="repository-release">下载当前仓库 Release</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

本仓可单独克隆，也可作为父仓子模块使用。两个平台入口只查询和下载 [JobsKits/WindowsOS_XP 的 Release](https://github.com/JobsKits/WindowsOS_XP/releases)，不提供其它仓库选择；脚本按自身位置定位本仓，不依赖父仓下载器或启动目录。运行前核验本仓 Git 根与 GitHub remote 的固定身份，remote 名称不限；缺少对应来源时停止，不把上层父仓当成本仓。

| 平台 | 版本根快捷入口 | 实施脚本与说明 |
| --- | --- | --- |
| [**MacOS**](https://www.apple.com/macos/) | [【MacOS】⏬下载当前仓库Release.command](<./【MacOS】⏬下载当前仓库Release.command>) | [MacOS 下载说明](<./MacOS/【MacOS】⏬下载当前仓库Release.command/README.md>) |
| [**Windows**](https://www.microsoft.com/windows) | [【WindowsOS】⏬下载当前仓库Release.cmd](<./【WindowsOS】⏬下载当前仓库Release.cmd>) | [WindowsOS 下载说明](<./WindowsOS/【WindowsOS】⏬下载当前仓库Release.cmd/README.md>) |

### <span id="jobs-toc-heading-3" data-jobs-toc="v2">[【MacOS】⏬下载当前仓库Release.command](<./【MacOS】⏬下载当前仓库Release.command>)</span><!-- jobs-toc:heading-end -->

> **目的：** 在 MacOS 选择本仓 Release 和附件，下载到本仓 `Releases/<编码标签>/`。

- 根快捷入口转交 `MacOS/【MacOS】⏬下载当前仓库Release.command/【MacOS】⏬下载当前仓库Release.command`，先阅读自述、回车继续，再通过 [**fzf**](https://formulae.brew.sh/formula/fzf) 选择版本和附件；最终下载提示后，空行或纯空白（含 Space／Tab）后回车开始，仅包含非空白文本的回答不执行。
- 只检查依赖，不自动安装；需要系统 [**zsh**](https://www.zsh.org/)、[**Git**](https://git-scm.com/)、[**curl**](https://curl.se/)、[**jq**](https://jqlang.org/)、shasum 和 fzf。`--help` 查看帮助，`--list` 只读查询本仓全部发布版本及附件，无需 fzf。
- 选中任意 ISO 分卷时补齐同组，支持断点续传、大小及 API 可用的 SHA-256 校验；已有完整文件校验后跳过，同名冲突保留并停止。全部完成后仅执行同版目录已有的 `merge.command`；缺失正常跳过，不补下载或复制合并工具。

### <span id="jobs-toc-heading-4" data-jobs-toc="v2">[【WindowsOS】⏬下载当前仓库Release.cmd](<./【WindowsOS】⏬下载当前仓库Release.cmd>)</span><!-- jobs-toc:heading-end -->

> **目的：** 在 Windows 原生终端选择并下载本仓 Release，无需 MacOS 或父仓脚本。

- 根快捷入口转交 `WindowsOS/【WindowsOS】⏬下载当前仓库Release.cmd/【WindowsOS】⏬下载当前仓库Release.cmd`，由同目录 `【WindowsOS】⏬下载当前仓库Release.ps1` 实施。需要 Windows 10 或更新版本、[**PowerShell**](https://learn.microsoft.com/powershell/) 5.1 或更新版本、Git 和 fzf；镜像仓名不代表支持在对应旧系统运行工具。
- 首屏自述仍为回车继续、非空输入取消；选择后等待最终下载提示，空行或纯空白（含 Space／Tab）后回车开始，仅包含非空白文本的回答不执行；`-Help` 查看帮助，`-List` 只读查询本仓清单，无需 fzf。分卷补齐、断点、大小及 API 可用的 SHA-256 校验与已有文件保护均在本仓执行。
- 下载完成后手工使用 [WindowsOS 子卷合并工具](<./WindowsOS/【WindowsOS】子卷合并/README.md>)；不运行 MacOS 合并入口。

确认下载后，入口仅在本仓 Git 元数据的 `info/exclude` 追加精确的 `/Releases/` 本地忽略规则，不修改受跟踪的 `.gitignore`。每版使用排他下载锁；网络传输失败持续退避重试，`Ctrl+C` 取消并保留完成文件与断点；本地错误和不安全路径停止。帮助、清单不创建附件目录，清单失败直接报错；日志在系统临时目录。

## 二、<span id="portable-tools">双端分卷工具</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

| 路径 | 职责 |
| --- | --- |
| [MacOS](./MacOS/README.md) | 拆分、合并各一个功能文件夹，入口与各自 README 同级；原始卷格式，明确勾选与精确删除确认。 |
| [WindowsOS](./WindowsOS/README.md) | PowerShell + CMD 的分卷、合并和 Common 模块，默认原始卷，保留旧清单 / gzip。 |
| [Releases](https://github.com/JobsKits/WindowsOS_XP/releases) | 仅镜像完整 ISO 或原有镜像分卷；不再存放工具 ZIP 或单脚本附件。 |

### <span id="jobs-toc-heading-6" data-jobs-toc="v2">[MacOS 分卷与合并](./MacOS/README.md)</span><!-- jobs-toc:heading-end -->

> **目的：** 按上限拆分明确指定的文件，或按完整分卷组还原。

- 在 macOS 双击或以 `/bin/zsh` 运行两个命令；可传一个位置参数或启动后拖入文件 / 目录。
- 上限为 50 / 100 / 1900 MiB 或自定义；目录只处理明确勾选对象。显式分卷目录在父目录还原，父目录中的子组输出到所输入父目录。
- 大小、SHA-256 和输入状态通过后无覆盖发布。默认保留原件，成功后精确 `YES` 才删除对应清单；失败保留候选。

### <span id="jobs-toc-heading-7" data-jobs-toc="v2">[WindowsOS 分卷与合并](./WindowsOS/README.md)</span><!-- jobs-toc:heading-end -->

> **目的：** 使用原生 PowerShell / CMD 处理互通原始卷，并保留旧清单模式。

- 双击两个功能目录中的 `.cmd`，或运行同名 `.ps1`；拆分支持单文件、目录、`-Path`、`-LimitMiB`，合并支持分卷目录或其父目录。
- 默认 `完整原文件名@序号of总数`，按数字顺序合并并核对缺卷、重号、大小和 SHA-256；现有结果拒绝覆盖，原件始终保留。
- `-LegacyManifest` 使用旧 `JobsSplit-1` 清单 / gzip，不与 `-Path` / `-LimitMiB` 混用；`-Check` 只读检查。普通操作先回车阅读自述、写入前精确 `YES`，fzf 取消不执行。

工具基线：macOS 系统 zsh + 本机 fzf；Windows 目标为 Windows 10 x64 / PowerShell 5.1 或更新版本，最低 build 与完整原生兼容性待验证。仓库的镜像系统名不代表工具可运行于 XP、2003、7 或 8.1。只检查依赖，不自动安装 / 升级。镜像分卷下载齐全后再指定实际来源目录；SHA-256 复制一致性不代替可信来源原始摘要。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
