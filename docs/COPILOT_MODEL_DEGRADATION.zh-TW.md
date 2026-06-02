# Copilot 模型能力減損估算

Snapshot: 2026-06-02  
Source: local `copilot-api` `/v1/models` metadata.

這份文件估算「把 Claude Code 前端接到 GitHub Copilot 模型」時，相對於完整 Claude Code 訂閱模式（約 1M context + `xhigh`/更高 thinking effort）的能力減損。這不是 benchmark 分數，而是根據 gateway 回報的 context、prompt/output limit、reasoning effort、thinking budget、tool/structured/vision support 做的工程判斷。

## 基準與限制

| 基準項目 | 完整 Claude Code 高配模式 | Copilot gateway 常見限制 |
|---|---:|---:|
| Context window | 約 1M tokens | 128k / 200k / 400k |
| Prompt 上限 | 接近 1M 等級 | 128k / 136k / 168k / 272k |
| Effort | 可用 `xhigh` / 更高 | 依模型不同，Opus 4.7/4.8 只回報 `medium` |
| Long-context 原文保留 | 很強 | 需要更依賴 grep、分批讀檔、摘要 |
| Tool calling | 支援 | Copilot chat models 也多數支援 |

## Metadata 摘要

| Model | Vendor | Context | Max prompt | Max output | Effort | Thinking budget | Vision images | 價格類別 |
|---|---|---:|---:|---:|---|---:|---:|---|
| `claude-opus-4.6` | Anthropic | 200k | 168k | 32k | low/medium/high | 32k | 1 | high |
| `claude-opus-4.7` | Anthropic | 200k | 168k | 32k | medium | 32k | 1 | high |
| `claude-opus-4.8` | Anthropic | 200k | 168k | 64k | medium | 32k | 1 | high |
| `claude-sonnet-4.6` | Anthropic | 200k | 168k | 32k | low/medium/high | 32k | 5 | medium |
| `gpt-5.3-codex` | OpenAI | 400k | 272k | 128k | low/medium/high/xhigh | n/a | 1 | medium |
| `gpt-5.4` | OpenAI | 400k | 272k | 128k | low/medium/high/xhigh | n/a | 1 | medium |
| `gpt-5.4-mini` | OpenAI | 400k | 272k | 128k | none/low/medium/high/xhigh | n/a | 1 | low |
| `gpt-5.5` | OpenAI | 400k | 272k | 128k | none/low/medium/high/xhigh | n/a | 1 | high |
| `gemini-3.1-pro-preview` | Google | 200k | 136k | 64k | low/medium/high | 32k | 10 | medium |
| `gemini-3.5-flash` | Google | 200k | 128k | 64k | low/medium/high | 24k | 10 | medium |
| `gemini-3-flash-preview` | Google | 128k | 128k | 64k | low/medium/high | 32k | 10 | low |
| `gemini-2.5-pro` | Google | 128k | 128k | 64k | not reported | 32,768 | 10 | medium |

Embedding models (`text-embedding-*`) are excluded because they are not chat/coding models.

## 能力保留估算

百分比是相對於「Claude Code 1M context + `xhigh`/更高 effort」的可用能力估算；同一模型在不同任務的減損差很多。

| Model | 日常 coding / 小修 bug | 中型跨檔分析 (<100k context) | 大型 repo / 長 logs (200k+ 原文) | 高難度推理 / 架構 / root cause | 主要減損原因 |
|---|---:|---:|---:|---:|---|
| `claude-opus-4.6` | 85-95% | 75-90% | 35-60% | 60-80% | 200k context；但仍有 high effort |
| `claude-opus-4.7` | 80-90% | 70-85% | 35-60% | 45-65% | effort 只回報 medium；200k context |
| `claude-opus-4.8` | 80-90% | 70-85% | 35-60% | 45-65% | effort 只回報 medium；200k context；輸出較長 |
| `claude-sonnet-4.6` | 75-88% | 65-80% | 35-55% | 50-70% | 模型階級低於 Opus；但 effort 支援 high |
| `gpt-5.3-codex` | 80-92% | 75-90% | 55-78% | 65-85% | coding 強、400k context；Claude-style agent reasoning 不一定等同 |
| `gpt-5.4` | 78-90% | 70-85% | 55-75% | 65-80% | 400k context + xhigh；非 Claude native 行為差異 |
| `gpt-5.4-mini` | 60-80% | 50-70% | 50-70% | 35-55% | mini 模型推理/穩定性較弱；適合便宜背景任務 |
| `gpt-5.5` | 80-92% | 75-88% | 55-75% | 70-85% | 400k context + xhigh；高階推理仍不是 Claude Opus 1M |
| `gemini-3.1-pro-preview` | 70-85% | 65-80% | 35-55% | 55-75% | 200k context、136k prompt；preview 風險 |
| `gemini-3.5-flash` | 55-75% | 45-65% | 30-50% | 35-55% | Flash 型模型，速度/成本優先 |
| `gemini-3-flash-preview` | 55-72% | 40-60% | 20-40% | 35-55% | 128k context；preview/flash 減損明顯 |
| `gemini-2.5-pro` | 65-80% | 55-70% | 20-40% | 50-70% | 128k context；effort metadata 未回報 |

## 最佳使用建議

| 需求 | 建議模型 | 理由 |
|---|---|---|
| 最接近 Claude Code / Opus 的日常體驗 | `claude-opus-4.8` | 模型品質高、輸出 64k；但 effort 只有 medium |
| 想保留 high effort 的 Anthropic 模型 | `claude-opus-4.6` 或 `claude-sonnet-4.6` | Opus 4.6 / Sonnet 4.6 metadata 回報支援 high |
| coding / refactor / patch 取向 | `gpt-5.3-codex` | Codex 系列對 coding workflow 通常更貼近 |
| 長一點的 repo context / logs | `gpt-5.5` 或 `gpt-5.4` | 400k context、272k prompt 比 Claude/Gemini 200k 更寬 |
| 便宜背景任務、摘要、分類 | `gpt-5.4-mini` 或 `gemini-3-flash-preview` | 成本低，但不要拿來做高風險推理 |
| 多圖/截圖分析 | Gemini 系列 | Metadata 回報最多 10 張圖；Anthropic/OpenAI 多數 1 張 |

## 實務判斷

Copilot Opus 不是「變笨」，而是被兩個外部限制壓住：

1. **Context 大幅縮小**：200k / 168k prompt 相對 1M 只剩約 17-20% 原文容量。任務塞得進時品質仍高；塞不進時就會被迫摘要、分批讀檔，錯失跨檔線索的機率上升。
2. **Thinking effort 不完整**：Opus 4.7 / 4.8 metadata 只回報 `medium`，所以即使 wrapper 把你的全域 `effortLevel=high/xhigh` 原封不動傳入，gateway/model 端也可能只按 medium 處理。

因此：

- **日常 coding**：Copilot Opus / Codex 可當主力，能力保留通常 75-90%。
- **長上下文任務**：400k OpenAI 系列通常比 200k Opus 更實用，但不等於 Claude 1M。
- **高風險架構與 incident root cause**：仍建議切回正常 Claude Code 1M + `xhigh`，或把任務拆小、先用工具收斂證據再丟給 Copilot 模型。

