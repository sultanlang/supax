#!/bin/sh

REQUIRED_PACKAGES="ocamlc ocamlfind opam"
UUTFPAGE="uutf"
# Check if required packages are installed
for package in $REQUIRED_PACKAGES; do
    if ! command -v $package > /dev/null; then
        echo "Error: You are missing $package"
        exit 1
    fi
done

for package in $UUTFPAGE; do
    if ! opam show $package > /dev/null; then
        echo "Error: You are missing $package"
        exit 1
    fi
done

# Build the project
cd mind 

ocamlc -c progress.ml
ocamlc -o starter progress.cmo  setup.ml

./starter