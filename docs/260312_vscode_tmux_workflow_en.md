# Running VS Code Jobs with a Paired tmux Session on McCleary

Updated: 2026-03-12 ET (via MCP time)

## Overview

This note explains a custom McCleary workflow where a VS Code job is launched on a compute node and a tmux session is created inside the same job so the terminal state can be traced later. Updated: 2026-03-12 ET (via MCP time)

YCRC currently recommends Open OnDemand Code Server for most users. That is the general-purpose and officially recommended path. Updated: 2026-03-12 ET (via MCP time)

This workflow is for advanced users who want to keep using local VS Code with Remote Tunnel while also keeping a traceable tmux session on the compute node for Codex or shell work. Updated: 2026-03-12 ET (via MCP time)

## What Actually Happens

`vprio`, `vday`, and `vgpu` are `sbatch` aliases. Updated: 2026-03-12 ET (via MCP time)

Current aliases:

```zsh
alias vday="sbatch /vast/palmer/home.mccleary/yy693/vscode-tunnel.sh"
alias vprio="sbatch /vast/palmer/home.mccleary/yy693/vscode-tunnel-priority.sh"
alias vgpu="sbatch /vast/palmer/home.mccleary/yy693/vscode-tunnel-gpu.sh"
alias vtmux="/vast/palmer/home.mccleary/yy693/devops/vscode-tmux-ops/scripts/260213_vscode_tmux_connect.sh"
```

When `vprio` is submitted, `vscode-tunnel-priority.sh` launches a VS Code job on the `priority` partition. Updated: 2026-03-12 ET (via MCP time)

Early in that job, `260213_vscode_tmux_bootstrap.sh` runs and does the following on the compute node. Updated: 2026-03-12 ET (via MCP time)

1. Creates a tmux session named `vscode`
2. Creates an `editor` window
3. Adds a `codex` window if it does not already exist
4. Writes host / jobid / session / started_at / tunnel_name into `/vast/palmer/scratch/hafler/yy693/vscode_tmux/latest.env`

After that, the job starts `code tunnel`. That means the VS Code tunnel target and the tmux session you later trace are tied to the same compute-node job. Updated: 2026-03-12 ET (via MCP time)

`vtmux` reads `latest.env`, checks with `squeue` that the job is still alive, then SSHes through the login node and runs `tmux attach -t vscode` on the compute node. Updated: 2026-03-12 ET (via MCP time)

## Basic Workflow

### 1. Log in to McCleary

```bash
ssh yy693@mccleary.ycrc.yale.edu
```

### 2. Submit a VS Code job

For the priority partition:

```bash
vprio
```

For the day partition:

```bash
vday
```

For a GPU job:

```bash
vgpu
```

### 3. Confirm that the job started

```bash
squeue -u "$USER"
```

If needed, inspect the log. The current scripts write logs here. Updated: 2026-03-12 ET (via MCP time)

```bash
ls -lt /home/yy693/palmer_scratch/slog/codeserver-*.log | head
```

### 4. Connect from local VS Code to the tunnel

In the current scripts, the tunnel name is fixed to `mccleary-tunnel`. Updated: 2026-03-12 ET (via MCP time)

From your local VS Code, use Remote Tunnels, sign in with GitHub, and connect to `mccleary-tunnel`. Updated: 2026-03-12 ET (via MCP time)

Notes:
- This tunnel name is user-specific in practice. Colleagues should use their own tunnel names, ideally including their NetID. Updated: 2026-03-12 ET (via MCP time)
- YCRC guidance explicitly says Remote Tunnel should target compute nodes, not login nodes. Updated: 2026-03-12 ET (via MCP time)

### 5. Trace the paired tmux session

```bash
vtmux
```

This attaches to the `vscode` tmux session on the compute node currently backing the VS Code job. Updated: 2026-03-12 ET (via MCP time)

Useful tmux basics:

- detach: `Ctrl-b`, then `d`. Updated: 2026-03-12 ET (via MCP time)
- window list: `Ctrl-b`, then `w`. Updated: 2026-03-12 ET (via MCP time)
- jump to window: `Ctrl-b`, then a number. Updated: 2026-03-12 ET (via MCP time)

## Why This Is Useful

The main benefit is that the VS Code job and the terminal session you want to inspect live in the same compute-node allocation. Updated: 2026-03-12 ET (via MCP time)

In practice this means:

- you can inspect Codex or shell work later on the same node. Updated: 2026-03-12 ET (via MCP time)
- VS Code does not burden the login node. Updated: 2026-03-12 ET (via MCP time)
- `latest.env` preserves the connection target, so you do not need to rediscover the hostname by hand every time. Updated: 2026-03-12 ET (via MCP time)

## What Colleagues Must Customize

As written, this setup contains many user-specific values. Colleagues should not reuse it unchanged. Updated: 2026-03-12 ET (via MCP time)

The main values to customize are:

- `#SBATCH -A prio_hafler`
- partition names such as `priority`, `day`, and `gpu`
- the log path `/home/yy693/palmer_scratch/slog/...`
- `YCRC_USER=yy693`
- the registry path `/vast/palmer/scratch/hafler/yy693/vscode_tmux/latest.env`
- the tunnel name `mccleary-tunnel`
- the absolute paths to the bootstrap and connect scripts

For colleagues, it is usually better to explain the launcher structure than to tell them to copy your aliases verbatim. Updated: 2026-03-12 ET (via MCP time)

The clean rollout order is:

1. Recommend OOD Code Server first
2. Share this advanced workflow only with people who specifically want local VS Code plus traceable tmux

## Difference from the Official tmux Pattern

The YCRC tmux guide recommends starting `tmux` on the login node and then running `salloc` inside it. Updated: 2026-03-12 ET (via MCP time)

This workflow intentionally differs: it creates tmux inside the VS Code Slurm job on the compute node. Updated: 2026-03-12 ET (via MCP time)

So this document should be read as a custom operational note for a Remote Tunnel workflow, not as the general YCRC default. Updated: 2026-03-12 ET (via MCP time)

## References

- YCRC VS Code guide: https://docs.ycrc.yale.edu/clusters-at-yale/access/ood-vscode/
- YCRC tmux guide: https://docs.ycrc.yale.edu/clusters-at-yale/guides/tmux/
