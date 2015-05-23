#!/bin/bash

ck="\\-=qwfpgjluy;[]\\\\arstdhneio'zxcvbkm,./"
dv="[]',.pyfgcrl/=\\\\aoeuidhtns\\-;qjkxbmwvz"
qw="\\-=qwertyuiop[]\\\\asdfghjkl;'zxcvbnm,./"

cases(){
    echo "$1$(echo "$1" | tr "a-z\-=\[\]\\;',./" "A-Z_+{}|:\"<>\?")"
}

CK="$(cases $ck)"
DV="$(cases $dv)"
QW="$(cases $qw)"

echo "ROT13"
echo "$1" | tr 'A-Za-z' 'N-ZA-Mn-za-m'

echo
echo "CK -> DV"
echo "$1" | tr "$CK" "$DV"

echo
echo "CK -> QW"
echo "$1" | tr "$CK" "$QW"

echo
echo "DV -> CK"
echo "$1" | tr "$DV" "$CK"

echo
echo "DV -> QW"
echo "$1" | tr "$DV" "$QW"

echo
echo "QW -> CK"
echo "$1" | tr "$QW" "$CK"

echo
echo "QW -> DV"
echo "$1" | tr "$QW" "$DV"
exit
