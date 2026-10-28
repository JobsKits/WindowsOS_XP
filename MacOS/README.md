# MacOS 分拆与合并工具

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

版本 `2026.10.28`。使用 [**macOS**](https://www.apple.com/macos/) 系统 zsh、文件工具和 [**fzf**](https://github.com/junegunn/fzf) 处理原始二进制分卷；只检查依赖，不安装、升级或修改 Shell 配置。返回[仓库总览](../README.md)。

## <span id="jobs-toc-heading-2" data-jobs-toc="v2">一、入口与使用 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

| 入口 | 输入与输出 |
| --- | --- |
| [split.command](./split.command) | 一个普通文件或目录；单文件只处理自身，目录只勾选本层大于上限的文件。新分卷目录位于源旁：去最后扩展名，无扩展名用 `.parts`。 |
| [merge.command](./merge.command) | 父目录或分卷目录；扫描本层及一级子目录，以完整原文件名分组，明确勾选后按数字顺序还原。 |

在本目录运行；也可双击后拖入路径，空输入使用脚本目录：

```shell
/bin/zsh ./split.command \
  '/镜像/大文件.iso'
/bin/zsh ./merge.command \
  '/镜像/大文件'
```

显式指定分卷目录时，本层组还原到其父目录；输入父目录并选择子组时输出到所输入目录。默认扫描脚本目录时，平铺组就在脚本目录输出。已有完整文件或分卷目录一律拒绝覆盖；建议先保留原件再核对结果。

## <span id="jobs-toc-heading-3" data-jobs-toc="v2">二、选择、校验与保护 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

- 自述回车后检查依赖。上限单选使用回车确认、Esc 取消；支持 50、100、1900 MiB 及自定义正数 MiB。目录文件和分卷组多选使用回车勾选 / 取消、空格确认、Ctrl+A 全选、Ctrl+D 清空、Esc 取消；空选不启动业务。文件选择层提供 `←` 返回上限。
- 按 `N=ceil(大小/上限)` 均衡切分，名称为 `完整原文件名@序号of总数`，按总数位宽补零；合并兼容旧三位等更宽编号和原名称内的 `@`，拒绝缺卷、重号、总数冲突和空卷。
- 固定内存流式处理，拆分比对源与分卷 SHA-256，合并比对流与候选摘要、大小和输入状态。无覆盖发布，失败或中断保留候选路径。拆分目录通过系统 JXA 调用排他重命名；合并通过硬链接发布，不支持的文件系统会安全停止。
- 原件默认保留；成功后只有精确输入大写 `YES` 且状态复核通过，才删除该源或本组精确分卷清单，不递归删除目录。日志为 `${TMPDIR:-/tmp}/实际脚本名.log`。
- SHA-256 复制验证不等于来源验证；镜像可信性仍需比较官方或其它可信来源给出的原始摘要。与 [WindowsOS 原始卷模式](../WindowsOS/README.md) 互通；Windows `-LegacyManifest` 清单 / gzip 模式不能交给本工具。

## <span id="jobs-toc-heading-4" data-jobs-toc="v2">三、验证范围 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

macOS + PowerShell 7 隔离内核已通过 264192 字节随机二进制文件、中文 `@` 文件名、11 卷的双向格式互通（两端重建 SHA-256 相同）。已通过 zsh 语法、隔离二进制往返、特殊路径、数字卷序、缺卷 / 重号 / 空卷及无覆盖验证；不自动处理真实系统镜像。两脚本自包含，可各自复制运行，但分卷来源路径仍须明确指定。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
