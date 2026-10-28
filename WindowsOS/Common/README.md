# Common 分卷公共模块

![Jobs出品，必属精品](https://picsum.photos/1500/400)

<!-- jobs-toc:start -->
<!-- jobs-toc:source {"v":2,"token":"[toc]"} -->
<details>
<summary>📚 目录（点击展开 / 收起）</summary>

- [🔥 前言](#%E5%89%8D%E8%A8%80)
- [一、模块职责](#jobs-toc-heading-2)
- [二、使用与边界](#jobs-toc-heading-3)

</details>
<!-- jobs-toc:end -->

---

## 🔥 <span id="前言">前言</span>

本目录只供相邻的分卷、合并入口加载，不单独双击执行业务。返回 [WindowsOS 总览](../README.md)。

## <span id="jobs-toc-heading-2" data-jobs-toc="v2">一、模块职责 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

| 文件 | 职责 |
| --- | --- |
| `JobsTools.ps1` | 共用输入确认、日志、路径和旧 `JobsSplit-1` / gzip 业务；同源模块中其它工具函数未由本包公开入口调用。 |
| `FileVolumes.ps1` | 原始 `文件名@序号of总数` 格式解析、固定缓冲 IO、输入共享锁、大小及 SHA-256 校验、无覆盖发布。 |
| `FileVolumeWorkflow.ps1` | 原始 / 旧清单模式分派、fzf 单选与返回、MiB 转换、单文件或目录扫描和执行确认。 |

## <span id="jobs-toc-heading-3" data-jobs-toc="v2">二、使用与边界 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

保留 `WindowsOS/Common/` 与两个功能目录的相邻关系，由入口按自身位置加载。需要 PowerShell 5.1 或更新版本；默认选择器使用本机 fzf，仅检查依赖，不安装、升级或修改系统执行策略。源及分卷始终保留，已有目标拒绝覆盖；确认前不会开始处理文件。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
