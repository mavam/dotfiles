#!/usr/bin/env perl
#
# filter email messages with `par'.
#

# Find window width.
#my $cols = `tput cols`;
#chomp $cols;
#$cols -= 2;

# Reflow using fmt:
#my $fmt = "fmt -w$cols";

# Or reflow using par:
# (I have PARINIT='rTbgq B=.,?!_A_a Q=_s>|+' . The par command
# here should contain display-filter settings that aren't in your
# general-purpose PARINIT.)
#my $fmt = "env PARINIT='rTbgq B=.,?!_A_a Q=_s>|+' par w${cols}h P=_s";
#my $fmt = "env PARINIT='rTbgq B=.,?!_A_a Q=_s>|+' par w${cols}h P=_s";
#my $fmt = "env PARINIT='rTbgq B=.,?!_A_a Q=_s>|+' par w72h P=_s";
my $fmt = "env PARINIT='rTbgqR B=.,?_A_a P=_s Q=>|}' par w72Th";

# Presume no .signature, but check later.
my $has_sig = 0;

# Skip header block
while (<STDIN>) {
    print;
    last if (/^$/);
}

# Reflow the body, if formatter is found.
open (FMT, "| $fmt") or *FMT = *STDOUT;
while (<STDIN>) {
    # Stop reflowing at signature indicator.  Can't just reassign output
    # fh because it can put perl's output and $fmt's output out of order.
    if (/^-- $/) {
        $has_sig = 1;
        print;
        last;
    }
    print FMT "$_";
}

# Copy the .signature, if found.
if ($has_sig) {
    print while (<STDIN>);
}

close(FMT);

