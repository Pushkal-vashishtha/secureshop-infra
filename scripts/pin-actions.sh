#!/usr/bin/env bash
# Pin every "uses: owner/repo[/path]@vX" in a workflow file to its commit SHA.
f="$1"
grep -oE 'uses: [^ ]+@v[0-9][^ ]*$' "$f" | sort -u | while read -r _ ref; do
  action=${ref%@*}; tag=${ref##*@}; repo=$(echo "$action" | cut -d/ -f1-2)
  sha=$(git ls-remote "https://github.com/$repo" "refs/tags/$tag" | sort -k2 | tail -1 | cut -f1)
  if [ ${#sha} -eq 40 ]; then
    sed -i "s|uses: $action@$tag\$|uses: $action@$sha # $tag|" "$f"
    echo "pinned  $action $tag -> $sha"
  else
    echo "FAILED  $action $tag (no SHA found)"
  fi
done
