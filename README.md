# dotfiles

Dotfiles for a fleet of four machines, managed with [chezmoi](https://chezmoi.io).

| Host | Role | Notes |
|------|------|-------|
| `domer` | workstation | CachyOS, Hyprland, the full desktop stack |
| `framework-13` | laptop | CachyOS, Hyprland + idle/lock/suspend extras |
| `alienware` | htpc | minimal shell setup |
| `palamedes` | server | keeps its own fish config (ignored here) |

## Layout

- Per-machine facts live in `.chezmoidata/machines.yaml`
  (`machines.<hostname>`: role, capability flags, keychain, PATH/env extras,
  shell aliases).
- Templates hoist `$m := index .machines .chezmoi.hostname` and branch on
  `$m.role` or capability flags (`has_hyprsunset`, `is_cachyos`, …); raw
  `.chezmoi.hostname` comparisons are reserved for genuinely host-tied things
  (monitor lines, daemons that only exist on one box). `.chezmoiignore` uses
  the same data for files that should only exist on some machines.
- `.chezmoi.toml.tmpl` generates chezmoi's own config on `chezmoi init`.
- `.chezmoiscripts/` holds `run_onchange` hooks (e.g. restart the wayle panel
  when its rendered config changes).
- `.chezmoiignore` also documents which app-managed files are deliberately
  *not* tracked, and why.
- `docs/` holds repo notes and never applies to `$HOME`.

## Usage

```sh
chezmoi init git@github.com:dekuraan/dotfiles.git
chezmoi diff     # review what would change on this host
chezmoi apply
```
