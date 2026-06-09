#!/usr/bin/env bash
# check-stdlib-only.sh — 检查 go.mod 是否只有标准库依赖
# L0 基座层不应引入任何第三方依赖。
# 白名单文件: contracts/allowed_deps.txt
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GO_MOD="${REPO_ROOT}/go.mod"
ALLOWED_FILE="${REPO_ROOT}/contracts/allowed_deps.txt"

if [[ ! -f "$GO_MOD" ]]; then
  echo "ERROR: go.mod not found at $GO_MOD"
  exit 1
fi

# 从 allowed_deps.txt 提取白名单（忽略注释和空行）
declare -A ALLOWED
if [[ -f "$ALLOWED_FILE" ]]; then
  while IFS= read -r line; do
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    dep=$(echo "$line" | awk '{print $1}')
    ALLOWED["$dep"]=1
  done < "$ALLOWED_FILE"
fi

# 解析 go.mod 的 require 块，排除 indirect 注释
FOUND_VIOLATIONS=0
IN_REQUIRE=0

while IFS= read -r line; do
  # 检测 require 块开始
  if [[ "$line" =~ ^require[[:space:]]+\( ]]; then
    IN_REQUIRE=1
    continue
  fi
  if [[ "$line" =~ ^require[[:space:]]+([^[:space:]]+) ]]; then
    # 单行 require
    dep="${BASH_REMATCH[1]}"
    # 跳过标准库（不含 .）
    if [[ "$dep" == *.* ]] && [[ -z "${ALLOWED[$dep]+x}" ]]; then
      echo "NON-STDLIB DEPENDENCY: $dep"
      FOUND_VIOLATIONS=1
    fi
    continue
  fi
  if [[ $IN_REQUIRE -eq 1 ]]; then
    if [[ "$line" == ")" ]]; then
      IN_REQUIRE=0
      continue
    fi
    # 跳过注释行
    [[ "$line" =~ ^[[:space:]]*// ]] && continue
    # 提取模块路径（第一个字段）
    dep=$(echo "$line" | awk '{print $1}')
    [[ -z "$dep" ]] && continue
    # 标准库模块路径不含 '.'，第三方包含 '.'
    if [[ "$dep" == *.* ]]; then
      if [[ -z "${ALLOWED[$dep]+x}" ]]; then
        echo "NON-STDLIB DEPENDENCY: $dep"
        FOUND_VIOLATIONS=1
      fi
    fi
  fi
done < "$GO_MOD"

if [[ $FOUND_VIOLATIONS -eq 1 ]]; then
  echo ""
  echo "STDLIB-ONLY CHECK FAILED: non-stdlib dependencies found."
  echo "Add approved deps to contracts/allowed_deps.txt."
  exit 1
fi

echo "STDLIB-ONLY CHECK PASSED: only stdlib dependencies."
exit 0
