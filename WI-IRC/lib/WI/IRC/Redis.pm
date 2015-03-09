package WI::IRC::Redis;
use Moo;
use Redis;
use JSON::XS qw|encode_json decode_json|;
my $r     = Redis->new;
my $queue = 'actions';
use POE::Session;

has heap => ( is => "rw" );

my $_heap;

sub start {
    my $self = shift;
    $_heap = $self->heap;
    POE::Session->create(
        inline_states => {
            _start       => \&handler_start,
            incrementzor => \&handler_increment,
            _stop        => \&handler_stop,
        }
    );
}

#redis lpop
sub handler_start {
    my ( $kernel, $heap, $session ) = @_[ KERNEL, HEAP, SESSION ];

    #     print "Session ", $session->ID, " has started.\n";
    $heap->{count} = 0;
    $kernel->yield('incrementzor');
}

sub handler_increment {
    my ( $kernel, $heap, $session ) = @_[ KERNEL, HEAP, SESSION ];

  #warn $session->ID;
  #     print "Session ", $session->ID, " counted to ", ++$heap->{count}, ".\n";
  # $kernel->yield('incrementzor') if $heap->{count} < 10;

    my $next = sub {
        my $kernel = shift;
        $kernel->delay_add( tick => 1.0, \&handler_increment );
        $kernel->yield('incrementzor');
    };
    $next->($kernel) and return if !$_heap;
    my $res = $r->lpop($queue);

    if ($res) {

        #       warn " GOT VAL: $res " x 100;
        $res = decode_json $res;
        #$res->{ action } = add_spoofed_nick
        #$_heap->{ircd}->yield( $res->{ action } => $res->{ args } );
        if ( $res->{action} eq 'add_spoofed_nick' ) {
            $_heap->{ircd}->yield( $res->{action} => $res->{args} );

            #} elsif ( $res->{ action } eq 'add_op' ) {
            #    #give ops for user... i copied from test-harness.pl.
            #    #must be adjusted
            #    return if $heap->{ircd}->state_is_chan_op( $nick, $channel );
            #    $heap->{ircd}->daemon_server_mode( $channel, '+o', $nick );
        }
        elsif ( $res->{action} eq 'part' ) {

            #part channel on behalf of spoofed user
            $_heap->{ircd}->yield(
                'daemon_cmd_part',
                $res->{args}->{nick},
                $res->{args}->{channel}
            );

        }
        elsif ( $res->{action} eq 'join' ) {

#           my $full        = $_heap->{ircd}->state_user_full( $res->{ args }->{ nick } );

            #join channel on behalf of spoofed user
            $_heap->{ircd}->yield(
                'daemon_cmd_join',
                $res->{args}->{nick},
                $res->{args}->{channel}
            );

        }
        elsif ( $res->{action} eq 'msg' ) {

            my $target = $res->{channel};
            my $nick   = $res->{nick};
            my $msg    = $res->{msg};
            $_heap->{ircd}->yield( 'daemon_cmd_privmsg', $nick, $target, $msg );
        }

   #: {"action":"connect","nick":"2222"}
   #       if ( defined $res  and ref $res eq ref [] and scalar @{$res} == 2 ) {
   #           warn'received from redis:';
   #           my $val = decode_json $res->[1];
   #           warn "ACTION:";
   #           warn "ACTION:";
   #           warn "ACTION:";
   #           warn p $val;
   #       }
        $kernel->yield('incrementzor');
    }
    else {
        #sleep 1;
        #$_[KERNEL]->delay(incrementzor => 1);
        $kernel->delay( incrementzor => 1 );
        #$next->($kernel);
    }
}

1;
