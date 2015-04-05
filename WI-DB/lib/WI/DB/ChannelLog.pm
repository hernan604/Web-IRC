package WI::DB::ChannelLog;
use Moo;
use DDP;
with qw|WI::DB::Role::Common|;
use WI::DB::Channel;
use WI::DB::User;

has table_name => ( is => 'rw', default => sub { '"ChannelLog"' } );
has app        => ( is => 'rw' );
has parent     => ( is => 'rw' );
has id         => ( is => 'rw' );
has user_id    => ( is => 'rw' );
has channel_id => ( is => 'rw' );
has line       => ( is => 'rw' );
has action     => ( is => 'rw' );
has created    => ( is => 'rw' );
has source     => ( is => 'rw' );
has user       => ( is => 'lazy', default => sub {
    my $self = shift;
    WI::DB::User
        ->new( app => $self->app )
        ->find( { id => $self->user_id } )
        ;
} );
has channel    => ( is => 'lazy', default => sub {
    my $self = shift;
    return undef if ! $self->channel_id;
    WI::DB::Channel
        ->new( app => $self->app )
        ->find( { id => $self->channel_id } )
        ;
} );

sub lines {
    my $self = shift;
    my $args = shift || {};
    my $order_by = shift || {};
    $args->{ channel_id } = $self->parent->id;
    my $lines = [];
    $self->search( $args, $order_by );
}

sub history {
    my $self = shift;
    my $args = shift || {};
    my $order_by = shift || {};
    $args->{ channel_id } = $self->parent->id;
    my $lines = [];
    my $results = $self->search( $args, $order_by );
    $results;
}

sub to_ws_obj {
    my $self = shift;
    return {
        channel_log_id  => $self->id,
        ( $self->channel )
            ? ( channel => $self->channel->name )
            : (),
        action          => $self->action,
        nick            => $self->user->username,
        source          => $self->source,
        line            => $self->line,
    }
}

1;
