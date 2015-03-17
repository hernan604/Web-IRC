package WI::DB::UserChannel;
use Moo;
with qw|WI::DB::Role::Common|;

has app         => ( is => 'rw' );
has table_name  => ( is => 'rw', default => sub { '"UserChannel"' } );
has user_id     => ( is => 'rw' );
has channel_id  => ( is => 'rw' );
has created     => ( is => 'rw' );      
has id          => ( is => 'rw' );
has source      => ( is => 'rw' );

sub join {
    my $self    = shift;
    my $user    = shift;
    my $channel = shift;
    my $source  = shift; #web or irc
    my $res     = $self->find_or_create(
        {
            user_id     => $user->id,
            channel_id  => $channel->id,
            source      => $source
        }
    );
}

sub part {
    my $self    = shift;
    my $user    = shift;
    my $channel = shift;
    my $source  = shift; #web or irc
    my $res     = $self->delete(
        {
            user_id     => $user->id,
            channel_id  => $channel->id,
            source      => $source
        }
    );
}

sub list_users {
    my $self = shift;
    my $channel = shift;
    my @values = ( $channel );
    my $result = $self->app->pg->db->query( <<QUERY, @values );
    SELECT * FROM "UserChannel" as user_channel 
    LEFT JOIN "User" as usr on user_channel.user_id = usr.id 
    LEFT JOIN "Channel" as channel on user_channel.channel_id = channel.id 
    WHERE channel.name = ?;
QUERY
    $result;
}

1;
