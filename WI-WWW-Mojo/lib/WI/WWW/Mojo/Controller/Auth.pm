package WI::WWW::Mojo::Controller::Auth;
use base 'Mojolicious::Controller';

sub login {
    my $self = shift;
    $self->respond_to( json => sub {
        my $self = shift;
        ( $self->req->method eq 'PUT' )
            ? $self->do_login
            : $self->render( json => { status => 'ERROR' } )
            ;
    }, html => sub {
        my $self = shift;
        $self->render( 'login' )
    } );
}

sub render_errors {
    my $self = shift;
    my $errors = shift;
    $self->render( json => { status => 'ERROR', errors => $errors } ); 
}

sub do_login {
    my $self = shift;
    $self->render_errors( [ 'Please fill in username and password' ] )
        and return
        if ! $self->validate;

    $self->render_errors( [ 'Wrong username or password' ] )
        and return 
        if ! $self->db->auth->validate_credentials( $self->req->json );

    $self->session({ nick => $self->req->json->{ username } }); 

    $self->render( json => {
        status => 'OK',
        redirect => $self->url_for('chat_root')
    } );
}

sub validate {
    my $self = shift;
    my $errors = [];
    if ( ! $self->req->json->{ username } || ! $self->req->json->{ password } ) {
        $self->render( json => {
            status => 'ERROR',
            errors => $errors
        } );
        return 0;
    }
    return 1;
}

sub validate_signup {
    my $self = shift;
    return 
        defined $self->req->json
        and exists $self->req->json->{ email }
        and exists $self->req->json->{ password }
        and exists $self->req->json->{ username }
        ;
}

sub signup {
    my $self = shift;
    $self->respond_to( html => sub {
        my $self = shift;
        $self->render( 'signup' );
    }, json => sub {
        my $self = shift;
        my $errors = [];
        if ( $self->req->method eq 'PUT' ) {
            push @{ $errors }, 'Please fill complete information before submission'
                if !$self->validate_signup;
            my $new_user = $self->req->json;
            my $success = 0;
            if ( $self->db->registration->is_avaliable( $new_user ) ) {
                $success = $self->db->registration->register( $new_user );
            } else {
                push @{ $errors }, 'Username or email already taken.';
            }
            $self->render( json => 
                ( scalar @{ $errors } )
                    ? { status => 'ERROR', errors => $errors }
                    : { status => 'OK', redirect => $self->url_for( 'chat_root' ) }
            );
            warn "TEM QUE FAZER UM HOOK para add user com senha pra conectar via irc..";
        }
    } );
}

1;
