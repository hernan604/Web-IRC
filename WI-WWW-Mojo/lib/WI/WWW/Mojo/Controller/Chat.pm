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
        channel  => $chan,
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
        channel  => $chan,
        nick    => $nick,
    } );
    $self->render( json => { status => 'OK' } );
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
        #user wrote a message
        my $dt   = DateTime->now( time_zone => 'America/Sao_Paulo' );
        my $args = decode_json encode('UTF-8', $args );#* * * TODO: Validate if $args is json  before decodde_json
        my $nick = $self->session('nick');
        $args->{ nick } = $nick;
#       $args->{ channel } = '#'.$self->param('channel');
        $args->{ source } = 'web';
        my $chan = $args->{ chan };
        my $queue = $self->queue->{main_incoming_web};
        my $item = {
            action  => $args->{ action }, #TODO: validate actions here
            line    => $args->{ line },
            nick    => $nick,
        };
        $item->{ channel } = $args->{ chan } if exists $args->{ chan } and defined $args->{ chan };
        if ( $args->{ action } eq 'private-message' ) {
            $item->{ from } = $self->session('nick');
            $item->{ to }   = $args->{ to };
            delete $item->{ nick };
        }
        $self->redis->rpush( $queue, encode_json $item ) if $self->nick->is_in_chan($nick, $chan);
    } );

    $self->on( finish => sub {
        delete $clients->{$id};
       #$self->nick->part( $nick, $chan );
        #TODO: Delete the user from inside channels.
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

sub ws_send_private_msg {
    my $self = shift;
    my $json = shift;

    foreach my $nick ( $json->{from}, $json->{to} ) {
        warn "ws_send to nick: $nick"
            if ( exists $self->nick->ws->{ $nick } );
        $self->nick->ws->{ $nick }->send( { json => $json } )
            if ( exists $self->nick->ws->{ $nick } );
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
            $self->from_redis( $clients, $res, $redis, $err, $val );
        }
        $self->blpop($clients);
    });
}

sub from_redis {
    my $self = shift;
    my ( $clients, $res, $redis, $err, $val ) = @_;
        $self->msg_from_irc(@_) 
     || $self->private_msg(@_) 
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
    for ( keys %{ $clients } ) {
        my $ws = $clients->{ $_ };
        $ws->send({ json => $val });
    }
    return 1;
}

sub disconnect {
    my ( $self, $clients, $res, $redis, $err, $val ) = @_;
    return 0 if !$val || !$val->{source} || !$val->{nick} || !$val->{action};
    return 0 if $val->{action} ne 'disconnect';
    for ( keys %{ $clients } ) {
        my $ws = $clients->{ $_ };
        $ws->send({ json => $val });
    }
    return 1;
}

sub msg_from_irc {
    my ( $self, $clients, $res, $redis, $err, $val ) = @_;
    return 0 if !$val || !$val->{source} || !$val->{nick} || !$val->{line} || !$val->{channel};
    return 0 if $val->{action} ne 'message';
    #my $val = decode_json $res;
    my $dt   = DateTime->now( time_zone => 'America/Sao_Paulo' );

    my $chan = $val->{channel};
    $self->ws_send( $chan => {
        source  => $val->{source},
        channel => $val->{channel},
        action  => $val->{action},
        nick    => $val->{nick},
        hms     => $dt->hms,
        line    => $val->{line},
    } );
    return 1;
}

sub private_msg {
    my ( $self, $clients, $res, $redis, $err, $val ) = @_;
    return 0 if !$val || !$val->{source} || !$val->{from} || !$val->{to} || !$val->{line};
    return 0 if $val->{action} ne 'private-message';
    warn "PRIVATE MESSAGE", p $val;
    $self->ws_send_private_msg( {
        source  => $val->{source},
        action  => $val->{action},
        to      => $val->{to},
        from    => $val->{from},
        created => $val->{created},
        line    => $val->{line},
    } );
    return 1;
}

sub channel_join {
    my ( $self, $clients, $res, $redis, $err, $val ) = @_;
    return 0 if 
           ! $val
        || ! $val->{source}
        || ! $val->{channel}
        || ! $val->{action}
        ||   $val->{action} ne 'join';
    my $dt = DateTime->now( time_zone => 'America/Sao_Paulo' );
    $self->nick->join( $val->{nick}, $val->{channel} , $val->{ source } ) ;
warn "JOIN";
warn p $val;

    $self->ws_send( $val->{channel} => {
        source      => $val->{source},
        channel      => $val->{channel},
        action      => $val->{action},
        nick        => $val->{nick},
        hms         => $dt->hms,
        text        => $val->{msg},
        last_msg_id => $val->{channel_log_id},
    } );

    return 1;
}

sub channel_part {
    my ( $self, $clients, $res, $redis, $err, $val ) = @_;
    return 0 if !$val || !$val->{source} || !$val->{channel} || !$val->{action} || $val->{action} ne 'part';
    my $dt = DateTime->now( time_zone => 'America/Sao_Paulo' );
    $self->nick->part( $val->{nick}, $val->{channel} , $val->{ source } );
warn "PART";
warn p $val;

    $self->ws_send( $val->{channel} => {
        source  => $val->{source},
        channel  => $val->{channel},
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
