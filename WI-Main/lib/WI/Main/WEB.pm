package WI::Main::WEB;
use strict;
use warnings;
use Moo;
use DDP;
use JSON::XS qw|encode_json decode_json|;

has _ref_main => ( is => 'rw' );

sub process {
    my $self = shift;
    my $item = shift;

warn "WIN MAIN WEB - REDIS ITEM:";
warn p $item;

    $item->{source}='web';

    $self->join( $item ) if $item->{action} eq 'join';
    $self->part( $item ) if $item->{action} eq 'part';
    $self->message( $item ) if $item->{action} eq 'message';
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
            name => $args->{target}
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
        line       => $args->{msg},
        source     => 'web',
    };
    $channel->log->insert( $log );
    #forward to web
    $self->_ref_main->redis->rpush( 'web_incoming_main', encode_json $args );
    $self->_ref_main->redis->rpush( 'irc_incoming_main', encode_json $args );
}

sub join {
    #updates the channel status. everytime a user joins/parts the channel status is updated. 
    my $self = shift;
    my $args = shift;
#   $args->{action} = 'join';
    $args->{source} = 'web';
    my $channel = $self->_ref_main->db->channel->find_or_create(
        {
            name => $args->{target}
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

    $channel->log->insert( $log );
    $user->join( $channel, 'web' );

    $self->_ref_main->redis->rpush( 'web_incoming_main', encode_json $args );
    $self->_ref_main->redis->rpush( 'irc_incoming_main', encode_json $args );
}

sub part {
    my $self = shift;
    my $args = shift;
    $args->{action} = 'part';
    $args->{source} = 'web';
    #updates the channel status. everytime a user joins/parts the channel status is updated.
    my $channel = $self->_ref_main->db->channel->find_or_create(
        {
            name => $args->{target}
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

    $channel->log->insert( $log );
    $user->part( $channel , 'web');
    $self->_ref_main->redis->rpush( 'web_incoming_main', encode_json $args );
    $self->_ref_main->redis->rpush( 'irc_incoming_main', encode_json $args );
}

1;
