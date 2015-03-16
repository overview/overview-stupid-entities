#!/bin/bash

# Deploy the latest version of this plugin
#
# The server (whose DNS name is in ecosystem.json) must have been provisioned
# using script/provision-ec2.sh.

DIR="$(dirname "$0")"/..

(cd "$DIR" && npm install) # make sure pm2 is installed
(cd "$DIR" && node_modules/.bin/pm2 deploy ecosystem.json production)
