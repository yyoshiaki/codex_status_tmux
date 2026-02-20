# codex_status_tmux

Codex のローカルセッション情報 (`~/.codex/sessions/*.jsonl`) から、tmux のステータスバーに利用枠の残量を表示します。

表示例:
- `5h 93%`
- `week 71% (6d)`

`week` の `(6d)` は週次リセットまでの残り日数です。

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

`~/.tmux.conf` に追加:

```tmux
set -g status-interval 30
set -g status-left-length 40
set -g status-right-length 120
set -g status-left '#[bold]#S#[default] '
set -g status-right '#($HOME/.local/bin/codex_limits_tmux.sh) | %Y-%m-%d %H:%M '
```

反映:

```bash
tmux source-file ~/.tmux.conf
```

## Color rules

- White text + green background: remaining > 25%
- White text + yellow background: remaining 11-25%
- White text + red background: remaining <= 10%
