package WI::WWW::Mojo::Controller::Chat;
use base 'Mojolicious::Controller';
use Mojo::Redis2;
use DateTime;
use DDP;
use JSON::XS qw|decode_json encode_json|;
#use Redis;
use utf8;
use Encode qw(decode encode);
#use strict;
#use warnings;

sub join {
    my $self = shift;
    my $nick = $self->session('nick');
    my $chan = '#'.$self->param('channel');
    $self->nick->join( $nick, $chan, 'web' );
    my $queue = $self->app->queue->{main_incoming_web};
    $self->app->redis->rpush( $queue, encode_json {
        action  => 'join',
        target  => $chan,
        nick    => $nick,
    } );

    $self->render( json => { status => 'OK' } );
}

sub part {
    my $self = shift;
    my $nick = $self->session('nick');
    my $chan = '#'.$self->param('channel');
    $self->nick->part( $nick, $chan, 'web' );
    my $queue = $self->app->queue->{main_incoming_web};
    $self->app->redis->rpush( $queue, encode_json {
        action  => 'part',
        target  => $chan,
        nick    => $nick,
    } );
    $self->render( json => { status => 'OK' } );
}

sub send_to_ircd {
    my $self = shift;
    my $args = shift;
    my $queue = $self->queue->{main_incoming_web};
    $self->redis->rpush( $queue, encode_json $args) if defined $args;
}

sub chat {
    my $self = shift;
    $self->respond_to(
        html => sub {
            my $self = shift;
            $self->redirect_to( '/login' ) 
                and return if ( ! $self->session->{ nick } );
            $self->render( 'chat' );
        }
    );
}

sub chat_ws {
    my $self = shift;
    $self->inactivity_timeout(60*60*24);


    my $id = sprintf "%s", $self->tx;
    $clients->{$id} = $self->tx;

    my $nick = $self->session('nick');

    $self->nick->ws->{$nick} = $self->tx 
        if ! exists $self->nick->ws->{$nick};

    if ( ! $self->nick->is_connected( $nick ) ) {
        $self->redis->rpush( 'main_incoming_web', encode_json {
            action  => 'connect',
            nick    => $self->session('nick'),
        } );
    }

    $self->on( message => sub {
        my ( $self, $args ) = @_; 

        warn p $self->nick;
        warn "^^ self->nick ^^";
        warn p $args;
        warn '^^ args ^^';

        #user wrote a message
        my $dt   = DateTime->now( time_zone => 'America/Sao_Paulo' );
        my $args = decode_json encode('UTF-8', $args );#* * * TODO: Validate if $args is json  before decodde_json
        my $nick = $self->session('nick');
        $args->{ nick } = $nick;
#       $args->{ channel } = '#'.$self->param('channel');
        $args->{ source } = 'web';
        my $chan = $args->{ chan };
        my $queue = $self->queue->{main_incoming_web};
        $self->redis->rpush( $queue, encode_json {
            action  => 'message',
            channel => $args->{ chan },
            msg     => $args->{ msg },
            nick    => $nick,
        } ) if $self->nick->is_in_chan($nick, $chan);

#       my $ws_path = '/chat_ws/'. $self->param('channel');

#       $self->ws_send( $chan => {
#           action  => 'message',
#           target  => $args->{ chan },
#           hms     => $dt->hms,
#           text    => $args->{msg},
#           source  => 'web',
#           nick    => $args->{nick},
#       } )


    } );

    $self->on( finish => sub {
        delete $clients->{$id};
       #$self->nick->part( $nick, $chan );
        #TODO: Tell WI-Main user has disconnected. Delete the user from inside channels.
        $self->nick->disconnected( $self->session( 'nick' ) );
        $self->redis->rpush( 'main_incoming_web', encode_json {
            action  => 'disconnect',
            nick    => $self->session('nick'),
        } );
    } );
    
    $self->blpop($clients, $chan);
}

sub ws_send {
    my $self = shift;
    my $chan = shift;
    my $json = shift;
    warn "ws_send";

    my $ws_in_chan = 
        { map { exists $self->nick->ws->{ $_ } 
                    ? ( $_ => $self->nick->ws->{ $_ } ) 
                    : () }
        @{ $self->nick->channels->{ $chan } } };

    for ( keys %{ $ws_in_chan } ) {
        my $nick = $_;
        my $ws = $ws_in_chan->{ $nick };
        warn " => SEND TO: $nick";
        warn p $json;
        $ws->send( { json => $json } );
    }
}

