package WI::Main;
use 5.008001;
use strict;
use warnings;
#use Moo;
use Mojo::Redis2;
use DDP;
use JSON::XS qw|encode_json decode_json|;
use WI::Main::IRC;
use WI::Main::WEB;
use Mojo::Base qw|Mojolicious|;
use WI::Main::Redis;

use lib '../WI-DB/lib/';
use WI::DB;

our $VERSION = "0.01";

sub startup {
    my $self = shift;
    $self->sessions->cookie_name( 'app_comments' );
    $self->sessions->default_expiration( 24*60*60*52 );
    $self->init_helpers;
    $self->init_routes;
    $self->init_redis;
}

sub _redis {
    my $self = shift;
    my $redis2 = Mojo::Redis2->new;
    $self->helper( redis => sub { $redis2 } );
}

sub _irc {
    my $self = shift;
    my $irc = WI::Main::IRC->new( _ref_main => $self );
    $self->helper( irc => sub { $irc; } );
}

sub _web {
    my $self = shift;
    my $web = WI::Main::WEB->new( _ref_main => $self );
    $self->helper( web => sub { $web } );
}

sub _db {
    my $self = shift;
    my $pg = Mojo::Pg->new( $ENV{WI_MOJO_PG_DSN} );
    $pg->max_connections(2);
    $pg->options( { pg_enable_utf8 => 0, } );
    my $db = WI::DB->new(
        pg                  => $pg,
        filepath_migrations => '../WI-DB/migrations.sql',
    );
    $self->helper( db => sub { $db } );
}

sub init_helpers {
    my $self = shift;
    $self->_redis;
    $self->_irc;
    $self->_web;
    $self->_db;        
}

sub init_routes {
    my $self = shift;

    my $r = $self->routes;
    $r->namespaces(['WI::Main::Controller']);

    $r->route( '/v1/auth/is_username_avaliable' )
        ->name( 'is_username_avaliable' )
        ->to( controller => 'Auth', action => 'is_username_avaliable' )
        ;

    $r->route( '/v1/auth/validate_credentials' )
        ->name( 'validate_credentials' )
        ->to( controller => 'Auth', action => 'validate_credentials' )
        ;

    $r->route( '/v1/auth/user_register' )
        ->name( 'user_register' )
        ->to( controller => 'Auth', action => 'user_register' )
        ;

    $r->route( '/v1/channel/list_users' )
        ->name( 'channel_list_users' )
        ->to( controller => 'Channel', action => 'list_users' )
        ;

    $r->route( '/v1/channel/history' )
        ->name( 'channel_history' )
        ->to( controller => 'Channel', action => 'history' )
        ;

    $r->route( '/v1/private/history' )
        ->name( 'private_history' )
        ->to( controller => 'History', action => 'private_message' )
        ;

    $r->route( '/v1/everyone-status' )
        ->name( 'everyone_status' )
        ->to( controller => 'User', action => 'everyone_status' )
        ;

    $r->route( '/v1/user/friend/list' )
        ->name( 'friend_list' )
        ->to( controller => 'User', action => 'friend_list' )
        ;

    $r->route( '/v1/user/channel/list' )
        ->name( 'channel_list' )
        ->to( controller => 'User', action => 'channel_list' )
        ;

    $r->route( '/v1/user/friend/add' )
        ->name( 'friend_add' )
        ->to( controller => 'User', action => 'friend_add' )
        ;

    $r->route( '/v1/user/friend/del' )
        ->name( 'friend_del' )
        ->to( controller => 'User', action => 'friend_del' )
        ;
}

sub init_redis {
    my $self = shift;
    $self->helper(
        main_redis => sub {
            WI::Main::Redis->new( app => $self )
        }
    );
    $self->main_redis->blpop_loop;
}

1;
__END__

=encoding utf-8

=head1 NAME

WI::Main - It's new $module

=head1 SYNOPSIS

    use WI::Main;

=head1 DESCRIPTION

WI::Main is ...

=head1 LICENSE

Copyright (C) hernan604.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

hernan604 E<lt>E<gt>

=cut

