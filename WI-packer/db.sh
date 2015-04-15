#!/bin/bash

sudo su - postgres -c "createdb lalala"
sudo su - postgres -c "psql -c \"CREATE USER vagrant WITH PASSWORD 'vagrant';\""
sudo su - postgres -c "psql -c \"GRANT ALL PRIVILEGES ON DATABASE lalala to vagrant;\""

