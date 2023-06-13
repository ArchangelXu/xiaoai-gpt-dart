#!/bin/bash
# Run this script if you want a compiled executable binary,
# but keep in mind that dart do not support cross-compile,
# which means compiled binary can only be run on same platform
# and same cpu arch. For example, you can't compile it on
# a intel-cpu-Macbook and execute it on another m1-cpu-Macbook.
# Better compile it on the machine on which you would execute it.

cd ..
mkdir "output"
dart compile exe bin/dart_gpt.dart -o dart_gpt

