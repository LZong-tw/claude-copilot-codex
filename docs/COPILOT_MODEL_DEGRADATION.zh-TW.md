# Copilot / Codex 模型能力減損估算

Snapshot: 2026-06-11

Source: `claude-copilot models` live metadata (`copilot_upstream_api_version:
2026-06-01`) plus `claude --help` for Claude Code CLI effort options.

這份文件估算「把 Claude Code 前端接到 GitHub Copilot / Codex 模型」時，相對於完整 Claude Code 訂閱模式（約 1M context + 高 effort）的能力減損。這不是 benchmark 分數，而是根據 gateway 回報的 context、prompt/output limit、context tier、reasoning effort、thinking budget、tool/structured/vision support 做的工程判斷。

## 基準與限制

| 基準項目 | 完整 Claude Code 高配模式 | Copilot / Codex gateway 目前回報 |
|---|---:|---:|
| Context window | 約 1M tokens | Copilot Anthropic/Gemini 最高 1M；Copilot GPT-5.4/5.5 最高 1.05M；獨立 Codex 100k-400k |
| Prompt 上限 | 接近 1M 等級 | Copilot Anthropic/Gemini 936k；Copilot GPT-5.4/5.5 922k；Copilot mini/codex 272k；獨立 Codex 100k/272k/400k |
| Context tiers | Claude Code 方案內部處理 | Copilot 多數長上下文模型回報 `200k(default)` + `long` tier |
| Output 上限 | 依 Claude Code 方案與模型 | 32k / 64k / 128k |
| Effort metadata | 可用高 effort | 多數模型回報 high 或 xhigh；Opus 4.7/4.8 已回報 xhigh/max |
| Claude Code CLI `--effort` | `low/medium/high/xhigh/max` | 不能直接選 metadata 裡的 `none` / `minimal` |
| Context window 控制 | Claude Code / VS Code 有各自 UI | 此 launcher 只能顯示 tier metadata 並傳 base model id；不能替帳號解鎖未授權 tier |

## Metadata 摘要

| Model | Source | Vendor | Context | Max prompt | Max output | Context tiers | Effort | Thinking budget | Vision images | 價格類別 |
|---|---|---|---:|---:|---:|---|---|---:|---:|---|
| `claude-opus-4-6` | Copilot | Anthropic | 1M | 936k | 64k | 200k default / 936k long | low/medium/high/max | 32k | 1 | high |
| `claude-opus-4-7` | Copilot | Anthropic | 1M | 936k | 64k | 200k default / 936k long | low/medium/high/xhigh/max | 32k | 1 | high |
| `claude-opus-4-8` | Copilot | Anthropic | 1M | 936k | 64k | 200k default / 936k long | low/medium/high/xhigh/max | 32k | 1 | high |
| `claude-sonnet-4-6` | Copilot | Anthropic | 1M | 936k | 64k | 200k default / 936k long | low/medium/high/max | 32k | 5 | medium |
| `gpt-5.3-codex` | Copilot | OpenAI | 400k | 272k | 128k | 272k default | low/medium/high/xhigh | n/a | 1 | medium |
| `gpt-5.4` | Copilot | OpenAI | 1.05M | 922k | 128k | 272k default / 922k long | none/low/medium/high/xhigh | n/a | 1 | medium |
| `gpt-5.4-mini` | Copilot | OpenAI | 400k | 272k | 128k | 272k default | none/low/medium/high/xhigh | n/a | 1 | low |
| `gpt-5.5` | Copilot | OpenAI | 1.05M | 922k | 128k | 272k default / 922k long | none/low/medium/high/xhigh | n/a | 1 | high |
| `gemini-3.1-pro-preview` | Copilot | Google | 1M | 936k | 64k | 200k default / 936k long | low/medium/high | 32k | 10 | medium |
| `gemini-3.5-flash` | Copilot | Google | 1M | 936k | 64k | 200k default / 936k long | minimal/low/medium/high | 24k | 10 | medium |
| `gemini-3-flash-preview` | Copilot | Google | 128k | 128k | 64k | - | low/medium/high | 32k | 10 | low |
| `gemini-2.5-pro` | Copilot | Google | 128k | 128k | 64k | - | not reported | 32,768 | 10 | medium |
| `codex/gpt-5.3-codex-spark` | Codex | OpenAI | 100k | 100k | 32k | - | minimal/low/medium/high/xhigh | n/a | 0 | n/a |
| `codex/gpt-5.4` | Codex | OpenAI | 400k | 400k | 128k | - | minimal/low/medium/high/xhigh | n/a | yes | n/a |
| `codex/gpt-5.4-mini` | Codex | OpenAI | 400k | 400k | 128k | - | minimal/low/medium/high/xhigh | n/a | yes | n/a |
| `codex/gpt-5.5` | Codex | OpenAI | 272k | 272k | 128k | - | minimal/low/medium/high/xhigh | n/a | yes | n/a |

