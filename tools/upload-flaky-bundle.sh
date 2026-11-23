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

# channel-1.json is the newest analytics-cli 1.x; GitHub's latest release is still 0.x, which
# takes the organization token that 1.x refuses.
releases=https://trunk.io/releases/analytics-cli/prod
asset=trunk-analytics-cli-x86_64-unknown-linux.tar.gz
curl_opts=(-fsSL --connect-timeout 10 --max-time 60 --retry 3)
version="$(curl "${curl_opts[@]}" "${releases}/channel-1.json" | jq -er .latest)"
curl "${curl_opts[@]}" -o "${asset}" "${releases}/${version}/${asset}"
sha256="$(curl "${curl_opts[@]}" "${releases}/${version}/manifest.json" | jq -er --arg a "${asset}" '.artifacts[$a].sha256')"
echo "${sha256}  ${asset}" | sha256sum -c -
tar -xzf "${asset}"
./trunk-analytics-cli upload \
	--junit-paths "${bundle}" \
	--org-url-slug merge-demo \
	--test-collection-id "${TRUNK_TEST_COLLECTION_ID}" \
	--token "${TRUNK_API_TOKEN}"
