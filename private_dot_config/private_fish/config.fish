if status is-interactive
    # Commands to run in interactive sessions can go here
end

if status is-login and status is-interactive
    # Set the universal variable SSH_KEYS_TO_AUTOLOAD to the path(s) of your key(s)
    set -Ua SSH_KEYS_TO_AUTOLOAD ~/.ssh/github-meetkai
    # You can add multiple keys by appending to the list
    # set -Ua SSH_KEYS_TO_AUTOLOAD ~/.ssh/id_other_key

    keychain --eval $SSH_KEYS_TO_AUTOLOAD | source
end

function fish_greeting
    pokeget random --hide-name | fastfetch --logo-position right --file-raw -
    # fastfetch
end

function tere
    set --local result (command tere $argv)
    [ -n "$result" ] && cd -- "$result"
end

zoxide init fish | source
starship init fish | source
