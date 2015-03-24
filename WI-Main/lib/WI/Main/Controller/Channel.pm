package WI::Main::Controller::Channel;
use base qw|Mojolicious::Controller|;
use DOP;

sub list_users {
    my $self = shift;
    $self->respond_to( json => sub {
        my $self = shift;
        $self->req->json->{ channel } =
            '#'.$self->req->json->{ channel }
            if $self->req->json->{ channel } !~ m|^#|;
        
        my $results = $self
            ->db
            ->user
            ->user_channel
            ->list_users( $self->req->json->{ channel } )
            ->hashes
            ->to_array
            ;
        $self->render( json => {
            status => 'OK',
            result => $results,
        } );
    } );
}

sub history {
    my $self = shift;
    $self->respond_to( json => sub {
        my $self = shift;
warn p $self->req->json;
warn "HISTORY ^^";
warn "HISTORY ^^";
warn "HISTORY ^^";
warn "HISTORY ^^";
        $self->req->json->{ channel } =
            '#'.$self->req->json->{ channel }
            if $self->req->json->{ channel } !~ m|^#|;
        
#       my $results = $self
#           ->db
#           ->user
#           ->user_channel
#           ->list_users( $self->req->json->{ channel } )
#           ->hashes
#           ->to_array
#           ;
        $self->render( json => {
            status => 'OK',
#           result => $results,
        } );
    } );
}

1;
