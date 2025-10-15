#!/usr/bin/env bash
set -euo pipefail

# Append auth params
SOURCE_BASE="${SOURCE_MONGODB_URL%/}"
DEST_BASE="${DESTINATION_MONGODB_URL%/}"
SOURCE_SUFFIX="?authSource=admin&tls=true&tlsInsecure=true"
DEST_SUFFIX="?authSource=admin"

# --- Helper functions --------------------------------------------------------
error_exit() { echo "Error: $*" >&2; exit 1; }

mask_uri() { 
    local uri="$1"
    echo "$uri" | sed -E 's#//([^/@]+)@#//*****:*****@#'
}

check_envs() {
    local required_vars=("SOURCE_MONGODB_URL" "DESTINATION_MONGODB_URL")
    local missing=false
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            echo "Missing environment variable: $var"
            missing=true
        fi
    done
    if [[ "$missing" == true ]]; then
        echo
        echo "Please set the following before running:"
        echo "  export SOURCE_MONGODB_URL='mongodb+srv://user:pass@cluster.mongodb.net'"
        echo "  export DESTINATION_MONGODB_URL='mongodb://user:pass@localhost:27017'"
        exit 1
    fi
}

usage() {
    echo "Usage: $0 [-d database] [-f filename] [-p prefix] [-o] [-k]"
    echo
    echo "Options:"
    echo "  -d DATABASE   Process a single database (overrides -f or stdin)"
    echo "  -f FILE       Read database names from FILE"
    echo "  -p PREFIX     Add PREFIX to each database name (e.g., stage-)"
    echo "  -o            Overwrite destination database if it exists (adds --drop)"
    echo "  -k            Keep dump directory after completion"
    echo "  -h            Show this help message"
    echo
    echo "You can also pipe database names directly, e.g.:"
    echo "  cat dbs.txt | $0 -p stage- -o -k"
    exit 0
}

# --- Parse options -----------------------------------------------------------
FILE=""
PREFIX=""
OVERWRITE=false
KEEP_DUMP=false
SINGLE_DB=""

while getopts ":d:f:p:okh" opt; do
    case $opt in
        d) SINGLE_DB=$OPTARG ;;
        f) FILE=$OPTARG ;;
        p) PREFIX=$OPTARG ;;
        o) OVERWRITE=true ;;
        k) KEEP_DUMP=true ;;
        h) usage ;;
        *) usage ;;
    esac
done
shift $((OPTIND -1))

check_envs

# --- Collect database list ---------------------------------------------------
DBS=()

if [[ -n "$SINGLE_DB" ]]; then
    DBS=("$SINGLE_DB")
elif [[ -n "$FILE" ]]; then
    [[ -f "$FILE" ]] || error_exit "File not found: $FILE"
    mapfile -t DBS < <(grep -v '^[[:space:]]*$' "$FILE" | sed 's/\r$//' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
elif [[ ! -t 0 ]]; then
    mapfile -t DBS < <(grep -v '^[[:space:]]*$' | sed 's/\r$//' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
else
    usage
fi

[[ ${#DBS[@]} -gt 0 ]] || error_exit "No databases provided."

# --- Check for mongo-tools ---------------------------------------------------
MONGODUMP=$(command -v mongodump || true)
MONGORESTORE=$(command -v mongorestore || true)
[[ -x "$MONGODUMP" && -x "$MONGORESTORE" ]] || error_exit "Missing mongo-tools (mongodump, mongorestore)"

# --- Work directories --------------------------------------------------------
DUMP_DIR="./dump"
mkdir -p "$DUMP_DIR"

# --- Main loop ---------------------------------------------------------------
for db in "${DBS[@]}"; do
    full_db="${PREFIX}${db}"
    echo
    echo "Processing database: ${full_db}"

    SRC_URI="${SOURCE_BASE}/${full_db}${SOURCE_SUFFIX}"
    DST_URI="${DEST_BASE}/${db}${DEST_SUFFIX}"

    MASKED_SRC=$(mask_uri "$SRC_URI")
    MASKED_DST=$(mask_uri "$DST_URI")

    echo "→ Dumping from ${MASKED_SRC}"
    "$MONGODUMP" --uri="${SRC_URI}" --out "$DUMP_DIR"

    echo "→ Restoring into ${MASKED_DST}"
    RESTORE_CMD=("$MONGORESTORE" --uri="${DST_URI}")
    [[ "$OVERWRITE" == true ]] && RESTORE_CMD+=("--drop")
    RESTORE_CMD+=("$DUMP_DIR/$full_db")
    "${RESTORE_CMD[@]}"

    echo "✓ Done with ${full_db}"
done

# --- Cleanup -----------------------------------------------------------------
if [[ "$KEEP_DUMP" == false ]]; then
    rm -rf "$DUMP_DIR"
else
    echo "ℹ️ Keeping dump directory: $DUMP_DIR"
fi

echo
echo "✅ All databases processed successfully."

exit 0
