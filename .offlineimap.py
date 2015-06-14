import subprocess

# Retrieves a password item from a non-iCloud keychain.
#
# Note the security program can use either find-generic-password or
# the more specific find-internet-password. We use the former because only this
# one works when manually a keychain item where the name is *not* in URL
# format.
#
# The flag -w prints only the password as plain text.
def get_keychain_pass(name):
  cmd = ['security', 'find-generic-password', '-s', name, '-w']
  return subprocess.check_output(cmd).strip()
