#!/bin/bash

size=$1
shift
got=$(wc -c $@ | tail -n1 | cut '-d ' -f1)
add=$((size - got))

blocksize=512
blocks=$((add/blocksize))
rest=$((add%blocksize))

cat $@
dd if=/dev/zero bs=$blocksize count=$blocks 2>/dev/null
dd if=/dev/zero bs=$rest count=1 2>/dev/null

