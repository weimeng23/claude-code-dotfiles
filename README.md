# Claude Code Dotfiles

Personal Claude Code configuration managed as dotfiles.

## Layout

- `claude-user/CLAUDE.md`: global personal instructions installed to `~/.claude/CLAUDE.md`
- `claude-user/settings.json`: global Claude Code settings installed to `~/.claude/settings.json`
- `claude-user/agents/`: personal subagents installed to `~/.claude/agents/`
- `claude-user/skills/`: personal skills installed to `~/.claude/skills/`
- `claude-user/hooks/`: personal hooks installed to `~/.claude/hooks/`
- `scripts/install.sh`: installs the personal config with backups
- `scripts/validate.sh`: validates JSON and shell scripts

## Install

Preview the files first:

```sh
find claude-user -type f -print
```

Install to `~/.claude/`:

```sh
scripts/install.sh
```

Use a different target directory:

```sh
CLAUDE_HOME=/tmp/claude-test scripts/install.sh
```

Existing files are backed up under `~/.claude/backups/dotfiles-<timestamp>/` before being overwritten.

To install into an alternate Claude Code config directory:

```sh
CLAUDE_CONFIG_DIR=~/.claude-work scripts/install.sh
```

The hook commands in `settings.json` use `CLAUDE_CONFIG_DIR` when it is set and fall back to `~/.claude`.

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
