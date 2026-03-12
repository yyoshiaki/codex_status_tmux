# McCleary で VS Code ジョブと tmux を一緒に立ち上げる運用

更新日: 2026-03-12 ET（via MCP time）

## 概要

この文書は、McCleary の計算ノード上で VS Code を動かしつつ、同じジョブの中で tmux セッションも立ち上げて、あとからそのセッションを追跡できるようにしている個人運用を、同僚向けに説明するためのメモです。更新日: 2026-03-12 ET（via MCP time）

YCRC の一般向け推奨は Open OnDemand の Code Server です。これは公式ドキュメントでも「most users 向けの推奨」とされています。更新日: 2026-03-12 ET（via MCP time）

一方で、この運用は advanced users 向けです。Slurm ジョブの中で VS Code Remote Tunnel を起動し、そのジョブ内に tmux セッションも作っておくことで、Codex や shell 作業をあとから `vtmux` で追跡できます。更新日: 2026-03-12 ET（via MCP time）

## 何が起きているか

`vprio`、`vday`、`vgpu` はそれぞれ `sbatch` の alias です。更新日: 2026-03-12 ET（via MCP time）

現在の alias は次の通りです。更新日: 2026-03-12 ET（via MCP time）

```zsh
alias vday="sbatch /vast/palmer/home.mccleary/yy693/vscode-tunnel.sh"
alias vprio="sbatch /vast/palmer/home.mccleary/yy693/vscode-tunnel-priority.sh"
alias vgpu="sbatch /vast/palmer/home.mccleary/yy693/vscode-tunnel-gpu.sh"
alias vtmux="/vast/palmer/home.mccleary/yy693/devops/vscode-tmux-ops/scripts/260213_vscode_tmux_connect.sh"
```

`vprio` を実行すると、`vscode-tunnel-priority.sh` が priority partition に VS Code 用ジョブを投げます。更新日: 2026-03-12 ET（via MCP time）

そのジョブの先頭で `260213_vscode_tmux_bootstrap.sh` が呼ばれ、計算ノード内で次の処理をします。更新日: 2026-03-12 ET（via MCP time）

1. `tmux` セッション `vscode` を作る
2. `editor` window を用意する
3. `codex` window が無ければ追加する
4. `/vast/palmer/scratch/hafler/yy693/vscode_tmux/latest.env` に、host / jobid / session / started_at / tunnel_name を記録する

その後で `code tunnel` を起動します。つまり、VS Code の接続先と、あとから追いかける tmux セッションの位置が、同じ計算ノードジョブにひもづきます。更新日: 2026-03-12 ET（via MCP time）

`vtmux` は `latest.env` を読み、`squeue` でジョブがまだ生きているかを確認し、その後 login node 経由で当該計算ノードに `ssh` して `tmux attach -t vscode` を実行します。更新日: 2026-03-12 ET（via MCP time）

## 基本手順

### 1. McCleary にログインする

```bash
ssh yy693@mccleary.ycrc.yale.edu
```

### 2. VS Code 用ジョブを投げる

priority を使うとき:

```bash
vprio
```

day を使うとき:

```bash
vday
```

GPU を使うとき:

```bash
vgpu
```

### 3. ジョブの起動を確認する

```bash
squeue -u "$USER"
```

必要なら log も確認します。現在の script では次の場所に出ます。更新日: 2026-03-12 ET（via MCP time）

```bash
ls -lt /home/yy693/palmer_scratch/slog/codeserver-*.log | head
```

### 4. ローカルの VS Code から tunnel に接続する

現在の script では tunnel 名は `mccleary-tunnel` に固定されています。更新日: 2026-03-12 ET（via MCP time）

ローカル PC 側の VS Code で Remote Tunnels を使い、GitHub 認証の上で `mccleary-tunnel` に接続します。更新日: 2026-03-12 ET（via MCP time）

注意:
- この tunnel 名は個人用設定です。同僚がそのまま同じ名前を使うより、自分の netid などを入れた別名にした方が安全です。更新日: 2026-03-12 ET（via MCP time）
- YCRC 公式にも、Remote Tunnel は compute node に対して使い、login node には直接つながないように書かれています。更新日: 2026-03-12 ET（via MCP time）

### 5. tmux セッションを追跡する

```bash
vtmux
```

これで、今走っている VS Code ジョブに対応する計算ノード内 tmux セッション `vscode` に attach します。更新日: 2026-03-12 ET（via MCP time）

tmux の基本操作:

- detach: `Ctrl-b` のあと `d`。更新日: 2026-03-12 ET（via MCP time）
- window 一覧: `Ctrl-b` のあと `w`。更新日: 2026-03-12 ET（via MCP time）
- window 移動: `Ctrl-b` のあと数字。更新日: 2026-03-12 ET（via MCP time）

## この運用の意図

このやり方の利点は、VS Code のジョブと terminal 作業の観測先が一致することです。更新日: 2026-03-12 ET（via MCP time）

具体的には:

- 計算ノード上で動いている shell / Codex セッションをあとから確認しやすい。更新日: 2026-03-12 ET（via MCP time）
- VS Code が login node に余計な負荷をかけない。更新日: 2026-03-12 ET（via MCP time）
- `latest.env` に接続先情報を残しているので、毎回 hostname を手で探さなくてよい。更新日: 2026-03-12 ET（via MCP time）

## 同僚向けに配るときの注意

このままでは user 固有値が多いので、そのまま配ってもすぐには使えません。更新日: 2026-03-12 ET（via MCP time）

同僚用に調整が必要な主な箇所:

- `#SBATCH -A prio_hafler`
- partition 名 (`priority`, `day`, `gpu`)
- log path (`/home/yy693/palmer_scratch/slog/...`)
- `YCRC_USER=yy693`
- registry path (`/vast/palmer/scratch/hafler/yy693/vscode_tmux/latest.env`)
- tunnel 名 (`mccleary-tunnel`)
- bootstrap / connect script の絶対 path

同僚へは「alias 名」を渡すより、「中で何を呼んでいるか」を説明した方が安全です。更新日: 2026-03-12 ET（via MCP time）

おすすめは次の 2 段階です。更新日: 2026-03-12 ET（via MCP time）

1. まずは公式推奨の OOD Code Server を案内する
2. local VS Code が必要な人だけ、この advanced workflow を配る

## 公式ドキュメントとの差分

YCRC 公式の tmux ガイドでは、`tmux` は login node 上で開始し、その中で `salloc` を実行する流れが推奨です。更新日: 2026-03-12 ET（via MCP time）

この運用はそれとは異なり、VS Code 用の Slurm ジョブの中で tmux を作ります。更新日: 2026-03-12 ET（via MCP time）

つまり、この文書は「一般的な YCRC 標準手順」ではなく、「VS Code Remote Tunnel を使う個人運用の共有メモ」です。更新日: 2026-03-12 ET（via MCP time）

## 参考

- YCRC VS Code guide: https://docs.ycrc.yale.edu/clusters-at-yale/access/ood-vscode/
- YCRC tmux guide: https://docs.ycrc.yale.edu/clusters-at-yale/guides/tmux/
