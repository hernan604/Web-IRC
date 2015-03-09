package WI::DB::Role::Common;
use Moo::Role;
use DDP;

sub new_with {
    my $self     = shift;
    my $hash     = shift;
    my $instance = $self->new($hash);
    $instance->app( $self->app );
    $instance;
}

sub find_or_create {
    my $self = shift;
    my $args = shift;
    my $results = $self->pg_find($args);
    if ( $results->rows ) {
        return $self->new_with( $results->hash );
    }
    else {
        return $self->insert( $args );
    }
}

sub insert {
    my $self = shift;
    my $args = shift;
    my ( $stmt, @values ) = $self->app->sql->insert( $self->table_name, $args, { returning => 'id' } );
    my $result = $self->app->pg->db->query( $stmt, @values );
    $self->find( $result->hash );
}

sub find {
    my $self         = shift;
    my $args         = shift;
    my $order_by     = shift;
    my $item = $self->new_with( $self->pg_find( $args, $order_by )->hash );
    $item;
}

sub pg_find {
    my $self         = shift;
    my $args         = shift || {};
    my $order_by     = shift || {};
    my ( $stmt, @values ) = $self->app->sql->select( $self->table_name, '*' , $args, $order_by );
    my $results = $self->app->pg->db->query( $stmt, @values );
    return $results;
}


sub search {
    my $self         = shift;
    my $args         = shift || {};
    my $order_by     = shift || {};
    my ( $stmt, @values ) = $self->app->sql->select( $self->table_name, '*' , $args, $order_by );
    my $results = $self->app->pg->db->query( $stmt, @values );
    $results;
}

1;

