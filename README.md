# MongoClone

## Description

`MongoClone` is a Bash script to **dump and restore MongoDB databases** between a source and a destination cluster.  
It supports **single databases, multiple databases from a file, or piped input**, with optional database prefixes, overwriting existing databases, and keeping dump directories for debugging.

The script also **masks credentials** in logs and automatically appends required authentication parameters to the connection strings.

---

## Features

- Dump and restore MongoDB databases safely
- Supports **single database** (`-d`) or multiple databases from a file (`-f`) or stdin
- Optional **prefix** for database names (`-p`)
- Optionally **overwrite** destination databases (`-o`)
- Optionally **keep dump directory** after completion (`-k`)
- Works with MongoDB URI connection strings, appending required auth and TLS parameters

---

## Requirements

- Bash 4+
- MongoDB Database Tools (`mongodump` and `mongorestore`) installed
- Environment variables:
  - `SOURCE_MONGODB_URL` – full MongoDB URI for source cluster (without database)
  - `DESTINATION_MONGODB_URL` – full MongoDB URI for destination cluster (without database)

---

## Installation

```bash
# Make script executable
chmod +x mongoclone.sh

# Optionally add to PATH
sudo mv mongoclone.sh /usr/local/bin/mongoclone
```

## Usage

```bash
./mongoclone.sh [options]
```

## Quick Flag Reference

| Flags                                  | Description | Example                                                |
|----------------------------------------|-------------|--------------------------------------------------------|
| `-d DATABASE`                          | Process a single database (overrides `-f` and stdin) | `./mongoclone.sh -d mydb`                              |
| `-f FILE`                              | Read database names from a file | `./mongoclone.sh -f databases.txt`                     |
| `-p PREFIX`                            | Add a prefix to database names | `./mongoclone.sh -f databases.txt -p stage-`           |
| `-o`                                   | Overwrite destination database if exists (`--drop`) | `./mongoclone.sh -f databases.txt -o`                  |
| `-k`                                   | Keep dump directory after completion | `./mongoclone.sh -f databases.txt -k`                  |
| `-d DATABASE -p PREFIX -o`             | Single database, prefixed, overwrite | `./mongoclone.sh -d mydb -p stage- -o`                 |
| `-f FILE -p PREFIX -k`                 | Multiple databases from file, keep dump | `./mongoclone.sh -f databases.txt -p dev- -k`          |
| `pipe \| ./mongoclone.sh -p PREFIX -o` | Pipe database names, prefix, overwrite | `cat database_list.txt \| ./mongoclone.sh -p stage- -o` |


## Usage Examples

### Setting required environment variables

Setting required environment variable to connect to MongoDB instances
```bash
export SOURCE_MONGODB_URL="mongodb+srv://user:pass@source-cluster.mongodb.net"
export DESTINATION_MONGODB_URL="mongodb://root:example@localhost:27017"
```

### Single database

Dump and restore a single database, adding a prefix and overwriting the destination if it exists:

```bash
./mongoclone.sh -d mydatabase -p stage- -o
```

### Multiple databases from a file

Read database names from databases.txt, add a prefix, and keep the dump directory for inspection:

```bash
./mongoclone.sh -f databases.txt -p dev- -k
```

### Getting databases list from a pipe

Pipe a list of database names directly into the script and overwrite destination databases:

```bash
cat databases_list.txt | ./mongoclone.sh -p stage- -o
```

### Processing a single database without prefix

Process a single database without adding any prefix:

```bash
./mongoclone.sh -d mydatabase
```

### Overwrite multiple databases

Read multiple databases from a file and overwrite existing ones at the destination:

```bash
./mongoclone.sh -f databases.txt -o
```

### Keep dump folder for debugging

Process databases from a file and retain the dump directory for manual inspection:

```bash
./mongoclone.sh -f databases.txt -k
```

## Credits

**Author:** Davide Villani

**License:** Creative Commons Zero v1.0 Universal

Inspired by common MongoDB migration workflows and open-source Bash scripting best practices.
