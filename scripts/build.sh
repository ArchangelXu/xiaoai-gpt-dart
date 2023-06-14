#!/bin/bash
cd "$(dirname "$0")"
cd ..
dart pub get
#dart pub run build_runner build --delete-conflicting-outputs

