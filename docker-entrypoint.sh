#!/bin/sh -e
# Magic to Provision the Container
# Brian Dwyer - Intelligent Digital Services

if [ -f '.terraform-version' ]; then
  echo "Terraform version file detected... Initializing: $(cat .terraform-version)"
  tfenv install
fi

# Kitchen Wrapper & Passthrough
case "$1" in
	#
	# Test-Kitchen
	#
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
	-*) kitchen "$@";;
	#
	# Terraform
	#
	tf ) terraform "$@";;
	apply ) terraform "$@";;
	plan ) terraform "$@";;
	env ) terraform "$@";;
	fmt ) terraform "$@";;
	get ) terraform "$@";;
	graph ) terraform "$@";;
	import ) terraform "$@";;
	output ) terraform "$@";;
	providers ) terraform "$@";;
	show ) terraform "$@";;
	taint ) terraform "$@";;
	untaint ) terraform "$@";;
	validate ) terraform "$@";;
	workspace ) terraform "$@";;
	0.12upgrade ) terraform "$@";;
	force-unlock ) terraform "$@";;
	state ) terraform "$@";;
	#
	# Other
	#
	* )	exec "$@";;
esac
