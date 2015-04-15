#!/bin/bash

COMMAND="
wget -O - http://install.perlbrew.pl | bash
source ~/perl5/perlbrew/etc/bashrc
echo 'source ~/perl5/perlbrew/etc/bashrc' >> ~/.bashrc
perlbrew init
perlbrew -j 4 install 5.21.9
perlbrew switch 5.21.9
perlbrew install-cpanm
cpanm Mojolicious
cpanm Selenium::Remote::Driver JSON::XS File::Slurp MIME::Base64 Digest::SHA1
cpanm Config::Any Moo Mojo::Pg SQL::Abstract DDP POE::Component::Server::IRC
cpanm Mojo::Redis2 Mojolicious DateTime Redis
mkdir ~/perl
cd ~/perl
git clone https://github.com/hernan604/Web-IRC.git ~/perl/
"

sudo su - vagrant -c "$COMMAND"
