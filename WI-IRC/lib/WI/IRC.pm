package WI::IRC;

# Import the constants
use POE::Component::Server::IRC::Plugin qw( :ALL );
use Moo;
use DDP;
use JSON::XS qw|encode_json decode_json|;
use IRC::Utils qw|matches_mask|;
use Mojo::Pg;

use lib '../WI-Main/lib';
use lib '../WI-DB/lib';
use WI::Main;
use Encode qw|encode decode|;
use WI::DB;
use utf8;

my $queue_from_irc = 'from_irc';


my $pg = Mojo::Pg->new( $ENV{WI_MOJO_PG_DSN} );
$pg->max_connections(5);
$pg->options( { pg_enable_utf8 => 0, } );
my $db = WI::DB->new(
    pg                  => $pg,
    filepath_migrations => '../WI-DB/migrations.sql',
);

my $wi_main = WI::Main->new( queue_from_irc => $queue_from_irc, db => $db );

has ircd => ( is => "rw" );

# Required entry point for POE::Component::Server::IRC::Backend
sub PCSI_register {
    my ( $self, $irc ) = @_;

    # Register events we are interested in
    $irc->plugin_register(
        $self, 'SERVER', qw(
          daemon_public
          daemon_privmsg
          daemon_cmd_privmsg
          daemon_join
          daemon_nick
          daemon_umode
          daemon_quit
          daemon_part
          daemon_kick
          daemon_mode
          daemon_topic
          daemon_public
          daemon_notice
          daemon_invite
          daemon_rehash
          daemon_gline
          daemon_kline
          )
    );

    #       $irc->plugin_register( $self, 'NICK', qw(method_nick) );
    #       $irc->plugin_register( $self, 'PRIVMSG', qw(me) )

    # Return success
    return 1;
}

# Required exit point for PoCo-Server-IRC
sub PCSI_unregister {
    my ( $self, $irc ) = @_;

    # PCSIB will automatically unregister events for the plugin

    # Do some cleanup...

    # Return success
    return 1;
}

# Registered events will be sent to methods starting with IRC_
# If the plugin registered for SERVER - irc_355
sub IRCD_connection {
    my ( $self, $irc, $line ) = @_;

    # Remember, we receive pointers to scalars, so we can modify them
    $$line = 'frobnicate!';

    # Return an exit code
    return PCSI_EAT_NONE;
}

#   sub IRCD_method_server {
#       warn "METHOD SERVER" ;
#       warn "METHOD SERVER" ;
#       warn "METHOD SERVER" ;
#       warn "METHOD SERVER" ;
#   }

sub find_nick {
    my $self = shift;
    my $nick = shift;
    return $self->ircd->{state}{peers}{ uc $self->ircd->server_name() }
      {users}->{ uc $nick };
}

sub is_spoofed {
    my $self = shift;
    my $nick = shift;
    my $user = $self->find_nick($nick);
    return 0 if !$user;
    return $user->{route_id} eq 'spoofed' ? 1 : 0;
}

sub hostname_parse {
    my $self          = shift;
    my $hostname_full = shift;
    my ( $nick, $ident, $host ) = $hostname_full =~ m#^(.+)!(.+)@(.+)$#g;
    return [ $nick, $ident, $host ];

}

sub IRCD_daemon_public {
    my $self = shift;
    my $ircd = shift;
    #warn p @_;
    my $from = shift;
    my $chan = shift;
    my $msg  = shift;
    warn "#forward msg to web interface";
    my ( $nick, $ident, $host ) = @{ $self->hostname_parse("$$from") };

#       warn "NICK: $nick, IDENT: $ident, HOST: $host";
#       my @user = $ircd->_state_find_user_host( 'administrator', 'STAFF' );
#       warn p @user;

    #       warn p $self->find_nick( $nick );

    if ( $self->find_nick($nick) && !$self->is_spoofed($nick) ) {

        #someone typed a message in irc.
        $wi_main->irc->message_public(
            {
                method => 'rpush',
                queue  => $queue_from_irc,
                obj    => {
                    source => 'irc',
                    action => 'msg',
                    nick   => $nick,
                   #msg    => decode('UTF-8',"$$msg"),
                    msg    => "$$msg",
                    ident  => $ident,
                    host   => $host,
                    target => "$$chan",
                }
            }
        );
    }

    #insert into message_public
    #    ('time', 'nick', 'chan', 'msg', 'source') values
    #    ( 10h20, 'Mary', '#chan','smg', 'IRC')
    #emit to website via websocket
}

