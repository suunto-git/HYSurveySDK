#!/bin/bash
# 用上游 Gitee 仓库覆盖 surveySDK/，并重新打上 SPM 的 Bundle.module 补丁。
#
# 用法:
#   ./sync.sh <上游 survey-sdk-ios 路径>
#
set -euo pipefail

SRC="${1:?用法: ./sync.sh <上游 survey-sdk-ios 路径>}"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ ! -d "$SRC/surveySDK/Classes" ]]; then
    echo "找不到 $SRC/surveySDK/Classes" >&2
    exit 1
fi

rsync -a --delete --exclude '.gitkeep' "$SRC/surveySDK/" "$REPO_DIR/surveySDK/"

python3 - "$REPO_DIR/surveySDK/Classes/HYUISurveyView.swift" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
text = p.read_text()
old = """    private func loadFile(res: String, ex: String) -> URL? {
        let myBundle = Bundle(for: Self.self)
        let path = myBundle.url(forResource: res, withExtension: ex, subdirectory: self.assets)
        return path
    }"""
new = """    private func loadFile(res: String, ex: String) -> URL? {
        #if SWIFT_PACKAGE
        let myBundle = Bundle.module
        #else
        let myBundle = Bundle(for: Self.self)
        #endif
        let path = myBundle.url(forResource: res, withExtension: ex, subdirectory: self.assets)
        return path
    }"""
if old not in text:
    if "Bundle.module" in text:
        print("Bundle.module 补丁已存在，跳过。")
        raise SystemExit(0)
    raise SystemExit("未找到 loadFile 原始实现，无法打补丁。")
p.write_text(text.replace(old, new, 1))
print("已打 Bundle.module 补丁")
PY

echo "已同步 $SRC -> $REPO_DIR/surveySDK"
