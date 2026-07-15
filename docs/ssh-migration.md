# SSH keys — scheme, migration, and rules

Status 2026-07-15: **domer done. framework-13 not started.**

> This file is in a **public** repo. Keep host inventory, addresses, and key
> fingerprints out of it. Read live state off the machines instead — it is
> authoritative and this would only go stale. Host aliases below resolve via
> `~/.ssh/config.local`, which is deliberately untracked.

## The scheme

Two keys per *client*, named by purpose. Filenames are identical everywhere; the
key **material** differs per machine, so any one machine can be revoked without
touching the others.

| File | Job |
|---|---|
| `~/.ssh/git` | GitHub only |
| `~/.ssh/tunnel` | tailnet hosts |

Private keys are **generated per-machine and never leave it**. They are not in
this repo, encrypted or otherwise — syncing them would collapse the per-machine
revocation this whole scheme exists to provide.

Comments must name the host (`git@domer`, `tunnel@framework-13`), because
`authorized_keys` shows only the comment. The fleet already contains keys
commented with an account name or nothing, which makes them unattributable and
therefore un-revokable without guesswork. Don't add to that.

Roles: **domer** client + server. **framework-13** client. **palamedes** server.
Tailscale SSH was evaluated and rejected — trust stays in keys + keychain.

## Done on domer

- `~/.ssh/github` → `~/.ssh/git`. Rename only; material and fingerprint
  unchanged, so GitHub kept working (it matches the key, not the filename).
- Generated `~/.ssh/tunnel`, authorized on palamedes, verified.
- `~/.ssh` was mode 755 → now 700. **Check this on framework-13 too.**
- `~/.ssh/config` tracked (sanitized); `~/.ssh/config.local` holds the host
  inventory and is untracked.
- `.chezmoidata.yaml` → `machines.domer.keychain_args` is now
  `--eval -Q --quiet git tunnel`. `config.fish` is generated from
  `config.fish.tmpl`; do not hand-edit it, the next apply reverts you.
- palamedes' `authorized_keys` reduced to `tunnel@domer` only. **framework-13
  therefore has no access to palamedes right now** — restoring it is the job
  below, via a new key, not by re-adding the old one.

## framework-13 — the remaining work

Run on framework-13:

```fish
chezmoi update
stat -c %a ~/.ssh            # want 700; chmod 700 ~/.ssh if not

ssh-keygen -t ed25519 -f ~/.ssh/git    -C "git@framework-13"
ssh-keygen -t ed25519 -f ~/.ssh/tunnel -C "tunnel@framework-13"
```

Real passphrases on both — keychain exists to cache them.

Write `~/.ssh/config.local` by hand (copy from domer; it is untracked by
design). Then authorize `~/.ssh/tunnel.pub` on each server, add `~/.ssh/git.pub`
to GitHub titled `framework-13`, and verify:

```fish
ssh palamedes 'echo ok'
ssh domer 'echo ok'
ssh -T github.com          # expect: Hi dekuraan!
```

**Only after all three pass**, flip framework-13 over in `.chezmoidata.yaml`:

```yaml
  framework-13:
    keychain_args: "--eval -Q --quiet git tunnel"   # was: -q --eval id_ed25519 github
```

then `chezmoi apply`. Doing this before the keys exist gives you a keychain
warning every shell; doing it before they're *authorized* means the old keys
stop being loaded while the new ones don't work yet.

Once `tunnel@framework-13` is confirmed on both servers, its old keys can be
retired from their `authorized_keys` — read the live files to see what's there.
Note `id_ed25519` is framework-13's pre-migration key: once `git` and `tunnel`
replace it, it should be removed from GitHub and from every `authorized_keys`,
not left as a dormant third credential.

## Editing authorized_keys — read this first

### Never filter authorized_keys with grep

This truncated a server's `authorized_keys` to empty and cost a recovery by
console. The command was:

```fish
set blob (cut -d' ' -f2 ~/.ssh/git.pub)
ssh <host> "... grep -vF '$blob' ~/.ssh/authorized_keys.bak > ~/.ssh/authorized_keys ..."
```

If `$blob` is empty for any reason, `grep -vF ''` matches **every** line, `-v`
inverts that to nothing, and the redirect writes nothing over the file. Reading
from a `.bak` guards against a *non-matching* pattern — not an *empty* one.
Under fish + reef, an interactively pasted `set blob (...)` is not guaranteed to
expand the way it reads on the page.

### Write the exact intended content instead

Deterministic, never reads the current file, cannot truncate:

```bash
cp ~/.ssh/authorized_keys ~/.ssh/authorized_keys.bak2 2>/dev/null
printf '%s\n' 'ssh-ed25519 AAAA...  tunnel@somehost' \
              'ssh-ed25519 AAAA...  tunnel@otherhost' \
              > ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
ssh-keygen -l -f ~/.ssh/authorized_keys   # confirm exactly what you meant
```

### Non-negotiable rules

1. **Confirm a recovery path exists before editing `authorized_keys` at all** —
   a working password, or console/IPMI. A key-only box plus one bad write is a
   permanent lockout with no network path back. Do not assume the account has a
   usable password; test it first.
2. **Keep a session open on the server** until new key auth is verified from a
   second terminal. This is what makes a mistake survivable.
3. **Verify the replacement works before removing the old key**, never after.
4. **Verify a retired key is actually denied** with `-F /dev/null`, or
   `~/.ssh/config` quietly adds `tunnel` to the offered identities and the test
   passes for the wrong reason:
   ```fish
   ssh -F /dev/null -o BatchMode=yes -o IdentitiesOnly=yes -i ~/.ssh/git <user>@<host> true
   ```

## Gotchas

- **`IdentitiesOnly yes`** is what stops ssh walking every agent key and
  tripping `Too many authentication failures`. Keep it.
- **MagicDNS is broken on domer** — its own health check reports
  systemd-resolved and NetworkManager wired together incorrectly. Hence
  addresses in `config.local` rather than bare names. Fix it and the
  `HostName` lines can go entirely.
- **`keychain --agents` is deprecated** in the installed version and warns if
  used. Correct: `keychain --eval -Q --quiet git tunnel`.
- **A missing key is only a warning** from keychain (exit 0), and `--quiet`
  does not suppress it.
- **palamedes' login shell is fish**, so remote one-liners are fish syntax
  unless wrapped in `bash -c`.
- The `git` key's comment on domer still reads `github`. Fixing needs the
  passphrase: `ssh-keygen -c -C "git@domer" -f ~/.ssh/git`.
