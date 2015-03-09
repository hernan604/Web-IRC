package WI::Main::WEB;
use strict;
use warnings;
use Moo;
use DDP;
use JSON::XS qw|encode_json decode_json|;

has _ref_main => ( is => 'rw' );

sub message_public {
    my $self = shift;
    my $args = shift;

    my $channel = $self->_ref_main->db->channel->find_or_create(
        {
            name => $args->{obj}->{target}
        }
    );
    my $user = $self->_ref_main->db->user->find_or_create(
        {
            username => $args->{obj}->{nick}
        }
    );

    my $log = {
        channel_id => $channel->id,
        user_id    => $user->id,
        line       => $args->{obj}->{msg},
        source     => 'web',
    };
    $channel->log->insert( $log );

    #forward to web
    $self->_ref_main->redis->rpush( $args->{ queue } , encode_json $args->{obj} );
}

sub channel_join {
    #updates the channel status. everytime a user joins/parts the channel status is updated. 
    my $self = shift;
    my $args = shift;
    $args->{obj}->{action} = 'join';
    $args->{obj}->{source} = 'web';
    my $channel = $self->_ref_main->db->channel->find_or_create(
        {
            name => $args->{obj}->{target}
        }
    );
    my $user = $self->_ref_main->db->user->find_or_create(
        {
            username => $args->{obj}->{nick}
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
    $user->join( $channel );

#   $self->_ref_main->channel_join( $args );
    $self->_ref_main->redis->rpush( 'from_irc', encode_json $args->{obj} );
#   $self->redis->rpush( 'actions' , encode_json $args ) if defined $args;
}

sub channel_part {
    my $self = shift;
    my $args = shift;
    $args->{obj}->{action} = 'part';
    $args->{obj}->{source} = 'web';
    #updates the channel status. everytime a user joins/parts the channel status is updated.
    my $channel = $self->_ref_main->db->channel->find_or_create(
        {
            name => $args->{obj}->{target}
        }
    );
    my $user = $self->_ref_main->db->user->find_or_create(
        {
            username => $args->{obj}->{nick}
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
    $user->part( $channel );
    $self->_ref_main->redis->rpush( 'from_irc', encode_json $args->{obj} );
}

1;
