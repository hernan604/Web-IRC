package WI::DB::ChannelLog;
use Moo;
use DDP;
with qw|WI::DB::Role::Common|;

has table_name => ( is => 'rw', default => sub { '"ChannelLog"' } );
has app        => ( is => 'rw' );
has parent     => ( is => 'rw' );
has id         => ( is => 'rw' );
has user_id    => ( is => 'rw' );
has channel_id => ( is => 'rw' );
has line       => ( is => 'rw' );

sub lines {
    my $self = shift;
    my $args = shift || {};
    $args->{ channel_id } = $self->parent->id;
    my $lines = [];
    $self->search( $args );
}

1;
