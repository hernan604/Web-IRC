package WI::WWW::Mojo::Controller::Chat;
use base 'Mojolicious::Controller';
use Mojo::Redis2;
use DateTime;
use DDP;
use JSON::XS qw|decode_json encode_json|;
use Redis;
use utf8;
use Encode qw(decode encode);
#use strict;
#use warnings;

my $redis = Mojo::Redis2->new;

#   sub chat_enter {
#       my $self = shift;
#       $self->respond_to(
#           html => sub {
#               my $self = shift;
#               $self->render('chat.enter');
#           },
#           json => sub {
#               if ( $self->req->method eq 'PUT' ) {
#                   #each user must have unique nicks - this will happen during registration.
#                   #when the user logs in, the nick will be saved into user session.
#   #               my $nick = $self->req->param('nick');
#                   my $nick = $self->tx->req->json->{ nick } ;
#                   $self->session({ nick  => $nick });

#                   $self->send_to_ircd({
#                       to => 'ircd',
#                       action => 'add_spoofed_nick',
#                       args => {
#                           nick   => $nick,
#                       }
#                   } );


#   #               $self->redirect_to('chat');
#                   $self->render( 'json' => {
#                       redirect => '/chat/' #put this in a json type of req
#                   } );
#               }
#           }
#       );
#   }

sub send_to_ircd {
#   use DDP;
#   warn p @_;
    my $self = shift;
    my $args = shift;
    warn 'SEND TO IRCD';
    $redis->rpush( 'actions' , encode_json $args ) if defined $args;
}

sub chat {
    my $self = shift;
    $self->respond_to(
        html => sub {
            my $self = shift;
            $self->redirect_to( '/login' ) and return if ( ! $self->session->{ nick } );
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
        $self->send_to_ircd( {
            to      => 'ircd',
            action  => 'add_spoofed_nick',
            args    => {
                nick   => $nick,
            }
        } ) ;
    }

    my $queue = 'actions';
    my $chan = '#'.$self->param('channel');

    $self->send_to_ircd( {
        to      => 'ircd',
        action  => 'join',
        args => {
            nick    => $self->session('nick'),
            channel => $chan
        }
    } );

    $self->wi_main->web->channel_join( { 
        queue => $queue, 
        obj => {
            target  => $chan,
            nick    => $self->session('nick'),
        }
    } ) ;


#   my $clients = {};
    $self->on(message => sub {
        my ( $self, $args ) = @_; 
        #user wrote a message
        my $dt   = DateTime->now( time_zone => 'America/Sao_Paulo' );
        my $args = decode_json encode('UTF-8', $args );#* * * TODO: Validate if $args is json  before decodde_json
        $args->{ nick  } = $self->session('nick');
        $args->{ channel } = '#'.$self->param('channel');
        $args->{ source } = 'web';

        $self->wi_main->web->message_public( { queue => $queue, obj => $args } ) 
            if ( $args->{action} eq 'msg' )
            and $self->nick->is_in_chan($nick, $chan);

        my $ws_path = '/chat_ws/'. $self->param('channel');

        for (keys %$clients) {
            if ( $clients->{$_} && $clients->{$_}->req && $clients->{$_}->req->url eq $ws_path ) {
                $clients->{$_}->send({json => {
                    action  => 'msg',
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


        $self->send_to_ircd( {
            to      => 'ircd',
            action  => 'part',
            args => {
                nick    => $self->session('nick'),
                channel => $chan
            }
        } );

        $self->wi_main->web->channel_part( { 
            queue => $queue, 
            obj => {
                target  => $chan,
                nick    => $self->session('nick'),
                action  => 'part',
            }
        } ) ;

    });
    
    $self->blpop($clients, $chan);
}


sub blpop {
    my $self = shift;
    my $clients = shift;
    my $chan = shift;
    my @keys = ('from_irc');
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
    return 0 if $val->{action} ne 'msg';
    #my $val = decode_json $res;
    my $dt   = DateTime->now( time_zone => 'America/Sao_Paulo' );

#   my $target = $val->{target};
#   $target =~ s|^#||;
#   my $chan_from_queue = $res->[0]; 
#   $chan_from_queue =~ s|^from_irc#||; 


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
    return 0 if !$val || !$val->{source} || !$val->{target} || !$val->{action} || $val->{action} ne 'join';
#   my $dt   = DateTime->now( time_zone => 'America/Sao_Paulo' );
#   for (keys %$clients) {
#       if ($clients->{$_} && $clients->{$_}->req && $clients->{$_}->req->url eq $ws_path ) {
#           $clients->{$_}->send({ json => $val }); # * * * security  problem here... must filter before forwaring to users
#       }
#   }
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

#   sub irc_ws {
#       #receive messages from irc
#       my $self = shift;
#       $self->inactivity_timeout(60*60*24);

#       my $id = sprintf "%s", $self->tx;
#       $clients->{$id} = $self->tx;


#       $self->blpop($clients);

#   #   while (1) {
#   #       my $val = $redis->blpop('input', 0);
#   #       if ( $val and ref $val eq ref [] ) {
#   #           $val->[1] = decode_json $val->[1];
#   #       }
#   #       warn "RECEIVED:"; 
#   #       warn p $val;
#   #       my $dt   = DateTime->now( time_zone => 'America/Sao_Paulo' );
#   #                                                                     
#   #       for (keys %$clients) {
#   #           $clients->{$_}->send({json => {
#   #               hms  => $dt->hms,
#   #               text => $val->[1],
#   #           }});
#   #       }

#   #   }

#   #   $self->on(message => sub {
#   #       my ($self, $msg) = @_;

#   #       my $dt   = DateTime->now( time_zone => 'America/Sao_Paulo' );

#   #       for (keys %$clients) {
#   #           $clients->{$_}->send({json => {
#   #               hms  => $dt->hms,
#   #               text => $msg,
#   #           }});
#   #       }
#   #   });

#       $self->on(finish => sub {
#           delete $clients->{$id};
#       });
#   }

1;
