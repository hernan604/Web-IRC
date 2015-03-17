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

my $redis = Mojo::Redis2->new;

sub send_to_ircd {
    my $self = shift;
    my $args = shift;
    warn 'SEND TO IRCD';
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
    my $channel = $self->param('channel');

    if ( ! $self->nick->is_connected( $nick ) ) {
        $self->redis->rpush( 'main_incoming_web', encode_json {
            action  => 'connect',
            nick    => $self->session('nick'),
        } );
    }

    my $queue = 'actions';
    my $chan = '#'.$self->param('channel');

    my $queue = $self->queue->{main_incoming_web};
    $self->redis->rpush( $queue, encode_json {
        action  => 'join',
        target  => $chan,
        nick    => $self->session('nick'),
    } );

    $self->on(message => sub {
        my ( $self, $args ) = @_; 
        #user wrote a message
        my $dt   = DateTime->now( time_zone => 'America/Sao_Paulo' );
        my $args = decode_json encode('UTF-8', $args );#* * * TODO: Validate if $args is json  before decodde_json
        $args->{ nick } = $self->session('nick');
        $args->{ channel } = '#'.$self->param('channel');
        $args->{ source } = 'web';

        my $queue = $self->queue->{main_incoming_web};
        $self->redis->rpush( $queue, encode_json {
            action  => 'message',
            channel => '#'.$self->param('channel'),
            msg     => $args->{ msg },
            nick    => $self->session('nick')
        } ) if $self->nick->is_in_chan($nick, $chan);

        my $ws_path = '/chat_ws/'. $self->param('channel');

        for (keys %$clients) {
            if ( $clients->{$_} && $clients->{$_}->req && $clients->{$_}->req->url eq $ws_path ) {
                $clients->{$_}->send({json => {
                    action  => 'message',
                    hms     => $dt->hms,
                    text    => $args->{msg},
                    source  => 'web',
                    nick    => $args->{nick},
                }});
            }
        }
    });

    $self->on(finish => sub {
        delete $clients->{$id};
        $self->nick->part( $nick, $chan );

        my $queue = $self->queue->{main_incoming_web};
        $self->redis->rpush( $queue, encode_json { 
            target  => $chan,
            nick    => $self->session('nick'),
            action  => 'part',
        } )
    });
    
    $self->blpop($clients, $chan);
}


sub blpop {
    my $self = shift;
    my $clients = shift;
    my $chan = shift;
    my @keys = ('web_incoming_main');
    my $timeout = 0;

    $redis->blpop( @keys, $timeout, sub {
        my ( $redis, $err, $res ) = @_;
        warn'received from redis 11111111:';
    #   warn p @_;
        if ( defined $res  and ref $res eq ref [] and scalar @{$res} == 2 ) {
            my $val = decode_json $res->[1];
            warn p $val;

            my $target = $val->{target};
            $target    =~ s|^#||;
            $ws_path   =  '/chat_ws/'.$target;

            $self->from_redis( $clients, $res, $redis, $err, $val, $ws_path );
        }
        $self->blpop($clients);
    });
}

sub from_redis {
    my $self = shift;
    my ( $clients, $res, $redis, $err, $val, $ws_path ) = @_;
        $self->msg_from_irc(@_) 
    || $self->channel_join(@_) 
    || $self->channel_part(@_) 
    || warn '*** could not find any action for this redis message' 
        and return; #try to execute messages received from redis
}

sub msg_from_irc {
    my ( $self, $clients, $res, $redis, $err, $val, $ws_path ) = @_;
    return 0 if !$val || !$val->{source} || !$val->{nick} || !$val->{msg};
    return 0 if $val->{action} ne 'message';
    #my $val = decode_json $res;
    my $dt   = DateTime->now( time_zone => 'America/Sao_Paulo' );

    for (keys %$clients) {
        if ($clients->{$_} && $clients->{$_}->req && $clients->{$_}->req->url eq $ws_path ) {
            $clients->{$_}->send({ json => {
                source  => $val->{source},
                target  => $val->{target},
                action  => $val->{action},
                nick    => $val->{nick},
                hms     => $dt->hms,
                text    => $val->{msg},
            }});
        }
    }
    return 1;
}

sub channel_join {
    my ( $self, $clients, $res, $redis, $err, $val, $ws_path ) = @_;
    return 0 if 
        !$val || 
        !$val->{source} || 
        !$val->{target} || 
        !$val->{action} || 
        $val->{action} ne 'join';
    my $dt   = DateTime->now( time_zone => 'America/Sao_Paulo' );
    $self->nick->join( $val->{nick}, $val->{target} );

    for (keys %$clients) {
        if ($clients->{$_} && $clients->{$_}->req && $clients->{$_}->req->url eq $ws_path ) {
            $clients->{$_}->send({ json => {
                source  => $val->{source},
                target  => $val->{target},
                action  => $val->{action},
                nick    => $val->{nick},
                hms     => $dt->hms,
                text    => $val->{msg},
            }});
        }
    }
    return 1;
}

sub channel_part {
    my ( $self, $clients, $res, $redis, $err, $val, $ws_path ) = @_;
    return 0 if !$val || !$val->{source} || !$val->{target} || !$val->{action} || $val->{action} ne 'part';
    my $dt   = DateTime->now( time_zone => 'America/Sao_Paulo' );
    $self->nick->join( $val->{nick}, $val->{target} );

    for (keys %$clients) {
        if ($clients->{$_} && $clients->{$_}->req && $clients->{$_}->req->url eq $ws_path ) {
            $clients->{$_}->send({ json => {
                source  => $val->{source},
                target  => $val->{target},
                action  => $val->{action},
                nick    => $val->{nick},
                hms     => $dt->hms,
                text    => $val->{msg},
            }});
        }
    }
    return 1;
}

sub root {
    my $self = shift;
    $self->respond_to(
        html => sub {
            my $self = shift;
            $self->redirect_to('/loginlogin') if ! $self->session('nick');
            $self->render( 'chat.root' );
        }
    );
}

1;
