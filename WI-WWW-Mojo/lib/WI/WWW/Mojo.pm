package WI::WWW::Mojo;
use Mojo::Base 'Mojolicious';
use 5.008001;
use strict;
use warnings;
use DateTime;
use JSON::XS qw|encode_json decode_json|;
#use WI::Main;
use WI::WWW::Mojo::Nick;
use Mojo::Pg;
use WI::DB;
use Mojo::UserAgent;
use Mojo::Redis2;

our $VERSION = "0.01";
my $channels = [];

sub init_redis {
    my $self = shift;
    my $redis2 = Mojo::Redis2->new;
    $self->helper( redis => sub { $redis2 } );
    $self->redis->rpush('main_incoming_web', '{"action":"cleanup"}');
}

sub init_enpoint {
    my $self = shift;
    $self->helper(
        queue => sub { {
            main_incoming_irc => 'main_incoming_irc', #irc to main
            main_incoming_web => 'main_incoming_web', #web to main
            web_incoming_main => 'web_incoming_main', #main to web
            irc_incoming_main => 'irc_incoming_main', #main to irc
        } }
    );

    $self->helper( endpoint => sub {{
        list_users      => 'http://127.0.0.1:9999/v1/channel/list_users',
        channel_history => 'http://127.0.0.1:9999/v1/channel/history',
    }} );
}

sub startup {
    warn "START UP - begin";
    my $self = shift;
    $self->sessions->cookie_name( 'wi' );
    $self->sessions->default_expiration( 24*60*60*365 );#1 year
    $self->init_enpoint;
    $self->init_redis;

    my $r    = $self->routes;
    $r->namespaces( ['WI::WWW::Mojo::Controller'] );

    $r->route('/signup')->name('signup')
      ->to( controller => 'Auth', action => 'signup' );

    $r->route('/login')->name('login')
      ->to( controller => 'Auth', action => 'login' );

    $r->route('/')->name('index')
      ->to( controller => 'Page', action => 'index' );

    $r->route('/chat/')->name('chat_root')
      ->to( controller => 'Chat', action => 'root' );

    $r->route('/chat/:channel')->name('chat')
      ->to( controller => 'Chat', action => 'chat' );

    $r->websocket('/chat_ws/')->name('chat_ws')
      ->to( controller => 'Chat', action => 'chat_ws' );

    $r->route('/channel/history')->name('channel_history')
      ->to( controller => 'Channel', action => 'history' );

    $r->route('/channel/list')->name('channel_list')
      ->to( controller => 'Channel', action => 'channel_list' );

    $r->route('/channel/list_users/:channel')->name('list_users')
      ->to( controller => 'Channel', action => 'list_users' );

    $r->route('/channel/join/:channel')->name('join')
      ->to( controller => 'Chat', action => 'join' );

    $r->route('/channel/part/:channel')->name('part')
      ->to( controller => 'Chat', action => 'part' );

#   $self->helper( redis => sub { Redis->new } );

    $self->helper( channels => sub { $channels } );    #array with channels

#   my $pg = Mojo::Pg->new( $ENV{WI_MOJO_PG_DSN} );
#   $pg->max_connections(5);
#   my $db = WI::DB->new( pg => $pg, _ref_main => $self, );
#   my $main = WI::Main->new( _ref_main => $self, db => $db );
#   $self->helper( wi_main => sub { $main } );

    my $nick = WI::WWW::Mojo::Nick->new( app => $self );
    $self->helper( nick => sub { $nick } );
#   $self->helper( db => sub { $db } );
    warn "START UP - finish";
}

#get '/' => 'index';

sub user_channels {

    #returns an array with the channels the user is in
    my $self = shift;

    #query some database and see what chans are active.
}

sub lista_channels {

    #returns a sorted array with thte chanels avaliable
}

sub join_channel {

    #joins a given channel
    my $self    = shift;
    my $channel = shift;

    #   $self
}

sub part_channel {

    #parts a given channel
}

sub msg_chan {

    #sends a message to channel.Everyone in the channel can see it.
}

sub kick_user {

    #kicks a user from a channel. user must be operator in that channel
    #LOW PRIORITY
}

my $clients = {};

1;
__END__

=encoding utf-8

=head1 NAME

WI::WWW::Mojo - It's new $module

=head1 SYNOPSIS

    use WI::WWW::Mojo;

=head1 DESCRIPTION

WI::WWW::Mojo is ...

=head1 LICENSE

Copyright (C) hernan604.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

hernan604 E<lt>E<gt>

=cut

