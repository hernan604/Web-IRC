package WI::DB::Channel;
use Moo;
use DDP;
with qw|WI::DB::Role::Common|;
use WI::DB::ChannelLog;
use WI::DB::UserChannel;

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

has user_channel => (
    is      => 'lazy',
    default => sub {
        my $self = shift;
        return WI::DB::UserChannel->new( app => $self->app );
    }
);

sub list_users {
    my $self = shift;
    $self->user_channel->search( {
        channel_id => $self->id
    } );
}

sub all {
    my $self = shift;
    my $channels = $self->app->pg->db->query('select name as channel from "Channel"')->hashes->to_array;
    [ map { $_->{ channel } } @{ $channels } ];
}

1;
