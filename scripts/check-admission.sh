#!/usr/bin/env bash
# check-admission.sh — 检查新增包是否经过 L0 审查
# 扫描仓库根目录下的 Go 包，与 contracts/admitted_packages.txt 比较。
# 未登记的包会导致 exit 1。
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ADMITTED_FILE="${REPO_ROOT}/contracts/admitted_packages.txt"

if [[ ! -f "$ADMITTED_FILE" ]]; then
  echo "ERROR: admitted_packages.txt not found at $ADMITTED_FILE"
  exit 1
fi

# 从 admitted_packages.txt 提取已登记的包名（忽略注释和空行）
declare -A ADMITTED
while IFS= read -r line; do
  # 跳过空行和注释
  [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
  pkg=$(echo "$line" | awk '{print $1}')
  ADMITTED["$pkg"]=1
done < "$ADMITTED_FILE"

# 扫描仓库根目录下的 Go 包（排除 .worktree, internal, examples, docs, contracts, scripts, release, reports）
FOUND_VIOLATIONS=0
for dir in "$REPO_ROOT"/*/; do
  dirname=$(basename "$dir")

  # 跳过非包目录
  case "$dirname" in
    .worktree|internal|examples|docs|contracts|scripts|release|reports|reports*) continue ;;
  esac

  # 检查是否包含 .go 文件
  if ls "$dir"*.go &>/dev/null 2>&1 || find "$dir" -maxdepth 1 -name "*.go" -print -quit 2>/dev/null | grep -q .; then
    if [[ -z "${ADMITTED[$dirname]+x}" ]]; then
      echo "UNREGISTERED PACKAGE: $dirname"
      echo "  -> Add to contracts/admitted_packages.txt after L0 review"
      FOUND_VIOLATIONS=1
    fi
  fi
done

if [[ $FOUND_VIOLATIONS -eq 1 ]]; then
  echo ""
  echo "ADMISSION CHECK FAILED: unregistered packages found."
  exit 1
fi

echo "ADMISSION CHECK PASSED: all packages are registered."
exit 0
