# Experiment 2 - using nix flake

The goal here is to replace my shonky prep-disk script approach with a
nix-driven approach where we use this repo as the config repository for the
system as a whole, but importantly we can use it as the driver for the whole
system. i.e. There'll be a Makefile at the top level which can build an ISO
suitable to run our system, which provides a command which uses nix against this
repo to generate a script which sets up the system entirely.
