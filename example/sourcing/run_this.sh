#!/usr/bin/env bash
echo "This is about to call another script in a sourcing way."
. ./sourced1.sh
echo "The sourced script has been called, along with its calls to other sourced scripts."
