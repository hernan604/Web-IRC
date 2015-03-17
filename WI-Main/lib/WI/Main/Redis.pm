package WI::Main::Redis;
use strict;
use warnings;
use Moo;
use DDP;
use JSON::XS qw|encode_json decode_json|;
use Mojo::Redis2;

has app => ( is => "rw" );

sub blpop_loop {
    my $self = shift;
    my @keys = (qw|
        main_incoming_irc 
        main_incoming_web
    |);
    my $timeout = 0;
    $self->app->redis->blpop( @keys, $timeout, sub {
        my ( $redis, $err, $res ) = @_;
        if ( defined $res 
             and ref $res eq ref [] 
             and scalar @{ $res } == 2 ) {
            my $queue   = $res->[0];
            my $val     = decode_json $res->[1];

            $self->app->irc->process( $val )
                if $queue eq 'main_incoming_irc'; 
            $self->app->web->process( $val )
                if $queue eq 'main_incoming_web';  
        }
        $self->blpop_loop;
    });
}

1;
