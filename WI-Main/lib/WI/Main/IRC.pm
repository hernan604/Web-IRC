package WI::Main::IRC;
use strict;
use warnings;
use Moo;
use DDP;
use JSON::XS qw|encode_json decode_json|;
use utf8;
use Encode qw(decode encode);
use DateTime::Precise;

has _ref_main => ( is => 'rw' );

sub message_public {

    #receives events that started in irc. Then passes them to the web
    my $self         = shift;
    my $args         = shift;
    my $redis_method = $args->{method};

    #   my $user = $self->_ref_main->db->user->find_or_create( {
    #
    #   } );

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
        line       => decode('UTF-8',$args->{obj}->{msg}),
        source     => 'irc',
        action     => $args->{obj}->{action},
    };

    $channel->log->insert( $log );

    #forward to web
    $self->_ref_main->redis->rpush( $args->{queue}, encode_json $args->{obj} );

}

sub channel_join {
    my $self = shift;
    my $args = shift;
    $args->{obj}->{action} = 'join';
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
        source     => 'irc',
        action     => 'join',
    };

    $channel->log->insert( $log );


#   #Chama o channel_join que eh um comando central. tem que atualizar tanto pela web e irc.
#   $self->_ref_main->channel_join( $args );
    $self->_ref_main->redis->rpush( $args->{queue}, encode_json $args->{obj} );
}

sub channel_part {
    #updates the channel status. everytime a user joins/parts the channel status is updated.
    my $self = shift;
    my $args = shift;
    #updates the channel status. everytime a user joins/parts the channel status is updated.
    $args->{obj}->{action} = 'part';
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
        source     => 'irc',
        action     => 'part',
    };

    $channel->log->insert( $log );
    $self->_ref_main->redis->rpush( $args->{queue}, encode_json $args->{obj} );
}

1;
