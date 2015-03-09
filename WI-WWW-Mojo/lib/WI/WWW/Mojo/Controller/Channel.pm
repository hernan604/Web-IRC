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

1;
