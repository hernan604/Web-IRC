package WI::Main::Controller::Auth;
use base 'Mojolicious::Controller';

sub validate_credentials {
    my $self = shift;
    $self->respond_to( json => sub {
        my $self = shift;
        my $res = ( $self->db->auth->validate_credentials( $self->req->json ) )
            ? { status => 'OK' }
            : { status => 'ERROR' }
            ;
        $self->render( json => $res );
    } );
}

sub is_username_avaliable {
    my $self = shift;
    $self->respond_to( json => sub {
        my $self = shift;
        $self->render( json => {
            is_avaliable => $self->db->registration->is_avaliable( $self->req->json )
        } );
    } );
}

sub user_register {
    my $self = shift;
    $self->respond_to( json => sub {
        my $self = shift;
        $self->render( json => { success => $self->db->registration->register( $self->req->json ) } );
    } );
}

1;
