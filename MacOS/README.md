# MacOS 下载、分拆与合并工具

![Jobs出品，必属精品](https://picsum.photos/1500/400)

<!-- jobs-toc:start -->
<!-- jobs-toc:source {"v":2,"token":"[toc]"} -->
<details>
<summary>📚 目录（点击展开 / 收起）</summary>

- [🔥 前言](#%E5%89%8D%E8%A8%80)
- [一、入口与使用](#jobs-toc-heading-2)
- [二、选择、校验与保护](#jobs-toc-heading-3)
- [三、验证范围](#jobs-toc-heading-4)

</details>
<!-- jobs-toc:end -->

---

## 🔥 <span id="前言">前言</span>

拆分版本 `2026.10.28`，合并版本 `2026.11.13`。使用 [**macOS**](https://www.apple.com/macos/) 系统 zsh、文件工具和 [**fzf**](https://github.com/junegunn/fzf) 处理原始二进制分卷；只检查依赖，不安装、升级或修改 Shell 配置。返回[仓库总览](../README.md)。

## <span id="jobs-toc-heading-2" data-jobs-toc="v2">一、入口与使用 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

```text
MacOS/
├── README.md
├── 【MacOS】子卷合并.command                  # 相对路径快捷入口
├── 【MacOS】源文件压缩分卷.command            # 相对路径快捷入口
├── 【MacOS】⏬下载Release.command             # 相对路径快捷入口
├── 【MacOS】⏬下载当前仓库Release.command/
│   ├── 【MacOS】⏬下载当前仓库Release.command
│   └── README.md
├── split.command/
│   ├── split.command
│   └── README.md
└── merge.command/
    ├── merge.command
    └── README.md
```

| 入口 | 输入与输出 |
| --- | --- |
| [【MacOS】⏬下载Release.command](<./【MacOS】⏬下载Release.command>) · [说明](<./【MacOS】⏬下载当前仓库Release.command/README.md>) | 选择本仓 GitHub Release 与附件，下载到仓库根 `Releases/<编码标签>/`；版本根的 `【MacOS】⏬下载当前仓库Release.command` 同样转交本功能包。 |
| [【MacOS】源文件压缩分卷.command](<./【MacOS】源文件压缩分卷.command>) · [说明](./split.command/README.md) | 一个普通文件或目录；单文件只处理自身，目录只勾选本层大于上限的文件。新分卷目录位于源旁：去最后扩展名，无扩展名用 `.parts`。 |
| [【MacOS】子卷合并.command](<./【MacOS】子卷合并.command>) · [说明](./merge.command/README.md) | 父目录或分卷目录；扫描本层及一级子目录，以完整原文件名分组，明确勾选后按数字顺序还原。无效路径或无分卷会持续询问。 |

三个外层快捷入口仅从自身位置按相对路径转发，保留参数与退出码，不复制实施逻辑或重复确认；真正脚本与专属 README 保留在功能包内，完整移动仓库仍可运行。下载器直接调用 `merge.command/merge.command --release-dir <本次Release目录>`，将产物保留在当前下载目录。

下载入口可独立于父仓运行；全部附件校验通过后，存在多卷 ISO 时自动调用 MacOS 功能包内的合并脚本，单个文件、多个独立 ISO 或 `@1of1` 不合并。下载功能另需 Git、curl、jq、shasum，具体确认、按键和保护见[下载说明](<./【MacOS】⏬下载当前仓库Release.command/README.md>)。以下输入路径、输出位置和删除确认仅适用于拆分 / 合并。

每项功能使用独立文件夹，实施脚本与其 `README.md` 同级。可双击本目录的平台前缀快捷入口，或从本目录执行以下相对路径命令；也可进入功能包直接运行实施脚本。空输入仍使用实施脚本所在的功能文件夹；处理镜像时请传入或拖入实际文件 / 目录：

```shell
/bin/zsh './【MacOS】源文件压缩分卷.command' \
  '/镜像/大文件.iso'
/bin/zsh './【MacOS】子卷合并.command' \
  '/镜像/大文件'
/bin/zsh './【MacOS】⏬下载Release.command' --list
```

显式指定分卷目录时，本层组还原到其父目录；输入父目录并选择子组时输出到所输入目录。默认扫描脚本目录时，平铺组就在脚本目录输出；`--release-dir <目录>` 则将本层及一级子目录的组统一输出到所指定目录。无效目录或未找到分卷时会持续询问，不想合并可关闭终端或按 `Ctrl+C`，输入结束也停止。已有完整文件或分卷目录一律拒绝覆盖；建议先保留原件再核对结果。

## <span id="jobs-toc-heading-3" data-jobs-toc="v2">二、选择、校验与保护 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

- 自述回车后检查依赖。上限单选使用回车确认、Esc 取消；支持 50、100、1900 MiB 及自定义正数 MiB。目录文件和分卷组多选使用回车勾选 / 取消、空格确认、Ctrl+A 全选、Ctrl+D 清空、Esc 取消；空选不启动业务。文件选择层提供 `←` 返回上限。
- 按 `N=ceil(大小/上限)` 均衡切分，名称为 `完整原文件名@序号of总数`，按总数位宽补零；合并兼容旧三位等更宽编号和原名称内的 `@`，拒绝缺卷、重号、总数冲突和空卷。
- 固定内存流式处理，拆分比对源与分卷 SHA-256，合并比对流与候选摘要、大小和输入状态。无覆盖发布，失败或中断保留候选路径。拆分目录通过系统 JXA 调用排他重命名；合并通过硬链接发布，不支持的文件系统会安全停止。
- 原件默认保留；成功后只有精确输入大写 `YES` 且状态复核通过，才删除该源或本组精确分卷清单，不递归删除目录。日志为 `${TMPDIR:-/tmp}/实际脚本名.log`。
- SHA-256 复制验证不等于来源验证；镜像可信性仍需比较官方或其它可信来源给出的原始摘要。与 [WindowsOS 原始卷模式](../WindowsOS/README.md) 互通；Windows `-LegacyManifest` 清单 / gzip 模式不能交给本工具。

## <span id="jobs-toc-heading-4" data-jobs-toc="v2">三、验证范围 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

macOS + PowerShell 7 隔离内核已通过 264192 字节随机二进制文件、中文 `@` 文件名、11 卷的双向格式互通（两端重建 SHA-256 相同）。已通过 zsh 语法、隔离二进制往返、特殊路径、数字卷序、缺卷 / 重号 / 空卷及无覆盖验证；不自动处理真实系统镜像。两脚本自包含，可各自复制运行，但分卷来源路径仍须明确指定。分卷校验、无效路径持续重询及 `--release-dir` 输出位置已使用临时分卷和真实 PTY／fzf 验证；平台外层快捷转发及调整后的下载器定位已通过迁移改名、无关工作目录与临时分卷的限定验证；真实系统镜像下载及合并未验。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
