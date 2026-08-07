# Claude Code Dotfiles

Personal Claude Code configuration managed as dotfiles.

## Layout

- `claude-user/CLAUDE.md`: global personal instructions installed to `$CLAUDE_CONFIG_DIR/CLAUDE.md`
- `claude-user/settings.json`: global Claude Code settings installed to `$CLAUDE_CONFIG_DIR/settings.json`
- `claude-user/agents/`: personal subagents installed to `$CLAUDE_CONFIG_DIR/agents/`
- `claude-user/skills/`: personal skills installed to `$CLAUDE_CONFIG_DIR/skills/`
- `claude-user/hooks/`: personal hooks installed to `$CLAUDE_CONFIG_DIR/hooks/`
- `scripts/install.sh`: installs the personal config with backups
- `scripts/install-skills.sh`: installs only personal skills for Claude Code or Codex
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

Install only personal skills:

```sh
scripts/install-skills.sh claude
scripts/install-skills.sh codex
scripts/install-skills.sh all
```

Claude Code skills use `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills/`. Codex skills default to `~/.agents/skills/`; set `CODEX_SKILLS_DIR` to override it:

```sh
CODEX_SKILLS_DIR=~/.codex/skills scripts/install-skills.sh codex
```

Existing files are backed up under the selected tool's config root at `backups/dotfiles-<timestamp>/` before being overwritten.

The installer validates managed JSON and shell files before writing to the target directory.
JSON validation requires either `jq` or `python3`.
Skill structure and names are always validated. Metadata is checked per Skill with the cached `skills` CLI in offline mode when available; a skipped metadata check warns but does not block installation.

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
