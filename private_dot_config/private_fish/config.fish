if status is-interactive
    # Purpose-named keys, identical filenames on every client; the key material
    # differs per machine so either can be revoked alone. Missing keys only warn.
    keychain --eval -Q --quiet git tunnel | source

    # reef: keep exported vars alive between bash-passthrough commands.
    # Must call the function, not just set reef_persist_mode — it also sets
    # __reef_state_file, without which state mode degrades back to off.
    # Guarded: this file is shared, and reef is not installed everywhere.
    if type -q reef
        reef persist state >/dev/null
    end
end

function fish_greeting
    pokeget random --hide-name | fastfetch --logo-position right --file-raw -
    # fastfetch
end

function tere
    set --local result (command tere $argv)
    [ -n "$result" ] && cd -- "$result"
end

alias google-chrome=google-chrome-stable

zoxide init fish | source
starship init fish | source
