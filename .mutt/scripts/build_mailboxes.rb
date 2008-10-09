#!/usr/bin/env ruby

# Where to look for directories.
MAILDIR = "#{ENV['HOME']}/.gmail"

# Order of mailboxes (if available).
ORDER = %w{
    INBOX
    drafts
    sent
    flagged
    private
    bay-area
    money
    shopping
    news
    health
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
    EECS
    UCB
    ICSI
    LBL
    TUM
    bro
    logs
    spam
    trash
}

# Discard the following mailboxes
REJECT = /^(\.){1,2}$|apple/i

dirs = Dir.entries(MAILDIR)
mboxes = dirs.sort_by {|dir| ORDER.index(dir) || dirs.index(dir) + ORDER.size} 

puts mboxes.reject {|dir| dir[REJECT]}.map {|mbox| "\"=#{mbox}\""}.join(' ')
