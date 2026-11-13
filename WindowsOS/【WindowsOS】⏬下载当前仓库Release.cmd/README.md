# WindowsOS_XP · WindowsOS Release 下载

![Jobs出品，必属精品](https://picsum.photos/1500/400)

---

## 🔥 <span id="前言">前言</span>

在 [**Windows**](https://www.microsoft.com/windows) 仅下载 [JobsKits/WindowsOS_XP 的 GitHub Release](https://github.com/JobsKits/WindowsOS_XP/releases)。[【WindowsOS】⏬下载当前仓库Release.cmd](<./【WindowsOS】⏬下载当前仓库Release.cmd>) 调用同目录 [【WindowsOS】⏬下载当前仓库Release.ps1](<./【WindowsOS】⏬下载当前仓库Release.ps1>)；[版本根快捷入口](<../../【WindowsOS】⏬下载当前仓库Release.cmd>) 按相对位置转交。本功能自包含，不依赖父仓、MacOS 脚本或 Common 模块；独立克隆本仓后也可使用。返回[WindowsOS 总览](../README.md)或[仓库总览](../../README.md)。

清单请求前会显示当前来源，例如：

```text
清单来源：https://api.github.com/repos/JobsKits/WindowsOS_XP/releases?per_page=100&page=1
```

附件下载前另显示实际官方直链、目标路径与大小。

## 一、运行与选择 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

需要 Windows 10 或更新版本、[**PowerShell**](https://learn.microsoft.com/powershell/) 5.1 或更新版本、[**Git**](https://git-scm.com/) 和 [**fzf**](https://formulae.brew.sh/formula/fzf)；仅检查依赖，不自动安装。网络与 JSON 使用系统 .NET 能力，无需 curl、jq 或额外解释器。镜像仓库名不代表本工具支持 XP、2003、7 或 8.1。

CMD 入口仅对本次 PowerShell 子进程使用执行策略参数，不持久修改系统策略。双击本目录 `.cmd` 或版本根同名快捷入口；也可在本目录的 PowerShell 中执行：

```powershell
& '.\【WindowsOS】⏬下载当前仓库Release.ps1'
& '.\【WindowsOS】⏬下载当前仓库Release.ps1' -Help
& '.\【WindowsOS】⏬下载当前仓库Release.ps1' -List
```

- 脚本目录必须属于本仓，且至少一个任意名称的 GitHub remote 指向 `JobsKits/WindowsOS_XP`；不把上层父仓误当成本仓，也不自动修改远端。
- 普通运行先显示自述，回车继续，非空输入后回车取消。选择 Release、再多选附件，显示官方来源、目标路径与总量。最终下载提示出现后，直接按 `Enter`，或只输入空白（含 `Space`／`Tab`）后按 `Enter`，都会开始下载；只有包含非空白文本的回答才不执行该批下载。EOF／`Ctrl+C` 仍终止。
- 附件选择和计划展示期间排队的按键会在最终下载提示出现前隔离。`Space` 确认附件／全选只形成计划；请松开原按键，看到最终提示后再重新输入空行或纯空白并按 `Enter` 开始，此前按键不代替本次确认。
- Release 单选 `Enter` 确认，仅剩一项（含搜索后）时 `Space` 直接确认。
- 附件有多项时，首行显示“全选”；在该操作行按 `Enter` 或 `Space`，会生成本版全部真实附件的计划，再进入原有下载确认，不会立即下载。“全选”本身不作为附件处理。只有一个附件时仅显示真实项；`Enter` 勾选 / 取消，`Space` 确认；没有附件时显示空态，不进入附件选择。
- 普通附件项用 `Enter` 勾选 / 取消、`Space` 确认已有勾选；空选且搜索后只剩一个真实项时，`Space` 直接确认，多项空选时先勾选当前项、再按 `Space` 确认。`Ctrl-D` 清空、`Esc` 取消，附件层 `←` 返回 Release；无匹配且空选不推进。
- `-Help` 显示帮助，`-List` 分页只读查询本仓全部已发布版本及完整附件清单，无需 fzf，不创建附件目录或修改 Git 排除配置。清单失败直接报错返回，不长期等待；不接受其它仓库参数。

## 二、产物与失败处理 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 本轮结果区分新下载、已存在且校验通过、未启动下载批次及已选但未检查／尝试的附件数。最终确认收到包含非空白文本的回答时仅说明本批未启动，不断言用户主动跳过；只有完成文件实际校验通过才计入“已存在且校验通过”。未检查／尝试不等于已经下载完成，原完成文件和断点保留。

- 下载到本仓根 `Releases/<URL编码标签>/`；确认下载后仅在本仓 Git 元数据 `info/exclude` 追加精确的 `/Releases/`，保留原规则，不改受跟踪的 `.gitignore`。临时日志在运行时显示路径，断点及身份记录保存在同版 `.partial/`。
- 选中任意 `原文件名@序号of总数` 分卷时补齐同组，兼容前导零；缺片、重号、总数冲突或越界停止。官方附件直链传输，支持断点续传，核对大小及 API 提供的 SHA-256；校验通过才发布完成文件，已有完整文件校验后跳过。
- 同名完成文件校验冲突、断点身份不符、不安全路径或本地写入错误会保留数据并停止。每版使用排他锁，阻止并行下载改写同一版本；不要在传输中移动下载目录或删除锁。
- 普通模式明确 API 限流时在同一分页自动等待，非限流清单错误停止，可处理后重新运行；附件网络 / HTTP 失败持续退避重试，优先遵守服务器更长等待，直到完成或 `Ctrl+C` 取消。取消保留完成文件及断点，不修改系统代理或全局 Git 配置。
- 下载完成后使用[WindowsOS 子卷合并工具](<../【WindowsOS】子卷合并/README.md>)手工选择本次 `Releases/<标签>/` 目录。不自动运行合并、挂载或安装系统。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
