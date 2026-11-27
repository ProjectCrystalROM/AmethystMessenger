#!/usr/bin/env bash
set -euo pipefail

test_dir=$(cd "$(dirname "$0")" && pwd)
discord=$(cd "$test_dir/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

python3 "$test_dir/test_http_framing.py"

if ! pkg-config --exists json-glib-1.0; then
	echo "SKIP: reaction lookup test requires json-glib-1.0 development files" >&2
	exit 0
fi

${CC:-cc} -std=c99 -Wall -Wextra \
	$(pkg-config --cflags json-glib-1.0) \
	-I"$discord" \
	-o "$tmp/test-reaction-lookup" \
	"$discord/reaction-lookup.c" "$test_dir/test_reaction_lookup.c" \
	$(pkg-config --libs json-glib-1.0)
"$tmp/test-reaction-lookup"
