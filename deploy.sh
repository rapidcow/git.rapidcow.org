#!/usr/bin/env bash
# Usage: ./deploy.sh [destination]
# A local destination is useful for rehearsing the exact deployment.
set -euo pipefail
cd -- "$(dirname -- "$0")"
destination=${1:-root@ubuntu:/srv/www/pub/git.rapidcow.org}
if (( $# > 1 )); then
	echo "usage: $0 [destination]" >&2
	exit 2
fi
destination=${destination%/}
path=${destination#*:}
case $path in
	''|/|.|..) echo 'Refusing an empty or root destination' >&2; exit 2 ;;
esac
# rsync interprets a relative backup-dir inside the destination.
case $destination in
	*:*) backup=$path.bak ;;
	*)
		case $destination in /*) ;; *) destination=$PWD/$destination ;; esac
		backup=$destination.bak
		;;
esac
work=$(mktemp -d "${TMPDIR:-/tmp}/git-deploy.XXXXXX")
trap 'rm -rf -- "$work"' EXIT
mkdir -- "$work/build" "$work/site" "$work/empty"

# Each deployment gets fresh configuration, metadata, and rendered pages.
./configure -DA="$PWD" -DB="$work/build" -Obase_url=/
siteconf -gB "$work/build"
make -C "$work/build"

# Materialize only the manifest. A failed producer fails this pipeline too.
siteconf -lF "$work/build/MY/MANIFEST" -0 |
	rsync -a --files-from=- --from0 --itemize-changes -- "$work/build/site/" "$work/site/"

# Reuse one sibling backup directory, clearing the previous deployment's backup.
rsync -a --delete --chown www-data:www-data -- "$work/empty/" "$destination.bak/"
# A full directory mirror (rather than --files-from) deletes even stale subtrees.
rsync -a --delete --backup --backup-dir="$backup" --itemize-changes --chown www-data:www-data -- \
	"$work/site/" "$destination/"
