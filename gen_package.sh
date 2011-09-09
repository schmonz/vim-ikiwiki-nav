#!/bin/bash

git archive --format=zip -o ikiwiki-nav_${1}.zip --prefix=ikiwiki-nav_${1}/ $1 \
    autoload doc ftplugin AUTHORS BUGS TODO
