#!/bin/bash

trap "echo trap1" SIGINT SIGTERM
trap "echo trap2" SIGINT SIGTERM # overrides previous trap

echo "sleeping 10s"
sleep 10 # is killed before trap is activated

echo "sleeping 10s"
sleep 10
