# SSH keys — scheme, migration, and rules

Status 2026-07-15: **domer, framework-13, alienware done. Migration complete.**

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
**alienware** server — LAN only, not on the tailnet, and easy to miss for exactly
that reason; `tailscale status` does not list it.
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

## Done on framework-13

`git` and `tunnel` generated with passphrases, authorized, and verified against
GitHub, domer, and palamedes — each confirmed to authenticate with the *new*
key, not an old one still sitting in the agent. `~/.ssh` was already 700.
`config.local` copied from domer verbatim. `keychain_args` flipped and applied.
Access to palamedes is restored via `tunnel@framework-13`.

palamedes' host key was not in framework-13's `known_hosts` (it never had a
successful connection to learn it), so `ssh palamedes` failed with **Host key
verification failed** — an unknown-host error, not an auth error. Don't reach
for `StrictHostKeyChecking=no`. The host key was read over the already-trusted
domer channel and compared against a direct `ssh-keyscan`; identical, so it was
pinned. Verify out-of-band like this whenever a first connection is also the
one that would teach you the key.

**Ordering:** generate and authorize keys *first*, apply `~/.ssh/config` last.
The tracked config sets `IdentityFile ~/.ssh/git` + `IdentitiesOnly yes` for
github.com, so applying it before `~/.ssh/git` exists offers GitHub no key at
all and breaks it until the key shows up.

## Done on alienware

alienware authorized framework-13's `id_ed25519` and was the machine's *only*
key in — retiring that key without acting here first would have locked
framework-13 out, silently. It was absent from this doc's roles list and from
`tailscale status`, so nothing pointed at it. `tunnel@framework-13` was added
and verified, then `id_ed25519` removed and confirmed denied. alienware has a
block in `config.local` with no `HostName` (it resolves on the LAN).

**Before retiring any key, enumerate who actually trusts it — don't infer it
from this file.** `ssh-keygen -l -f ~/.ssh/known_hosts` lists every host this
machine has ever connected to, which is the honest starting point; the roles
list above is a summary and was wrong. Test each candidate with
`-F /dev/null -o IdentitiesOnly=yes -i <key>` before deleting anything.

alienware also authorizes domer's **`git`** key (its comment reads `github`) for
host access. That is a GitHub key doing tunnel's job, contradicting the
one-job-each rule. Left alone here — it is domer's credential to rotate.

## Old keys retired

framework-13's `id_ed25519` and `github` are gone: revoked on domer and
alienware, confirmed denied there, removed from the agent, and deleted from
`~/.ssh`. All four hosts re-verified afterwards with only `git` and `tunnel`
loaded. `id_ed25519` was never on palamedes or GitHub; neither key opened
gitlab.com.

The stale GitHub entry titled `Framework` may still be listed — it was this
machine's `github` key. Deleting the private key made it permanently unusable
(the material was unique to framework-13; domer's GitHub key is different), so
it is clutter rather than a live credential. Remove it with
`gh ssh-key delete <id> --yes`.

The router at `192.168.1.1` and a `framework-12` entry appear in
framework-13's `known_hosts` and were never tested against `id_ed25519`, which
is now deleted. Deliberate — judged not worth keeping the key alive for. If the
router turns out to have trusted it, recover via its web UI or console and
authorize `tunnel@framework-13`.

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
- **`-Q` skips loading entirely if the agent already has *any* key.** It reports
  `Found existing populated ssh-agent (quick)` and adds nothing — so mid-
  migration, an agent holding only the *old* keys silently prevents the new ones
  from loading, with no prompt and no error. This is correct at boot (empty
  agent) but confusing while switching. To force it: `ssh-add ~/.ssh/git
  ~/.ssh/tunnel` directly, or clear the agent first with `ssh-add -D`.
- **One passphrase prompt covers both keys** when they share a passphrase.
  keychain passes `git` and `tunnel` to a single `ssh-add`, and `ssh-add` retries
  an already-entered passphrase against later keys, re-prompting only if it
  fails. Identical passphrases therefore cost one prompt per *boot*, not per key
  and not per shell — the agent persists. Sharing a passphrase makes the two keys
  one secret; the split buys revocation granularity, not blast-radius isolation.
- **`!` in Claude Code runs bash, not fish** — `keychain ... | source` is fish
  syntax and fails there with a `source: filename argument required` error from
  bash. It also has no TTY, so a passphrase prompt cannot appear at all; use a
  real terminal or an `SSH_ASKPASS` helper (fuzzel works, as with sudo-askpass).
- **A missing key is only a warning** from keychain (exit 0), and `--quiet`
  does not suppress it.
- **palamedes' login shell is fish**, so remote one-liners are fish syntax
  unless wrapped in `bash -c`.
- The `git` key's comment on domer still reads `github`. Fixing needs the
  passphrase: `ssh-keygen -c -C "git@domer" -f ~/.ssh/git`.
