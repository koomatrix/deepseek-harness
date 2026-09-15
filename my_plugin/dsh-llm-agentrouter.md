# dsh-llm-agentrouter

把 AgentRouter 中转站接入 DeepSeek Harness 的 profile bundle：一条 provider 路由、五个模型及其推理档位，一个在「设置 → 插件」里切换国内 / 国际端点的开关，以及一层让出站请求符合该中转站要求的兼容处理。

- 仓库：https://github.com/aqiu817/dsh-llm-agentrouter.git
- npm：https://www.npmjs.com/package/dsh-llm-agentrouter （本机装的是 registry 版 `^0.1.0`）

## 安装

```shell
# 装进 web profile（本机无全局 dsh，从源码 checkout 运行；
# profile 的 node_modules 是 pnpm 9.15.4 布局，系统 pnpm 12 会报
# ERR_PNPM_PUBLIC_HOIST_PATTERN_DIFF，必须用 shim —— 见 dsh-chinese-thinking.md）
cd /Users/fatcat/Application/program/deepseek-harness
PATH=/tmp/pnpm9-shim:$PATH node --import tsx/esm apps/cli/src/bin.ts plugin --profile web add -w dsh-llm-agentrouter

# 存入中转站 key（二选一，不写进任何配置文件）：
#   a) Web「设置 → 模型」页写入 ~/.dsh/.credentials.yaml
#   b) 让 AGENTROUTER_API_KEY 存在于进程环境中

# 重启 host（bundle 层栈在启动时解析，patchReload: live 不管 bundle 增删）
```

- 包自带 `dsh.bundle` 声明，`plugin add` 的 reconcile 会**自动**登记进 `~/.dsh/profiles/web/package.json` 的 `dsh.profile.bundles`——无需手改（上游 README 里手动编辑 bundles 一步已过时）。
- **顺序要求**：`dsh-llm-agentrouter` 必须排在 `@deepseek-ai/dsh-base` 之后，其 `llm-pi-ai` 覆盖才生效（当前顺序：dsh-base → dsh-web-app → dsh-llm-agentrouter → …）。
- 上游 README 推荐从源码 `file:` 安装（务必 `file:` 而非 `link:`：符号链接下插件找不到 `@deepseek-ai/schemastery` 等 peer）；本机用的是 registry 安装，二者皆可。

## 日常使用

### 端点切换

「设置 → 插件 → AgentRouter 中转站」单选国内 / 国际，点选即写入、下一次请求生效（进行中的流式请求仍走旧端点）。等价于编辑 `~/.dsh/settings.yaml`：

```yaml
llm-agentrouter:
  endpoint: cn   # 或 intl；本机当前为 intl
```

### 国际端点要走代理

`agentrouter.org` 本机直连不通，启动 host 时给代理（`NODE_USE_ENV_PROXY=1` 必需，Node 22 的 fetch 默认忽略 `HTTPS_PROXY`）：

```shell
NODE_USE_ENV_PROXY=1 HTTPS_PROXY=http://<代理主机>:<端口> dsh web
```

国内端点不需要代理，代理也不妨碍它。

### 增删模型

`~/.dsh/settings.yaml` 的 `llm-pi-ai:` 分节按 provider 逐键合并，下一次请求生效。本机已加 `gpt-6-astra`：

```yaml
llm-pi-ai:
  providers:
    agentrouter:
      apiKeyEnv: AGENTROUTER_API_KEY
      api: openai-completions
      models:
        - id: gpt-6-astra
          name: gpt-6-astra
```

## 卸载

```shell
cd /Users/fatcat/Application/program/deepseek-harness
PATH=/tmp/pnpm9-shim:$PATH node --import tsx/esm apps/cli/src/bin.ts plugin --profile web remove -w dsh-llm-agentrouter
# 重启 host 生效
```

reconcile 会自动从 `dsh.profile.bundles` 移除。**不会自动清理的残留**，需要手动删：

- `~/.dsh/settings.yaml` 里的 `llm-agentrouter:` 分节和 `llm-pi-ai.providers.agentrouter:` 分节
- `~/.dsh/.credentials.yaml` 里的 `AGENTROUTER_API_KEY`（模型选择器里的 AgentRouter 分组会随 bundle 移除而消失，key 留着无害但没必要）

## 关键边界（摘自上游 README）

- **不要把密钥写进 `headers`**：该字典会被设置界面原样渲染，`apiKeyEnv` 只是引用，密钥放 `.credentials.yaml` 或环境变量。
- **图片输入未声明**：路由是 `defaultInput: [text]`，点名图片会被拒。
- **402 = Claude/GPT 配额耗尽**：中转站预算池用尽时返回 402，围栏会追加 `quotaHint` 提示文案（可在 `llm-agentrouter.quotaHint` 改，空串关闭）。
- 五个内置模型：`claude-opus-5`、`claude-opus-4-8`、`gpt-5.6-sol`、`deepseek-v4-flash`、`glm-5.3`，推理档位各不相同，详见上游 README。
