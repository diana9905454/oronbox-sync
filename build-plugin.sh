#!/bin/bash
# ============================================
# OronBox同步器 - OronBox插件打包脚本
# 将插件文件 + 内嵌手环应用(rpk) 打包为 .obp (ZIP) 格式
# ============================================

set -e

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="${ROOT_DIR}/oronbox-sync-plugin"
OUTPUT_DIR="${ROOT_DIR}/dist"
OUTPUT_FILE="${OUTPUT_DIR}/oronbox-sync.obp"
RPK_DEST="${PLUGIN_DIR}/app/com.oronbox.sync.rpk"

echo "=========================================="
echo "  OronBox同步器 - 插件打包工具 (v2.3.0)"
echo "=========================================="
echo ""

# 检查插件目录
if [ ! -d "$PLUGIN_DIR" ]; then
  echo "[错误] 插件目录不存在: $PLUGIN_DIR"
  exit 1
fi

# 检查必要文件
MISSING=0
for file in manifest.json main.js; do
  if [ ! -f "${PLUGIN_DIR}/${file}" ]; then
    echo "[错误] 缺少必要文件: ${file}"
    MISSING=1
  fi
done

if [ $MISSING -eq 1 ]; then
  exit 1
fi

# 定位最新手环应用 rpk（优先取 vela 工程 dist 下的产物）
LATEST_RPK="$(ls -t ${ROOT_DIR}/vela-oronbox-sync/dist/*.rpk 2>/dev/null | head -1 || true)"
if [ -z "$LATEST_RPK" ]; then
  LATEST_RPK="$(ls -t ${OUTPUT_DIR}/*.rpk 2>/dev/null | head -1 || true)"
fi
if [ -z "$LATEST_RPK" ]; then
  echo "[错误] 未找到手环应用 rpk，请先构建 vela 工程"
  exit 1
fi
echo "  使用 rpk: $LATEST_RPK"

# 复制 rpk 到插件包内目录
mkdir -p "${PLUGIN_DIR}/app"
cp "$LATEST_RPK" "$RPK_DEST"
echo "  -> 已内嵌 rpk: app/com.oronbox.sync.rpk ($(stat -c%s "$RPK_DEST" 2>/dev/null) 字节)"

# 创建输出目录
mkdir -p "$OUTPUT_DIR"

# 清理旧的打包文件
rm -f "$OUTPUT_FILE"

# 打包为 .obp (ZIP格式)
echo "[1/3] 正在打包插件文件..."
cd "$PLUGIN_DIR"
zip -r -X "$OUTPUT_FILE" manifest.json main.js > /dev/null 2>&1

# 图标文件
if [ -f "icon.png" ]; then
  zip -r -X "$OUTPUT_FILE" icon.png > /dev/null 2>&1
  echo "  -> 已包含图标: icon.png"
fi

# 内嵌手环应用
if [ -f "app/com.oronbox.sync.rpk" ]; then
  zip -r -X "$OUTPUT_FILE" app > /dev/null 2>&1
  echo "  -> 已包含手环应用: app/com.oronbox.sync.rpk"
fi

# 检查打包结果
if [ -f "$OUTPUT_FILE" ]; then
  FILESIZE=$(stat -c%s "$OUTPUT_FILE" 2>/dev/null || stat -f%z "$OUTPUT_FILE" 2>/dev/null || echo "?")
  echo ""
  echo "[2/3] 打包完成!"
  echo "  文件: $OUTPUT_FILE"
  echo "  大小: ${FILESIZE} 字节"
  echo ""
  echo "[3/3] 使用方法:"
  echo "  1. 在OronBox客户端中打开: 设置 -> 插件 -> 导入插件"
  echo "  2. 选择 oronbox-sync.obp 文件导入"
  echo "  3. 打开插件 -> 点击「安装手环应用」即可安装手环端"
  echo ""
  echo "  OronBox插件限制: 压缩包 <= 32MiB, 单文件 <= 8MiB"
else
  echo "[错误] 打包失败"
  exit 1
fi