# codex_status_tmux

Show remaining Codex limits in your tmux status bar using local session data (`~/.codex/sessions/*.jsonl`).

Example:
- `5h 93%`
- `week 71% (6d)`
- `cr N/A`

`(6d)` is the number of days remaining until the weekly reset.
`5h` / `week` prefer the main limit (`limit_id=codex`) over Spark limits. (Updated: 2026-02-27 ET, via MCP time)
`cr` shows credit balance when available, otherwise `N/A`. (Updated: 2026-02-27 ET, via MCP time)

## Prerequisites

- `tmux`
- `jq`

## Install

```bash
git clone <your-repo-url>
cd codex_status_tmux
chmod +x scripts/codex_limits_tmux.sh
mkdir -p "$HOME/.local/bin"
cp scripts/codex_limits_tmux.sh "$HOME/.local/bin/codex_limits_tmux.sh"
```

## tmux config

Add this to `~/.tmux.conf`:

```tmux
set -g status-interval 30
set -g status-left-length 40
set -g status-right-length 120
set -g status-left '#[bold]#S#[default] '
set -g status-right '#($HOME/.local/bin/codex_limits_tmux.sh) | %Y-%m-%d %H:%M '
```

Apply:

```bash
tmux source-file ~/.tmux.conf
```

## Color Rules

- White text + green background: remaining > 25%
- White text + yellow background: remaining 11-25%
- White text + red background: remaining <= 10%
