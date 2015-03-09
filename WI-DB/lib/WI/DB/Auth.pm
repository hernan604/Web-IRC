package WI::DB::Auth;
use Moo;

has app => ( is => 'rw' );

sub validate_credentials { 
    my $self = shift;
    my $credentials = shift;
    my $results = $self->app->pg->db->query( 'select * from "User" where username = ? and password = ?'
        , $credentials->{ username }
        , $credentials->{ password } 
    );
    return $results->rows;
}

1;
