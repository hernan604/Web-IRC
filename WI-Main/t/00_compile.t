use strict;
use Test::More 0.98;

use_ok $_ for qw(
    WI::Main
);

my $main = WI::Main->new;
$main->start;

done_testing;

