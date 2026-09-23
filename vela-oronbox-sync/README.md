# OronBox同步器 - Vela手环应用

## 概述

这是运行在小米手环9/10/11及多款 Vela 手表上的 Vela 快应用（RPK包），负责接收来自 OronBox 插件的字符串数据，并使用 Vela 原生 `<qrcode>` 组件生成二维码显示在手环屏幕上。

**设计原则**：手环端只接收字符串，不存储二维码图片，最大化节省手环存储空间。

## 文件结构

```
vela-oronbox-sync/
├── package.json              # npm配置（构建脚本）
├── src/
│   ├── manifest.json         # 应用清单（包名、路由、权限、屏幕适配）
│   ├── app.ux                # 应用入口（生命周期回调）
│   ├── pages/
│   │   └── index/
│   │       └── index.ux      # 主页面（QR码展示、数据接收）
│   └── i18n/                 # 多语言
│       ├── defaults.json
│       ├── zh-CN.json
│       └── en.json
├── sign/                     # 签名文件目录（需自行生成）
└── README.md
```

## 屏幕适配

| 设备 | 分辨率 | 屏形 | designWidth | 缩放比 |
|------|--------|------|-------------|--------|
| 小米手环9 | 192×490 | 胶囊形 | 212 | 0.91 |
| 小米手环10/11 | 212×520 | 胶囊形 | 212 | 1.00 |
| 小米手环9 Pro | 336×480 | 矩形 | 212 | 1.58 |
| Xiaomi Watch S3/S4/S5 | 466–480 | 圆形 | 212 | ~2.2 |

- `designWidth: 212` 作为基准宽度，`px` 按 设备宽/212 等比缩放，二维码保持正方形
- 容器高度使用弹性布局（`flex:1`/百分比），避免方形、圆形屏纵向溢出
- `@media (shape: rect)` 缩小矩形屏二维码；`@media (shape: circle)` 增加安全区、避让圆角
- 小米手环8 Pro 因 API Level 限制不支持 `<qrcode>` 组件，无法显示二维码

## manifest.json 关键配置

| 字段 | 值 | 说明 |
|------|-----|------|
| `package` | com.oronbox.sync | 包名（与OronBox插件通信匹配） |
| `minAPILevel` | 2 | qrcode组件要求APILevel≥2 |
| `features` | system.interconnect, system.device, system.storage | 所需系统接口 |
| `config.designWidth` | 212 | 基准设计宽度（多屏等比缩放） |
| `display.fullScreen` | true | 全屏显示 |

## 数据接收流程

```
OronBox插件 appside.send('com.oronbox.sync', hexData)
    │
    ▼
Vela interconnect.onmessage 回调触发
    │
    ▼
提取 data.data 字段（Hex编码的UTF-8字符串）
    │
    ▼
isHexString() 判断是否为Hex编码
    │
    ▼
hexToString() 解码为原始字符串（支持中文、emoji）
    │
    ▼
更新 qrValue → <qrcode> 组件自动渲染二维码
    │
    ▼
storage.set() 持久化保存（重启后可恢复）
```

## 构建与安装

### 环境要求
- Node.js 16+
- AIoT-IDE（可视化IDE）或 AIoT-toolkit（命令行工具）

### 使用 AIoT-toolkit 构建

```bash
# 安装 AIoT-toolkit
npm install -g aiot-toolkit

# 进入项目目录
cd vela-oronbox-sync

# 安装依赖
npm install

# 构建debug包（生成 dist/xxx.debug.rpk）
aiot build

# 构建release包
aiot release
```

### 使用 AIoT-IDE 构建
1. 用 AIoT-IDE 打开 `vela-oronbox-sync` 目录
2. 点击「打包」按钮生成 `.debug.rpk`
3. 点击「发布」按钮生成 release 包

### 安装到手环
1. 打开小米运动健康 / Mi Fitness App
2. 连接手环
3. 在 App 中找到「设备 → 应用管理」
4. 选择构建好的 `.rpk` 文件安装

### 签名文件
首次构建前需要生成签名文件：
```bash
# 在 sign/ 目录下放置以下文件
# sign/certificate.pem  - 证书文件
# sign/private.pem      - 私钥文件
```
如果涉及与手机App通信，证书需要与手机App一致。本应用仅与OronBox通信，使用默认签名即可。

## Vela API 使用

### `<qrcode>` 组件（APILevel 2+）
```html
<qrcode value="https://iot.mi.com" style="color: #000000; background-color: #ffffff;" />
```

### `@system.interconnect`
```javascript
import interconnect from '@system.interconnect'
interconnect.onmessage = (data) => { /* 接收数据 */ }
interconnect.send({ data: 'message' })  // 发送数据
```

### `@system.device`
```javascript
import device from '@system.device'
const info = await device.getInfo()
// info.screenWidth, info.screenHeight, info.screenShape
```

### `@system.storage`
```javascript
import storage from '@system.storage'
storage.set({ key: 'key', value: 'value' })
storage.get({ key: 'key', success: (data) => {} })
```