sub IRCD_daemon_cmd_message {
    warn "DAEMON CMD MESSAGE!!!!" x 100;
}

sub IRCD_daemon_cmd_privmsg {
    warn "DAEMON CMD PRIVMSG!!!!" x 100;
}

sub IRCD_daemon_privmsg {
    warn "DAEMON PRIVMSG" x 100;
}

sub IRCD_daemon_join {
    my ( $self, $ircd, $hostname, $chan ) = @_;
    my ( $nick, $ident, $host ) = @{ $self->hostname_parse("$$hostname") };
    my $queue_name = 'from_irc';
    my $nick_info = $self->find_nick($nick);
    if ( $self->find_nick($nick) && !$self->is_spoofed($nick) ) {
        $wi_main->irc->channel_join(
            {
                method => 'rpush',
                queue  => $queue_from_irc,
                obj    => {
                    source  => 'irc',
                    action  => 'join',
                    nick    => $nick,
                    target => "$$chan",
                    ident   => $ident,
                    host    => $host,
                }
            }
        );
    }
}

sub IRCD_daemon_nick {
    warn "DAEMON NICK" x 100;
}

sub IRCD_daemon_umode {
    warn "DAEMON UMODE" x 100;
}

sub IRCD_daemon_quit {
    warn "DAEMON QUIT" x 100;
}

sub IRCD_daemon_part {
    my ( $self, $ircd, $hostname, $chan ) = @_;
    my ( $nick, $ident, $host ) = @{ $self->hostname_parse("$$hostname") };
    my $queue_name = 'from_irc';
    my $nick_info = $self->find_nick($nick);
    if ( $self->find_nick($nick) && !$self->is_spoofed($nick) ) {
        $wi_main->irc->channel_part(
            {
                method => 'rpush',
                queue  => $queue_from_irc,
                obj    => {
                    source  => 'irc',
                    action  => 'part',
                    nick    => $nick,
                    target  => "$$chan",
                    ident   => $ident,
                    host    => $host,
                }
            }
        );
    }
}

sub IRCD_daemon_kick {
    warn "DAEMON KICK" x 100;
}

sub IRCD_daemon_mode {
    warn "DAEMON MODE" x 100;
}

sub IRCD_daemon_topic {
    warn "DAEMON TOPIC" x 100;
}

sub IRCD_daemon_notice {
    warn "DAEMON NOTICE" x 100;
}

sub IRCD_daemon_invite {
    warn "DAEMON INVITE" x 100;
}

sub IRCD_daemon_rehash {
    warn "DAEMON REHASH" x 100;
}

sub IRCD_daemon_gline {
    warn "DAEMON GLONE" x 100;
}

sub IRCD_daemon_kline {
    warn "DAEMON KLINE" x 100;
}

# Default handler for events that do not have a corresponding
# plugin method defined.
sub _default {
    my ( $self, $irc, $event ) = splice @_, 0, 3;

    warn "PLUGIN: Default called for $event\n";
    warn "PLUGIN: Default called for $event\n";
    warn "PLUGIN: Default called for $event\n";
    warn "PLUGIN: Default called for $event\n";
    warn "PLUGIN: Default called for $event\n";
    warn "PLUGIN: Default called for $event\n";

    # Return an exit code
    return PCSI_EAT_NONE;
}
1;
