#!/bin/sh

for file in * ; do
    if ! file $file | grep -q 'directory' ; then
        continue
    fi
    if [ $file == share ] ; then
        continue
    fi

    ( cd $file; makepkg -fR )
done

mkdir -p ../share
find . -name '*.pkg.tar.gz' | xargs mv -t ../share/

