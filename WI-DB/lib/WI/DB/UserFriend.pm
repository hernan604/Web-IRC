package WI::DB::UserFriend;
use Moo;
with qw|WI::DB::Role::Common|;

has app         => ( is => 'rw' );
has parent      => ( is => 'rw' );
has table_name  => ( is => 'rw', default => sub { '"UserChannel"' } );
has id          => ( is => 'rw' );
has user_id     => ( is => 'rw' );
has friend_user_id  => ( is => 'rw' );
has created     => ( is => 'rw' );      

sub list {
    my $self = shift;
    my @values = ( $self->parent->id );
    my $result = $self->app->pg->db->query( <<QUERY, @values );
    SELECT friend.username AS nick 
    FROM "UserFriend" as "user_friend" 
    LEFT JOIN "User" as "friend" on friend.id = user_friend.friend_user_id 
    WHERE user_id = ?
QUERY
    $result;
}

sub set {
    my $self = shift;
    my $friends = shift||[]; #array of nicks
    my $friend_ids = $self->app->pg->db->query(
        'select id from "User" where username in ('.( join "," , ('?') x ( scalar @{ $friends} )).');'
    , @{ $friends } )->hashes->to_array;

    #remove my friends
    $self->app->pg->db->query(
        'delete from "UserFriend" where user_id = ?',
        $self->parent->id,
    );

    my $values  = [ map { $self->parent->id => $_->{ id } } @{ $friend_ids } ];
    my $placeholders = join ',', @{ [ ("(? , ?)") x scalar @{ $friend_ids } ]};
    #readd my friends
    $self->app->pg->db->query(
        'insert into "UserFriend" ( "user_id", "friend_user_id" ) values'. $placeholders,
        @{ $values }
    );
}

sub add {
    my $self = shift;
    my $friend = shift;
    $self->app->pg->db->query(
        'insert into "UserFriend" ( user_id, friend_user_id ) values ( ? , ? )',
        $self->parent->id,
        $friend->id,
    );
}

sub del {
    my $self = shift;
    my $friend = shift;
    $self->app->pg->db->query(
        'delete from "UserFriend" WHERE user_id = ? AND friend_user_id = ?',
        $self->parent->id,
        $friend->id,
    );
}

1;
