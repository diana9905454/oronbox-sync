#!/bin/bash
# ============================================
# OronBox 同步器 - 全量构建脚本
# 一键构建 OronBox 插件 (.obp) 和 Vela 手环应用 (.rpk)
# ============================================

set -e

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="${ROOT_DIR}/oronbox-sync-plugin"
VELA_DIR="${ROOT_DIR}/vela-oronbox-sync"
DIST_DIR="${ROOT_DIR}/dist"

echo "=========================================="
echo "  OronBox 同步器 - 全量构建"
echo "=========================================="
echo ""

mkdir -p "$DIST_DIR"

# ============================================
# 阶段 1：构建 OronBox 插件 (.obp)
# ============================================
echo "[阶段 1/2] 构建 OronBox 插件"
echo "------------------------------------------"

PLUGIN_MISSING=0
for file in manifest.json main.js; do
  if [ ! -f "${PLUGIN_DIR}/${file}" ]; then
    echo "  [错误] 缺少: ${PLUGIN_DIR}/${file}"
    PLUGIN_MISSING=1
  fi
done

if [ $PLUGIN_MISSING -eq 0 ]; then
  OBP_FILE="${DIST_DIR}/oronbox-sync.obp"
  rm -f "$OBP_FILE"
  cd "$PLUGIN_DIR"
  zip -r -X "$OBP_FILE" manifest.json main.js > /dev/null 2>&1

  # 打包图标（如果存在）
  if [ -f "icon.png" ]; then
    zip -r -X "$OBP_FILE" icon.png > /dev/null 2>&1
  fi

  if [ -f "$OBP_FILE" ]; then
    SIZE=$(stat -c%s "$OBP_FILE" 2>/dev/null || stat -f%z "$OBP_FILE" 2>/dev/null || echo "?")
    echo "  [成功] oronbox-sync.obp (${SIZE} 字节)"
  else
    echo "  [失败] 插件打包失败"
    exit 1
  fi
else
  echo "  [跳过] 插件文件不完整"
fi

echo ""

# ============================================
# 阶段 2：构建 Vela 手环应用 (.rpk)
# ============================================
echo "[阶段 2/2] 构建 Vela 手环应用"
echo "------------------------------------------"

VELA_MANIFEST="${VELA_DIR}/src/manifest.json"
if [ ! -f "$VELA_MANIFEST" ]; then
  echo "  [错误] 缺少 Vela manifest: ${VELA_MANIFEST}"
  exit 1
fi

# 检查 aiot-toolkit 是否安装
if command -v aiot &> /dev/null; then
  echo "  aiot-toolkit 已安装"
  cd "$VELA_DIR"

  # 检查 node_modules
  if [ ! -d "node_modules" ]; then
    echo "  正在安装依赖..."
    npm install 2>&1 | tail -3
  fi

  echo "  正在构建 RPK..."
  if aiot build 2>&1 | tail -5; then
    # 查找生成的 RPK 文件
    RPK_FILE=$(find "$VELA_DIR/dist" -name "*.rpk" 2>/dev/null | head -1)
    if [ -n "$RPK_FILE" ]; then
      cp "$RPK_FILE" "${DIST_DIR}/"
      RPK_NAME=$(basename "$RPK_FILE")
      SIZE=$(stat -c%s "$RPK_FILE" 2>/dev/null || stat -f%z "$RPK_FILE" 2>/dev/null || echo "?")
      echo "  [成功] ${RPK_NAME} (${SIZE} 字节)"
    else
      echo "  [警告] 未找到生成的 RPK 文件，请检查构建输出"
    fi
  else
    echo "  [失败] RPK 构建失败"
    echo "  请确保 aiot-toolkit 已正确安装: npm install -g aiot-toolkit"
  fi
else
  echo "  [跳过] aiot-toolkit 未安装"
  echo ""
  echo "  安装方法:"
  echo "    1. npm install -g aiot-toolkit"
  echo "    2. 或使用 AIoT-IDE 打开 ${VELA_DIR} 目录可视化构建"
  echo ""
  echo "  手动构建:"
  echo "    cd ${VELA_DIR}"
  echo "    npm install"
  echo "    aiot build      # 构建 debug 包"
  echo "    aiot release    # 构建 release 包"
fi

echo ""
echo "=========================================="
echo "  构建完成"
echo "=========================================="
echo ""
echo "  产物目录: ${DIST_DIR}"
ls -la "$DIST_DIR" 2>/dev/null || echo "  (目录为空)"
echo ""
echo "  下一步:"
echo "    1. 在 OronBox 客户端中导入 oronbox-sync.obp"
echo "    2. 通过小米运动健康 App 将 .rpk 安装到手环"
echo "    3. 在 OronBox 插件中输入文本并同步"
echo ""