Embedding models (`text-embedding-*`) are excluded because they are not chat/coding models.

## 能力保留估算

百分比是相對於「Claude Code 1M context + 高 effort」的可用能力估算；同一模型在不同任務的減損差很多。Copilot 長上下文 tier 出現在 metadata 時，長文任務的主要限制已從「塞不下」改成「模型行為是否等同 Claude 原生、gateway 是否完整保留 Claude Code 的 agent semantics」。

| Model | 日常 coding / 小修 bug | 中型跨檔分析 (<100k context) | 大型 repo / 長 logs (200k+ 原文) | 高難度推理 / 架構 / root cause | 主要減損原因 |
|---|---:|---:|---:|---:|---|
| `claude-opus-4-8` | 90-98% | 86-96% | 78-92% | 78-92% | 模型品質高、936k prompt、xhigh/max 可用；仍經過 Copilot gateway 而非 Claude Code 原生管線 |
| `claude-opus-4-7` | 88-96% | 84-94% | 76-90% | 76-90% | xhigh/max 已開；同為 936k prompt |
| `claude-opus-4-6` | 86-95% | 82-92% | 72-88% | 72-86% | 支援 high/max 但無 xhigh；同為 936k prompt |
| `claude-sonnet-4-6` | 80-92% | 74-88% | 68-84% | 62-80% | Sonnet 階級低於 Opus；但 context/prompt 已接近 1M |
| `gpt-5.3-codex` | 83-94% | 76-90% | 55-78% | 65-85% | coding 強、400k context；Claude-style agent 行為仍有差異 |
| `gpt-5.4` | 84-94% | 80-92% | 76-90% | 68-85% | 922k prompt + xhigh；非 Claude native，工具/指令遵循風格不同 |
| `gpt-5.4-mini` | 65-82% | 55-72% | 50-70% | 40-60% | mini 模型推理/穩定性較弱；長 context 沒有升到 1M |
| `gpt-5.5` | 85-95% | 82-93% | 78-91% | 72-88% | 922k prompt + xhigh；高階 agent reasoning 仍非 Claude Opus |
| `gemini-3.1-pro-preview` | 74-88% | 70-84% | 66-82% | 58-76% | 936k prompt + high；preview 模型仍有穩定性風險 |
| `gemini-3.5-flash` | 62-80% | 56-72% | 54-70% | 40-60% | 936k prompt 但 Flash 型模型，速度/成本優先 |
| `gemini-3-flash-preview` | 55-72% | 40-60% | 20-40% | 35-55% | 128k context；preview/flash 減損明顯 |
| `gemini-2.5-pro` | 65-80% | 55-70% | 20-40% | 50-70% | 128k context；effort metadata 未回報 |
| `codex/gpt-5.4` | 82-94% | 78-90% | 65-82% | 68-85% | 獨立 Codex prompt 400k；但 ChatGPT quota 不在 Copilot dashboard |
| `codex/gpt-5.4-mini` | 65-84% | 58-75% | 55-75% | 42-62% | 400k context 但 mini 推理較弱 |
| `codex/gpt-5.5` | 82-93% | 76-88% | 55-78% | 70-85% | prompt 272k；高階推理仍非 Claude Opus 1M |
| `codex/gpt-5.3-codex-spark` | 72-86% | 58-74% | 25-45% | 45-65% | prompt 100k、output 32k；適合較小 coding 任務 |

## 最佳使用建議

