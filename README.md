# dotfiles

Dotfiles for a fleet of four machines, managed with [chezmoi](https://chezmoi.io).

| Host | Role | Notes |
|------|------|-------|
| `domer` | workstation | CachyOS, Hyprland, the full desktop stack |
| `framework-13` | laptop | CachyOS, Hyprland + idle/lock/suspend extras |
| `alienware` | htpc | minimal shell setup |
| `palamedes` | server | keeps its own fish config (ignored here) |

## Layout

- Per-machine facts live in `.chezmoidata.yaml` (`machines.<hostname>`:
  role, keychain, PATH/env extras, shell aliases).
- Host differences are handled two ways: templates keyed on
  `.chezmoi.hostname` (`hyprland.conf.tmpl`, `config.fish.tmpl`,
  `wayle/config.toml.tmpl`, …) and host-gated blocks in `.chezmoiignore`
  for files that should only exist on some machines.
- `.chezmoiignore` also documents which app-managed files are deliberately
  *not* tracked, and why.
- `docs/` holds repo notes and never applies to `$HOME`.

## Usage

```sh
chezmoi init git@github.com:dekuraan/dotfiles.git
chezmoi diff     # review what would change on this host
chezmoi apply
```
