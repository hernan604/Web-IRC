package WI::DB::User;
use Moo;
with qw|WI::DB::Role::Common|;
use WI::DB::UserChannel;
use WI::DB::PrivateMessageLog;
use WI::DB::UserFriend;

has app        => ( is => 'rw' );
has table_name => ( is => 'rw', default => sub { '"User"' } );
has id         => ( is => 'rw' );
has email      => ( is => 'rw' );
has username   => ( is => 'rw' );
has password   => ( is => 'rw' );
has status   => ( is => 'rw' );
has last_status   => ( is => 'rw' );

has user_channel => (
    is      => 'lazy',
    default => sub {
        my $self = shift;
        return WI::DB::UserChannel->new( app => $self->app );
    }
);

has friends => (
    is      => 'lazy',
    default => sub {
        my $self = shift;
        return WI::DB::UserFriend->new( app => $self->app, parent => $self );
    }
);


has private_message_log => (
    is      => 'lazy',
    default => sub {
        my $self = shift;
        WI::DB::PrivateMessageLog->new( app => $self->app , parent => $self );
    }
);

sub set {
    my $self  = shift;
    my $args  = shift;
    my $where = shift || { id => $self->id };
    $self->update( $args , $where );
}

sub join {
    my $self = shift;
    my $channel = shift;
    my $source = shift; #web or irc
    warn "WARNING: user->join missing source" and return if ( ! $source );
    $self->user_channel->join( $self, $channel, $source );
}

sub part {
    my $self = shift;
    my $channel = shift;
    my $source = shift; #web or irc
    warn "WARNING: user->join missing source" and return if ( ! $source );
    $self->user_channel->part( $self, $channel, $source );
}
    
1;
