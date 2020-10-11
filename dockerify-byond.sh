#!/usr/bin/env bash
# dockerify-byond.sh
# Create Docker images for BYOND

npm ci
node_modules/.bin/coffee dockerify.coffee
