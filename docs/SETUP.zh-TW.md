# Claude Code × GitHub Copilot / Codex 設定文件

用 `caozhiyuan/copilot-api` 把 **GitHub Copilot + Codex（OAuth）** 包成本機
Anthropic 相容 endpoint，讓 `claude`（Claude Code）當前端使用，**不影響**你既有的
公司 gateway 設定。

---

## 1. 架構

```
claude (前端)
   │  ANTHROPIC_BASE_URL=http://localhost:4141
   ▼
copilot-api (本機 gateway, port 4141)
   ├─ provider: copilot  → GitHub Copilot（device-flow OAuth）
   └─ provider: codex    → Codex / ChatGPT（browser OAuth）
```

- `copilot-api` 出算力 + 處理 OAuth 登入與 token 自動刷新。
- 公司用的 `~/.claude/settings.json`（`llm-gateway.kkcompany-internal.com`）**完全沒被更動**。
  啟動器會用乾淨環境，並用
  `claude --setting-sources "" --settings ~/.config/claude-copilot/settings.json`
  啟動，避免 Claude Code 載入全域 `apiKeyHelper`／MCP／plugin；你的全域設定不會被改。

---

## 2. 已安裝 / 已建立的東西

| 項目 | 路徑 | 說明 |
|---|---|---|
| copilot-api | `~/.bun/bin/copilot-api`（v1.10.28，bun global） | 本機 gateway |
| 隔離 config 目錄 | `~/.config/claude-copilot/` | Claude Code 的獨立 settings/log/session 目錄；啟動時用 `--setting-sources ""` 避免讀取全域設定 |
| 啟動器 | `~/.local/bin/claude-copilot` | 自動拉起 server 再開 claude |
| server log | `~/.config/claude-copilot/server.log` | 排錯看這裡 |

`~/.bun/bin` 與 `~/.local/bin` 都已在 PATH。

---

## 3. ⚠️ 還沒做的一步：OAuth 登入（需你本人 + 瀏覽器）

我無法代替你在瀏覽器授權，請執行下面兩個指令各一次（之後 token 會自動刷新，不必重登）。

### 3-1 Copilot（device flow）
```sh
copilot-api auth login --provider copilot
```
終端會印出一組代碼，例如 `XXXX-XXXX`，並要你開
**https://github.com/login/device** 輸入代碼，用**有 Copilot 訂閱**的 GitHub 帳號授權。

> 降低 ToS 風險（建議）：若你也用 opencode，可改用 opencode 的 OAuth app：
> `copilot-api --oauth-app=opencode auth login --provider copilot`

### 3-2 Codex（ChatGPT browser OAuth）
```sh
copilot-api auth login --provider codex
```
會開瀏覽器登入 ChatGPT / Codex，憑證自動保存與刷新。
（沒有 Codex/ChatGPT 訂閱可略過，純用 Copilot。）

完成後驗證：
```sh
claude-copilot start      # 拉起 server
claude-copilot models     # 應印出可用模型 JSON
```

---

## 4. 日常用法

```sh
claude-copilot            # 自動啟動 server（若沒開）並進入 Claude Code
claude-copilot status     # 看 server 是否在跑
claude-copilot stop       # 停掉 server
claude-copilot "幫我看這段程式"   # 後面參數直接傳給 claude
```

要回到公司 gateway，就照舊用原本的 `claude`，兩者井水不犯河水。

---

## 5. 切換模型（含 Codex）

### 你帳號實際可用的模型（已實測，business 方案）

**Copilot 主流（`/v1/models`，走 Copilot 額度）**
`claude-opus-4.6` / `claude-opus-4.7` / `claude-opus-4.8` / `claude-sonnet-4.6` /
`gpt-5.4` / `gpt-5.4-mini` / `gpt-5.5` / **`gpt-5.3-codex`** /
`gemini-3.1-pro-preview` / `gemini-3.5-flash` / `gemini-2.5-pro` …

**獨立 Codex provider（`/codex/v1/models`，走你的 ChatGPT 訂閱額度）**
用 `codex/` 前綴呼叫：`codex/gpt-5.4` / `codex/gpt-5.4-mini` / `codex/gpt-5.5` /
`codex/gpt-5.3-codex-spark`

> 為什麼 `/v1/models` 看不到 Codex？這是 copilot-api 刻意設計——預設清單不聚合
> provider 模型。Codex 模型在 `/codex/v1/models`，用 `codex/<model>` 前綴存取。

### 模型如何餵進 Claude Code

`claude-copilot models` 會同時抓：

- Copilot `/v1/models`：原樣餵給 Claude Code，例如 `claude-opus-4.8`、
  `claude-sonnet-4.6`、`gpt-5.5`、`gpt-5.3-codex`、Gemini 等。
- Codex `/codex/v1/models`：自動加上 `codex/` 前綴後餵給 Claude Code，例如
  `codex/gpt-5.4`、`codex/gpt-5.4-mini`、`codex/gpt-5.5`。

合併後的 catalog 會寫到 `~/.config/claude-copilot/models.json`。

單次指定：

```sh
claude-copilot --model gpt-5.5 "幫我看這段"
claude-copilot --model codex/gpt-5.4 "幫我看這段"
```

完整互動選單（會寫入預設 `ANTHROPIC_MODEL`）：

```sh
claude-copilot pick-model
claude-copilot pick-model codex/gpt-5.4
```

