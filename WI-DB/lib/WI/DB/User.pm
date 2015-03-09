package WI::DB::User;
use Moo;
with qw|WI::DB::Role::Common|;

has app        => ( is => 'rw' );
has table_name => ( is => 'rw', default => sub { '"User"' } );
has id         => ( is => 'rw' );
has email      => ( is => 'rw' );
has username   => ( is => 'rw' );
has password   => ( is => 'rw' );

sub join {
    my $self = shift;
    my $channel = shift;
    my $source = shift; #web or irc
    #add in table user_channels
}

sub part {
    my $self = shift;
    my $channel = shift;
    my $source = shift; #web or irc
    #add from table user_channels
}
    
1;
