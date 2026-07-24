function zc --description 'Launch `claude --worktree <name>` in a minimal zellij session'
    # Tabs: claude | lazygit | shell (lazygit + fish open inside the worktree
    # once Claude has created it).
    #
    # Usage: zc [name] [extra claude args...]
    #   zc feature-auth
    #   zc bugfix-123 --model opus
    #
    # Notes:
    #   - Run `claude` once in the repo first to accept the trust dialog,
    #     otherwise --worktree exits with an error on first use.
    #   - Add `.claude/worktrees/` to your .gitignore.

    # ---- dependency + repo checks --------------------------------------------
    for dep in claude zellij lazygit git
        if not command -q $dep
            echo "zc: missing dependency: $dep" >&2
            return 127
        end
    end

    set -l root (git rev-parse --show-toplevel 2>/dev/null)
    if test -z "$root"
        echo "zc: not inside a git repository" >&2
        return 1
    end

    # ---- name, paths, session -------------------------------------------------
    set -l name $argv[1]
    set -l extra $argv[2..-1]
    if test -z "$name"
        set name "wt-"(random 1000 9999)
    end

    # Claude Code creates worktrees at <repo-root>/.claude/worktrees/<name>
    set -l wt_dir "$root/.claude/worktrees/$name"
    set -l session "claude-"(basename $root)"-$name"

    # Reattach if this session already exists
    if zellij list-sessions -s 2>/dev/null | grep -qx -- $session
        zellij attach $session
        return $status
    end

    # ---- build the layout -------------------------------------------------------
    # lazygit/fish tabs wait until `claude --worktree` has created the directory.
    set -l wait_cmd "while not test -d '$wt_dir'; sleep 0.3; end; cd '$wt_dir';"

    # zellij runs the `claude` *binary*, not the fish function, so the function's
    # Remote Control injection doesn't apply here — add it unless the caller
    # already passed a remote-control/print flag.
    set -l claude_args "\"--worktree\" \"$name\""
    set -l inject_rc 1
    for a in $extra
        switch $a
            case -p --print --remote-control '--remote-control=*'
                set inject_rc 0
        end
        set claude_args "$claude_args \"$a\""
    end
    if test $inject_rc -eq 1
        set claude_args "$claude_args \"--remote-control\""
    end

    set -l layout (mktemp -t zc.XXXXXX.kdl)
    printf '%s\n' \
        'layout {' \
        '    default_tab_template {' \
        '        children' \
        '        pane size=1 borderless=true {' \
        '            plugin location="zellij:compact-bar"' \
        '        }' \
        '    }' \
        "    tab name=\"claude\" focus=true cwd=\"$root\" {" \
        "        pane command=\"claude\" {" \
        "            args $claude_args" \
        '        }' \
        '    }' \
        '    tab name="lazygit" {' \
        '        pane command="fish" {' \
        "            args \"-c\" \"$wait_cmd exec lazygit\"" \
        '        }' \
        '    }' \
        '    tab name="shell" {' \
        '        pane command="fish" {' \
        "            args \"-c\" \"$wait_cmd exec fish\"" \
        '        }' \
        '    }' \
        '}' \
        'pane_frames false' >$layout

    # ---- launch (minimal UI: compact bar, no pane frames) -----------------------
    # -n (not -l): with --session, -l means "add tabs to an existing session" and
    # fails when it doesn't exist. -n always starts a new one.
    zellij -s $session -n $layout
    set -l st $status
    rm -f $layout
    return $st
end
