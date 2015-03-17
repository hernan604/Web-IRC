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

sub process {
    my $self = shift;
    my $item = shift;
    warn "Process[IRC]:";
    warn p $item;


    $item->{source}='irc';

    $self->join( $item ) if $item->{action} eq 'join';
    $self->part( $item ) if $item->{action} eq 'part';
    $self->message( $item ) if $item->{action} eq 'message';
    $self->cleanup( $item ) if $item->{action} eq 'cleanup';
}

sub cleanup {
    my $self = shift;
    $self->_ref_main->db->user->user_channel->delete( { source => 'irc' } );
}

sub message {

    #receives events that started in irc. Then passes them to the web
    my $self         = shift;
    my $args         = shift;
    my $redis_method = $args->{method};

    #   my $user = $self->_ref_main->db->user->find_or_create( {
    #
    #   } );

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
        line       => decode('UTF-8',$args->{msg}),
        source     => 'irc',
        action     => $args->{action},
    };

    $channel->log->insert( $log );

    #forward to web
    $self->_ref_main->redis->rpush( 'web_incoming_main', encode_json $args );

}

sub join {
    my $self = shift;
    my $args = shift;
    $args->{action} = 'join';
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
        source     => 'irc',
        action     => 'join',
    };

    $channel->log->insert( $log );
    $user->join( $channel, 'irc' );


#   #Chama o channel_join que eh um comando central. tem que atualizar tanto pela web e irc.
#   $self->_ref_main->channel_join( $args );
    $self->_ref_main->redis->rpush( 'web_incoming_main', encode_json $args );
}

sub part {
    #updates the channel status. everytime a user joins/parts the channel status is updated.
    my $self = shift;
    my $args = shift;
    #updates the channel status. everytime a user joins/parts the channel status is updated.
    $args->{action} = 'part';
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
        source     => 'irc',
        action     => 'part',
    };

    $channel->log->insert( $log );
    $user->part( $channel , 'irc' );
    $self->_ref_main->redis->rpush( 'web_incoming_main', encode_json $args );
}

1;
