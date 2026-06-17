#!/usr/bin/env bash
# Search YouTube and print title | duration | uploader | URL for each hit.
# Usage:
#   search.sh <N> <query...>
#   search.sh 10 "brain atlas webinar"
#
# For more advanced filters, invoke yt-dlp directly with --match-filters.
set -euo pipefail

if [ "$#" -lt 2 ]; then
    echo "usage: search.sh <N> <query...>" >&2
    echo "  N = number of results (e.g. 10)" >&2
    exit 2
fi

N="$1"
shift
QUERY="$*"

exec yt-dlp "ytsearch${N}:${QUERY}" \
    --print "%(title)s | %(duration_string)s | %(uploader)s | %(webpage_url)s" \
    --skip-download
