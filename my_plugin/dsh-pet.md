# @linxin666/dsh-pet

注册表驱动的多宠物伴侣插件（host 半区 + client 半区一个包）：内置鲸鱼娘，也接受任何「`pet.json` manifest + 一张图集」的自定义宠物。

- npm：https://www.npmjs.com/package/@linxin666/dsh-pet （本机装的是 0.3.22，`-E` 精确锁定）
- 仓库：https://github.com/zhu1090093659/dsh-web-ui
- 作者同系列：`@linxin666/dsh-web-all`（全家桶）、`dsh-pet`、`dsh-usage`、`dsh-client-ui-skin-center`

## ⚠️ 含不可关闭的外发遥测

`lib/client.js` 启动时会上报一次（每天最多一次）：

```js
const ENDPOINT = "https://dsh-market.com/api/telemetry/event";
reportDailyHeartbeat([{ name: "@linxin666/dsh-pet" }]);
// body: { kind: "heartbeat", visitor: <localStorage 随机 32 位 hex>,
//         items: [{ name: "@linxin666/dsh-pet", version: "0.3.22" }] }
```

- 只发**插件名 + 版本 + 持久匿名 ID**，不含会话内容/密钥/代码
- 无开关；`navigator.webdriver` 为真时跳过
- **安装后想关掉，两种办法：**
  1. 网络层拦截（推荐，一劳永逸）：`sudo sh -c 'echo "0.0.0.0 dsh-market.com" >> /etc/hosts'`
  2. 本地改 `~/.dsh/profiles/web/node_modules/@linxin666/dsh-pet/lib/client.js`，让 `reportDailyHeartbeat` 首行 `return`（注意下次 `pnpm install` 可能被 pnpm store 还原）

其余审计干净：无 `child_process`/`eval`、无 install 脚本、宠物 API 全走同源 `/api/pet/*`、无其他外部域名。

## 安装

```shell
# 本机无全局 dsh，从源码 checkout 运行；profile 的 node_modules 是 pnpm 9.15.4 布局，
# 系统 pnpm 12 会报 ERR_PNPM_PUBLIC_HOIST_PATTERN_DIFF，必须用 shim
# （shim 重建步骤见 dsh-chinese-thinking.md）
cd /Users/fatcat/Application/program/deepseek-harness
PATH=/tmp/pnpm9-shim:$PATH node --import tsx/esm apps/cli/src/bin.ts plugin --profile web add -w -E @linxin666/dsh-pet

# 重启 Web GUI 生效（bundle 层栈在启动时解析）
```

- 包自带 `dsh.bundle` 声明，reconcile 自动登记进 `dsh.profile.bundles`，无需手改
- 插件要求 `dsh >= 0.1.5-rc.1`（本机 0.1.5-rc.2 ✓），客户端平台 `web`
- 包体 16MB（内置图集 + Live2D Cubism vendor）

## 功能

| 能力 | 说明 |
|---|---|
| 多宠物注册表 | 宿主扫描内置 `assets/`、自定义宠物目录、组合配置条目；每只宠物 = `pet.json` + 图集，不用改代码 |
| 设置入口 | 一级设置分区「宠物」，卡片列出所有已注册宠物，切换即持久化 |
| 状态动画 | 会话活动 → manifest 定义的 9 态轨道；等待/思考/调工具/整理/完成/失败各不同 |
| 互动 | 点击摸头（+1 亲密度，10s 冷却）；喂小鱼干（+5，30s 冷却）；库存上限 20，每 30 轮 +1、每 5 小时 +1 |
| 亲密度 | 每完成一轮 +1，9 级从「幼鲸」到「鲸生共渡」 |
| 多会话气泡 | 顶层会话各用自己气泡报告状态，+N 角标收纳其余，点击跳转对应会话；子代理借父会话体现 |
| 碎碎念 | 流式输出期间按「正在干什么」触发独白；不读模型原文、不引用路径/工具名 |
| 语音包 DIY | 宠物目录 `voice.json` + 全局 `$DSH_HOME/pets/.voice.json` 覆盖所有文案与面板 |
| 拖动/隐藏 | 位置持久化；面板可隐藏，隐藏后出现「召唤{name}」按钮 |

## 卸载

```shell
cd /Users/fatcat/Application/program/deepseek-harness
PATH=/tmp/pnpm9-shim:$PATH node --import tsx/esm apps/cli/src/bin.ts plugin --profile web remove -w @linxin666/dsh-pet
# 重启 GUI 生效
```

reconcile 会自动从 bundles 移除。**不会自动清理**的残留：
- **`~/.dsh/pet.json`** ← 状态文件本体：当前宠物 id、各宠物名字、亲密度（points/pets/turns）、小鱼干库存、显示位置与尺寸、gameplay 数据
- `~/.dsh/pets/`（自定义宠物目录与 `.voice.json`，如创建过）
- 浏览器 localStorage 的 `dsh-web-ui-telemetry-visitor` / `dsh-web-ui-telemetry-day:*`

## 运维备注

- **健康检查**：`curl -s http://127.0.0.1:3080/api/pet/state` 返回当前动画/气泡/阶段（`idle`/`thinking`/`tool`…）与它感知到的会话列表——插件活着且能正确识别工具调用。
- 状态文件 `~/.dsh/pet.json` 是纯文本 JSON，可直接读改（如手工调亲密度）。
- 本机实测：装完重启 GUI 后立即生效，无需其他配置。
