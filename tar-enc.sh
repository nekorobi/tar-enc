#!/bin/bash
# tar-enc.sh
# MIT License © 2024 Nekorobi
version='1.0.1'
compress=gzip  cipher=aes256  mode=encrypt  dir=. # current directory
unset name files passOpt dry quiet; declare -a files

help() {
  cat << END
Usage: ./tar-enc.sh [Option]... File-or-Directory...

Archive(Compress) and Encrypt(Symmetric cipher: openssl v3)
files(directories) => a single encrypted file

Options:
  -C, --camellia
      Use Camellia cipher.
      Default: AES (aes-256-cbc, PBKDF2, sha-256, salt)
  -d, --decrypt
      Decrypt mode. (Default: Encrypt mode)
      Note that this overwrites existing files.
  -D, --directory Path
      Specify the destination directory path. (in Encrypt and Decrypt mode)
      Default: current directory
  -l, --list
      List mode. Just list the content paths.
  -n, --name Filename
      Specify the destination file name. (in Encrypt mode)
      Default: e.g. FIRST_PATHNAME.2024-01-23.gzip.aes
        -C /path/to/dir File1 test/File2 => dir.2024-01-23.gzip.camellia
  -p, --pass-env
      Use PASS environment variable for a passphrase.
      Default: Prompts for a passphrase.
  --xz, --bzip2
      Change the compression format.
      Default: gzip. Refer to the following:
        Compressed Size:     gzip > bzip2 > xz
        Compression Speed:   gzip > bzip2 > xz
        Decompression Speed: gzip > xz    > bzip2

  -h, --help     show this help.
  --dry-run      just show the openssl command line. Nothing changes.
  -q, --quiet    be as quiet as possible.
  -V, --version  show this version.

tar-enc.sh v$version
MIT License © 2024 Nekorobi
END
}

error() { echo -e "\e[1;31mError:\e[m $1" 1>&2; [[ $2 ]] && exit $2 || exit 1; }

while [[ $# -gt 0 ]]; do
  case "$1" in
  -D|--directory|-n|--name) [[ $# = 1 || $2 =~ ^- ]] && error "$1: requires an argument";;&
  --bzip2)        compress=bzip2; shift 1;;
  -C|--camellia)  cipher=camellia256; shift 1;;
  -d|--decrypt)   [[ $mode = list ]] && error "--decrypt, --list: exclusive options"; mode=decrypt; shift 1;;
  -D|--directory) dir=$(readlink -m "$2"); shift 2;; # dir: Not ending with a / (except root)
  -l|--list)      [[ $mode = decrypt ]] && error "--decrypt, --list: exclusive options"; mode=list; shift 1;;
  -n|--name)      name=$2; shift 2;;
  -p|--pass-env)  [[ $PASS ]] || error "$1: requires 'PASS' environment variable"; export PASS; passOpt="-pass env:PASS"; shift 1;;
  --xz)           compress=xz; shift 1;;
  #
  -h|--help)      help; exit 0;;
  --dry-run)      dry=yes; shift 1;;
  -q|--quiet)     quiet=yes; shift 1;;
  -V|--version)   echo tar-enc.sh $version; exit 0;;
  # ignore
  "") shift 1;;
  # invalid
  -*) error "$1: unknown option";;
  # Operand
  *)  [[ -f $1 || -d $1 ]] || error "$1: not a file or directory" 2; files[${#files[@]}]=$1; shift 1;;
  esac
done
[[ ${#files[@]} -gt 0 ]] || error "file (directory) not specified" 2
for e in "${files[@]}"; do [[ -r $e ]] || error "$e: permission denied" 2; done

# --directory
if [[ ! $dry && $mode != list ]]; then
  mkdir -p "$dir" && [[ -w $dir && -x $dir ]] || error "--directory: permission denied" 2
fi

Openssl="openssl enc -$cipher -pbkdf2 $passOpt"

encrypt() {
  # --name
  [[ $name =~ / ]] && error "--name: cannot contain '/'"
  [[ ! $name ]] && name=$(basename ${files[0]}).$(date +%F).$compress.${cipher:0:-3}
  [[ $dir = / ]] && out=/$name || out=$dir/$name
  [[ -f $out ]] && error "--directory, --file: file exists: $out"
  #
  quote() { for e in "$@"; do echo -e \'$e\' " "; done; }
  Tar="tar --create --$compress --to-stdout"
  [[ ! $quiet ]] && echo $Tar $(quote "${files[@]}") \| $Openssl -out \'$out\'
  [[ $dry ]] && exit
  $Tar "${files[@]}" | $Openssl -out "$out" || error "encryption failed" 20
  [[ ! $quiet ]] && ls -lh "$out" || true
}

decrypt() {
  for e in "${files[@]}"; do [[ -f $e ]] || error "$e: not a file" 2; done
  tarOpt=(--extract --$compress --directory)
  for e in "${files[@]}"; do
    if [[ $mode = list ]]; then
      [[ ! $quiet ]] && echo $Openssl -d -in \'$e\' \| tar --list --$compress
      [[ $dry ]] && break
      $Openssl -d -in "$e" | tar --list --$compress || error "--list: failed: $e" 21
    else
      [[ ! $quiet ]] && echo $Openssl -d -in \'$e\' \| tar ${tarOpt[@]} \'$dir\'
      [[ $dry ]] && break
      $Openssl -d -in "$e" | tar ${tarOpt[@]} "$dir" || error "--decrypt: failed: $e" 22
    fi
  done
}

# check openssl v3, tar
{ type openssl && type tar && openssl version -v | grep "^OpenSSL 3\."; } >/dev/null 2>&1 ||
  error "Required commands: openssl (version 3), tar" 3

if [[ $mode = encrypt ]]; then encrypt; else decrypt; fi
# error status: option 1, operand 2, version 3, encrypt 20, list 21, decrypt 22
