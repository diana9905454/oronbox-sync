# OronBox 同步器

## 项目简介

OronBox同步器是一个完整的字符串→二维码同步方案，包含两个组件：

1. **OronBox插件**（`.obp`）- 运行在 OronBox 客户端中，提供文本输入界面，将字符串同步到手环
2. **Vela手环应用**（`.rpk`）- 运行在小米手环9/10/11上，接收字符串并使用原生组件生成二维码展示

**核心设计**：只传输字符串（约50字节），不传输二维码图片（1-10KB），由手环端Vela原生`<qrcode>`组件生成二维码，最大化节省手环存储空间。

## 构建产物

| 产物 | 文件 | 大小 | 说明 |
|------|------|------|------|
| OronBox 插件 | `dist/oronbox-sync.obp` | ~403KB | ZIP格式，含manifest+main.js+icon |
| Vela 手环应用 | `dist/com.oronbox.sync.debug.1.0.0.rpk` | ~411KB | Debug包，需安装到手环 |

## 架构图

```
┌─────────────────────────────────────────────────────┐
│                    OronBox 客户端                    │
│  ┌─────────────────────────────────────────────┐    │
│  │           OronBox同步器插件 (.obp)            │    │
│  │                                               │    │
│  │  ┌──────────────┐  ┌────────────────────┐   │    │
│  │  │  文本输入框   │  │  WiFi/URL 快捷模板  │   │    │
│  │  └──────────────┘  └────────────────────┘   │    │
│  │  ┌──────────────┐  ┌────────────────────┐   │    │
│  │  │  历史记录列表 │  │  设备状态显示       │   │    │
│  │  └──────────────┘  └────────────────────┘   │    │
│  │                                               │    │
│  │  [输入文本]  [同步到手环]                      │    │
│  └─────────────────────────────────────────────┘    │
│                        │                             │
│          appside.send('com.oronbox.sync', hexData)  │
│          ↘ 备用: protocol.send(base64)              │
└────────────────────────┼─────────────────────────────┘
                         │
                    BLE / 协议层
                         │
┌────────────────────────┼─────────────────────────────┐
│              小米手环 9/10/11 (Vela OS)               │
│  ┌─────────────────────▼──────────────────────┐      │
│  │      Vela RPK 应用 (com.oronbox.sync)      │      │
│  │                                              │      │
│  │   interconnect.onmessage → 接收Hex数据      │      │
│  │           ↓                                  │      │
│  │   hexToString() → 解码为原始字符串           │      │
│  │           ↓                                  │      │
│  │   <qrcode value="字符串" /> → 原生渲染QR码  │      │
│  │           ↓                                  │      │
│  │   vibrator.vibrate() → 震动反馈              │      │
│  │           ↓                                  │      │
│  │   storage.set() → 持久化保存(重启可恢复)     │      │
│  └──────────────────────────────────────────────┘      │
└─────────────────────────────────────────────────────────┘
```

## 目录结构

```
/workspace/
├── README.md                          # 本文档
├── .gitignore                         # Git忽略配置
├── build-all.sh                       # 全量构建脚本（插件+RPK）
├── build-plugin.sh                    # 仅构建插件脚本
├── dist/                              # 构建产物
│   ├── oronbox-sync.obp               # OronBox插件包
│   └── com.oronbox.sync.debug.1.0.0.rpk  # Vela手环应用包
│
├── oronbox-sync-plugin/               # OronBox 插件源码
│   ├── manifest.json                  # 插件清单
│   ├── main.js                        # 插件主逻辑
│   ├── icon.png                       # 插件图标
│   └── README.md                      # 插件文档
│
└── vela-oronbox-sync/                 # Vela 手环应用源码
    ├── package.json                   # npm配置
    ├── package-lock.json              # 依赖锁定
    ├── README.md                      # 应用文档
    ├── sign/                          # 签名文件目录
    │   ├── .gitkeep
    │   └── README.md                  # 签名生成说明
    ├── dist/                          # RPK构建输出
    └── src/
        ├── manifest.json              # 应用清单
        ├── app.ux                     # 应用入口
        ├── Index/
        │   └── index.ux               # 主页面（QR码展示+数据接收）
        ├── common/
        │   └── logo.png               # 应用图标
        └── i18n/                      # 多语言
            ├── defaults.json
            ├── zh-CN.json
            └── en.json
```

## 支持设备（多屏适配）

