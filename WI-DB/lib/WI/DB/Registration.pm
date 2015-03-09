package WI::DB::Registration;
use Moo;
use DDP;

has app => ( is => 'rw' );

sub is_avaliable { 
    my $self = shift;
    my $new_user = shift;
    my $results = $self->app->pg->db->query(
        'select * from "User" where username = ? or email = ?', 
        $new_user->{ username }, 
        $new_user->{ email }
    );
    return 1 if ! $results->hash;
    return 0;
} #check if username is avaliable

sub register { 
    my $self = shift;
    my $new_user = shift;
    my $results = $self->app->pg->db->query('insert into "User" (username, password, email) values (?,?,?)', 
        $new_user->{ username },
        $new_user->{ password },
        $new_user->{ email },
    );
    return $results->rows;
} #registers the user

1;
