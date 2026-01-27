if status is-interactive
    keychain --eval ssh -Q --quiet github-meetkai | source # Commands to run in interactive sessions can go here
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
