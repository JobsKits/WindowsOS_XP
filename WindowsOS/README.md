# WindowsOS 分拆与合并工具

![Jobs出品，必属精品](https://picsum.photos/1500/400)

<!-- jobs-toc:start -->
<!-- jobs-toc:source {"v":2,"token":"[toc]"} -->
<details>
<summary>📚 目录（点击展开 / 收起）</summary>

- [🔥 前言](#%E5%89%8D%E8%A8%80)
- [一、功能与目录](#jobs-toc-heading-2)
- [二、格式、保护与旧模式](#jobs-toc-heading-3)
- [三、验证与日志](#jobs-toc-heading-4)

</details>
<!-- jobs-toc:end -->

---

## 🔥 <span id="前言">前言</span>

最低支持系统：目标 [**Windows**](https://www.microsoft.com/windows) 10 x64，最低 build 与完整兼容性仍待验证；需要 Windows PowerShell 5.1 或更新版本。镜像仓库名称中的 XP、2003、7、8.1 不代表工具能在对应旧系统运行。返回[仓库总览](../README.md)。

## <span id="jobs-toc-heading-2" data-jobs-toc="v2">一、功能与目录 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

| 入口 | 当前能力 |
| --- | --- |
| [源文件分卷](<./【WindowsOS】源文件压缩分卷/README.md>) | 单文件或本层目录选择；50 / 100 / 1900 MiB、自定义或 `-LimitMiB` 上限；默认原始二进制 `.chunks` 分卷。 |
| [子卷合并](<./【WindowsOS】子卷合并/README.md>) | 本层及一级子目录按组选择，检查完整连续卷号，数字排序无覆盖还原。 |
| [Common](./Common/README.md) | 路径 / 交互 / 日志、流式分卷内核和 fzf 工作流。复制本包时必须保留目录相邻关系。 |

双击功能目录内同名 `.cmd`，或从本目录运行：

```powershell
& '.\【WindowsOS】源文件压缩分卷\【WindowsOS】源文件压缩分卷.ps1' `
    -Path 'D:\镜像\大文件.iso' `
    -LimitMiB 100
& '.\【WindowsOS】子卷合并\【WindowsOS】子卷合并.ps1' `
    -Path 'D:\镜像\大文件.iso.chunks'
```

正常运行先显示自述并回车，真正写入前精确输入 `YES`；Ctrl+C、空选或 EOF 取消。默认模式使用 [**fzf**](https://github.com/junegunn/fzf)，回车单选、Esc 取消；拆分目录文件选择可用 `←` 返回上限。依赖仅检查，不自动安装。`.cmd` 仅为本次 PowerShell 进程设置执行策略，不持久改变系统策略。

## <span id="jobs-toc-heading-3" data-jobs-toc="v2">二、格式、保护与旧模式 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

原始卷名称为 `完整原文件名@序号of总数`，支持补零和名称内的 `@`，与 [MacOS 工具](../MacOS/README.md) 互通。Windows 分卷目录为 `完整文件名.chunks`；macOS 使用去扩展名的目录，但卷内容与名称格式相同。直接输入分卷目录时在父目录还原；输入父目录选择子组时在所输入目录还原。

固定 1 MiB 缓冲区，输入只读共享锁及大小 / SHA-256 / 源状态检查后无覆盖发布。Windows 始终保留源文件和分卷；失败保留候选并显示位置。复制一致性校验不能替代可信原始镜像摘要。

`-LegacyManifest` 保留 `JobsSplit-1` 清单与可选 gzip 压缩流程，两端 Windows 入口均需显式使用它；不能与 `-Path` / `-LimitMiB` 混传，也不能与 macOS 原始卷合并混用。只读依赖检查可使用 `-Check`，不会执行业务。

## <span id="jobs-toc-heading-4" data-jobs-toc="v2">三、验证与日志 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

macOS + PowerShell 7 隔离内核已通过 264192 字节随机二进制文件、中文 `@` 文件名、11 卷的双向格式互通（两端重建 SHA-256 相同）。PowerShell 源码采用 UTF-8 BOM，CMD 保留 CRLF。已有原始卷 / 清单流程的隔离回归、源码复核及 PowerShell 7 语法检查通过；Windows PowerShell 5.1、真实 CMD 双击、fzf 和目标文件系统仍需 Windows 实机验收。日志在确认自述后显示实际临时路径，原始卷无需安装额外压缩软件。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
