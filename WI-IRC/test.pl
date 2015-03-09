#use utf8;
use strict;
use warnings;
use Mojo::Pg;
use DDP;
use Test::More;
use lib '../WI-DB/lib/';
use WI::DB;
use Mojo::JSON qw(decode_json encode_json);
use Mojo::UserAgent;
use utf8;

$SIG{'INT'} = \&kill_services;

my $dsn = $ENV{WI_MOJO_PG_DSN};
my $pg = Mojo::Pg->new( $dsn );
$pg->options( { pg_enable_utf8 => 0, } );
$pg->max_connections(1);
my $db = WI::DB->new( dsn => $dsn );

sub server_start {
    my $pid ;
    if (($pid = fork) == 0) {
        die "unable to fork: $!" unless defined($pid);
       #exec('perl server.pl 2> log 2>&1');
        exec('perl server.pl 2> log &');
        die "unable to exec: $!";
    }
    return $pid;
}

sub client_start {
    my $pid ;
    if (($pid = fork) == 0) {
        die "unable to fork: $!" unless defined($pid);
        exec('perl client.pl &');
        die "unable to exec: $!";
    }
    return $pid;
}

sub webserver_start {
    my $pid ;
    if (($pid = fork) == 0) {
        die "unable to fork: $!" unless defined($pid);
        exec('cd ../WI-WWW-Mojo/ && start.sh &');
        die "unable to exec: $!";
    }
    return $pid;
}

$db->cleanup;
my $server_pid  = server_start();
my $webserver_pid  = webserver_start();
sleep 1;
my $client_pid  = client_start();
sleep 15; #let client do some tests.
warn "--- iniciando testes ---";
&run_tests();
#sleep 2;
&run_webtests();

#tail   pid:   $tail_pid
warn <<INFO;
---------------STARTED-------------
server      pid:   $server_pid
client      pid:   $client_pid
webserver   pid:   $webserver_pid

Press ctrl+c to stop

INFO

kill_services();

sub kill_services {
    warn "STOPPING SERVICES";
    kill 'HUP', $server_pid, $client_pid, $webserver_pid;
    done_testing;
    exit 0;
};

warn 'done_testing';
#&kill_services();

while (1) {
    my $x = <>;
}

sub run_webtests {
    use Test::Mojo;
    use lib qw|../WI-WWW-Mojo/lib/|;
    use lib qw|../WI-Main/lib/|;
    my $t = Test::Mojo->new( 'WI::WWW::Mojo' );
    $t->ua->max_redirects( 10 );
#   my $t2 = Test::Mojo->new( 'WI::WWW::Mojo' );
#   $t2->ua->max_redirects( 10 );
    $t->get_ok('/')
        ->content_like(qr/Welcome/, 'right content')
    ;
    
    #signup
    $t->put_ok('/signup' => {
            Accept          => 'application/json',
            'Content-Type'  => 'application/json; charset=UTF-8',
        }, 
        json => {
            email       => 'teste@teste.com',
            username    => 'teste',
            password    => 'teste123',
        } )
        ->json_has('/status')
        ->json_is('/status','OK')
        ->json_has('/redirect')
        ->json_is('/redirect', '/chat')
    ;

    #TODO signup with bad credentials..
    #TODO try to signup without all credentials
    #login
    $t->put_ok('/login' => {
            Accept          => 'application/json',
            'Content-Type'  => 'application/json; charset=UTF-8',
        }, 
        json => {
            password    => "teste123",
            username    => "teste"
        } )
        ->json_has('/redirect')
        ->json_is('/redirect','/chat')
        ->json_has('/status')
        ->json_is('/status','OK')
    ;

    my $ws1 = $t->websocket_ok('/chat_ws/systems' => {
        'Sec-WebSocket-Extensions' => 'permessage-deflate',
    })
        ->send_ok( encode_json {
            source  => 'web', 
            action  => 'msg', 
            msg     => "My msg. áéíóú !" 
        } )
        ->message_ok
        ->message_like( qr|My msg| )
#       ->message_is( encode_json {} )
#       ->finish_ok
    ;

    my $ws2 = $t->websocket_ok('/chat_ws/systems' => {
        'Sec-WebSocket-Extensions' => 'permessage-deflate',
    })
        ->send_ok( encode_json {
            action  => 'msg', 
            msg     => "My msg. XYZ !" 
        } )
        ->message_ok
        ->message_like( qr|XYZ| )
#       ->message_is( encode_json {} )
#       ->finish_ok
    ;

#   TODO FIX THIS TESTS; 
#   $ws1
#       ->message_like( qr|XYZ| )
#       ->send_ok( encode_json {
#           action  => 'msg', 
#           msg     => "Hi i am ws1!" 
#       } )
#   ;

#   $ws2
#       ->message_like( qr|Hi i am ws1| )
#       ->send_ok( encode_json {
#           action  => 'msg', 
#           msg     => "Hi ws1, i am ws2!" 
#       } )
#   ;
#       
#   $ws1
#       ->message_like( qr|Hi ws1, i am ws2| )
#       ->finish_ok
#   ;
#   $ws2
#       ->finish_ok
#   ;

}

sub run_tests {
    test_logs();
    test_log_lines_from_specific_channel( );
    test_log_lines_between_dates( );
}

sub test_logs {
    #check if lines weer logged
    my $result = $pg->db->query('select * from "ChannelLog"');
    my $lines = $result->hashes->to_array;
    for ( @{ $lines } ) {
        delete $_->{ id };
        delete $_->{ channel_id };
        delete $_->{ user_id };
        delete $_->{ created };
       #delete $_->{ source };
    }
    is_deeply( $lines , [
        {
            line       =>"============> MENSAGEM AUTOMATICA #1",
            source     =>"irc",
        },
        {
            line       =>"============> MENSAGEM AUTOMATICA #2",
            source     =>"irc",
        },
        {
            line       =>"============> MENSAGEM AUTOMATICA #3",
            source     =>"irc",
        },
        {
            line       =>"teste: teste1 teste2 teste3",
            source     =>"irc",
        },
        {
            line       =>"teste: ááá ééé ííí óóó úúú",
            source     =>"irc",
        },
        {
            line       =>"AAAAAAAAAAAAAAAA",
            source     =>"irc",
        }
    ], 'Messages were saved correctly');
}

sub test_log_lines_from_specific_channel {
    my $chan    = $db->channel->find( { name => '#systems' } );
    my $results = $chan->log->lines( { } );
    my $lines   = $results->hashes->to_array;
    ok( scalar @{$lines} == 3, '3 messages in this channel' );
}

sub test_log_lines_between_dates {
    my $chan        = $db->channel->find( { name => '#systems' } );
    my $lines       = $chan->log->lines->hashes->to_array;
    my $dt_initial  = ${ \shift @{$lines} }->{created};
    my $dt_final    = ${ \pop @{$lines} }->{created};
    my $results = $chan->log->lines( {
        created => {
            '>' => $dt_initial,
            '<' => $dt_final  
        }
    } );
    ok( scalar @{$results->hashes->to_array} == 1, 'only 1 message between these 2 dates' );
}

