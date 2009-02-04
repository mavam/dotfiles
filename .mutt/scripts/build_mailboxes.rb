#!/usr/bin/env ruby

# Where to look for directories.
MAILDIR = "#{ENV['HOME']}/.gmail"

# Order of mailboxes (if available).
ORDER = %w{
    INBOX
    sent
    drafts
    flagged
    .list.boost
    .list.boost.spirit
    .list.zsh-users
    .list.sup-talk
    .list.pentest
    .list.metasploit
    .list.ids
    .list.wifisec
    .list.botnets
    .list.misc
    .devnull
    health
    private
    EECS
    UCB
    ICSI
    LBL
    TUM
    bro
    logs
    bay-area
    money
    news
    shopping
    spam
    trash
}

dirs = Dir.entries(MAILDIR)
mboxes = dirs.sort_by {|dir| ORDER.index(dir) || dirs.index(dir) + ORDER.size} 

puts mboxes.reject {|box| box[/^(\.){1,2}$/]}.map {|box| "\"=#{box}\""}.join(' ')