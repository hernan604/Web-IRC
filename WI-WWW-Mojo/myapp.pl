use strict;
use warnings;
use Mojo::Server::Morbo;
my $morbo = Mojo::Server::Morbo->new;
$morbo->watch(['./']);
$morbo->run('scripts/app');

