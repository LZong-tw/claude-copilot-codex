# claude-copilot

Run **Claude Code** with **GitHub Copilot** and/or **OpenAI Codex (ChatGPT)** as the
backend — without touching your existing `~/.claude/settings.json`.

It's a thin wrapper around [`@jeffreycao/copilot-api`](https://github.com/caozhiyuan/copilot-api)
(a local OpenAI/Anthropic-compatible gateway for Copilot + Codex) plus an isolated
launcher that starts the gateway and runs `claude --settings <isolated.json>`.

```
claude (front end)
  │  ANTHROPIC_BASE_URL=http://localhost:4141
  ▼
copilot-api (local gateway, :4141)
  ├─ provider: copilot → GitHub Copilot       (device-flow OAuth)
  └─ provider: codex   → OpenAI Codex / ChatGPT (browser OAuth)
```

Your normal `claude` (e.g. a company gateway) is unaffected — this uses a separate
settings file via `--settings`, so the two never collide.

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
claude-copilot models        # list Copilot models
claude-copilot codex-models  # list standalone Codex models
claude-copilot               # start gateway (if needed) and open Claude Code
claude-copilot "fix this"    # any args pass through to `claude`
claude-copilot status        # gateway health
claude-copilot stop          # stop the gateway
claude-copilot usage         # Copilot quota + local token usage (incl. Codex)
```

## Choosing the model

Edit `~/.config/claude-copilot/settings.json` (`env` block). Set the three main
model vars together when switching engines:

| Want | `ANTHROPIC_MODEL` / `_OPUS_` / `_SONNET_` | Quota source |
| --- | --- | --- |
| Copilot Claude (default) | `claude-opus-4.6` | Copilot |
| Copilot-hosted Codex | `gpt-5.3-codex` | Copilot |
| Standalone Codex (ChatGPT) | `codex/gpt-5.4` | ChatGPT plan |

`ANTHROPIC_DEFAULT_HAIKU_MODEL` is the small/background model (default `gpt-5-mini`).
After changes: `claude-copilot stop && claude-copilot start`.

Model lists depend on your plan — confirm with `claude-copilot models` /
`claude-copilot codex-models`. Standalone Codex models are reached with the
`codex/` prefix (the gateway doesn't list provider models in `/v1/models` by design).

## Usage & quota

- `claude-copilot usage` shows **Copilot** quota (from `/usage`) and **local token
  counts per provider/model** (from `~/.local/share/copilot-api/copilot-api.sqlite`),
  including standalone Codex requests (`provider_name = codex`).
- Standalone Codex **remaining** quota is **not** visible here — it lives on your
  ChatGPT plan (check at chatgpt.com). Copilot-hosted `gpt-5.3-codex` *does* count
  against Copilot quota and shows in the dashboard.
- Web dashboard (Copilot only): `http://localhost:4141/usage-viewer?endpoint=http://localhost:4141/usage`

## Notes & caveats

- Use model id `claude-opus-4.6` (no `[1m]` suffix). Sending context far beyond
  Copilot's window may get your account flagged.
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
