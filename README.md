# codex_status_tmux

Show remaining Codex limits in your tmux status bar using local session data (`~/.codex/sessions/*.jsonl`). (Updated: 2026-03-12 ET, via MCP time)

## What This Repo Covers

- `scripts/codex_limits_tmux.sh`: prints `5h`, `week`, and `cr` segments for tmux status bars. (Updated: 2026-03-12 ET, via MCP time)
- `docs/260312_vscode_tmux_workflow_ja.md`: Japanese notes for the custom McCleary workflow that launches VS Code on a compute node and attaches to the paired tmux session. (Updated: 2026-03-12 ET, via MCP time)
- `docs/260312_vscode_tmux_workflow_en.md`: English version of the same workflow notes. (Updated: 2026-03-12 ET, via MCP time)

## Current Status Output

Example:
- `5h 93%`
- `week 71% (6d)`
- `cr N/A`

Notes:
- `(6d)` is the number of days remaining until the weekly reset. (Updated: 2026-03-12 ET, via MCP time)
- `5h` / `week` prefer the main limit (`limit_id=codex`) over Spark limits when both are present. (Updated: 2026-03-12 ET, via MCP time)
- `cr` shows credit balance when available, otherwise `N/A`. (Updated: 2026-03-12 ET, via MCP time)

## Prerequisites

- `tmux` (Updated: 2026-03-12 ET, via MCP time)
- `jq` (Updated: 2026-03-12 ET, via MCP time)

## Install

```bash
git clone <your-repo-url>
cd codex_status_tmux
chmod +x scripts/codex_limits_tmux.sh
mkdir -p "$HOME/.local/bin"
cp scripts/codex_limits_tmux.sh "$HOME/.local/bin/codex_limits_tmux.sh"
```

## tmux Config

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

- White text + green background: remaining > 25%. (Updated: 2026-03-12 ET, via MCP time)
- White text + yellow background: remaining 11-25%. (Updated: 2026-03-12 ET, via MCP time)
- White text + red background: remaining <= 10%. (Updated: 2026-03-12 ET, via MCP time)

## McCleary Workflow Notes

This repo also documents a custom advanced-user workflow for McCleary where a Slurm job launches a VS Code tunnel on a compute node and creates a tmux session on that same compute node so Codex or other terminal work can be traced live. (Updated: 2026-03-12 ET, via MCP time)

Important context:
- YCRC currently recommends Open OnDemand Code Server for most users. (Updated: 2026-03-12 ET, via MCP time)
- Remote Tunnel / Remote SSH workflows should target compute nodes, not login nodes. (Updated: 2026-03-12 ET, via MCP time)
- The tmux pattern documented in YCRC docs is to start `tmux` on the login node and run `salloc` inside it; the workflow described in `docs/` intentionally differs because it keeps a traceable tmux session inside the VS Code job itself. (Updated: 2026-03-12 ET, via MCP time)

See:
- Japanese: `docs/260312_vscode_tmux_workflow_ja.md`
- English: `docs/260312_vscode_tmux_workflow_en.md`
