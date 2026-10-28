# `merge.command` 分卷合并

![Jobs出品，必属精品](https://picsum.photos/1500/400)

<!-- jobs-toc:start -->
<!-- jobs-toc:source {"v":2,"token":"[toc]"} -->
<details>
<summary>📚 目录（点击展开 / 收起）</summary>

- [🔥 前言](#%E5%89%8D%E8%A8%80)
- [一、输入与运行](#jobs-toc-heading-2)
- [二、选择与卷号检查](#jobs-toc-heading-3)
- [三、输出与原件保护](#jobs-toc-heading-4)
- [四、依赖与互通](#jobs-toc-heading-5)

</details>
<!-- jobs-toc:end -->

---

## 🔥 <span id="前言">前言</span>

版本 `2026.10.28`。在 [**macOS**](https://www.apple.com/macos/) 把完整的 `原文件名@序号of总数` 原始分卷按数字顺序还原；与[拆分工具](../split.command/README.md)配套，不解压 gzip 或归档格式。返回 [MacOS 工具总览](../README.md)。

## <span id="jobs-toc-heading-2" data-jobs-toc="v2">一、输入与运行 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

双击本目录 [merge.command](./merge.command)，或在本目录传入一个分卷目录 / 父目录参数：

```shell
/bin/zsh ./merge.command \
  '/镜像/foo'
```

先阅读内置自述并回车，再检查依赖。未传参数时可拖入目录；输入为空扫描**本功能目录 `MacOS/merge.command/`**，不会自动改用仓库根目录、终端当前目录或镜像下载目录。请明确传入真正的分卷目录；`Ctrl+C` 或输入结束停止。

只扫描所输入目录和一级普通子目录，排除隐藏、依赖和构建目录；按完整原文件名分组，名称内的 `@` 保持原意。不自动进入更深层目录，没有分卷时说明后退出。

## <span id="jobs-toc-heading-3" data-jobs-toc="v2">二、选择与卷号检查 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

- 用 [**fzf**](https://github.com/junegunn/fzf)明确勾选分卷组：回车勾选 / 取消、空格确认、`Ctrl+A` 全选、`Ctrl+D` 清空、Esc 取消。空选与取消不合并；选择器失败报错停止。
- 兼容补零编号，按数字卷号排序；总数冲突、缺卷、重复编号（含不同补零写法）和空卷均拒绝，不把不同原文件名混成一组。
- 从父目录扫描到多个组时可多选，逐组报告成功 / 失败；任何一组失败使整个流程返回失败状态。

## <span id="jobs-toc-heading-4" data-jobs-toc="v2">三、输出与原件保护 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

| 输入方式 | 还原位置 |
| --- | --- |
| 显式传入 / 拖入直接含分卷的目录 | 本层分卷组还原到该目录的父目录。 |
| 传入父目录并选择其中子目录的组 | 还原到所输入父目录。 |
| 空输入，默认扫描本功能目录 | 平铺组还原到本功能目录；一级子目录的组也还原到本功能目录。 |

流式写入独占候选，核对字节总数、流与候选 SHA-256、分卷状态后，通过硬链接无覆盖发布。已有同名文件、目录或链接均保留并报错；文件系统不支持硬链接时安全停止。失败或中断保留候选路径，不发布残缺结果。

原分卷默认保留；合并成功后仅精确输入大写 `YES`，且状态复核通过，才删除本组精确分卷清单。只在目录已空时尝试移除，不递归删除其它内容。日志位于系统临时目录中的 `merge.log`；入口改名后按实际脚本名生成日志。

## <span id="jobs-toc-heading-5" data-jobs-toc="v2">四、依赖与互通 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

使用系统 [**zsh**](https://www.zsh.org/)、文件工具、`shasum`、`link` 与可用 fzf；fzf 需支持 footer / transform。只检查，不安装、升级或修改 Shell 配置，缺失或损坏时停止。

支持 [WindowsOS 默认原始卷模式](../../WindowsOS/README.md)产生的同名协议；Windows 的 `-LegacyManifest` 清单 / gzip 模式不直接互用。没有可信原文件摘要时，合并 SHA-256 只验证本次复制一致性，不能据此证明镜像来源可信。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
