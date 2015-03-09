package WI::Main;
use 5.008001;
use strict;
use warnings;
use Moo;
use Redis;
use DDP;
use JSON::XS qw|encode_json decode_json|;
use WI::Main::IRC;
use WI::Main::WEB;
our $VERSION = "0.01";

has timeout     => ( is => 'rw', default => sub { 5 } );
#has queue_from_irc  => ( is => 'rw', default => sub { 'from_irc' } );
has redis => ( is => 'rw', default => sub { Redis->new});

has irc => ( is => 'rw',  default => sub {
    my $self = shift;
    WI::Main::IRC->new( _ref_main => $self );
} );

has web => ( is => 'rw',  default => sub {
    my $self = shift;
    WI::Main::WEB->new( _ref_main => $self );
} );

has db => ( is => 'rw' );

sub send_to_web {
    my $self = shift;
    #reeceives irc events that should be send  to web interface
}

sub send_to_irc {
    my $self = shift;
    #receives web events that should be sent to irc
} 

#   sub channel_join {
#       my $self = shift;
#       my $args = shift;
#       $self->_ref_main->redis->rpush( $args->{ queue } , encode_json $args->{obj} );
#   }


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

