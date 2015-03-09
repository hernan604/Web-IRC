use strict;
use warnings;
use lib '../POE-Component-Server-IRC-1.54/lib';
use POE qw(Component::Server::IRC);
use lib './lib';
use DDP;
use utf8;

print STDERR "-- SERVER RESTARTED --";

my %config = (
    servername  => 'WI',
    serverdesc  => '[x] server description [x]',
    nicklen     => 15,
    network     => 'wi',
    maxchannels => 30,
    version     => 1.0,
#   info        => [
#       'Welcome do WI WebIrc Server by perldelux',
#       'This service is not a right, its a privilege. Follow the rules and have fun.',
#   ],
    motd => [ split "\n", <<MOTD],
Welcome do WI WebIrc Server by perldelux
This service is not a right, its a privilege.
Follow the rules and have fun.

This service can be accessed from the web using the url:

    http://www.url.com.br

MOTD
);

my $pocosi = POE::Component::Server::IRC->spawn(
    config => \%config,
    debug  => 1,
);

use WI::IRC;
my $plugin = WI::IRC->new( ircd => $pocosi );
$pocosi->plugin_add( 'ExamplePlugin', $plugin );

POE::Session->create(
    heap          => { ircd => $pocosi },
    inline_states => {
        _start   => \&_start,
        _default => \&_default,

        #       ircd_daemon_nick    => \&ev_nick,
        #       ircd_daemon_join    => \&ev_join,
        #       ircd_daemon_part    => \&ev_part,
        #       ircd_daemon_privmsg => \&ev_privmsg,
        #       ircd_daemon_public  => \&ev_public,

        #       _daemon_public  => \&ev_public,

        #       ircd_daemon_topic   => \&ev_topic,
        #       ircd_daemon_kick    => \&ev_kick,
        #       ircd_daemon_mode    => \&ev_mode,

        #       publish_message => \&publish_message,

        #       ircd_daemon_ircmsg => \&ircmsg,
        event_name => sub {
            warn "$_[ARG0]\n";
            warn "--------------- event =====================";

            #       $_[KERNEL]->post( $_[SESSION], "event_name", $_[ARG0] + 1 );
        },
    },
);

$poe_kernel->run();

sub _start {
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];

    use WI::IRC::Redis;
    my $redis = WI::IRC::Redis->new( heap=> $heap );
    $redis->start;

    $heap->{ircd}->yield( 'register', 'all' );

    # Anyone connecting from the loopback gets spoofed hostname
    $heap->{ircd}->add_auth(
        mask     => '*@localhost',
        spoof    => 'STAFF',
        no_tilde => 1,
    );

    # We have to add an auth as we have specified one above.
    $heap->{ircd}->add_auth( mask => '*@*' );

    # Start a listener on the 'standard' IRC port.
    $heap->{ircd}->add_listener( port => 40404 );

    # Add an operator who can connect from localhost
    $heap->{ircd}->add_operator(
        {
            username => 'moo',
            password => 'fishdont',

            #           ipmask => '*@127.0.0.1'
            #           ipmask => '*@STAFF'
        }
    );
}

sub _default {
    my ( $event, $args ) = @_[ ARG0 .. $#_ ];

    print "$event :::::::::::::::::::::::::: ";
    for my $arg (@$args) {
        if ( ref($arg) eq 'ARRAY' ) {
            print "[", join( ", ", @$arg ), "] ";
        }
        elsif ( ref($arg) eq 'HASH' ) {
            print "{", join( ", ", %$arg ), "} ";
        }
        else {
            print "'$arg' " if defined $arg;
        }
    }

    print "\n";
}

