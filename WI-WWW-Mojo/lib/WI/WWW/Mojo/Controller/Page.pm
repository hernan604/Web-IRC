package WI::WWW::Mojo::Controller::Page;
use base 'Mojolicious::Controller';

sub index {
    my $self = shift;
    $self->respond_to( html => sub {
        my $self  = shift;
        $self->render( 'index' );
    } );
}

1;
