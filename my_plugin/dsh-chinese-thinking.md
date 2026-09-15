# @max-null/dsh-chinese-thinking

注入一条固定的 system-prompt 段，让 agent 始终用中文思考和回复（无论用户用什么语言）。无工具、无存储、无状态。当前安装版本精确锁定为 **0.3.0**（已逐文件审计：仅一次 `ctx.systemPrompt.section()` 调用，无网络/文件访问、无 install 脚本）。

https://github.com/Max-Null/dsh-chinese-thinking

## 安装

注意：本机 profile 的 `node_modules` 是 GUI 安装器用 **pnpm 9.15.4** 创建的，系统 pnpm 12 直接装会报 `ERR_PNPM_PUBLIC_HOIST_PATTERN_DIFF`，需先用 pnpm 9.15.4 shim：

```shell
# 一次性准备 pnpm 9.15.4 shim（/tmp 重启系统后会被清理，届时重跑这段重建）
mkdir -p /tmp/pnpm9-shim && cd /tmp \
  && curl -sL https://registry.npmjs.org/pnpm/-/pnpm-9.15.4.tgz -o pnpm9.tgz \
  && tar xzf pnpm9.tgz && mv package pnpm9 \
  && printf '#!/bin/sh\nexec node /tmp/pnpm9/dist/pnpm.cjs "$@"\n' > pnpm9-shim/pnpm \
  && chmod +x pnpm9-shim/pnpm

# 安装：-w 规避 workspace 根识别问题；-E 锁定精确版本（第三方插件防供应链升级）
cd /Users/fatcat/Application/program/deepseek-harness
PATH=/tmp/pnpm9-shim:$PATH node --import tsx/esm apps/cli/src/bin.ts plugin --profile web add -w -E @max-null/dsh-chinese-thinking
```

- 包自带 `dsh.bundle` 声明，`plugin add` 的 reconcile 会**自动**把它登记进 `~/.dsh/profiles/web/package.json` 的 `dsh.profile.bundles`——不要手动编辑 `cordis.patch.yml`（会重复注册同 id 的 insert）。
- 装完**重启 Web GUI 才生效**：`patchReload: live` 只热加载 `cordis.patch.yml`，bundle 层栈在启动时解析。旧会话的提示词是启动时组装的，重启后请新开会话观察效果。

## 卸载

```shell
cd /Users/fatcat/Application/program/deepseek-harness
PATH=/tmp/pnpm9-shim:$PATH node --import tsx/esm apps/cli/src/bin.ts plugin --profile web remove -w @max-null/dsh-chinese-thinking
```

reconcile 会自动把它从 `dsh.profile.bundles` 中移除；同样需要重启 GUI 生效。
