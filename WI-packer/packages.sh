#!/bin/bash
echo '==> installing packages'
pacman -S --noconfirm postgresql vim wget screen redis git

echo '==> enable postgres'
sudo su - postgres -c "initdb --locale en_US.UTF-8 -D '/var/lib/postgres/data'"
systemctl enable postgresql.service
systemctl start postgresql.service

echo '==> enable redis'
systemctl enable redis.service
systemctl start redis.service