| 需求 | 建議模型 | 理由 |
|---|---|---|
| 最接近 Claude Code / Opus 的日常體驗 | `claude-opus-4-8` | 模型品質高、936k prompt、64k output，且 metadata 已回報 xhigh/max |
| 想要長 prompt 的 coding / refactor | `claude-opus-4-8`、Copilot `gpt-5.5`、`gpt-5.4` | 三者 metadata 都已回報接近 1M prompt 的 long tier |
| 高風險 reasoning 但不想離開 Copilot | `claude-opus-4-8 --effort xhigh` 或 `--effort max` | Claude Code CLI 可傳 xhigh/max；gateway 目前回報 Opus 4.8 支援 |
| 便宜背景任務、摘要、分類 | `gpt-5.4-mini` 或 `codex/gpt-5.4-mini` | context 大但推理較弱，適合低風險任務 |
| 多圖/截圖分析 | Gemini 系列 | Metadata 回報最多 10 張圖；Anthropic/OpenAI 多數 1 張 |
| 最大可靠性 / 原生 Claude Code 行為 | 正常 Claude Code 訂閱模式 | Copilot gateway 即使有長 context，也不是 Claude Code 原生模型供應鏈 |

## VS Code Copilot 的 context / effort UI 對這個 repo 的意義

**這不是單純「不能調 context」：VS Code 確實已在 Language Models UI 暴露 Context Size；此 repo 目前能做的是對齊同一份 models metadata，而不是 hack Claude Code 內建 UI。**

- VS Code Copilot 0.52.0 會用較新的 Copilot models API (`x-github-api-version: 2026-06-01`) 取得 `token_pricing.default.context_max` 與 `token_pricing.long_context.context_max`，UI 才能顯示 `200K(default)` / `1M` 類選項。
- `copilot-api` 1.11.4 的 bundle 仍可能使用較舊 API date；launcher 會在啟動 gateway 前 patch installed `token-*.js`，讓 `/v1/models` 回傳目前 VS Code 能看到的 long-context metadata。
- Claude Code CLI 2.1.159 的 `--effort` 接受值是 `low/medium/high/xhigh/max`。OpenAI/Gemini metadata 裡的 `none` / `minimal` 可以顯示，但不能保證能透過 Claude Code CLI 直接選。
- Claude Code 內建 `/model` picker 不讀 gateway `/v1/models`，也沒有 VS Code 的 Context Size 下拉選單；完整清單和能力欄位仍由 `claude-copilot models` / `pick-model` / shell completion 提供。
- Copilot OpenAI 長上下文模型在 `/v1/models` 可能以 `gpt-5.5[1m]` 這類 display id 出現，但實際 Anthropic-compatible request 要送 `gpt-5.5`。launcher 會把 `[1m]` 當 alias 顯示/接受，並在送 Claude Code 前移除。

## 實務判斷

Copilot Opus 已不是「被砍到 200k + medium」的狀態；在 `2026-06-01` metadata 下，Opus 4.7/4.8 回報 `xhigh/max` 與 936k prompt long tier。主要風險改成：

1. **Context tier 是帳號/endpoint metadata，不是保證解鎖**：你的帳號看得到 long tier 才有意義；wrapper 不能替別人打開。
2. **Claude Code 沒有 VS Code 的 Context Size UI**：此 repo 顯示 tier 並傳 base model id，但不修改 Claude Code client 的內建 picker。
3. **CLI effort 與 provider metadata 不完全同一套**：Claude Code CLI 只接受 `low/medium/high/xhigh/max`；metadata 的 `none/minimal` 是 provider 側能力描述。
4. **模型行為差異**：OpenAI/Codex 在 coding 和長 prompt 很強，但不等於 Claude Opus 的 agent 行為；高風險 architecture / incident RCA 仍要用證據鏈和工具驗證。

因此：

- **日常 coding**：Copilot Opus / Codex 可當主力，能力保留通常 80-98%。
- **長上下文 coding/logs**：若你的 metadata 有 long tier，Copilot Opus 或 GPT-5.5/5.4 都可接近 1M 原文；獨立 Codex 仍以 400k 內較穩。
- **高風險架構與 incident root cause**：仍建議切回正常 Claude Code 1M + 高 effort，或把任務拆小、先用工具收斂證據再丟給 Copilot/Codex 模型。
