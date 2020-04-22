#!/bin/sh

for i in $(find src -name '*.c'); do
	f="${i%.*}".nim
	echo c2nim "$i => $f"
	c2nim --cdecl $i --out:$f
done 

