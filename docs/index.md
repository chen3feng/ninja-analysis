---
title: 目录
nav_order: 1
---

# Ninja 源码深度分析

## 背景

几乎所有大型 C/C++ 项目都绕不开一个问题：**改一个文件后，重新构建要等多久？** 在 Ninja 出现之前，主流构建工具在增量构建上往往要花数秒甚至数十秒——每次构建都要重新解析复杂规则、做大量条件判断、扫描整棵依赖树。对 Chromium 这种数万文件的项目，"改一行、等十秒才开始编译"是日常。

[Ninja](https://github.com/ninja-build/ninja) 由 Google 的 Evan Martin 在开发 Chromium 时创造，2012 年开源。它的设计哲学只有一句话：**专注于速度**。官方手册的定位是 "Where other build systems are high-level languages, Ninja aims to be an assembler"——别的构建系统是高级语言，Ninja 想做汇编器。

Ninja 把"做决策"这件慢事全部上移给生成器（CMake、GN、Meson 等）：人不手写 `build.ninja`，生成器一次性把所有条件判断、平台差异都算好，落成一份扁平、无分支、纯描述的 `build.ninja`。Ninja 自己每次只做一件事——**用最少的工作把过时目标重建出来**。这让它在 Chromium 上把"改动后的启动时间"从约 10 秒压到 1 秒以内，并成为 C/C++ 世界事实上的底层构建引擎。

但 Ninja 的"快"不是魔法，而是一整套环环相扣的工程设计：紧凑的构建图内存模型、re2c 生成的词法器、零拷贝字符串、追加式二进制日志、命令哈希脏检查、`restat` 短路、关键路径优先调度……本系列文档从源码出发，逐模块拆解这些机制——由浅入深，从架构全景深入到二进制日志格式与子进程调度细节。

## 文档导航

| # | 文档 | |
|---|------|------|
| 1 | [架构概述](01-架构概述.md) | 全局鸟瞰：Ninja 是什么、为什么快、分层架构、完整生命周期 |
| 2 | [代码结构分析](02-代码结构分析.md) | 顶层目录、`configure.py`/CMake/bootstrap 自举、re2c、测试 |
| 3 | [构建图模型](03-构建图模型.md) | `Node`/`Edge`/`State`/`Pool`、显式/隐式/order-only 依赖、字符串驻留 |
| 4 | [Manifest 解析](04-Manifest解析.md) | Lexer、Parser、`EvalString` 与 `BindingEnv`、`$in`/`$out` |
| 5 | [构建执行流程](05-构建执行流程.md) | `Plan` → `Builder` 构建循环 → `CommandRunner` → 命令完成回路 |
| 6 | [增量构建：脏检查、Build Log 与 Restat](06-增量构建与脏检查.md) | mtime 脏检查、命令哈希、`.ninja_log`、`restat` 短路 |
| 7 | [依赖发现：Depfile 与 Deps Log](07-依赖发现.md) | Depfile 解析、`.ninja_deps` 二进制格式、隐式依赖回填 |
| 8 | [子进程、并行调度与 Dyndep](08-子进程与并行调度.md) | `subprocess`、`-j`/`-l`/console pool、jobserver、动态依赖 |

## 如何使用

```bash
git clone --recurse-submodules https://github.com/chen3feng/ninja-analysis.git
```

在 VS Code 中打开，`Cmd/Ctrl + 点击` 代码引用即可跳转到 Ninja 源码对应行。

## 生成方法

这些文档由 AI（Claude Code）通过系统性阅读 Ninja 源码生成，并经人工核对行号。流程：

1. **探索**：围绕具体问题，从入口点跟踪调用链，精确定位行号
2. **生成**：结构化文档 + ASCII 架构图 + 可点击代码引用
3. **版本锁定**：Ninja 代码作为 git submodule 固定 commit（`5a7fe11`），保证行号永久有效

详见 [README](https://github.com/chen3feng/ninja-analysis/blob/master/README.md)。
