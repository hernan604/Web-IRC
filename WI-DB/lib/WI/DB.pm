package WI::DB;
use Moo;
use Mojo::Pg;
use WI::DB::Registration;
use WI::DB::Auth;
use WI::DB::User;
use WI::DB::Channel;
use SQL::Abstract;

has [
    qw|
      dsn
      filepath_migrations
      |
] => ( is => 'rw' );

has registration => (
    is => 'lazy',
    default =>
      sub { my $self = shift; WI::DB::Registration->new( app => $self ) }
);

has auth => (
    is      => 'lazy',
    default => sub {
        my $self = shift;
        WI::DB::Auth->new( app => $self );
    }
);

has _ref_main => ( is => 'rw' );

has pg => (
    is      => 'rw',
    default => sub {
        my $self = shift;
        my $pg   = Mojo::Pg->new( $self->dsn );
        $pg->max_connections(5);
        $pg;
    }
);

has user => (
    is => 'rw',
    default => sub {
        my $self = shift;
        WI::DB::User->new( app => $self );
    }
);

has channel => (
    is => 'rw',
    default => sub {
        my $self = shift;
        WI::DB::Channel->new( app => $self );
    }
);

has user_channel => (
    is => 'rw',
    default => sub {
        my $self = shift;
        WI::DB::UserChannel->new( app => $self );
    }
);

has sql => (
    is => 'rw',
    default => sub {
        my $self = shift;
        SQL::Abstract->new;
    }
);


sub migrate {
    my $self = shift;
    if ( $self->filepath_migrations ) {
        $self->pg->migrations->from_file( $self->filepath_migrations )->migrate;
    }
}

sub cleanup {
    my $self = shift;
    $self->pg->db->query('delete from "ChannelLog" where 1 = 1');
    $self->pg->db->query('delete from "User" where 1 = 1');
    $self->pg->db->query('delete from "Channel" where 1 = 1');
}

sub BUILD {
    my $self = shift;
    $self->migrate;
}

1;
