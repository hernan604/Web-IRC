package WI::DB::UserChannel;
use Moo;
with qw|WI::DB::Role::Common|;

has app         => ( is => 'rw' );
has user        => ( is => 'rw' );
has table_name  => ( is => 'rw', default => sub { '"UserChannel"' } );
has user_id     => ( is => 'rw' );
has channel_id  => ( is => 'rw' );
has created     => ( is => 'rw' );      
has id          => ( is => 'rw' );
has source      => ( is => 'rw' );

sub _join {
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

sub _part {
    my $self    = shift;
    my $user    = shift;
    my $channel = shift;
    my $source  = shift; #web or irc
    my $res     = $self->delete(
        {
            user_id     => $user->id,
            channel_id  => $channel->id,
            ($source) 
                ? ( source      => $source )
                : ()
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

sub list {
    my $self = shift;
    $self->app->pg->db->query(<<QUERY, $self->user->id );
    SELECT "username" AS nick , "status", channel.name as channel
    FROM "UserChannel" AS user_channel
    LEFT JOIN "Channel" AS channel ON channel.id = user_channel.channel_id
    LEFT JOIN "User" AS "user" ON "user".id = user_channel.user_id
    WHERE user_id = ?
QUERY
}

sub set {
    # receives an array of channel names and sets this as this user channels
    my $self = shift;
    my $channels = shift;
    my $placeholders = join ',', ("?") x scalar @{ $channels } ;
    my @channel_ids = map 
        { $_->{ id } }
        @{ $self->app->pg->db->query(<<CHAN_IDS, @{ $channels })->hashes->to_array };
    select id from "Channel" where name in ($placeholders)
CHAN_IDS
    my @values = map { $self->user->id , $_ } @channel_ids;
    $placeholders = join ",", ( "(? , ?)" ) x scalar @channel_ids ;
    $self->app->pg->db->query( <<QUERY , @values );
    insert into "UserChannel" ( user_id, channel_id )
    VALUES $placeholders
QUERY
}

1;
