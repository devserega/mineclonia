#!/bin/sh
cutoff=50
tmp=$(mktemp -d)
find ../mods/ -name "*.png"| while read f; do
	of=$(basename $f)
	cp $f $tmp/$of
	optipng -quiet -strip all -o7 $tmp/$of
	s1=$(cat $f|wc -c)
	s2=$(cat $tmp/$of |wc -c)
	saved=$(echo "$s1 - $s2" |bc) 
	if [ $saved -gt $cutoff ]; then
		mv $tmp/$of $f
		echo $f $saved bytes saved
	else
		rm $tmp/$of
	fi
done

rm -rf $tmp
