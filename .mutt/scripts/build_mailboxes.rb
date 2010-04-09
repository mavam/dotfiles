#!/usr/bin/env ruby

require 'set'

# Where to look for directories.
MAILDIR = "#{ENV['HOME']}/.gmail"

# Custom order of mailboxes.
ORDER = %w{
    INBOX
    sent
    drafts
    flagged
    list
    private
    devnull
    health
    airjaldi
    EECS
    UCB
    ICSI
    CCIED
    LBL
    TUM
    bro
    logs
    bay-area
    money
    news
    travel
    shopping
    spam
    trash
    universe
}

# Check whether a directory is a Maildir. 
def maildir?(dir)
  intersection = Dir.entries(dir).to_set & ["cur", "new", "tmp"]
  return intersection.size == 3
end

# Build mailboxes from a given base directory. 
def build(base)
  dirs = Dir.entries(base).reject { |dir| dir =~ /^\.{1,2}$/ }

  mail, more = dirs.partition do |dir| 
    path = File.join(base, dir)
    xor = Dir.entries(path).to_set ^ [".", "..", "cur", "new", "tmp"].to_set
    xor.size == 0
  end

  return mail if more.to_set == ["cur", "new", "tmp"].to_set

  nested = more.map do |dir| 
    boxes = build(File.join(base, dir))
    [dir] + boxes.map { |box| File.join(dir,box) }
  end

  mail + nested
end

dirs = build(MAILDIR)

# FIXME: prettify this ugliness.
mboxes = dirs.sort_by do |mbox| 
  box = mbox.kind_of?(Array) ? mbox[0] : mbox
  ORDER.index(box) || ORDER.size + dirs.index(box)
end

puts mboxes.flatten.map {|box| "\"=#{box}\""} * " "
