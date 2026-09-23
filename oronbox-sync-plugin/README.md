# OronBox 同步器插件

开发者：Diana

## 概述

OronBox同步器是一个 OronBox 插件（.obp），用于将用户输入的字符串同步到小米手环上，手环端通过 Vela 原生 `<qrcode>` 组件生成并显示二维码。

**核心架构**：插件只传输字符串数据（约50字节），由手环端原生组件生成二维码，最大化节省手环存储空间。

## 文件结构

```
oronbox-sync-plugin/
├── manifest.json    # 插件清单（权限、运行时、入口声明）
├── main.js          # 插件主逻辑（UI、设备通信、同步逻辑）
└── README.md        # 本文档
```

## manifest.json 说明

| 字段 | 值 | 说明 |
|------|-----|------|
| `api_level` | 1 | OronBox插件API级别 |
| `id` | org.zxor.oronbox.sync | 插件唯一标识 |
| `name` | OronBox同步器 | 显示名称 |
| `runtime` | js | QuickJS沙箱运行时 |
| `entry` | main.js | 入口文件 |
| `permissions` | ui, device, appside, interconnect | 所需权限 |

## 权限说明

| 权限 | 用途 |
|------|------|
| `ui` | 渲染插件界面 |
| `device` | 列出/连接设备、启动手环应用 |
| `appside` | 向手环应用发送数据 |
| `interconnect` | 插件间通信（备用通道） |

## 核心功能

### 1. 文本输入
- 支持通过对话框输入任意文本
- 提供WiFi密码、网址、纯文本等快捷模板
- 历史记录持久化（最近10条）

### 2. 设备连接
- 自动检测已连接的设备
- 支持多设备选择
- 自动连接首个可用设备

### 3. 数据同步
- 字符串经UTF-8编码为Hex后发送
- 通过 `OronBox.appside.send()` 发送到手环应用
- 手环端通过 `interconnect.onmessage` 接收并解码

### 4. 历史记录
- 点击历史项可快速重新加载
- 存储在 `OronBox.storage` 中

## 数据编码流程

```
用户输入字符串
    │
    ▼
encodeURIComponent(str) → UTF-8字符串
    │
    ▼
逐字节转Hex → "48656c6c6f..."
    │
    ▼
OronBox.appside.send('com.oronbox.sync', hexData)
    │
    ▼
手环 interconnect.onmessage 接收
    │
    ▼
hexToString() 解码还原原始字符串
    │
    ▼
<qrcode value="原始字符串" /> 渲染二维码
```

## 打包方法

```bash
cd oronbox-sync-plugin
zip -r ../dist/oronbox-sync.obp manifest.json main.js
```

或使用打包脚本：
```bash
bash ../build-plugin.sh
```

## 导入方法

1. 在 OronBox 客户端中打开 设置 → 插件 → 导入插件
2. 选择 `oronbox-sync.obp` 文件
3. 导入后在插件列表中找到「OronBox同步器」
4. 首次运行时授权所需权限

## 依赖

- OronBox 客户端（支持 .obp 插件格式）
- 手环端需安装配套的 Vela RPK 应用（`com.oronbox.sync`）
