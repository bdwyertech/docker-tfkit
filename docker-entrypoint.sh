#!/bin/sh -e
# Magic to Provision the Container
# Brian Dwyer - Intelligent Digital Services

tfenv install

# Passthrough
exec "$@"
