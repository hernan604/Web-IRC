package WI::DB::PrivateMessageLog;
use Moo;
use DDP;
with qw|WI::DB::Role::Common|;

has table_name      => ( is => 'rw', default => sub { '"PrivateMessageLog"' } );
has app             => ( is => 'rw' );
has parent          => ( is => 'rw' );
has id              => ( is => 'rw' );
has from_user_id    => ( is => 'rw' );
has to_user_id      => ( is => 'rw' );
has line            => ( is => 'rw' );
has source          => ( is => 'rw' );
has created         => ( is => 'rw' );

sub from_user {
    my $self = shift;
    WI::DB::User
        ->new( app => $self->app )
        ->find( { id => $self->from_user_id } )
}

sub to_user {
    my $self = shift;
    WI::DB::User
        ->new( app => $self->app )
        ->find( { id => $self->to_user_id } )
}

sub to_ws_obj {
    my $self = shift;
    return {
        from    => $self->from_user->username,
        to      => $self->to_user->username,
        line    => $self->line,
        source  => $self->source,
        created => $self->created,
        action  => 'private-message',
    };
}

1;
