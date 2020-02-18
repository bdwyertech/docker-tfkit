#!/bin/sh -e
# Magic to Provision the Container
# Brian Dwyer - Intelligent Digital Services

if [ -f '.terraform-version' ]; then
  echo "Terraform version file detected... Initializing: $(cat .terraform-version)"
  tfenv install
fi

# Kitchen Wrapper & Passthrough
case "$1" in
	console ) kitchen "$@";;
	converge ) kitchen "$@";;
	create ) kitchen "$@";;
	destroy ) kitchen "$@";;
	diagnose | doctor ) kitchen "$@";;
	exec ) kitchen "$@";;
	help ) kitchen "$@";;
	init ) kitchen "$@";;
	list ) kitchen "$@";;
	login ) kitchen "$@";;
	package ) kitchen "$@";;
	setup ) kitchen "$@";;
	test ) kitchen "$@";;
	verify ) kitchen "$@";;
	version ) kitchen "$@";;
	* )	exec "$@";;
esac
