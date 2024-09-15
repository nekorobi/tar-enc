# tar-enc

[![Test](https://github.com/nekorobi/tar-enc/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/nekorobi/tar-enc/actions)

- Archive(Compress) and Encrypt(Symmetric cipher: openssl v3)
- files(directories) => a single encrypted file

## tar-enc.sh
- This Bash script depends on openssl version 3.
- `./tar-enc.sh --help`

### Default
- Encrypt mode
- Algorithm: gzip and AES (aes-256-cbc, PBKDF2, sha-256, salt)
- File name: FIRST_PATHNAME.YYYY-MM-DD.gzip.aes

## Example
```bash
./tar-enc.sh file1 dir1 dir2 ...
# => file1.2024-01-23.gzip.aes
```

- `-l, --list`: List mode
- `-d, --decrypt`: Decrypt mode
```bash
./tar-enc.sh -d file1.2024-01-23.gzip.aes
```

## MIT License
- © 2024 Nekorobi
