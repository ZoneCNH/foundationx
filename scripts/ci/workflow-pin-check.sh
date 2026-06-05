#!/usr/bin/env sh
set -eu

workflow_dir=".github/workflows"
failed=0

if [ ! -d "$workflow_dir" ]; then
	exit 0
fi

for file in "$workflow_dir"/*.yml "$workflow_dir"/*.yaml; do
	[ -e "$file" ] || continue
	if ! awk -v file="$file" '
		/^[[:space:]]*(-[[:space:]]*)?uses:[[:space:]]*/ {
			ref = $0
			sub(/^[[:space:]]*(-[[:space:]]*)?uses:[[:space:]]*/, "", ref)
			sub(/[[:space:]]+#.*/, "", ref)
			gsub(/^[[:space:]]+|[[:space:]]+$/, "", ref)
			gsub(/^["\047]|["\047]$/, "", ref)

			if (ref ~ /^\.\//) {
				next
			}

			if (ref ~ /^docker:\/\//) {
				digest = "@sha256:"
				digest_at = index(ref, digest)
				if (digest_at == 0) {
					printf "%s:%d: docker action reference must be pinned to an immutable sha256 digest: %s\n", file, NR, ref
					failed = 1
					next
				}

				sha = substr(ref, digest_at + length(digest))
				if (length(sha) != 64 || sha !~ /^[0-9a-fA-F]+$/) {
					printf "%s:%d: docker action reference must be pinned to a sha256 digest: %s\n", file, NR, ref
					failed = 1
				}
				next
			}

			at = index(ref, "@")
			if (at == 0) {
				printf "%s:%d: action reference must include an immutable 40-character SHA: %s\n", file, NR, ref
				failed = 1
				next
			}

			sha = substr(ref, at + 1)
			if (length(sha) != 40 || sha !~ /^[0-9a-fA-F]+$/) {
				printf "%s:%d: action reference must be pinned to a 40-character SHA: %s\n", file, NR, ref
				failed = 1
			}
		}
		END { exit failed ? 1 : 0 }
	' "$file"; then
		failed=1
	fi
done

if [ "$failed" -ne 0 ]; then
	exit 1
fi
