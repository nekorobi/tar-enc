#!/bin/bash
set -e; cd ${0%/*} # here
script=../tar-enc.sh
export PASS="secret pass"
mkdir -p tmp; rm -fr tmp/*

[[ $(date +%H%M%S) =~ ^235959$ ]] && sleep 1 || true
date=$(date +%F)
todayEnc=hello.$date.gzip.aes  helloEnc=hello.gzip.aes  allEnc=all.gzip.camellia

# --dry-run
result=$($script --dry-run hello)
line="tar --create --gzip --to-stdout 'hello' | openssl enc -aes256 -pbkdf2 -out './hello.$date.gzip.aes'"
[[ $line = $result ]] || exit 51

result=$($script --dry-run -C -D /path/to/dir hello --xz -n $date.enc)
line="tar --create --xz --to-stdout 'hello' | openssl enc -camellia256 -pbkdf2 -out '/path/to/dir/$date.enc'"
[[ $line = $result ]] || exit 52

result=$($script --dry-run -d $helloEnc)
line="openssl enc -aes256 -pbkdf2 -d -in '$helloEnc' | tar --extract --gzip --directory '.'"
[[ $line = $result ]] || exit 53

result=$($script --dry-run -l $allEnc)
line="openssl enc -aes256 -pbkdf2 -d -in '$allEnc' | tar --list --gzip"
[[ $line = $result ]] || exit 54

# Default
cd tmp
../$script -p ../hello ../x ../y -q >/dev/null 2>&1 &&
  ../$script -l $todayEnc -p -q >/dev/null &&
  ../$script -d $todayEnc -p -q &&
  [[ $(cat y/yy/yy1) = yy1 ]] || { rm -fr ./*; exit 60; }
rm -fr ./*
cd ..

# --camellia
$script -C -D tmp -n all.enc -p hello x y -q &&
  $script -C -l tmp/all.enc -p -q >/dev/null &&
  $script -C -d -D tmp tmp/all.enc -p -q &&
  [[ $(cat tmp/y/yy/yy1) = yy1 ]] || { rm -fr tmp/*; exit 61; }
rm -fr tmp/*

# --xz
$script --xz -D tmp -n all.enc -p hello x y -q &&
  $script --xz -l tmp/all.enc -p -q >/dev/null &&
  $script --xz -d -D tmp tmp/all.enc -p -q &&
  [[ $(cat tmp/y/yy/yy1) = yy1 ]] || { rm -fr tmp/*; exit 62; }
rm -fr tmp/*

# --bzip2
$script --bzip2 -D tmp -n all.enc -p hello x y -q &&
  $script --bzip2 -l tmp/all.enc -p -q >/dev/null &&
  $script --bzip2 -d -D tmp tmp/all.enc -p -q &&
  [[ $(cat tmp/y/yy/yy1) = yy1 ]] || { rm -fr tmp/*; exit 63; }
rm -fr tmp/*

# decrypt multiple files
$script -d -D tmp $helloEnc $allEnc -p -q &&
  [[ $(cat tmp/y/yy/yy1) = yy1 ]] || { rm -fr tmp/*; exit 64; }
rm -fr tmp/*

echo success: test.sh
