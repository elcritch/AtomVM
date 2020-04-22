#!/bin/sh

for i in $(find src -name "*.c"); do
	echo c2nim $i;
	c2nim --cdecl $i --out:${i:r}.nim;
done 

