# `split.command` 文件拆分

![Jobs出品，必属精品](https://picsum.photos/1500/400)

<!-- jobs-toc:start -->
<!-- jobs-toc:source {"v":2,"token":"[toc]"} -->
<details>
<summary>📚 目录（点击展开 / 收起）</summary>

- [🔥 前言](#%E5%89%8D%E8%A8%80)
- [一、输入与运行](#jobs-toc-heading-2)
- [二、上限与选择](#jobs-toc-heading-3)
- [三、产物与保护](#jobs-toc-heading-4)
- [四、依赖与互通](#jobs-toc-heading-5)

</details>
<!-- jobs-toc:end -->

---

## 🔥 <span id="前言">前言</span>

版本 `2026.10.28`。在 [**macOS**](https://www.apple.com/macos/) 把普通文件拆成可由[合并工具](../merge.command/README.md)还原的原始分卷；只切分字节，不压缩。返回 [MacOS 工具总览](../README.md)。

## <span id="jobs-toc-heading-2" data-jobs-toc="v2">一、输入与运行 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

双击本目录 [split.command](./split.command)，或在本目录传入一个文件 / 目录参数：

```shell
/bin/zsh ./split.command \
  '/镜像/foo.iso'
```

先阅读内置自述并回车，再检查依赖。未传参数时可拖入文件或目录；输入为空使用**本功能目录 `MacOS/split.command/`**，不会自动改用仓库根目录、终端当前目录或镜像下载目录。处理镜像时应明确传参或拖入其真实路径；`Ctrl+C` 或输入结束停止。

单文件模式只处理该文件；目录模式不递归子目录，只列出当前层严格大于上限的普通文件，随后明确勾选。没有候选时可返回调整上限，不隐式执行。

## <span id="jobs-toc-heading-3" data-jobs-toc="v2">二、上限与选择 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

- 上限提供 50 / 100 / 1900 MiB 与自定义正数 MiB；自定义可带小数，换算结果至少一个字节。上限单选按回车确认、Esc 取消；自定义输入回车返回标准选择。
- 目录文件列表使用 [**fzf**](https://github.com/junegunn/fzf)：回车勾选 / 取消、空格确认、`Ctrl+A` 全选、`Ctrl+D` 清空、`←` 返回上限、Esc 取消。空选与取消均不拆分；选择器失败报错停止。
- 已有文件大小不超过所选上限时不拆分，可返回选择更小上限。

## <span id="jobs-toc-heading-4" data-jobs-toc="v2">三、产物与保护 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

| 项目 | 行为 |
| --- | --- |
| 分卷目录 | 位于源文件旁，去掉最后扩展名；无扩展名时使用 `完整文件名.parts`。 |
| 分卷名称 | `完整原文件名@序号of总数`，按总数位宽补零；按 `N=ceil(大小/上限)` 均衡切分。 |
| 校验与发布 | 流式拆分，比较总大小、源与分卷 SHA-256 和源文件状态；完整候选通过系统排他重命名后发布。 |
| 已有目标 / 失败 | 拒绝覆盖已有分卷目录；失败或中断保留候选并显示路径，不把残缺结果当作完成。 |
| 原文件删除 | 默认保留；成功后仅精确输入大写 `YES`，且源状态与摘要复核通过，才删除该源文件。 |
| 日志 | 系统临时目录中的 `split.log`；入口改名后按实际脚本名生成日志。 |

## <span id="jobs-toc-heading-5" data-jobs-toc="v2">四、依赖与互通 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

使用系统 [**zsh**](https://www.zsh.org/)、文件工具、`shasum`、`osascript` 与可用 fzf；fzf 需支持脚本实际使用的 footer / transform 等选项。只检查，不安装、升级或修改 Shell 配置；缺失、损坏或文件系统不支持排他发布时安全停止。

分卷与 [WindowsOS 默认原始卷模式](../../WindowsOS/README.md)互通，目录命名可不同；Windows 的 `-LegacyManifest` 清单 / gzip 模式不交给本工具。SHA-256 复制校验不证明镜像来源可信；验证来源仍需比较可信渠道提供的原始文件摘要。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
