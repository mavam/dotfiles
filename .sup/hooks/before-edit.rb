# Mutt-like send-hooks.
recipients = header.values_at("To", "Cc", "Bcc").flatten
if recipients.any? { |r| r =~ /sup-talk|lists\./ }
  a = Redwood::AccountManager.account_for("vallentin@icsi.berkeley.edu")
  header["From"] = a.full_address
end

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

# FIXME: The check whether the signature has already been appended is necssary
# because the hook is executed multiple times per email. If have no clue why...
body.concat(sig) unless body.last == sig.last
