# Vela 应用签名文件

此目录用于存放 Vela RPK 应用的签名文件。

## 需要的文件

- `certificate.pem` - 证书文件
- `private.pem` - 私钥文件

## 生成方法

### 方法 1：使用 OpenSSL 生成

```bash
# 生成私钥
openssl genrsa -out private.pem 2048

# 生成自签名证书
openssl req -new -x509 -key private.pem -out certificate.pem -days 3650 \
  -subj "/CN=OronBoxSync/O=OronBox Community/C=CN"
```

### 方法 2：通过 AIoT-IDE 生成

1. 打开 AIoT-IDE
2. 打开项目目录 `vela-oronbox-sync`
3. 在工具栏选择「生成签名」
4. IDE 会自动在 `sign/` 目录生成签名文件

### 方法 3：通过 AIoT-toolkit 生成

```bash
cd vela-oronbox-sync
aiot genSign
```

## 注意事项

- 如果应用涉及与手机 App 通信（interconnect），签名证书需要与手机 App 一致
- 本应用仅与 OronBox 通信，使用自签名证书即可
- 签名文件一旦生成并发布，不要更改，否则已安装的应用将无法更新
- **请勿将签名文件提交到 Git 仓库**（.gitignore 已排除）
