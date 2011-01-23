if num_inbox > 0
  mails = from_and_subj_inbox.map { |f,s| "#{f}\t#{s}" }
  File.open(File.expand_path('~/Dropbox/tmp/new-mail'), 'a') do |f| 
    f.puts(mails * "\n")
  end
end
