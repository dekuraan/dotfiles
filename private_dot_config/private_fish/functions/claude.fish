function claude --wraps claude --description 'claude with Remote Control on by default'
    # Skip auto-injection for non-interactive/print runs, or if the user
    # already passed a remote-control flag. To bypass entirely: `command claude ...`
    for arg in $argv
        switch $arg
            case -p --print --remote-control '--remote-control=*'
                command claude $argv
                return $status
        end
    end
    command claude --remote-control $argv
end
