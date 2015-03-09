package WI::WWW::Mojo::Nick;
#use base 'Mojolicious::Controller';
use Moo;
use DDP;

has _ref_main => ( is => 'rw' );
has nicks     => ( is => 'rw', default => sub { { } } );
has channels  => ( is => 'rw', default => sub { { } } );

sub connected {
    my $self = shift;
    my $nick = shift;
    $self->nicks->{$nick} = {} if ! $self->nicks->{$nick};
    $self->nicks->{$nick}->{connected} = 1;
}

sub disconnect {
    my $self = shift;
    my $nick = shift;
    $self->nicks->{$nick} = {} if ! $self->nicks->{$nick};
    $self->nicks->{$nick}->{connected} = 0;
}

sub join {
    my $self = shift;
    my $nick = shift;
    my $chan = shift;
    $self->nicks->{$nick}->{$chan} = 1;
    $self->channels->{$chan} = [] 
        if ! exists $self->channels->{$chan};
#   push @{$self->channels->{$chan}}, $nick;    
#   warn p $self->channels->{$chan};
}

sub part {
    my $self = shift;
    my $nick = shift;
    my $chan = shift;
    delete $self->nicks->{$nick}->{$chan} 
        if exists $self->nicks->{$nick} and 
           exists $self->nicks->{$nick}->{$chan} ;

#   $self->channels->{$chan} = [grep {$1 if $_ ne $nick} @{$self->channels->{$chan}}];
#   warn p $self->channels->{$chan};
}

sub is_connected {
    my $self = shift;
    my $nick = shift;
    return ( $nick && $self->nicks->{$nick} && $self->nicks->{$nick}->{connected} ) || 0;
}

sub is_in_chan {
    my $self = shift;
    my $nick = shift;
    my $chan = shift;
    return $nick 
        and $chan 
        and $self->nicks->{$nick} 
        and $self->nicks->{$nick}->{$chan};
}

1;
