# Claude Code Dotfiles

Personal Claude Code configuration managed as dotfiles.

## Layout

- `claude-user/CLAUDE.md`: global personal instructions installed to `$CLAUDE_CONFIG_DIR/CLAUDE.md`
- `claude-user/settings.json`: global Claude Code settings installed to `$CLAUDE_CONFIG_DIR/settings.json`
- `claude-user/agents/`: personal subagents installed to `$CLAUDE_CONFIG_DIR/agents/`
- `claude-user/skills/`: personal skills installed to `$CLAUDE_CONFIG_DIR/skills/`
- `claude-user/hooks/`: personal hooks installed to `$CLAUDE_CONFIG_DIR/hooks/`
- `scripts/install.sh`: installs the personal config with backups
- `scripts/validate.sh`: validates JSON and shell scripts

## Install

Preview the files first:

```sh
find claude-user -type f -print
```

Install to `~/.claude/`, the default Claude Code config directory:

```sh
scripts/install.sh
```

Install to a different Claude Code config directory:

```sh
CLAUDE_CONFIG_DIR=~/.claude-work scripts/install.sh
```

Existing files are backed up under `$CLAUDE_CONFIG_DIR/backups/dotfiles-<timestamp>/` before being overwritten.

The hook commands in `settings.json` use `CLAUDE_CONFIG_DIR` when it is set and fall back to `~/.claude`.

The installer copies managed files but does not delete stale files that already exist in the target directory.

Included personal skills:

- `karpathy-guidelines`: concise coding discipline for simple, surgical, verified changes.

## Validate

```sh
scripts/validate.sh
```

## Do Not Commit

Do not store these in this repository:

- `~/.claude.json`
- `.claude/settings.local.json`
- `CLAUDE.local.md`
- API keys, tokens, cookies, OAuth sessions, or private credentials
- generated logs, caches, or temporary files
