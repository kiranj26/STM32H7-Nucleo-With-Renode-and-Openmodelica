#!/usr/bin/perl
# Usage: perl capture_uart.pl <port> <baud> <seconds> <outfile>
# Opens the port (held open so stty settings stick on macOS), resets the
# target over SWD with st-flash, then logs timestamped lines for <seconds>.
use strict;
use warnings;
use Time::HiRes qw(time);
use IO::Select;

my ($port, $baud, $secs, $out) = @ARGV;
open(my $fh, '+<', $port) or die "open $port: $!";
system("stty -f $port $baud raw -echo") == 0 or die "stty failed";
open(my $log, '>', $out) or die "open $out: $!";

my $sel = IO::Select->new($fh);

# Drain bytes buffered before the reset (stale output from earlier runs).
my $drain_until = time + 0.7;
while ((my $d = $drain_until - time) > 0) {
    sysread($fh, my $junk, 4096) if $sel->can_read($d);
}

system("st-flash reset >/dev/null 2>&1") == 0 or warn "st-flash reset failed\n";

my $deadline = time + $secs;
my $buf = '';
while ((my $left = $deadline - time) > 0) {
    next unless $sel->can_read($left);
    my $n = sysread($fh, my $chunk, 4096);
    last unless $n;
    $buf .= $chunk;
    while ($buf =~ s/^([^\n]*\n)//) {
        (my $line = $1) =~ s/\r//g;
        printf $log "%.3f %s", time, $line;
    }
}
close $log;
