package WI::WWW::Mojo::Controller::Channel;
use base 'Mojolicious::Controller';

sub channel_list {
    my $self = shift;
    $self->respond_to( json => sub {
        my $self = shift;
        $self->render( json => {
            channels => $self->channels
        } );
    });
}

sub list_users {
    my $self = shift;
    my $req = $self->ua->put(
        $self->endpoint->{list_users} => {
            Accept => 'application/json' 
        },
        json => {
            channel => $self->param('channel')
        }
    );
    $self->render( json => $req->res->json );
}

1;
