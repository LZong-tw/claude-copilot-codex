# Copilot / Codex 模型能力減損估算

Snapshot: 2026-06-11

Source: local `copilot-api` `/v1/models` + `/codex/v1/models` metadata, and `claude --help` for Claude Code CLI effort options.

這份文件估算「把 Claude Code 前端接到 GitHub Copilot / Codex 模型」時，相對於完整 Claude Code 訂閱模式（約 1M context + 高 effort）的能力減損。這不是 benchmark 分數，而是根據 gateway 回報的 context、prompt/output limit、reasoning effort、thinking budget、tool/structured/vision support 做的工程判斷。

## 基準與限制

| 基準項目 | 完整 Claude Code 高配模式 | Copilot / Codex gateway 目前回報 |
|---|---:|---:|
| Context window | 約 1M tokens | Copilot Anthropic/Gemini 多為 264k；Copilot OpenAI 400k；獨立 Codex 100k-400k |
| Prompt 上限 | 接近 1M 等級 | Copilot Anthropic/Gemini 200k；Copilot OpenAI 272k；獨立 Codex 100k/272k/400k |
| Output 上限 | 依 Claude Code 方案與模型 | 32k / 64k / 128k |
| Effort metadata | 可用高 effort | 多數模型回報 high 或 xhigh；Opus 4.7/4.8 已回報 xhigh/max |
| Claude Code CLI `--effort` | `low/medium/high/xhigh/max` | 不能直接選 metadata 裡的 `none` / `minimal` |
| Context window 控制 | 由模型/帳號/服務端決定 | launcher 只能讀取並顯示上限，不能替使用者解鎖更大 context |

## Metadata 摘要

| Model | Source | Vendor | Context | Max prompt | Max output | Effort | Thinking budget | Vision images | 價格類別 |
|---|---|---|---:|---:|---:|---|---:|---:|---|
| `claude-opus-4.6` | Copilot | Anthropic | 264k | 200k | 64k | low/medium/high/max | 32k | 1 | high |
| `claude-opus-4.7` | Copilot | Anthropic | 264k | 200k | 64k | low/medium/high/xhigh/max | 32k | 1 | high |
| `claude-opus-4.8` | Copilot | Anthropic | 264k | 200k | 64k | low/medium/high/xhigh/max | 32k | 1 | high |
| `claude-sonnet-4.6` | Copilot | Anthropic | 264k | 200k | 64k | low/medium/high/max | 32k | 5 | medium |
| `gpt-5.3-codex` | Copilot | OpenAI | 400k | 272k | 128k | low/medium/high/xhigh | n/a | 1 | medium |
| `gpt-5.4` | Copilot | OpenAI | 400k | 272k | 128k | none/low/medium/high/xhigh | n/a | 1 | medium |
| `gpt-5.4-mini` | Copilot | OpenAI | 400k | 272k | 128k | none/low/medium/high/xhigh | n/a | 1 | low |
| `gpt-5.5` | Copilot | OpenAI | 400k | 272k | 128k | none/low/medium/high/xhigh | n/a | 1 | high |
| `gemini-3.1-pro-preview` | Copilot | Google | 264k | 200k | 64k | low/medium/high | 32k | 10 | medium |
| `gemini-3.5-flash` | Copilot | Google | 264k | 200k | 64k | minimal/low/medium/high | 24k | 10 | medium |
| `gemini-3-flash-preview` | Copilot | Google | 128k | 128k | 64k | low/medium/high | 32k | 10 | low |
| `gemini-2.5-pro` | Copilot | Google | 128k | 128k | 64k | not reported | 32,768 | 10 | medium |
| `codex/gpt-5.3-codex-spark` | Codex | OpenAI | 100k | 100k | 32k | minimal/low/medium/high/xhigh | n/a | 0 | n/a |
| `codex/gpt-5.4` | Codex | OpenAI | 400k | 400k | 128k | minimal/low/medium/high/xhigh | n/a | yes | n/a |
| `codex/gpt-5.4-mini` | Codex | OpenAI | 400k | 400k | 128k | minimal/low/medium/high/xhigh | n/a | yes | n/a |
| `codex/gpt-5.5` | Codex | OpenAI | 272k | 272k | 128k | minimal/low/medium/high/xhigh | n/a | yes | n/a |

Embedding models (`text-embedding-*`) are excluded because they are not chat/coding models.

## 能力保留估算

百分比是相對於「Claude Code 1M context + 高 effort」的可用能力估算；同一模型在不同任務的減損差很多。

