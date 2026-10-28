# WindowsOS_XP

![Jobs出品，必属精品](https://picsum.photos/1500/400)

<!-- jobs-toc:start -->
<!-- jobs-toc:source {"v":2,"token":"[toc]"} -->
<details>
<summary>📚 目录（点击展开 / 收起）</summary>

- [🔥 前言](#%E5%89%8D%E8%A8%80)
- [一、双端分卷工具](#portable-tools)
  - [MacOS 分卷与合并](#jobs-toc-heading-3)
  - [WindowsOS 分卷与合并](#jobs-toc-heading-4)

</details>
<!-- jobs-toc:end -->

---

## 🔥 <span id="前言">前言</span>

Jobs 维护的系统镜像资料与双端分卷工具。镜像附件位于 [**GitHub Releases**](https://github.com/JobsKits/WindowsOS_XP/releases)；分卷工具源码在本 Git 仓库，克隆后即可按平台说明使用。

## 一、<span id="portable-tools">双端分卷工具</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

| 路径 | 职责 |
| --- | --- |
| [MacOS](./MacOS/README.md) | 拆分、合并各一个功能文件夹，入口与各自 README 同级；原始卷格式，明确勾选与精确删除确认。 |
| [WindowsOS](./WindowsOS/README.md) | PowerShell + CMD 的分卷、合并和 Common 模块，默认原始卷，保留旧清单 / gzip。 |
| [Releases](https://github.com/JobsKits/WindowsOS_XP/releases) | 仅镜像完整 ISO 或原有镜像分卷；不再存放工具 ZIP 或单脚本附件。 |

### <span id="jobs-toc-heading-3" data-jobs-toc="v2">[MacOS 分卷与合并](./MacOS/README.md)</span><!-- jobs-toc:heading-end -->

> **目的：** 按上限拆分明确指定的文件，或按完整分卷组还原。

- 在 macOS 双击或以 `/bin/zsh` 运行两个命令；可传一个位置参数或启动后拖入文件 / 目录。
- 上限为 50 / 100 / 1900 MiB 或自定义；目录只处理明确勾选对象。显式分卷目录在父目录还原，父目录中的子组输出到所输入父目录。
- 大小、SHA-256 和输入状态通过后无覆盖发布。默认保留原件，成功后精确 `YES` 才删除对应清单；失败保留候选。

### <span id="jobs-toc-heading-4" data-jobs-toc="v2">[WindowsOS 分卷与合并](./WindowsOS/README.md)</span><!-- jobs-toc:heading-end -->

> **目的：** 使用原生 PowerShell / CMD 处理互通原始卷，并保留旧清单模式。

- 双击两个功能目录中的 `.cmd`，或运行同名 `.ps1`；拆分支持单文件、目录、`-Path`、`-LimitMiB`，合并支持分卷目录或其父目录。
- 默认 `完整原文件名@序号of总数`，按数字顺序合并并核对缺卷、重号、大小和 SHA-256；现有结果拒绝覆盖，原件始终保留。
- `-LegacyManifest` 使用旧 `JobsSplit-1` 清单 / gzip，不与 `-Path` / `-LimitMiB` 混用；`-Check` 只读检查。普通操作先回车阅读自述、写入前精确 `YES`，fzf 取消不执行。

工具基线：macOS 系统 zsh + 本机 fzf；Windows 目标为 Windows 10 x64 / PowerShell 5.1 或更新版本，最低 build 与完整原生兼容性待验证。仓库的镜像系统名不代表工具可运行于 XP、2003、7 或 8.1。只检查依赖，不自动安装 / 升级。镜像分卷下载齐全后再指定实际来源目录；SHA-256 复制一致性不代替可信来源原始摘要。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