sub blpop {
    my $self = shift;
    my $clients = shift;
    my $chan = shift;
    my @keys = ('web_incoming_main');
    my $timeout = 0;

    $self->redis->blpop( @keys, $timeout, sub {
        my ( $redis, $err, $res ) = @_;
        warn'received from redis 11111111:';
    #   warn p @_;
        if ( defined $res  
             and ref $res eq ref [] 
             and scalar @{$res} == 2 ) {
            my $val = decode_json $res->[1];
            warn p $val;

            my $target = $val->{target};
#           $target    =~ s|^#||;
#           $ws_path   =  '/chat_ws/'.$target;

            $self->from_redis( $clients, $res, $redis, $err, $val );
        }
        $self->blpop($clients);
    });
}

sub from_redis {
    my $self = shift;
    my ( $clients, $res, $redis, $err, $val ) = @_;
        $self->msg_from_irc(@_) 
     || $self->channel_join(@_) 
     || $self->channel_part(@_) 
     || $self->connect(@_) 
     || $self->disconnect(@_) 
     || warn '*** could not find any action for this redis message' 
         and return; #try to execute messages received from redis
}

sub connect { 
    my ( $self, $clients, $res, $redis, $err, $val ) = @_;
    return 0 if !$val || !$val->{source} || !$val->{nick} || !$val->{action};
    return 0 if $val->{action} ne 'connect';
    warn "Tell everyone a user has connected" ; 
    warn "TODO: Change user status to connected... or the user last saved status. The status must come within this message. That means Main must set the status on the hash before information gets here.";
}

sub disconnect { 
    my ( $self, $clients, $res, $redis, $err, $val ) = @_;
    return 0 if !$val || !$val->{source} || !$val->{nick} || !$val->{msg} || !$val->{channel};
    return 0 if $val->{action} ne 'disconnect';
    warn "Tell everyone a user has connected" ;
}

sub msg_from_irc {
    my ( $self, $clients, $res, $redis, $err, $val ) = @_;
    return 0 if !$val || !$val->{source} || !$val->{nick} || !$val->{msg} || !$val->{channel};
    return 0 if $val->{action} ne 'message';
    #my $val = decode_json $res;
    my $dt   = DateTime->now( time_zone => 'America/Sao_Paulo' );

    my $chan = $val->{channel};
    $self->ws_send( $chan => {
        source  => $val->{source},
        target  => $val->{channel},
        action  => $val->{action},
        nick    => $val->{nick},
        hms     => $dt->hms,
        text    => $val->{msg},
    } );

#   for (keys %$clients) {
#       $clients->{$_}->send({ json => {
#           source  => $val->{source},
#           target  => $val->{target},
#           action  => $val->{action},
#           nick    => $val->{nick},
#           hms     => $dt->hms,
#           text    => $val->{msg},
#       }});
#   }
    return 1;
}

sub channel_join {
    my ( $self, $clients, $res, $redis, $err, $val ) = @_;
    return 0 if 
           ! $val
        || ! $val->{source}
        || ! $val->{target}
        || ! $val->{action}
        ||   $val->{action} ne 'join';
    my $dt = DateTime->now( time_zone => 'America/Sao_Paulo' );
    $self->nick->join( $val->{nick}, $val->{target} , $val->{ source } ) ;
warn "JOIN";
warn p $val;

    $self->ws_send( $val->{target} => {
        source  => $val->{source},
        target  => $val->{target},
        action  => $val->{action},
        nick    => $val->{nick},
        hms     => $dt->hms,
        text    => $val->{msg},
    } );

    return 1;
}

sub channel_part {
    my ( $self, $clients, $res, $redis, $err, $val ) = @_;
    return 0 if !$val || !$val->{source} || !$val->{target} || !$val->{action} || $val->{action} ne 'part';
    my $dt = DateTime->now( time_zone => 'America/Sao_Paulo' );
    $self->nick->part( $val->{nick}, $val->{target} , $val->{ source } );
warn "PART";
warn p $val;

    $self->ws_send( $val->{target} => {
        source  => $val->{source},
        target  => $val->{target},
        action  => $val->{action},
        nick    => $val->{nick},
        hms     => $dt->hms,
        text    => $val->{msg},
    } );
    return 1;
}

sub root {
    my $self = shift;
    $self->respond_to(
        html => sub {
            my $self = shift;
            $self->redirect_to('/login') if ! $self->session('nick');
            $self->render( 'chat.root' );
        }
    );
}

1;
