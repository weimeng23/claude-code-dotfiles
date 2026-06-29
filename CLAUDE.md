# CLAUDE.md

This repository stores my personal Claude Code dotfiles.

## Scope

Keep this repo personal-first. Do not add team templates, shared MCP servers, or organization policy unless explicitly requested.

The default install target is `~/.claude/`. When `CLAUDE_CONFIG_DIR` is set, install there instead:

- `claude-user/CLAUDE.md` -> `$CLAUDE_CONFIG_DIR/CLAUDE.md`
- `claude-user/settings.json` -> `$CLAUDE_CONFIG_DIR/settings.json`
- `claude-user/agents/` -> `$CLAUDE_CONFIG_DIR/agents/`
- `claude-user/skills/` -> `$CLAUDE_CONFIG_DIR/skills/`
- `claude-user/hooks/` -> `$CLAUDE_CONFIG_DIR/hooks/`

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

After changing install behavior, run `scripts/validate.sh` and inspect the script flow before using it against the resolved target directory.