| 设备 | 屏幕分辨率 | 屏幕形状 | 缩放比 | 状态 |
|------|-----------|---------|--------|------|
| 小米手环9 | 192×490 | 胶囊形 | 0.91 | ✅ 原生 |
| 小米手环10/11 | 212×520 | 胶囊形 | 1.00 | ✅ 原生 |
| 小米手环9 Pro | 336×480 | 矩形 | 1.58 | ✅ 适配 |
| Redmi Watch 5 | 432×514 | 矩形 | 2.04 | ✅ 适配 |
| Xiaomi Watch S3/S4/S5 | 466–480 | 圆形 | ~2.2 | ✅ 适配 |
| 小米手环8 Pro | 336×480 | 矩形 | 1.58 | ⚠️ 不支持QR |

**适配机制**：`designWidth=212` 进行等比缩放，二维码保持正方形；`.body` 改为弹性高度解决方形/圆形屏纵向溢出；通过 `@media (shape: rect/circle)` 为矩形屏缩小二维码、为圆形屏增加安全区并避让圆角。

> 小米手环8 Pro 因 API Level 限制不支持 `<qrcode>` 组件，无法显示二维码（非布局问题），故不推荐。

## 快速开始

### 一键构建

```bash
bash build-all.sh
```

### 分步构建

#### 1. 构建 OronBox 插件

```bash
bash build-plugin.sh
# 输出: dist/oronbox-sync.obp
```

#### 2. 构建 Vela RPK 应用

```bash
cd vela-oronbox-sync
npm install
aiot build          # 构建 debug 包
# 输出: dist/com.oronbox.sync.debug.1.0.0.rpk
```

### 安装与使用

1. **安装插件**：在 OronBox 客户端中 → 设置 → 插件 → 导入 → 选择 `oronbox-sync.obp`
2. **安装手环应用**：通过小米运动健康App → 设备 → 应用管理 → 安装 `.rpk` 文件
3. **使用**：在 OronBox 插件中输入文本 → 点击「同步到手环」→ 手环震动并显示二维码

## 技术选型对比

| 方案 | 传输数据量 | 手环存储占用 | 实现复杂度 | 采用 |
|------|-----------|------------|-----------|------|
| **字符串直传 + 手环原生生成** | ~50字节 | 极小(仅存字符串) | 低 | ✅ |
| 插件生成QR图片 → 传输图片 | 1-10KB | 大(存图片) | 高 | ❌ |
| 插件生成QR矩阵 → 传输矩阵 | ~200字节 | 中(存矩阵) | 中 | ❌ |

## 通信架构

### 主通道：appside
```
插件 OronBox.appside.start('com.oronbox.sync')
     → OronBox.appside.send('com.oronbox.sync', hexData)
手环 interconnect.onmessage → hexToString() → <qrcode>
```

### 备用通道：protocol（主通道失败时自动切换）
```
插件 OronBox.protocol.send(base64Data, { deviceId })
手环 协议层接收 → tryBase64Decode() → <qrcode>
```

### 数据编码
```
原始字符串 → encodeURIComponent() → unescape() → UTF-8字节
     → 逐字节转Hex → "48656c6c6f..." → 发送
手环接收 → Hex → parseInt → bytes[] → UTF-8解码 → 原始字符串
```

## 关键API

### OronBox 插件 API
| API | 用途 |
|-----|------|
| `OronBox.ui.render(tree)` | 渲染UI组件树 |
| `OronBox.ui.dialog(opts)` | 弹出对话框 |
| `OronBox.device.list()` | 列出设备 |
| `OronBox.device.connect(id)` | 连接设备 |
| `OronBox.device.apps.launch(pkg)` | 启动手环应用 |
| `OronBox.appside.start(appId)` | 建立 appside 会话 |
| `OronBox.appside.send(appId, hexData)` | 向手环应用发送 Hex 数据 |
| `OronBox.protocol.send(base64, opts)` | 备用通道发送 |
| `OronBox.storage.get/set(key, value)` | 键值存储 |

### Vela 手环 API
| API | 用途 |
|-----|------|
| `<qrcode value="..." />` | 原生二维码组件 (APILevel 2+) |
| `@system.interconnect` | 与手机端通信 |
| `@system.device` | 获取屏幕信息 |
| `@system.storage` | 持久化存储 |
| `@system.vibrator` | 震动反馈 |
