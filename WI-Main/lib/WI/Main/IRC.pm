package WI::Main::IRC;
use strict;
use warnings;
use Moo;
use DDP;
use JSON::XS qw|encode_json decode_json|;
use utf8;
use Encode qw(decode encode);
use DateTime::Precise;
with qw|WI::Main::Role::CommonEvent|;

has _ref_main => ( is => 'rw' );

sub process {
    my $self = shift;
    my $item = shift;
    warn "Process[IRC]:";
    warn p $item;


    $item->{source}='irc';

    $item->{channel} = lc $item->{channel} if exists $item->{channel};

    $self->join( $item ) if $item->{action} eq 'join';
    $self->part( $item ) if $item->{action} eq 'part';
    $self->message( $item ) if $item->{action} eq 'message';
    $self->private_message( $item ) if $item->{action} eq 'private-message';
    $self->cleanup( $item ) if $item->{action} eq 'cleanup';
    $self->connect( $item ) if $item->{action} eq 'connect';
    $self->disconnect( $item ) if $item->{action} eq 'disconnect';
}

sub cleanup {
    my $self = shift;
    $self->_ref_main->db->user->user_channel->delete( { source => 'irc' } );
}

sub connect {
    my $self = shift;
    my $args = shift;
    $self->_ref_main->redis->rpush( 'web_incoming_main', encode_json $args );
#   $self->_ref_main->redis->rpush( 'irc_incoming_main', encode_json $args );
}

sub disconnect {
    my $self = shift;
    my $args = shift;
    $self->_ref_main->redis->rpush( 'web_incoming_main', encode_json $args );
#   $self->_ref_main->redis->rpush( 'irc_incoming_main', encode_json $args );
}

sub private_message {
    my $self = shift;
    my $args = shift;

    my $from = $self->_ref_main->db->user->find_or_create({
        username => $args->{ from }
    });
    my $to   = $self->_ref_main->db->user->find_or_create({
        username => $args->{ to }
    });
    my $log  = {
        from_user_id    => $from->id,
        to_user_id      => $to->id,
        source          => 'web',
        line            => $args->{line},
    };
    my $res = $from->private_message_log->insert( $log )->to_ws_obj;
#   #forward to web
    $self->_ref_main->redis->rpush( 'web_incoming_main', encode_json $res );
#   $self->_ref_main->redis->rpush( 'irc_incoming_main', encode_json $res );

}

sub message {

    #receives events that started in irc. Then passes them to the web
    my $self         = shift;
    my $args         = shift;

    my $channel = $self->_ref_main->db->channel->find_or_create(
        {
            name => $args->{channel}
        }
    );
    my $user = $self->_ref_main->db->user->find_or_create(
        {
            username => $args->{nick}
        }
    );

    my $log = {
        channel_id => $channel->id,
        user_id    => $user->id,
        line       => decode('UTF-8',$args->{line}),
        source     => 'irc',
        action     => $args->{action},
    };

    $log = $channel->log->insert( $log );
    my $res = $channel->log->find( { id => $log->id } )->to_ws_obj;

    #forward to web
    $self->_ref_main->redis->rpush( 'web_incoming_main', encode_json $res );

}

sub join {
    my $self = shift;
    my $args = shift;
    $args->{action} = 'join';
    #updates the channel status. everytime a user joins/parts the channel status is updated.
    my $channel = $self->_ref_main->db->channel->find_or_create(
        {
            name => $args->{channel}
        }
    );
    my $user = $self->_ref_main->db->user->find_or_create(
        {
            username => $args->{nick}
        }
    );

    my $log = {
        channel_id => $channel->id,
        user_id    => $user->id,
#       line       => decode('UTF-8',$args->{obj}->{msg}),
        source     => 'irc',
        action     => 'join',
    };

    $log = $channel->log->insert( $log );
    my $res = $channel->log->find( { id => $log->id } )->to_ws_obj;
    $user->join( $channel, 'irc' );


#   #Chama o channel_join que eh um comando central. tem que atualizar tanto pela web e irc.
#   $self->_ref_main->channel_join( $args );
    $self->_ref_main->redis->rpush( 'web_incoming_main', encode_json $res );
}

sub part {
    #updates the channel status. everytime a user joins/parts the channel status is updated.
    my $self = shift;
    my $args = shift;
    $args->{action} = 'part';
    my $channel = $self->_ref_main->db->channel->find_or_create(
        {
            name => $args->{channel}
        }
    );
    my $user = $self->_ref_main->db->user->find_or_create(
        {
            username => $args->{nick}
        }
    );

    my $log = {
        channel_id => $channel->id,
        user_id    => $user->id,
#       line       => decode('UTF-8',$args->{obj}->{msg}),
        source     => 'irc',
        action     => 'part',
    };

    $log = $channel->log->insert( $log );
    my $res = $channel->log->find( { id => $log->id } )->to_ws_obj;
    $user->part( $channel , 'irc' );
    $self->_ref_main->redis->rpush( 'web_incoming_main', encode_json $res );
}

1;
