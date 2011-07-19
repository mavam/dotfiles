# Mutt-like send-hooks. Select an account identified by it's full email address
# given a pattern to be matched against the recipients.
me = nil
header.values_at("To", "Cc", "Bcc").flatten.each do |recipient|
  case recipient
  when /bro-ids.org/
    me = "vallentin@icir.org"
  when /sup-talk|lists\.|zsh-users/
    me = "vallentin@icsi.berkeley.edu"
  end
end
header["From"] = Redwood::AccountManager.account_for(me).full_address if me


# Body signature.
default_sig = ["", "    Matthias"]
eecs_sig = default_sig + [""] +
  ["Matthias Vallentin",
   "EECS Department",
   "723 Soda Hall - MC 1776",
   "University of California",
   "Berkeley, CA, USA  94720-1776"]

# TODO: add some logic that selects the appropriate signature.
sig = default_sig

# The check whether the signature has already been appended is necssary because
# the hook is executed multiple times per email. No clue why...
body.concat(sig) unless body.last == sig.last
