#!/usr/bin/env bash

# tsserver requires absolute paths in its input commands. So in tsserver.input,
# I replace every occurrence of '$PWD' with the current directory. Then, I pipe
# the result to tsserver.

sed -e 's|$PWD|'$PWD'|g' < tsserver.input | ./node_modules/.bin/tsserver
