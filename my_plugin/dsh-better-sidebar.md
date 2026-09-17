# dsh-better-sidebar

把 DSH Web GUI 变成 VSCode 式工作台：右侧栏（文件管理 / 编辑预览 / 内嵌浏览器 / 真实终端 / 文件变动 / 后台任务 / 侧边对话）+ 底部面板，布局按会话隔离。并把 `ctx.betterSidebar` 服务开放给第三方插件（`registerTab` / `registerFileViewer`，生态已有 28+ 插件）。

- npm：https://www.npmjs.com/package/dsh-better-sidebar （本机装的是 0.19.1，`-E` 精确锁定）
- 仓库：https://github.com/omdsh-dev/DSH-better-sidebar
- 要求 DSH `0.1.5-rc.1+`，README 标注**已在 0.1.5-rc.2 上验证**（= 本机宿主版本）
- 带 **SLSA provenance 签名**（GitHub Actions OIDC 可信发布），供应链较规范
- **无遥测**：插件自有代码无绝对 URL 请求；扫出的域名全是打包 vendor（mermaid/dagre/chevrotain）的文档链接

## ⚠️ 安装踩坑：pnpm 9 不读 pnpm-workspace.yaml

首装失败：

```
ERR_PNPM_NO_MATCHING_VERSION  No matching version found for @deepseek-ai/dsh-settings@>=0.1.5 <0.2.0-0
```

原因链：插件的 peer 依赖指向 `@deepseek-ai/dsh-*`；**pnpm 9 不支持从 `pnpm-workspace.yaml` 读设置**（pnpm 10+ 才有），所以 profile 里已声明的 `autoInstallPeers: false` 被忽略 → pnpm 去 registry 解析这些 peer → 官方包只有 prerelease（在 `next` tag 下）→ 解析失败。

**修法（已做，必须保留）**：`~/.dsh/profiles/web/.npmrc` 写 `auto-install-peers=false`。

> 以后在此 profile 装任何带 `@deepseek-ai/*` peer 的插件都依赖这个文件。同理，`pnpm-workspace.yaml` 里的 `nodeLinker: hoisted` 在 pnpm 9 下也未生效（实际是 isolated 布局）。

## 安装

```shell
# 本机无全局 dsh，从源码 checkout 运行；profile 是 pnpm 9.15.4 布局，
# 系统 pnpm 12 会报 ERR_PNPM_PUBLIC_HOIST_PATTERN_DIFF，必须用 shim
# （shim 重建步骤见 dsh-chinese-thinking.md）
cd /Users/fatcat/Application/program/deepseek-harness
PATH=/tmp/pnpm9-shim:$PATH node --import tsx/esm apps/cli/src/bin.ts plugin --profile web add -w -E dsh-better-sidebar

# 重启 Web GUI 生效
```

装完 peer 会打印一堆 `✕ missing peer` 警告 + 「Peer dependencies that should be installed」清单——**这是正常的**，那些 `@deepseek-ai/dsh-*` 由宿主在运行时提供。

## 依赖与原生模块

- 依赖 `node-pty@^1.1.0`（原生模块），但包含 **`prebuilds/darwin-arm64/pty.node`** → Apple Silicon **无需编译**，终端开箱可用（另有 win32-x64/arm64、darwin-x64 预编译）
- 其余依赖：`ws`、`xterm`、`@codemirror/*`（多语言）、`mermaid`、`dompurify`、`rxjs`、`react-icons`、`schemastery`、`clsx`
- 打包体积 15MB（349 文件），启动只拉 ~325KB 核心，终端/编辑器/Mermaid 按需懒加载

## ⚠️ 会新增模型可调用的工具（默认关闭）

| 工具 | 开启位置 | 效果 |
|---|---|---|
| `terminal_*` | 设置里可选开启 | **模型能直接操控真实 shell** |
| `sidebar_open` | 全局设置开启 | 模型可主动在侧边栏打开文件/文件夹/网页 |

装完建议先别开这两个开关——这是本插件能力跨度最大的部分。

## 安全设计（自述，已核对代码结构）

- 路由有 Host 头信任围栏（与 `/api` 一致）；`fs.write` 原子写入
- 媒体/预览路由**仅限会话 cwd 内文件**；git 只调 CLI、绝不设置身份
- HTML 预览与浏览器 tab 在**不透明源沙箱 iframe** 中渲染（无 `allow-same-origin` / `allow-top-navigation`、`no-referrer`、权限策略全禁）
- 地址栏拒绝 `javascript:` / `data:` / `file:` 与 localhost 等本机地址
- 界面实时显示沙箱状态（关闭时红色警示），可临时解锁当前页面；设置页可按功能关沙箱（默认关、带警告）
- 文件变动预览有**敏感内容脱敏**（凭据形态路径整文件遮罩；`api_key:` / `Bearer` / `sk-` / `AKIA` / `ghp_` / PEM 等按内容形态遮值），默认开启，仅影响显示

## 卸载

```shell
cd /Users/fatcat/Application/program/deepseek-harness
PATH=/tmp/pnpm9-shim:$PATH node --import tsx/esm apps/cli/src/bin.ts plugin --profile web remove -w dsh-better-sidebar
# 重启 GUI 生效
```

reconcile 自动从 bundles 移除。**不会自动清理**的残留：

- 浏览器 localStorage：`dsh-sidebar:v1:<sessionId>`（每会话布局/Tab/面板）、`dsh-sidebar:v1:redaction`（脱敏开关记忆）
- 已固定的终端持久化在会话状态里（`__pinnedHome`）
- `~/.dsh/profiles/web/.npmrc` 是本插件安装时引入的**必要配置**，卸载时不要删（其他插件也用得到）

## 本机实测备注

- 安装后重启 GUI，会话头右侧出现侧边栏开合按钮，底部出现工作台
- 快捷键与逐项开关见包内 `README.md`（含「🔐 安全」「⚠️ 已知限制」「🖥️ 平台支持」章节）
