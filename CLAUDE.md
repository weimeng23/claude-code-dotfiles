# CLAUDE.md

This repository stores my personal Claude Code dotfiles.

## Scope

Keep this repo personal-first. Do not add team templates, shared MCP servers, or organization policy unless explicitly requested.

The install target is `~/.claude/`:

- `claude-user/CLAUDE.md` -> `~/.claude/CLAUDE.md`
- `claude-user/settings.json` -> `~/.claude/settings.json`
- `claude-user/agents/` -> `~/.claude/agents/`
- `claude-user/skills/` -> `~/.claude/skills/`
- `claude-user/hooks/` -> `~/.claude/hooks/`

## Safety

Never commit secrets or Claude runtime state:

- `~/.claude.json`
- `.claude/settings.local.json`
- `CLAUDE.local.md`
- API keys, tokens, OAuth sessions, cookies, or credentials
- generated logs, caches, or temporary files

Examples that need secrets should use environment variable placeholders such as `${ANTHROPIC_API_KEY}`.

## Editing Rules

Keep changes small and reversible.

Before changing Claude Code paths or config keys, verify the current docs or schema. Prefer stable user-scope files over project-scope templates in this repo.

Use `apply_patch` for manual edits. Do not overwrite existing user files in install scripts without creating a timestamped backup.

## Validation

After editing JSON, validate that it parses.

After editing shell scripts, run `bash -n`.

After changing install behavior, run `scripts/validate.sh` and inspect the script flow before using it against `~/.claude/`.
