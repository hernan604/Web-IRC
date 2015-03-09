package WI::DB::Channel;
use Moo;
use DDP;
with qw|WI::DB::Role::Common|;
use WI::DB::ChannelLog;

has table_name => ( is => 'rw', default => sub { '"Channel"' } );
has app        => ( is => 'rw' );
has id         => ( is => 'rw' );
has name       => ( is => 'rw' );
has topic      => ( is => 'rw' );
has modes      => ( is => 'rw' );

has log => (
    is      => 'lazy',
    default => sub {
        my $self = shift;
        my $channel_log = WI::DB::ChannelLog->new(
            parent => $self,
            app    => $self->app,
        );
        $channel_log;
    }
);

1;
