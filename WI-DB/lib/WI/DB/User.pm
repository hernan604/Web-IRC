package WI::DB::User;
use Moo;
with qw|WI::DB::Role::Common|;
use WI::DB::UserChannel;

has app        => ( is => 'rw' );
has table_name => ( is => 'rw', default => sub { '"User"' } );
has id         => ( is => 'rw' );
has email      => ( is => 'rw' );
has username   => ( is => 'rw' );
has password   => ( is => 'rw' );

has user_channel => (
    is      => 'lazy',
    default => sub {
        my $self = shift;
        return WI::DB::UserChannel->new( app => $self->app );
    }
);

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
