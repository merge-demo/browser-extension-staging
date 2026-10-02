#!/usr/bin/env bash
# Uploads one synthetic JUnit bundle for the browser extension's flaky-test
# e2e. A PR without the file (every PR the e2e did not create) uploads nothing.
set -euo pipefail

bundle="$1"
# Only a PR that commits the bundle uploads it: a merged e2e PR can leave the
# file on main, and every later PR would otherwise upload it too.
git fetch --no-tags --depth=1 origin "${BASE_SHA}"
if ! git diff --name-only "${BASE_SHA}" HEAD -- "${bundle}" | grep -q .; then
	echo "This PR does not change ${bundle}; nothing to upload."
	exit 0
fi

curl -fsSL --retry 3 -o trunk-analytics-cli.tar.gz \
	https://github.com/trunk-io/analytics-cli/releases/latest/download/trunk-analytics-cli-x86_64-unknown-linux.tar.gz
tar -xzf trunk-analytics-cli.tar.gz
./trunk-analytics-cli upload \
	--junit-paths "${bundle}" \
	--org-url-slug merge-demo \
	--token "${TRUNK_API_TOKEN}"
