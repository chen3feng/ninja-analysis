# ninja-analysis

> Ninja 构建系统源码深度分析——逐模块拆解架构、构建图、Manifest 解析、增量构建、依赖发现与并行调度等核心机制。

## 项目背景

几乎所有大型 C/C++ 项目都绕不开一个问题：**改动一个文件后，重新构建要等多久？** 在 Ninja 出现之前，主流构建工具（Make、SCons、MSBuild 等）在增量构建上往往要花数秒甚至数十秒——它们在每次构建时都要重新解析复杂的构建规则、做大量条件判断、扫描整棵依赖树。对于 Chromium 这种数万文件的项目，"改一行代码、等十秒才开始编译"是日常。

[Ninja](https://github.com/ninja-build/ninja) 由 Google 的 Evan Martin 在开发 Chromium 时创造，2012 年开源。它的设计哲学只有一句话：**专注于速度（focus on speed）**。官方手册里有一句广为流传的定位——

> "Where other build systems are high-level languages, Ninja aims to be an assembler."
> （别的构建系统是高级语言，Ninja 想做的是汇编器。）

Ninja 把"做决策"这件慢事**全部上移**给生成器程序（CMake、GN、Meson 等）：人不直接手写 `build.ninja`，而是由生成器一次性把所有条件判断、平台差异、规则展开都计算好，落成一份"扁平、无分支、纯描述"的 `build.ninja`。这样 Ninja 自己在每次增量构建时只需做一件事——**用最少的工作把过时的目标重新构建出来**。

这个设计让 Ninja 在 Chromium 上把"一次文件改动后的启动时间"从约 10 秒压到了 **1 秒以内**，并迅速成为 C/C++ 世界事实上的底层构建引擎：CMake、GN、Meson、Kati 默认都生成 Ninja 文件。

然而 Ninja 的"快"并不是靠魔法，而是靠一整套环环相扣的工程设计：紧凑的构建图内存模型、re2c 生成的词法器、零拷贝字符串、追加式二进制日志（`.ninja_log` / `.ninja_deps`）、命令哈希脏检查、`restat` 短路、关键路径优先调度……这些机制散落在约 3 万行 C++ 代码中，官方文档侧重于"怎么用"，对"怎么实现"鲜有涉及。

## 本项目做什么

从源码出发，逐模块拆解 Ninja 的核心机制：

- **不是官方手册的翻译**——已有的语法/用法说明不再重复
- **聚焦实现**——关注代码层面"为什么这样写、为什么这样快"
- **可点击直达源码行号**——每个代码引用链接到 submodule 中固定 commit 的精确行
- **由浅入深**——从架构全景逐步深入到二进制日志格式与子进程调度细节

Ninja 源码固定为 git submodule，pin 在 commit [`5a7fe11`](https://github.com/ninja-build/ninja/tree/5a7fe11473259e7111dfb6196541f503bc5fa512)，保证所有行号永久有效。

## 快速开始

```bash
git clone --recurse-submodules https://github.com/chen3feng/ninja-analysis.git
cd ninja-analysis
```

源码通过 git submodule 引入。在 VS Code 中打开，`Cmd/Ctrl + 点击` 代码引用即可跳转到对应行。

## 文档索引

| # | 文档 | 内容 |
|---|------|------|
| 1 | [架构概述](docs/01-架构概述.md) | Ninja 是什么、为什么快、分层架构、一次构建的完整生命周期、关键子系统 |
| 2 | [代码结构分析](docs/02-代码结构分析.md) | 顶层目录、`configure.py`/CMake/bootstrap 自举、re2c 词法器生成、测试体系 |
| 3 | [构建图模型](docs/03-构建图模型.md) | `Node` / `Edge` / `State` / `Pool`：核心数据结构、显式/隐式/order-only 依赖、字符串驻留 |
| 4 | [Manifest 解析](docs/04-Manifest解析.md) | Lexer（re2c）、递归下降 Parser、`EvalString` 与 `BindingEnv` 变量求值、作用域与 `$in`/`$out` |
| 5 | [构建执行流程](docs/05-构建执行流程.md) | `main` → 加载 → `Plan` → `Builder` 构建循环 → `CommandRunner` → 命令完成回路 |
| 6 | [增量构建：脏检查、Build Log 与 Restat](docs/06-增量构建与脏检查.md) | mtime 脏检查、命令哈希、`.ninja_log` 格式、`restat` 短路、`disk_interface` |
| 7 | [依赖发现：Depfile 与 Deps Log](docs/07-依赖发现.md) | Depfile 解析、`.ninja_deps` 二进制格式、`ImplicitDepLoader`、MSVC `/showIncludes` |
| 8 | [子进程、并行调度与 Dyndep](docs/08-子进程与并行调度.md) | `subprocess` / `SubprocessSet`、`-j`/`-l`/console pool、jobserver、动态依赖 dyndep |

## 文档特点

- **精确行号**：每个代码引用形如 `[graph.cc:42](ninja/src/graph.cc#L42)`，可点击直接跳转
- **可验证**：所有行号基于 submodule 中的固定 commit，不会溯源失效
- **架构图**：ASCII 流程图和调用链，无需外部工具即可阅读
- **表格总结**：每个模块末尾有关键设计决策和行号对照表

## 这些文档是如何生成的

这些文档由 AI（Claude Code）通过系统性阅读 Ninja 源码生成，并经人工核对行号。流程：

1. **探索**：围绕具体问题，从入口点 `main()` 跟踪调用链，精确定位类/函数/行号
2. **生成**：结构化文档 + ASCII 架构图 + 可点击代码引用
3. **核对**：逐条验证 `<file>:<line>` 引用，标记并修正幻觉
4. **版本锁定**：Ninja 代码作为 git submodule 固定 commit，保证行号永久有效

方法论参见 [chen3feng/ai-code-analysis](https://github.com/chen3feng/ai-code-analysis)。

## License

文档部分采用 [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)。Ninja 源码（submodule）版权归其原作者所有，遵循其 Apache-2.0 协议。
