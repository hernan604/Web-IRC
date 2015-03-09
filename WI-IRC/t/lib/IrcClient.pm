package IrcClient;
use utf8;
use strict;
use warnings;
use base qw|Class::Accessor|;
use DDP;
use POE qw|Component::IRC|;

IrcClient->mk_accessors( qw| 
    nickname 
    ircname 
    server 
    channels 
    port 
    irc 
    tasks
| );

my $irc;
my @channels; 
my @tasks;

sub new {
    my $self  = shift;
    my $class = ref($self) || $self;
    
    $class = bless {}, $class;
    my $args = shift;
    map { $class->$_( $args->{ $_ } ) } keys %{ $args };
    return $class;
}

sub init {
    my $self = shift;
    @channels = @{ $self->channels };
    @tasks = @{ $self->tasks };

    $irc  = POE::Component::IRC->spawn(
        nick    => $self->nickname,
        ircname => $self->ircname,
        server  => $self->server,
        port    => $self->port,
    ) or die "Oh noooo! $!";
    $self->irc( $irc );


    POE::Session->create(
        package_states => [
            $self => [qw(_default _start irc_001 irc_public)],
        ],
        heap => { irc => $irc },
    );

    $poe_kernel->run();
}

sub _start {
    my $heap = $_[HEAP];
    # retrieve our component's object from the heap where we stashed it
    my $irc = $heap->{irc};

    $irc->yield( register => 'all' );
    $irc->yield( connect  => {} );
    return;
}

sub irc_001 {
    my $sender = $_[SENDER];

    # Since this is an irc_* event, we can get the component's object by
    # accessing the heap of the sender. Then we register and connect to the
    # specified server.
    my $irc = $sender->get_heap();

    print "Connected to ", $irc->server_name(), "\n";

    # we join our channels
    $irc->yield( join => $_ ) for @channels;
    $irc->yield( privmsg => '#systems' => "teste: teste1 teste2 teste3" );
    $irc->yield(
        privmsg => '#systems' => "teste: ááá ééé ííí óóó úúú" );

    for ( @tasks ) {
        $_->( $irc );
    }

    return;
}

sub irc_public {
    my ( $sender, $who, $where, $what ) = @_[ SENDER, ARG0 .. ARG2 ];
    my $nick = ( split /!/, $who )[0];
    my $channel = $where->[0];

#   if ( my ($rot13) = $what =~ /^rot13 (.+)/ ) {
#       $rot13 =~ tr[a-zA-Z][n-za-mN-ZA-M];
#       $irc->yield( privmsg => $channel => "$nick: $rot13" );
#   }
    return;
}

# We registered for all events, this will produce some debug info.
sub _default {
    my ( $event, $args ) = @_[ ARG0 .. $#_ ];
    my @output = ("$event: ");

    for my $arg (@$args) {
        if ( ref $arg eq 'ARRAY' ) {
            push( @output, '[' . join( ', ', @$arg ) . ']' );
        }
        else {
            push( @output, "'$arg'" );
        }
    }
    print join ' ', @output, "\n";
    return;
}

1;
