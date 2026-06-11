# claude-copilot-codex

[繁體中文 README](README.zh-TW.md) · [Detailed setup](docs/SETUP.md) · [繁體中文設定文件](docs/SETUP.zh-TW.md)

Run **Claude Code** with **GitHub Copilot** and/or **OpenAI Codex (ChatGPT)** as the
backend — without touching your existing `~/.claude/settings.json`.

It's a thin wrapper around [`@jeffreycao/copilot-api`](https://github.com/caozhiyuan/copilot-api)
(a local OpenAI/Anthropic-compatible gateway for Copilot + Codex) plus an isolated
launcher that starts the gateway and runs Claude Code with its own
`CLAUDE_CONFIG_DIR`.

```
claude (front end)
  │  ANTHROPIC_BASE_URL=http://localhost:4141
  ▼
copilot-api (local gateway, :4141)
  ├─ provider: copilot → GitHub Copilot       (device-flow OAuth)
  └─ provider: codex   → OpenAI Codex / ChatGPT (browser OAuth)
```

Your normal `claude` (e.g. a company gateway) is unaffected. The launcher uses
a clean process environment plus `claude --setting-sources "" --settings ...`,
so Claude Code does not load your global `~/.claude/settings.json` while this
mode is running.

## Why

- Reuse a **Copilot** and/or **ChatGPT** subscription as the model behind Claude Code.
- Keep one front end (`claude`) while switching the engine.
- No edits to your global Claude config.

## Install

```sh
git clone https://github.com/LZong-tw/claude-copilot-codex.git && cd claude-copilot-codex
./install.sh
```

`install.sh` will:
- copy `settings.example.json` → `~/.config/claude-copilot/settings.json` (won't overwrite),
- symlink `bin/claude-copilot` into `~/.local/bin`,
- install `copilot-api` globally via bun or npm if missing.

Requirements: `bun` (recommended) or Node.js ≥ 22.13, `claude` CLI, `curl`, `python3`,
and `sqlite3` (for the `usage` view). A GitHub Copilot subscription and/or a
ChatGPT/Codex plan.

## Use

```sh
claude-copilot auth          # one-time: Copilot device-flow + Codex browser OAuth
claude-copilot models        # list all Copilot + Codex models usable by Claude Code
claude-copilot pick-model    # interactive full model picker; saves default
claude-copilot pick-model codex/gpt-5.4
claude-copilot completion zsh # shell completion; also supports bash/fish
claude-copilot copilot-models # raw /v1/models
claude-copilot codex-models  # raw /codex/v1/models
claude-copilot               # start gateway (if needed) and open Claude Code
claude-copilot --model gpt-5.5 "fix this"
claude-copilot --model codex/gpt-5.4 "fix this"
claude-copilot "fix this"    # any args pass through to `claude`
claude-copilot status        # gateway health
claude-copilot stop          # stop the gateway
claude-copilot usage         # Copilot quota + local token usage (incl. Codex)
```

## Choosing the model

`claude-copilot models` refreshes `~/.config/claude-copilot/models.json` from both
gateway endpoints and prints every model id Claude Code can receive, plus the
reported context window, prompt/output limits, and reasoning effort levels:

- Copilot `/v1/models` as-is, e.g. `claude-opus-4.8`, `gpt-5.5`, `gpt-5.3-codex`.
- Codex `/codex/v1/models` with the required `codex/` prefix, e.g.
  `codex/gpt-5.4`.

Use any chat model directly with `claude-copilot --model <id> ...`. If `--model`
is omitted, the launcher passes the `ANTHROPIC_MODEL` from
`~/.config/claude-copilot/settings.json` (default `claude-opus-4.8`). The small
background model is `ANTHROPIC_DEFAULT_HAIKU_MODEL` (default `gpt-5.4-mini`).

Claude Code's built-in `/model` picker only shows its built-in Claude aliases
plus the three custom Opus/Sonnet/Haiku slots; it does not expose arbitrary
gateway models. Use `claude-copilot pick-model` for the full Copilot + Codex
list, or enable shell completion so `claude-copilot --model <TAB>` completes
every chat model from the catalog:

```sh
# zsh
source <(claude-copilot completion zsh)

# bash
source <(claude-copilot completion bash)

# fish
claude-copilot completion fish | source
```

Because `--setting-sources ""` intentionally prevents loading your global
settings, the launcher copies through only the global `effortLevel` value by
passing `--effort <value>` unless you already provided `--effort` yourself.

## Context window and effort

Effort is exposed through Claude Code's own `--effort` flag. Claude Code 2.1.159
accepts `low`, `medium`, `high`, `xhigh`, and `max`; the launcher preserves your
global `effortLevel` or your explicit `claude-copilot --effort ...` choice.

Context window is not a local toggle. It is the server-side limit reported by
your Copilot/Codex account for each model, so this repo can display and use the
reported `context_window`, `max_prompt`, and `max_output` metadata, but it cannot
unlock larger windows for other users. Check your live values with:

```sh
claude-copilot models
```

## Usage & quota

- `claude-copilot usage` shows **Copilot** quota (from `/usage`) and **local token
  counts per provider/model** (from `~/.local/share/copilot-api/copilot-api.sqlite`),
  including standalone Codex requests (`provider_name = codex`).
- See [`docs/COPILOT_MODEL_DEGRADATION.zh-TW.md`](docs/COPILOT_MODEL_DEGRADATION.zh-TW.md)
  for model-by-model capability degradation estimates versus full Claude Code
  1M context + high-effort usage.
- Standalone Codex **remaining** quota is **not** visible here — it lives on your
  ChatGPT plan (check at chatgpt.com). Copilot-hosted `gpt-5.3-codex` *does* count
  against Copilot quota and shows in the dashboard.
- Web dashboard (Copilot only): `http://localhost:4141/usage-viewer?endpoint=http://localhost:4141/usage`

## Notes & caveats

- Use model ids like `claude-opus-4.8` / `codex/gpt-5.4` (no `[1m]` suffix).
  Sending context far beyond
  Copilot's window may get your account flagged.
- The detailed setup guide is available in [English](docs/SETUP.md) and
  [Traditional Chinese](docs/SETUP.zh-TW.md).
- `WebSearch` is denied (Copilot API has no native web search) — install an MCP
  fetch/search tool instead if needed.
- `copilot-api` reverse-engineers GitHub Copilot endpoints. **This may violate the
  GitHub Copilot / OpenAI Terms of Service. Use at your own risk.** For opencode users,
  the `--oauth-app=opencode` login lowers ToS risk.
- Credentials live in `~/.local/share/copilot-api/` and are **not** part of this repo
  (see `.gitignore`). Never commit `codex_credentials.json` or `github_token`.

## Optional: add a router (CCR)

This covers Copilot **and** Codex with a single front end. If you later want
scenario-based routing (default / background / longContext / think across multiple
models), put [`claude-code-router`](https://github.com/musistudio/claude-code-router)
in front and add `http://localhost:4141` as one of its providers.

## Credits

- Gateway: [caozhiyuan/copilot-api](https://github.com/caozhiyuan/copilot-api)
- Router idea: [musistudio/claude-code-router](https://github.com/musistudio/claude-code-router)

## License

MIT
