package WI::Main::Controller::Channel;
use base qw|Mojolicious::Controller|;
use DDP;

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
            results => $results,
        } );
    } );
}

sub history {
    my $self = shift;
    $self->respond_to( json => sub {
        my $self = shift;
        if ( ! $self->req->json 
            || ! exists $self->req->json->{id} 
            || ! defined $self->req->json->{id} 
            || ! exists $self->req->json->{channel} 
            || ! defined $self->req->json->{channel} 
        ) {
            return $self->render( json => { status => "ERROR" }, status => 500 );
        }
        $self->req->json->{ channel } =
            '#'.$self->req->json->{ channel }
            if $self->req->json->{ channel } !~ m|^#|;

        my $channel = $self->db->channel->find( { name => $self->req->json->{ channel } } );

        my $results = $channel
            ->log
            ->history( { id => { '<' => $self->req->json->{ id } } } , { -asc => [ qw| id | ] } )
            ;

        $results = [ map {
            $channel->log->find( { id => $_->{id} } )->to_ws_obj
        } @{ $results->hashes->to_array } ];

        $self->render( json => {
            status => 'OK',
            results => $results,
        } );
    } );
}

1;
