#!/usr/bin/env bash
# Benchmark regression check: 对比当前与基线，阻断 >10% 回退。
# 基线文件: contracts/bench/baseline.txt（首次运行或 make bench-baseline 创建）
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BASELINE="$ROOT/contracts/bench/baseline.txt"
THRESHOLD="${BENCH_REGRESSION_THRESHOLD:-10}"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT HUP INT TERM

cd "$ROOT"
pkgs=$(go list ./... | grep -v /examples | grep -v /scripts | grep -v /contracts)
FAILED=0

echo "=== kernel benchmark regression check (threshold: ${THRESHOLD}%) ==="

# 函数：从 benchmark 输出提取 ns/op（取首次出现的值，多 run 取中位数）
extract_ns() {
  local file="$1"
  awk '/^Benchmark/{
    name=$1
    for(i=2;i<=NF;i++){
      if($i ~ /ns\/op/){
        val=$(i-1)+0
        if(val>0) print name, val
        next
      }
    }
  }' "$file" | sort -t' ' -k1,1 -k2,2n | awk '{
    if($1!=prev){
      if(prev!="") printf "%s %.2f\n", prev, vals[int((len+1)/2)]
      prev=$1; len=0; delete vals
    }
    vals[++len]=$2
  } END {
    if(prev!="") printf "%s %.2f\n", prev, vals[int((len+1)/2)]
  }'
}

# 运行当前 benchmark (count=3 取中位数)
CURRENT="$TMPDIR/current.txt"
for pkg in $pkgs; do
  go test -bench=. -benchmem -count=3 "$pkg" >> "$CURRENT" 2>&1 || true
done

if ! grep -q '^Benchmark' "$CURRENT"; then
  echo "WARN: No benchmarks found. Skipping."
  exit 0
fi

extract_ns "$CURRENT" > "$TMPDIR/current_parsed.txt"

if [ ! -f "$BASELINE" ]; then
  echo "No baseline found. Creating: $BASELINE"
  mkdir -p "$(dirname "$BASELINE")"
  for pkg in $pkgs; do
    go test -bench=. -benchmem -count=3 "$pkg" >> "$BASELINE" 2>&1 || true
  done
  echo "Baseline created. Re-run to check for regressions."
  exit 0
fi

# 对比
extract_ns "$BASELINE" > "$TMPDIR/baseline_parsed.txt"

printf "%-42s %12s %12s %8s\n" "Benchmark" "Baseline(ns)" "Current(ns)" "Delta"
printf "%-42s %12s %12s %8s\n" "------------------------------------------" "------------" "-----------" "-----"

while read -r name current_ns; do
  baseline_ns=$(awk -v n="$name" '$1==n {print $2; exit}' "$TMPDIR/baseline_parsed.txt")
  if [ -z "$baseline_ns" ] || [ "$baseline_ns" = "0" ]; then
    printf "%-42s %12s %12.1f %8s\n" "$name" "N/A" "$current_ns" "[NEW]"
  else
    delta=$(awk "BEGIN {printf \"%.1f\", (($current_ns - $baseline_ns) / $baseline_ns) * 100}")
    if awk "BEGIN {exit !($delta > $THRESHOLD)}"; then
      printf "%-42s %12.1f %12.1f %7.1f%% [REGRESSION]\n" "$name" "$baseline_ns" "$current_ns" "$delta"
      FAILED=1
    else
      printf "%-42s %12.1f %12.1f %7.1f%%\n" "$name" "$baseline_ns" "$current_ns" "$delta"
    fi
  fi
done < "$TMPDIR/current_parsed.txt"

# 检查基线中存在但当前缺失的 benchmark
while read -r name baseline_ns; do
  if ! grep -q "^$name " "$TMPDIR/current_parsed.txt"; then
    echo "WARN: '$name' in baseline but missing in current run"
  fi
done < "$TMPDIR/baseline_parsed.txt"

if [ "$FAILED" -eq 1 ]; then
  echo ""
  echo "FAIL: Benchmark regression > ${THRESHOLD}% detected."
  echo "Update baseline: make bench-baseline"
  exit 1
fi

echo ""
echo "PASS: All benchmarks within ${THRESHOLD}% of baseline."
