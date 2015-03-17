use v5.14;
my $var = 'abc';
given ($var) {
    when (/^abc/) { my $abc = 1 ; warn 1 }
    when (/^def/) { my $def = 1 ; warn 2 }
    when (/^xyz/) { my $xyz = 1 ; warn 3 }
    default { my $nothing = 1 }
}
