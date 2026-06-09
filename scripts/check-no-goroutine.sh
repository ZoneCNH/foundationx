#!/usr/bin/env bash
# check-no-goroutine.sh — 检查 L0 包是否偷偷启动 goroutine
# L0 包不应有隐藏的 goroutine（除 lifecycx/shutdownx/syncx 明确管理的）。
# 扫描根目录下所有 Go 包的 .go 文件，查找 "go func" 或 "go " 关键字。
# 排除 _test.go 文件。
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# 允许启动 goroutine 的包（这些包的职责包含并发管理）
ALLOWED_PACKAGES="lifecycx shutdownx syncx examples internal"

FOUND_VIOLATIONS=0

for dir in "$REPO_ROOT"/*/; do
  dirname=$(basename "$dir")

  # 跳过非包目录
  case "$dirname" in
    .worktree|docs|contracts|scripts|release|reports|reports*) continue ;;
  esac

  # 跳过允许的包
  skip=0
  for allowed in $ALLOWED_PACKAGES; do
    if [[ "$dirname" == "$allowed" ]]; then
      skip=1
      break
    fi
  done
  [[ $skip -eq 1 ]] && continue

  # 扫描 .go 文件（排除 _test.go）
  while IFS= read -r file; do
    # 跳过测试文件
    [[ "$file" == *_test.go ]] && continue

    # 查找 go 关键字启动 goroutine（go func 或 go someFunc）
    # 使用 grep -n 显示行号
    matches=$(grep -nE '^\s*go\s+(func|[a-zA-Z_])' "$file" 2>/dev/null || true)
    if [[ -n "$matches" ]]; then
      while IFS= read -r match; do
        rel_path="${file#$REPO_ROOT/}"
        echo "HIDDEN GOROUTINE: ${rel_path}:${match}"
        FOUND_VIOLATIONS=1
      done <<< "$matches"
    fi
  done < <(find "$dir" -maxdepth 1 -name "*.go" -not -name "*_test.go" 2>/dev/null)
done

if [[ $FOUND_VIOLATIONS -eq 1 ]]; then
  echo ""
  echo "NO-GOROUTINE CHECK FAILED: L0 packages must not spawn hidden goroutines."
  echo "Allowed packages: $ALLOWED_PACKAGES"
  exit 1
fi

echo "NO-GOROUTINE CHECK PASSED: no hidden goroutines in L0 packages."
exit 0
