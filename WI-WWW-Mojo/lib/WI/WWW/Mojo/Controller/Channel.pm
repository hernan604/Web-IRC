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
    # TODO: return if $self->session('nick') not in channel
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

sub history {
    my $self = shift;
    warn "GETTING HISTORY FOR: ";    
    # TODO: return if $self->session('nick') not in channel
    my $req = $self->ua->put(
        $self->endpoint->{channel_history} => {
            Accept => 'application/json' 
        },
        json => {
            id        => $self->req->json->{id},
            channel   => $self->req->json->{channel},
        }
    );
    $self->render( json => $req->res->json );
}

1;
