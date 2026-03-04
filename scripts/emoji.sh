#!/usr/bin/env bash
# emoji.sh — 根据关键词获取表情包图片
# 用法: emoji.sh <关键词> [数量]
# 示例: emoji.sh 开心
#       emoji.sh 委屈 3
# 输出: JSON { "url": "...", "keyword": "...", "total": N }
#       多张时输出 JSON 数组

set -euo pipefail

API_BASE="https://api.tangdouz.com/a/biaoq.php"
TIMEOUT=8

usage() {
  echo "Usage: $0 <keyword> [count]" >&2
  echo "  keyword  搜索关键词（中文），如: 开心、委屈、加油" >&2
  echo "  count    返回图片数量（默认 1，最大 5）" >&2
  exit 1
}

[[ $# -lt 1 ]] && usage

KEYWORD="$1"
COUNT="${2:-1}"

(( COUNT < 1 )) && COUNT=1
(( COUNT > 5 )) && COUNT=5

ENCODED=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$KEYWORD'))" 2>/dev/null || echo "$KEYWORD")

RESPONSE=$(curl -s -m "$TIMEOUT" "${API_BASE}?return=json&nr=${ENCODED}" 2>/dev/null) || {
  echo '{"error":"API request failed","keyword":"'"$KEYWORD"'"}' >&2
  exit 1
}

if ! echo "$RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); assert isinstance(d,list)" 2>/dev/null; then
  echo '{"error":"Invalid API response","keyword":"'"$KEYWORD"'"}' >&2
  exit 1
fi

TOTAL=$(echo "$RESPONSE" | python3 -c "import sys,json; print(len(json.load(sys.stdin)))")

if [[ "$TOTAL" -eq 0 ]]; then
  echo '{"error":"No results found","keyword":"'"$KEYWORD"'"}' >&2
  exit 1
fi

python3 -c "
import sys, json, random

data = json.loads('''$RESPONSE''')
total = len(data)
count = min($COUNT, total)

selected = random.sample(data, count)

if count == 1:
    item = selected[0]
    print(json.dumps({
        'url': item['thumbSrc'],
        'keyword': '$KEYWORD',
        'total': total
    }, ensure_ascii=False))
else:
    result = []
    for item in selected:
        result.append({
            'url': item['thumbSrc'],
            'keyword': '$KEYWORD',
            'total': total
        })
    print(json.dumps(result, ensure_ascii=False))
"
