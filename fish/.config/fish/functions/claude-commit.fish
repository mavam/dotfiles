function claude-commit
    set -l prompt "Create a commit message for the following diff. "
    set prompt "$prompt Include the commit message only, do not surround it with any prose or markdown code blocks. "
    set prompt "$prompt ONLY INCLUDE THE COMMIT MESSAGE. Your output will be piped to the commit message. "
    set prompt "$prompt Do not sign off the commit. "
    set prompt "$prompt Do not use conventional commits, use a simple title and body. "
    set prompt "$prompt Keep the title under 50 characters. "
    set prompt "$prompt Keep the body under 80 characters per line."

    if test (count $argv) -ge 1
        set prompt "$prompt The commit closes $argv[1]."
    end

    set prompt "$prompt\n\n"(git diff --cached)

    echo "$prompt" | claude --print | git commit --file=-
    git show --color=always | env LESSCHARSET=utf-8 less -FRX
end
