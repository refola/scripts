#!/bin/bash
echo "This is sourced one, before calling sourced two."
. ./sourced2.sh
echo "This is sourced one, after calling sourced two."

