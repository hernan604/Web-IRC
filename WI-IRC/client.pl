use lib './t/lib/'; 
use IrcClient;

my $say_something = sub {
    my $irc = shift;
    $irc->yield( privmsg => '#systems' => "AAAAAAAAAAAAAAAA" );
};

my $irc_client = IrcClient->new( {
    nickname => 'Flibble' . $$,
    ircname  => 'Flibble the Sailor Bot',
    server   => 'localhost',
    channels => ['#systems'],
    port     => 40404,
    tasks    => [
        $say_something,
#       \&kill_services
    ]
} );
$irc_client->init;
