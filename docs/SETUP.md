# Claude Code × GitHub Copilot / Codex Setup

[繁體中文設定文件](SETUP.zh-TW.md) · [English README](../README.md) · [繁體中文 README](../README.zh-TW.md)

Use `caozhiyuan/copilot-api` to expose **GitHub Copilot + Codex (OAuth)** as a local Anthropic-compatible endpoint, then run `claude` (Claude Code) as the front end **without affecting** your existing company gateway setup.

---

## 1. Architecture

```text
claude (front end)
   │  ANTHROPIC_BASE_URL=http://localhost:4141
   ▼
copilot-api (local gateway, port 4141)
   ├─ provider: copilot  → GitHub Copilot (device-flow OAuth)
   └─ provider: codex    → Codex / ChatGPT (browser OAuth)
```

- `copilot-api` supplies the backend and handles OAuth login + token refresh.
- Your normal `~/.claude/settings.json` is **not modified**. The launcher starts Claude Code with a clean environment and:

```sh
claude --setting-sources "" --settings ~/.config/claude-copilot/settings.json
```

This prevents Claude Code from loading global `apiKeyHelper`, MCP servers, plugins, and status line settings while the Copilot/Codex mode is running.

---

## 2. Installed / created files

| Item | Path | Purpose |
|---|---|---|
| `copilot-api` | `~/.bun/bin/copilot-api` or npm global bin | Local gateway |
| Isolated config dir | `~/.config/claude-copilot/` | Separate settings/log/session directory for Copilot mode |
| Launcher | `~/.local/bin/claude-copilot` | Starts the gateway if needed, then opens Claude Code |
| Server log | `~/.config/claude-copilot/server.log` | Debug gateway startup/runtime errors |

Make sure `~/.local/bin` and your bun/npm global bin directory are in `PATH`.

---

## 3. OAuth login

These steps require your browser. Run them once; tokens are stored under `~/.local/share/copilot-api/` and refreshed automatically.

### 3-1. GitHub Copilot (device flow)

```sh
copilot-api auth login --provider copilot
```

The terminal prints a code like `XXXX-XXXX`. Open **https://github.com/login/device**, enter the code, and authorize with a GitHub account that has a Copilot subscription.

> Lower ToS-risk option: if you also use opencode, you can use the opencode OAuth app:
>
> ```sh
> copilot-api --oauth-app=opencode auth login --provider copilot
> ```

### 3-2. Codex / ChatGPT (browser OAuth)

```sh
copilot-api auth login --provider codex
```

This opens a browser login for ChatGPT / Codex. Skip it if you only want Copilot.

Verify after login:

```sh
claude-copilot start
claude-copilot models
```

---

## 4. Daily usage

```sh
claude-copilot                       # start server if needed, then open Claude Code
claude-copilot status                # check gateway health
claude-copilot stop                  # stop the gateway process started by the launcher
claude-copilot "review this code"    # pass arguments through to claude
```

To go back to your company gateway, use your normal `claude` command.

---

## 5. Model switching (including Codex)

### Available model families

Copilot `/v1/models` returns models such as:

```text
claude-opus-4.6 / claude-opus-4.7 / claude-opus-4.8 / claude-sonnet-4.6
gpt-5.4 / gpt-5.4-mini / gpt-5.5 / gpt-5.3-codex
gemini-3.1-pro-preview / gemini-3.5-flash / gemini-2.5-pro / ...
```

Standalone Codex provider models live under `/codex/v1/models` and are used with a `codex/` prefix:

```text
codex/gpt-5.4 / codex/gpt-5.4-mini / codex/gpt-5.5 / codex/gpt-5.3-codex-spark
```

Why does `/v1/models` not include standalone Codex? That is how `copilot-api` separates provider models. The launcher merges both endpoints for you.

### How models are passed into Claude Code

`claude-copilot models` fetches both:

- Copilot `/v1/models` as-is, e.g. `claude-opus-4.8`, `gpt-5.5`, `gpt-5.3-codex`.
- Codex `/codex/v1/models` with the required `codex/` prefix, e.g. `codex/gpt-5.4`.

The merged catalog is saved to:

```text
~/.config/claude-copilot/models.json
```

One-off model selection:

```sh
claude-copilot --model gpt-5.5 "review this"
claude-copilot --model codex/gpt-5.4 "review this"
```

Interactive full model picker:

```sh
claude-copilot pick-model
claude-copilot pick-model codex/gpt-5.4
```

Claude Code's built-in `/model` picker currently shows only built-in Claude aliases and the three custom Opus/Sonnet/Haiku slots. It does **not** expand arbitrary gateway models. To make `/model` itself show all gateway models, you would effectively have to patch/hack the Claude Code client, which is brittle and not recommended for this public repo.

