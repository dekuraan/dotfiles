## Share one cargo target/ dir across every wam worktree.
##
## Why: each worktree (main, wt-*, .claude/worktrees/agent-*, .dev/worktree/*)
## otherwise builds its own multi-GB target/. Pointing them all at one shared
## dir + leaning on the existing sccache rustc-wrapper (~/.cargo/config.toml)
## keeps disk usage flat and reuses dep rlibs across branches.
##
## How: on every PWD change, if cwd is under /home/gideon/dev/wam, export
## CARGO_TARGET_DIR. Leaving a wam dir un-sets it (only when we own the value,
## so a manual override survives).

set -g __wam_target_dir /home/gideon/.cache/wam-target

function __wam_cargo_target --on-variable PWD
    set -l here (pwd -P)
    if string match -rq '^/home/gideon/dev/wam(/|$)' -- $here
        set -gx CARGO_TARGET_DIR $__wam_target_dir
    else if set -q CARGO_TARGET_DIR
        and test "$CARGO_TARGET_DIR" = "$__wam_target_dir"
        set -e CARGO_TARGET_DIR
    end
end

__wam_cargo_target