Claude Code 內建 `/model` 目前只會列出內建 Claude alias 加上三個 custom
Opus/Sonnet/Haiku slot，不會把任意 gateway model 全部展開；完整清單要用
`claude-copilot pick-model` 或 `claude-copilot models`。

如果你沒有手動給 `--model`，啟動器會把
`~/.config/claude-copilot/settings.json` 裡的 `ANTHROPIC_MODEL` 轉成
Claude Code 的 `--model` 參數。

`--setting-sources ""` 會刻意不讀公司用的全域 settings，所以啟動器會另外**只讀**
`~/.claude/settings.json` 的 `effortLevel`，並原封不動用 `--effort <值>` 塞回
Claude Code；如果你自己已經傳 `--effort`，就以你手動指定為準。

### 預設模型設定：編輯 `~/.config/claude-copilot/settings.json` 的 `env`

```jsonc
{
  "env": {
    "ANTHROPIC_BASE_URL": "http://localhost:4141",
    "ANTHROPIC_AUTH_TOKEN": "dummy",            // 本機不驗，任意字串
    "ANTHROPIC_MODEL": "claude-opus-4.8",        // ← 沒手動 --model 時的主模型
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "claude-opus-4.8",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "claude-sonnet-4.6",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "gpt-5.4-mini" // 背景小任務（Copilot）
  }
}
```

### 用 Codex 當主力時：

| 想用 | 單次指定 | 或把 `ANTHROPIC_MODEL` 設成 | 額度 | 實測 |
|---|---|---|---|---|
| Copilot 託管 codex | `--model gpt-5.3-codex` | `gpt-5.3-codex` | Copilot | ✅ |
| 你的 ChatGPT Codex | `--model codex/gpt-5.4` | `codex/gpt-5.4` | ChatGPT | ✅ |

改 settings 後不需要重啟 Claude Code server；下次執行 `claude-copilot` 會重新讀。

> 註：獨立 Codex（`codex/…`）後端**強制 streaming + 需要 system**，Claude Code 本來
> 就都會帶，正常使用沒問題；只有用裸 curl 少帶欄位才會看到
> `Instructions are required` / `Stream must be set to true`。

---

## 6. README 重要警告（務必遵守）

- Claude Code 的 model ID 用 `claude-opus-4.8` / `claude-sonnet-4.6`，**不要加 `[1m]` 後綴**；
  丟超出 Copilot context window 太多的內容**可能被官方 ban**。
- 已在隔離 settings 關掉非必要流量（`DISABLE_NON_ESSENTIAL_MODEL_CALLS` 等）以省 quota。
- 已 `deny` WebSearch：Copilot API 不支援原生網搜，建議改裝 `mcp_server_fetch` 之類工具。
- 此 gateway 屬逆向 GitHub Copilot 端點，**可能違反 Copilot / OpenAI ToS，自行評估風險**。

---

## 7. 額度與用量（含 Codex）

**重點：官方 Usage Dashboard（`/usage-viewer` → `/usage`）的額度進度條只涵蓋 GitHub
Copilot，看不到獨立 Codex（ChatGPT）的剩餘額度。** 已實測 `/usage` 只回 Copilot 資料
（`copilot_for_business_seat_quota` / `quota_snapshots`）。

| 你怎麼用 Codex | 剩餘額度去哪看 | 本機 token 消耗 |
|---|---|---|
| Copilot 託管 `gpt-5.3-codex` | ✅ Dashboard quota 進度條（算 Copilot 額度） | ✅ 本機 sqlite |
| 獨立 `codex/gpt-5.4`（ChatGPT） | ❌ Dashboard 看不到 → 去 **chatgpt.com 帳號設定** | ✅ 本機 sqlite（provider=codex） |

### 看用量的方式

```sh
claude-copilot usage      # 一次看：Copilot 額度 + 本機各 provider/model token 統計（含 Codex）
```

或直接看圖形 Dashboard（僅 Copilot 額度）：
`http://localhost:4141/usage-viewer?endpoint=http://localhost:4141/usage`

本機 token 紀錄存在 `~/.local/share/copilot-api/copilot-api.sqlite`（表 `token_usage_events`，
有 `provider_name` / `model` 欄位）。已實測獨立 Codex 請求會以 `provider_name=codex` 記錄，
所以**本機花了多少 token 看得到，但 ChatGPT 方案的剩餘上限要去 OpenAI 那邊查**。

```sh
# 自己下 SQL 也行：
sqlite3 ~/.local/share/copilot-api/copilot-api.sqlite \
  "SELECT provider_name, model, SUM(total_tokens) FROM token_usage_events GROUP BY 1,2;"
```

---

## 8. 疑難排解

| 症狀 | 處理 |
|---|---|
| `claude-copilot start` 報 not healthy | 多半沒登入；跑第 3 節的 auth 指令 |
| 401 / 模型不存在 | 用 `claude-copilot models` 看實際模型名，改 settings |
| port 4141 被占用 | `COPILOT_API_PORT=4142 claude-copilot`（base_url 也要同步改） |
| 看詳細錯誤 | `tail -f ~/.config/claude-copilot/server.log` |
| 想用 GUI | 下載 Electron 桌面版：github.com/caozhiyuan/copilot-api/releases |

---

## 9. 進階：要不要加 CCR（claude-code-router）？

本方案只用 `copilot-api` 就同時涵蓋 Copilot + Codex，**單一前端即可**。
只有當你想要「不同任務自動分流到不同模型」（default / background / longContext / think）
時才需要再疊 CCR，把這個 `http://localhost:4141` 當成 CCR 的一個 provider。
目前不需要。