The stable alternative is shell completion:

```sh
# zsh
source <(claude-copilot completion zsh)

# bash
source <(claude-copilot completion bash)

# fish
claude-copilot completion fish | source
```

Then `claude-copilot --model <TAB>` and `claude-copilot pick-model <TAB>` complete the full chat model catalog.

If you omit `--model`, the launcher reads `ANTHROPIC_MODEL` from `~/.config/claude-copilot/settings.json` and passes it to Claude Code as `--model`.

Because `--setting-sources ""` intentionally prevents loading global settings, the launcher separately reads only `effortLevel` from `~/.claude/settings.json` and passes it through as `--effort <value>`. If you provide `--effort` yourself, your explicit value wins.

See [`COPILOT_MODEL_DEGRADATION.zh-TW.md`](COPILOT_MODEL_DEGRADATION.zh-TW.md) for model-by-model capability tradeoff estimates versus full Claude Code 1M context + higher-effort usage.

### Default model settings

Edit `~/.config/claude-copilot/settings.json`:

```jsonc
{
  "env": {
    "ANTHROPIC_BASE_URL": "http://localhost:4141",
    "ANTHROPIC_AUTH_TOKEN": "dummy",
    "ANTHROPIC_MODEL": "claude-opus-4.8",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "claude-opus-4.8",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "claude-sonnet-4.6",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "gpt-5.4-mini"
  }
}
```

Using Codex as the main model:

| Goal | One-off command | Or set `ANTHROPIC_MODEL` to | Quota source |
|---|---|---|---|
| Copilot-hosted Codex | `--model gpt-5.3-codex` | `gpt-5.3-codex` | Copilot |
| ChatGPT Codex | `--model codex/gpt-5.4` | `codex/gpt-5.4` | ChatGPT |

Changing settings does not require restarting the gateway; the next `claude-copilot` launch re-reads settings.

> Standalone Codex (`codex/...`) requires streaming and a system/instructions field. Claude Code sends those normally; bare curl requests can fail with `Instructions are required` or `Stream must be set to true` if fields are missing.

---

## 6. Important warnings

- Use model ids like `claude-opus-4.8`, `claude-sonnet-4.6`, or `codex/gpt-5.4`; do **not** add a `[1m]` suffix.
- Sending context far beyond the Copilot model's window may get your account flagged.
- Non-essential Claude Code traffic is disabled in the isolated settings to save quota.
- `WebSearch` is denied because Copilot API does not support native web search. Use an MCP fetch/search tool instead if needed.
- This gateway reverse-engineers GitHub Copilot endpoints and may violate GitHub Copilot / OpenAI Terms of Service. Use at your own risk.

---

## 7. Quota and usage, including Codex

The official usage dashboard (`/usage-viewer` → `/usage`) only covers GitHub Copilot quota. It does **not** show remaining standalone Codex / ChatGPT quota.

| Codex path | Remaining quota | Local token usage |
|---|---|---|
| Copilot-hosted `gpt-5.3-codex` | Dashboard quota bars (Copilot quota) | Local sqlite |
| Standalone `codex/gpt-5.4` | Not visible here; check ChatGPT account settings | Local sqlite (`provider=codex`) |

Use:

```sh
claude-copilot usage
```

Or open the Copilot-only dashboard:

```text
http://localhost:4141/usage-viewer?endpoint=http://localhost:4141/usage
```

Local token records are stored in `~/.local/share/copilot-api/copilot-api.sqlite`, table `token_usage_events`, with `provider_name` and `model` columns.

```sh
sqlite3 ~/.local/share/copilot-api/copilot-api.sqlite \
  "SELECT provider_name, model, SUM(total_tokens) FROM token_usage_events GROUP BY 1,2;"
```

---

## 8. Troubleshooting

| Symptom | Fix |
|---|---|
| `claude-copilot start` does not become healthy | Usually not logged in; run the auth commands in section 3 |
| 401 / model not found | Run `claude-copilot models` and use an actual model id |
| Port 4141 is occupied | Use `COPILOT_API_PORT=4142 claude-copilot` and update `ANTHROPIC_BASE_URL` accordingly |
| Need detailed errors | `tail -f ~/.config/claude-copilot/server.log` |
| Want the GUI | Download the Electron build from `github.com/caozhiyuan/copilot-api/releases` |

---

## 9. Optional: CCR (`claude-code-router`)

This launcher already covers Copilot + Codex with one front end. You only need CCR if you want scenario-based routing across multiple providers, such as default / background / longContext / think. In that case, add `http://localhost:4141` as one CCR provider.

