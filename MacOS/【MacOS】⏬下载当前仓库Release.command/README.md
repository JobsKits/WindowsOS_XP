# WindowsOS_XP · MacOS Release 下载

![Jobs出品，必属精品](https://picsum.photos/1500/400)

---

## 🔥 <span id="前言">前言</span>

在 [**MacOS**](https://www.apple.com/macos/) 仅下载 [JobsKits/WindowsOS_XP 的 GitHub Release](https://github.com/JobsKits/WindowsOS_XP/releases)。本目录内 [【MacOS】⏬下载当前仓库Release.command](<./【MacOS】⏬下载当前仓库Release.command>) 是自包含实施脚本；[版本根快捷入口](<../../【MacOS】⏬下载当前仓库Release.command>) 与平台外层的 [【MacOS】⏬下载Release.command](<../【MacOS】⏬下载Release.command>) 均按相对路径转交它。单独克隆本仓即可使用，保留本目录相对布局即可迁移。返回[MacOS 总览](../README.md)或[仓库总览](../../README.md)。

清单请求前会显示当前来源，例如：

```text
➤ 清单来源｜GitHub / api.github.com｜https://api.github.com/repos/JobsKits/WindowsOS_XP/releases（分页参数：per_page=100&page=1）
```

附件下载前另显示实际官方直链、标签、目标文件路径与大小。

## 一、运行与选择 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

在本目录双击脚本，或从本目录执行；版本根快捷入口接受相同参数：

```shell
/bin/zsh './【MacOS】⏬下载当前仓库Release.command'
/bin/zsh './【MacOS】⏬下载当前仓库Release.command' --help
/bin/zsh './【MacOS】⏬下载当前仓库Release.command' --list
```

- 依赖系统 [**zsh**](https://www.zsh.org/)、[**Git**](https://git-scm.com/)、[**curl**](https://curl.se/)、[**jq**](https://jqlang.org/)、shasum 与 [**fzf**](https://formulae.brew.sh/formula/fzf)；只检查，不自动安装。帮助和清单不需要 fzf。
- 脚本目录必须属于本仓，且至少一个任意名称的 GitHub remote 指向 `JobsKits/WindowsOS_XP`；不把上层父仓误当成本仓，不接受 `--repo` 等跨仓参数。
- 普通运行先显示自述，回车继续，非空输入后回车取消。固定本仓身份后选择 Release，再多选附件；展示官方来源、目标目录、附件大小与总量。最终下载提示出现后，直接按 `Enter`，或只输入空白（含 `Space`／`Tab`）后按 `Enter`，都会开始下载；只有包含非空白文本的回答才不执行该批下载。EOF／`Ctrl+C` 仍终止。
- 附件选择和计划展示期间排队的按键会在最终下载提示出现前隔离。`Space` 确认附件／全选只形成计划；请松开原按键，看到最终提示后再重新输入空行或纯空白并按 `Enter` 开始，此前按键不代替本次确认。
- Release 单选 `Enter` 确认，仅剩一项（含搜索后）时 `Space` 直接确认。
- 附件有多项时，首行显示“全选”；在该操作行按 `Enter` 或 `Space`，会生成本版全部真实附件的计划，再进入原有下载确认，不会立即下载。“全选”本身不作为附件处理。只有一个附件时仅显示真实项；`Enter` 勾选 / 取消，`Space` 确认；没有附件时显示空态，不进入附件选择。
- 普通附件项用 `Enter` 勾选 / 取消、`Space` 确认已有勾选；空选且搜索后只剩一个真实项时，`Space` 直接确认，多项空选时先勾选当前项、再按 `Space` 确认。`Ctrl-D` 清空、`Esc` 取消，附件层 `←` 返回 Release；搜索无匹配且空选不推进。
- `--list` 分页查询全部已发布版本及其完整附件清单，不下载附件或修改 Git 排除配置，失败直接返回非零状态；不会从当前入口切换到其它仓库。

## 二、产物与失败处理 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 本轮结果区分新下载、已存在且校验通过、未启动下载批次及已选但未检查／尝试的附件数。最终确认收到包含非空白文本的回答时仅说明本批未启动，不断言用户主动跳过；只有完成文件实际校验通过才计入“已存在且校验通过”。未检查／尝试不等于已经下载完成，原完成文件和断点保留。

- 下载到本仓根 `Releases/<URL编码标签>/`，例如 `Releases/v1.0.0/`；首次确认下载后只在本仓 `info/exclude` 追加 `/Releases/`，保留已有规则，不改 `.gitignore`。日志位于系统临时目录，运行时显示实际位置。
- 选中任意 ISO 分卷 `原文件名.iso@序号of总数` 自动补齐同组；兼容补零，缺片、重号、总数冲突和越界停止。使用 API 官方直链，显示实际传输进度；续传及附件身份记录在同版 `.partial/`。
- 每片按大小及 API 提供的 SHA-256 校验，通过后才发布完成文件。已有完整文件校验后跳过；同名冲突、身份不符、不安全路径及本地写入错误保留原文件并停止。每版使用系统锁，拒绝并行改写同一下载。
- 网络、HTTP 传输与候选校验失败持续退避重试，优先遵守服务器更长等待，不设次数或总时长上限；明确 API 限流在原分页自动等待。非限流清单错误可重试、使用已校验的本地历史计划或返回；历史计划不代表线上最新清单。
- `Ctrl+C` 或关闭终端可取消，保留完成文件和断点。不要在运行中删除锁或移动下载目录；恢复后重新运行并选择同版即可继续。
- 所选附件全部下载或既有文件校验通过后，若存在总卷数大于 1 的 ISO 分卷，自动调用 MacOS 功能包内的 [merge.command](../merge.command/merge.command)，传入 `--release-dir <本次Release目录>`；扫描和合并输出均在该下载目录。单个文件、多个独立 ISO 或 `@1of1` 不合并，不运行下载附件中的脚本。缺少有效的仓库合并入口时报错并保留下载文件。合并保留自述、分卷组选择及精确 `YES` 删除确认，期间持续持有本版锁；正常退出也可能是取消选择，不等于已生成镜像。不挂载镜像或安装系统。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
