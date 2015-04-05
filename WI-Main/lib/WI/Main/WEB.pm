package WI::Main::WEB;
use strict;
use warnings;
use Moo;
use DDP;
use JSON::XS qw|encode_json decode_json|;
with qw|WI::Main::Role::CommonEvent|;

has _ref_main => ( is => 'rw' );

sub process {
    my $self = shift;
    my $item = shift;

warn "WIN MAIN WEB - REDIS ITEM:";
warn p $item;

    $item->{source}='web';
    $item->{channel} = lc $item->{channel} if exists $item->{channel} and defined $item->{channel} ;

    $self->join( $item ) if $item->{action} eq 'join';
    $self->part( $item ) if $item->{action} eq 'part';
    $self->message( $item ) if $item->{action} eq 'message';
    $self->private_message( $item ) if $item->{action} eq 'private-message';
    $self->connect( $item ) if $item->{action} eq 'connect';
    $self->disconnect( $item ) if $item->{action} eq 'disconnect';
    $self->cleanup( $item ) if $item->{action} eq 'cleanup';
}

sub cleanup {
    my $self = shift;
    $self->_ref_main->db->user->user_channel->delete( { source => 'web' } );
}

sub connect {
    my $self = shift;
    my $args = shift;
    $self->_ref_main->redis->rpush( 'web_incoming_main', encode_json $args );
    $self->_ref_main->redis->rpush( 'irc_incoming_main', encode_json $args );
}

sub disconnect {
    my $self = shift;
    my $args = shift;
    $self->_ref_main->redis->rpush( 'web_incoming_main', encode_json $args );
    $self->_ref_main->redis->rpush( 'irc_incoming_main', encode_json $args );
}

sub message {
    my $self = shift;
    my $args = shift;

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
        line       => $args->{line},
        source     => 'web',
        action     => 'message',
    };
    $log = $channel->log->insert( $log );
    my $res = $channel->log->find( { id => $log->id } )->to_ws_obj;
    #forward to web
    $self->_ref_main->redis->rpush( 'web_incoming_main', encode_json $res );
    $self->_ref_main->redis->rpush( 'irc_incoming_main', encode_json $res );
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
    $self->_ref_main->redis->rpush( 'irc_incoming_main', encode_json $res );
}

=head2 join

INPUT: {"action":"join","target":"#systems","nick":"teste","source":"web"} at /home/administrator/perl/WI-V3/WI-Main/scripts/../lib/WI/Main/WEB.pm line 87.

OUTPUT: {
"channel_log_id":79612,
"target":"#systems",
"action":"join",
"nick":"teste",
"source":"web"} at /home/administrator/perl/WI-V3/WI-Main/scripts/../lib/WI/Main/WEB.pm line 112.


=cut

sub join {
    #updates the channel status. everytime a user joins/parts the channel status is updated. 
    my $self = shift;
    my $args = shift;
#   $args->{action} = 'join';
    $args->{source} = 'web';
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
        source     => 'web',
        action     => 'join',
    };

    $log = $channel->log->insert( $log );
    $user->join( $channel, 'web' );
    my $res = $channel->log->find( { id => $log->id } )->to_ws_obj;
    $self->_ref_main->redis->rpush( 'web_incoming_main', encode_json $res );
    $self->_ref_main->redis->rpush( 'irc_incoming_main', encode_json $res );
}

sub part {
    my $self = shift;
    my $args = shift;
    $args->{action} = 'part';
    $args->{source} = 'web';
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
        source     => 'web',
        action     => 'part',
    };

    $log = $channel->log->insert( $log );
    $user->part( $channel , 'web');
    my $res = $channel->log->find( { id => $log->id } )->to_ws_obj;
    $self->_ref_main->redis->rpush( 'web_incoming_main', encode_json $res );
    $self->_ref_main->redis->rpush( 'irc_incoming_main', encode_json $res );
}

1;
