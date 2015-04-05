package WI::WWW::Mojo::Controller::User;
use base 'Mojolicious::Controller';

sub profile {
    my $self = shift;
    #respond with my profile
    warn "USER PROFILE";
    $self->respond_to( json => sub {
        my $self = shift;

        my $friends = $self->ua->get(
            $self->endpoint->{friend_list} => {
                Accept => 'application/json' 
            },
            json => {
                nick => $self->session('nick'),
            }
        );
        my $res = {
            nick => $self->session( 'nick' ),
            friends => $friends->res->json->{ results }, 
        };
        $self->render( json => $res );
    } );
}

sub everyone_status {
    my $self = shift;
    #respond with my profile
    $self->respond_to( json => sub {
        my $self = shift;
        my $req = $self->ua->get(
            $self->endpoint->{everyone_status} => {
                Accept => 'application/json' 
            },
        );
        $self->render( json => $req->res->json );
    } );
}

sub friend_del {
    my $self = shift;
    use DDP;
    warn p $self->req->json;
    warn "^^ JSON";
    #respond with my profile
    $self->respond_to( json => sub {
        my $self = shift;
        my $args = $self->req->json;
        $args->{ user } = $self->session('nick');
        my $req = $self->ua->get(
            $self->endpoint->{user_friend_del} => {
                Accept => 'application/json' 
            },
            json => $args
        );
        $self->render( json => $req->res->json );
    } );
}

sub friend_add {
    my $self = shift;
    #respond with my profile
    $self->respond_to( json => sub {
        my $self = shift;
        my $args = $self->req->json;
        $args->{ user } = $self->session('nick');
        my $req = $self->ua->get(
            $self->endpoint->{user_friend_add} => {
                Accept => 'application/json' 
            },
            json => $args
        );
        $self->render( json => $req->res->json );
    } );
}

1;
