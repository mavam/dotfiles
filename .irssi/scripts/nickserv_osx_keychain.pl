use strict;

use vars qw($VERSION %IRSSI);

use Irssi;

$VERSION = '1.00';
%IRSSI = (
  authors     => 'Sven Strothoff',
  contact     => 'sven.strothoff@googlemail.com',
  name        => 'NickServ OS X Keychain Identification',
  description => 'This script allows you to identify to NickServ using the' .
                 'stored password from the OS X keychain.',
  license     => 'GNU GPL v3'
);

sub cmd_identify {
  my ($data, $server, $witem) = @_;

  if (!$server || !$server->{connected}) {
    Irssi::print("Not connected to server.", MSGLEVEL_CLIENTERROR);
    return;
  }

  if ($data) {
    chomp(my $password = `security find-generic-password -w -s "irssi" -c "irss" -a "$data" 2>&1`);
    if ($? != 0) {
      Irssi::print("Unable to retrieve password for account '$data':\n$password", MSGLEVEL_CLIENTERROR);
      return;
    }
    $server->command("MSG NickServ identify $password");
    Irssi::print("Sent identification for $data to NickServ.", MSGLEVEL_CLIENTNOTICE);
  } else {
    Irssi::print("Account name required.", MSGLEVEL_CLIENTERROR);
  }
}

Irssi::command_bind('identify', \&cmd_identify);
