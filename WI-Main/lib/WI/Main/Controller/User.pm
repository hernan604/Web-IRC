package WI::Main::Controller::User;
use base 'Mojolicious::Controller';

sub everyone_status {
    my $self = shift;
    $self->respond_to( json => sub {
        my $self = shift;
        my $everyone_status = $self->db->everyone_status;
        $self->render( json => { results => $everyone_status } );
    } );
}

sub friend_list {
    my $self = shift;
    $self->respond_to( json => sub {
        my $self  = shift;
        my $user = $self
            ->db
            ->user
            ->find_or_create({
                username => $self->req->json->{nick}
            })
            ;
        my $results = $user
            ->friends
            ->list
            ->hashes
            ->to_array
            ;
        my $friend_list = [map { $_->{ nick } } @{ $results }];
        if ( ! scalar @{ $friend_list } ) {
            #set my initial list with everyone
            my $everyone = $self->db->everyone_status;
            $friend_list = [ map { $_->{ username } } @{ $everyone } ];
            $user->friends->set( $friend_list );
        }
        $self->render( json => { results => $friend_list } );
    } );
}

sub friend_add {
    my $self = shift;
    $self->respond_to( json => sub {
        my $self  = shift;
        my $user = $self
            ->db
            ->user
            ->find_or_create({
                username => $self->req->json->{user}
            })
            ;

        my $friend = $self
            ->db
            ->user
            ->find_or_create({
                username => $self->req->json->{friend}
            })
            ;

        if ( $user->id and $friend->id ) {
            $user->friends->add( $friend );
        }
        $self->render( json => { status => 'OK' } );
    } );
}

sub friend_del {
    my $self = shift;
    $self->respond_to( json => sub {
        my $self  = shift;
        my $user = $self
            ->db
            ->user
            ->find_or_create({
                username => $self->req->json->{user}
            })
            ;

        my $friend = $self
            ->db
            ->user
            ->find_or_create({
                username => $self->req->json->{friend}
            })
            ;

        if ( $user->id and $friend->id ) {
            $user->friends->del( $friend );
        }
        $self->render( json => { status => 'OK' } );
    } );
}

1;
