# claude-copilot-codex

[English README](README.md) · [English setup](docs/SETUP.md) · [繁體中文設定文件](docs/SETUP.zh-TW.md)

用 **GitHub Copilot** 和／或 **OpenAI Codex（ChatGPT）** 當後端跑 **Claude Code**，而且不改你原本的 `~/.claude/settings.json`。

這個 repo 是 [`@jeffreycao/copilot-api`](https://github.com/caozhiyuan/copilot-api) 的薄包裝：`copilot-api` 在本機提供 OpenAI/Anthropic 相容 gateway，`claude-copilot` launcher 則用隔離設定啟動 Claude Code。

```text
claude (front end)
  │  ANTHROPIC_BASE_URL=http://localhost:4141
  ▼
copilot-api (local gateway, :4141)
  ├─ provider: copilot → GitHub Copilot       (device-flow OAuth)
  └─ provider: codex   → OpenAI Codex / ChatGPT (browser OAuth)
```

你的正常 `claude`（例如公司 gateway）不會被影響。launcher 會用乾淨 process environment 和 `claude --setting-sources "" --settings ...`，所以這個模式不會載入全域 `~/.claude/settings.json`。

## 為什麼

- 重用 **Copilot** 和／或 **ChatGPT** 訂閱，當 Claude Code 的模型後端。
- 保留同一個前端（`claude`），但可以切換不同引擎。
- 不改你的全域 Claude 設定。

## 安裝

```sh
git clone https://github.com/LZong-tw/claude-copilot-codex.git && cd claude-copilot-codex
./install.sh
```

`install.sh` 會：

- 複製 `settings.example.json` → `~/.config/claude-copilot/settings.json`（若已存在不覆蓋）；
- 將 `bin/claude-copilot` symlink 到 `~/.local/bin`；
- 若找不到 `copilot-api`，用 bun 或 npm 全域安裝。

需求：`bun`（建議）或 Node.js ≥ 22.13、`claude` CLI、`curl`、`python3`、`sqlite3`（用量查詢用），以及 GitHub Copilot 訂閱和／或 ChatGPT/Codex 方案。

## 使用

```sh
claude-copilot auth           # 第一次：Copilot device-flow + Codex browser OAuth
claude-copilot models         # 列出 Claude Code 可用的 Copilot + Codex models
claude-copilot pick-model     # 完整互動選單；儲存預設模型
claude-copilot pick-model codex/gpt-5.4
claude-copilot completion zsh # shell completion，也支援 bash/fish
claude-copilot copilot-models # 原始 /v1/models
claude-copilot codex-models   # 原始 /codex/v1/models
claude-copilot patch-api-version # 將 copilot-api 對齊 VS Code 目前 models API
claude-copilot                # 啟動 gateway（若需要）並開 Claude Code
claude-copilot --model gpt-5.5 "fix this"
claude-copilot --model codex/gpt-5.4 "fix this"
claude-copilot "fix this"     # 其他參數直接傳給 claude
claude-copilot status         # gateway health
claude-copilot stop           # 停掉 gateway
claude-copilot usage          # Copilot quota + 本機 token usage（含 Codex）
```

## 選模型

`claude-copilot models` 會從兩個 gateway endpoint 更新 `~/.config/claude-copilot/models.json`，並列出所有可傳給 Claude Code 的 model id，以及各模型回報的 context window、prompt/output 上限、context tiers、reasoning effort：

- Copilot `/v1/models` 原樣使用，例如 `claude-opus-4-8`、`gpt-5.5`、`gpt-5.3-codex`。
- Codex `/codex/v1/models` 會自動加上必要的 `codex/` 前綴，例如 `codex/gpt-5.4`。

任何 chat model 都可以直接用：

```sh
claude-copilot --model <id> ...
```

若省略 `--model`，launcher 會把 `~/.config/claude-copilot/settings.json` 的 `ANTHROPIC_MODEL` 傳給 Claude Code 的 `--model`（預設 `claude-opus-4-8`）。背景小模型是 `ANTHROPIC_DEFAULT_HAIKU_MODEL`（預設 `gpt-5.4-mini`）。

Claude Code 內建 `/model` picker 只會顯示內建 Claude alias 加上三個 custom Opus/Sonnet/Haiku slot，不會顯示任意 gateway model。完整 Copilot + Codex 清單請用 `claude-copilot pick-model`，或開 shell completion 讓 `claude-copilot --model <TAB>` 直接補全：

```sh
# zsh
source <(claude-copilot completion zsh)

# bash
source <(claude-copilot completion bash)

# fish
claude-copilot completion fish | source
```

因為 `--setting-sources ""` 會刻意阻止載入你的全域 settings，launcher 會另外只讀全域 `effortLevel`，並用 `--effort <value>` 原樣塞回 Claude Code；若你已手動傳 `--effort`，就以你指定的為準。

## Context window 和 effort

Effort 走 Claude Code 自己的 `--effort` 參數。Claude Code 2.1.159 接受 `low`、`medium`、`high`、`xhigh`、`max`；launcher 會保留你的全域 `effortLevel`，或使用你手動指定的 `claude-copilot --effort ...`。

目前 VS Code Copilot 使用較新的 Copilot models API（`2026-06-01`），會回傳 `200K(default)` 與 `long`（依模型約 `936k` 或 `922k` prompt）這類 context tiers。launcher 會在啟動 gateway 前 patch 已安裝的 `copilot-api` bundle，把上游 API version 對齊這個版本，因為 upstream `copilot-api` 可能還停在舊日期；若之後 upstream 跟上，可用 `CLAUDE_COPILOT_UPSTREAM_API_VERSION` 覆蓋。

Claude Code 在這個模式沒有 VS Code 的 Context Size 選單。wrapper 可以顯示同樣的 tier metadata，也接受像 `gpt-5.5[1m]` 這種 alias，但實際送 request 前會移除 `[1m]`，因為本機 gateway 接受的是 `gpt-5.5` 這種 base model id。它也不能替其他帳號解鎖更大的 window；long-context tier 必須出現在你自己的 model metadata。請用下面指令看 live values：

```sh
claude-copilot models
```

## 用量與額度

- `claude-copilot usage` 會顯示 **Copilot** quota（來自 `/usage`）與**本機 token usage**（來自 `~/.local/share/copilot-api/copilot-api.sqlite`），包含獨立 Codex 請求（`provider_name = codex`）。
- 各模型相對完整 Claude Code 1M context + high-effort 的能力減損估算，見 [`docs/COPILOT_MODEL_DEGRADATION.zh-TW.md`](docs/COPILOT_MODEL_DEGRADATION.zh-TW.md)。
- 獨立 Codex 的**剩餘**額度不會出現在這裡；它屬於你的 ChatGPT plan，請到 chatgpt.com 查。Copilot 託管的 `gpt-5.3-codex` 則會算 Copilot quota。
- Web dashboard（只含 Copilot）：`http://localhost:4141/usage-viewer?endpoint=http://localhost:4141/usage`

## 注意事項

- Model id 請用 `claude-opus-4-8` / `codex/gpt-5.4` 這種形式，不要加 `[1m]` 後綴。丟超過 Copilot context window 太多的內容可能會讓帳號被標記。
- 詳細設定文件有 [English](docs/SETUP.md) 與 [繁體中文](docs/SETUP.zh-TW.md) 版本。
- `WebSearch` 已 deny；Copilot API 沒有原生 web search，需要時請改裝 MCP fetch/search。
- `copilot-api` 逆向 GitHub Copilot endpoint，**可能違反 GitHub Copilot / OpenAI Terms of Service，請自行評估風險**。opencode 使用者可用 `--oauth-app=opencode` 降低 ToS 風險。
- 憑證存在 `~/.local/share/copilot-api/`，不屬於本 repo（見 `.gitignore`）。不要 commit `codex_credentials.json` 或 `github_token`。

## Optional: add a router (CCR)

本專案用單一前端同時涵蓋 Copilot **和** Codex。若之後想做情境式 routing（default / background / longContext / think 對不同模型），可以把 [`claude-code-router`](https://github.com/musistudio/claude-code-router) 放在前面，並把 `http://localhost:4141` 設成其中一個 provider。

## Credits

- Gateway: [caozhiyuan/copilot-api](https://github.com/caozhiyuan/copilot-api)
- Router idea: [musistudio/claude-code-router](https://github.com/musistudio/claude-code-router)

## License

MIT
