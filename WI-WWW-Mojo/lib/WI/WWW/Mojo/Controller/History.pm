package WI::WWW::Mojo::Controller::History;
use base 'Mojolicious::Controller';
use DDP;

sub private_message {
    my $self = shift;
    $self->respond_to( json => sub {
        my $self = shift;

        warn "Private Message history";
        my $nick    = $self->session('nick');
        my $target  = $self->req->json->{ nick };
        warn "History between $nick and ".$target;

        my $req = $self->ua->put(
            $self->endpoint->{private_history} => {
                Accept => 'application/json'
            },
            json => {
                from    => $nick,   #from me
                to      => $target, #with someone else
            }
        );

        $self->render( json => $req->res->json );
    } );
}


1;
