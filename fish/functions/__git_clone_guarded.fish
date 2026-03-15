function __git_clone_guarded_supports_remote --argument-names repo_url
    switch $repo_url
        case 'https://*/*' 'http://*/*' 'git@*:*' 'ssh://git@*/*'
            return 0
    end

    return 1
end

function __git_clone_guarded_cleanup --argument-names target_dir target_existed
    if test "$target_existed" = false; and test "$target_dir" != "."
        rm -rf -- "$target_dir"
        echo "❌ Removed incomplete clone at '$target_dir'" >&2
    end
end

function __git_clone_guarded --description "Clone a repo recursively and configure guarded pushes"
    if test (count $argv) -lt 1 -o (count $argv) -gt 2
        echo "ℹ Usage: gclg <repo-url> [directory]" >&2
        return 1
    end

    set -l repo_url $argv[1]
    set -l target_dir

    if test (count $argv) -eq 2
        set target_dir $argv[2]
    else
        set target_dir (basename $repo_url)
        set target_dir (string replace -r '\.git/?$' '' $target_dir)
    end

    if test -z "$target_dir"
        echo "❌ Unable to determine target directory for $repo_url" >&2
        return 1
    end

    if not __git_clone_guarded_supports_remote "$repo_url"
        echo "❌ gclg only supports HTTPS or SSH remotes so guarded pushes can be configured" >&2
        echo "   unsupported remote: $repo_url" >&2
        return 1
    end

    set -l target_existed false
    if test -e "$target_dir"
        set target_existed true
    end

    git clone --recursive $argv
    set -l clone_status $status
    if test $clone_status -ne 0
        return $clone_status
    end

    set -l repo_root (git -C "$target_dir" rev-parse --show-toplevel 2>/dev/null)
    if test -z "$repo_root"
        echo "❌ Failed to resolve cloned repository at '$target_dir'" >&2
        __git_clone_guarded_cleanup "$target_dir" "$target_existed"
        return 1
    end

    git-guard-pushes "$repo_root"
    set -l guard_status $status
    if test $guard_status -ne 0
        __git_clone_guarded_cleanup "$target_dir" "$target_existed"
        return $guard_status
    end
end