| Model | 日常 coding / 小修 bug | 中型跨檔分析 (<100k context) | 大型 repo / 長 logs (200k+ 原文) | 高難度推理 / 架構 / root cause | 主要減損原因 |
|---|---:|---:|---:|---:|---|
| `claude-opus-4.8` | 88-96% | 80-92% | 45-68% | 75-90% | 模型品質高且已支援 xhigh/max；但 prompt 仍是 200k，不是 1M |
| `claude-opus-4.7` | 86-95% | 78-90% | 45-68% | 73-88% | xhigh/max 已開；context/prompt 同上 |
| `claude-opus-4.6` | 85-94% | 76-88% | 42-65% | 70-85% | 支援 high/max 但無 xhigh；context/prompt 同上 |
| `claude-sonnet-4.6` | 78-90% | 68-82% | 42-62% | 60-78% | Sonnet 階級低於 Opus；但 264k context + high/max 可用 |
| `gpt-5.3-codex` | 83-94% | 76-90% | 55-78% | 65-85% | coding 強、400k context；Claude-style agent 行為仍有差異 |
| `gpt-5.4` | 80-92% | 72-88% | 55-78% | 65-82% | 400k context + xhigh；非 Claude native |
| `gpt-5.4-mini` | 65-82% | 55-72% | 50-70% | 40-60% | mini 模型推理/穩定性較弱；適合便宜背景任務 |
| `gpt-5.5` | 82-93% | 76-88% | 55-78% | 70-85% | 400k context + xhigh；高階 agent reasoning 仍非 Claude Opus |
| `gemini-3.1-pro-preview` | 72-86% | 66-80% | 42-62% | 58-76% | 264k context + high；preview 模型仍有穩定性風險 |
| `gemini-3.5-flash` | 60-78% | 50-68% | 38-58% | 40-60% | Flash 型模型，速度/成本優先 |
| `gemini-3-flash-preview` | 55-72% | 40-60% | 20-40% | 35-55% | 128k context；preview/flash 減損明顯 |
| `gemini-2.5-pro` | 65-80% | 55-70% | 20-40% | 50-70% | 128k context；effort metadata 未回報 |
| `codex/gpt-5.4` | 82-94% | 78-90% | 65-82% | 68-85% | 獨立 Codex prompt 400k；但 ChatGPT quota 不在 Copilot dashboard |
| `codex/gpt-5.4-mini` | 65-84% | 58-75% | 55-75% | 42-62% | 400k context 但 mini 推理較弱 |
| `codex/gpt-5.5` | 82-93% | 76-88% | 55-78% | 70-85% | prompt 272k；高階推理仍非 Claude Opus 1M |
| `codex/gpt-5.3-codex-spark` | 72-86% | 58-74% | 25-45% | 45-65% | prompt 100k、output 32k；適合較小 coding 任務 |

## 最佳使用建議

| 需求 | 建議模型 | 理由 |
|---|---|---|
| 最接近 Claude Code / Opus 的日常體驗 | `claude-opus-4.8` | 模型品質高、64k output，且 metadata 已回報 xhigh/max |
| 想要長 prompt 的 coding / refactor | `codex/gpt-5.4` 或 Copilot `gpt-5.5` | Codex `gpt-5.4` prompt 400k；Copilot OpenAI 系列 prompt 272k |
| 高風險 reasoning 但不想離開 Copilot | `claude-opus-4.8 --effort xhigh` 或 `--effort max` | Claude Code CLI 可傳 xhigh/max；gateway 目前回報 Opus 4.8 支援 |
| 便宜背景任務、摘要、分類 | `gpt-5.4-mini` 或 `codex/gpt-5.4-mini` | context 大但推理較弱，適合低風險任務 |
| 多圖/截圖分析 | Gemini 系列 | Metadata 回報最多 10 張圖；Anthropic/OpenAI 多數 1 張 |
| 最大可靠性 / 1M 原文上下文 | 正常 Claude Code 訂閱模式 | Copilot/Codex gateway 不能替你解鎖 1M context |

## VS Code Copilot 的 context / effort UI 對這個 repo 的意義

**Effort 可以暴露給使用者；context window 只能讀 metadata，不能任意調大。**

- `copilot-api` 目前會把 Copilot `/chat/completions` 與 Anthropic `/v1/messages` payload 原樣轉送；Claude Code 送出的 thinking/effort 類欄位可沿著 request 傳到 gateway。
- Claude Code CLI 2.1.159 的 `--effort` 接受值是 `low/medium/high/xhigh/max`。OpenAI/Gemini metadata 裡的 `none` / `minimal` 可以顯示，但不能保證能透過 Claude Code CLI 直接選。
- Context window 是「帳號 + model endpoint + Copilot/ChatGPT feature flag」回報的服務端上限。launcher 可以顯示 `context_window` / `max_prompt` / `max_output`，但不能幫別人的帳號打開未授權的 400k 或 1M。
- Claude Code 內建 `/model` picker 不讀 gateway `/v1/models`，因此完整清單和能力欄位仍由 `claude-copilot models` / `pick-model` / shell completion 提供；要讓內建 `/model` 顯示所有選項才需要 patch Claude Code client。

## 實務判斷

Copilot Opus 不是「被砍到 medium」了；截至這次 snapshot，Opus 4.7/4.8 已回報 `xhigh/max`，主要減損改成：

1. **Prompt 仍不是 1M**：Opus/Gemini 多為 200k prompt，OpenAI Copilot 為 272k，獨立 Codex 最高 400k。塞得進時品質接近；塞不進時仍要靠工具搜尋、分批讀檔、摘要。
2. **CLI effort 與 provider metadata 不完全同一套**：Claude Code CLI 只接受 `low/medium/high/xhigh/max`；metadata 的 `none/minimal` 是 provider 側能力描述。
3. **模型行為差異**：OpenAI/Codex 在 coding 和長 prompt 很強，但不等於 Claude Opus 的 agent 行為；高風險 architecture / incident RCA 仍要用證據鏈和工具驗證。

因此：

- **日常 coding**：Copilot Opus / Codex 可當主力，能力保留通常 80-95%。
- **長上下文 coding/logs**：`codex/gpt-5.4` 或 Copilot OpenAI 系列通常比 Copilot Opus 更能塞原文。
- **高風險架構與 incident root cause**：仍建議切回正常 Claude Code 1M + 高 effort，或把任務拆小、先用工具收斂證據再丟給 Copilot/Codex 模型。
