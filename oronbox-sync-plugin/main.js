/**
 * OronBox 同步器插件 - main.js (v2.4.4)
 * ============================================
 * 功能：
 *   1. 输入 OronBox 配对链接 -> interconnect.send(pkg, text) -> 手环原生 <qrcode> 展示
 *   2. 手环回执 {"tag":"__ack__","ok":1} 时显示"已确认显示"
 *   3. 一键安装手环应用：从插件包内取出 rpk -> /data -> device.install
 */

globalThis.activate = async (plugin) => {
  const { Column, Row, Text, Button, TextField, Divider } = OronBox.ui;

  let inputText = '';
  let status = '就绪 - 输入OronBox连接链接后点击同步';
  let statusColor = '#888888';
  let isSyncing = false;
  let isInstalling = false;
  let ackConfirmed = false;

  // 目标快应用包名（与手环 manifest.json 中 package 一致）
  const VELA_PKG = 'com.oronbox.sync';
  // 内嵌在 .obp 中的手环应用安装包
  const RPK_INNER_PATH = '/plugin/app/com.oronbox.sync.rpk';
  const RPK_DATA_PATH = '/data/com.oronbox.sync.rpk';

  // ============ 工具函数 ============

  function delay(ms) {
    return new Promise(r => {
      if (typeof setTimeout === 'function') setTimeout(r, ms);
      else r();
    });
  }

  // 仅允许 OronBox 设备配对链接
  // 例：https://oronbox.zxor.org/open?source=deviceQr&name=Xiaomi+Smart+Band+9&mac=0434C31BC468&authkey=74b567eb28c30fab0e9da999d3bab807
  function isValidPairLink(str) {
    const s = (str || '').trim();
    return (
      s.indexOf('https://oronbox.zxor.org/open?') === 0 &&
      s.indexOf('mac=') >= 0 &&
      s.indexOf('authkey=') >= 0
    );
  }

  // ============ 同步逻辑 ============

  async function syncToBand() {
    if (isSyncing) return;
    if (!inputText || !inputText.trim()) {
      status = '请先输入文本';
      statusColor = '#ff4444';
      render();
      return;
    }
    if (!isValidPairLink(inputText)) {
      status = '仅支持 OronBox 连接链接（含 mac 和 authkey）';
      statusColor = '#ff4444';
      render();
      return;
    }

    isSyncing = true;
    ackConfirmed = false;
    try {
      status = '正在检查设备...';
      statusColor = '#ffaa00';
      render();

      const devices = await OronBox.device.list();
      const connected = devices.find(d => d.connected) || devices.find(d => d.current);
      if (!connected) throw new Error('请先在 OronBox 中连接手环');

      status = '正在打开手环应用...';
      statusColor = '#ffaa00';
      render();
      try {
        await OronBox.device.apps.launch(VELA_PKG);
      } catch (e) {}
      // 等待手环应用启动并建立 interconnect 会话
      await delay(2000);

      status = '正在同步...';
      statusColor = '#ffaa00';
      render();

      // 发送到当前设备
      await OronBox.interconnect.send(VELA_PKG, inputText);

      status = '已发送，等待手环确认...';
      statusColor = '#44ff44';
    } catch (e) {
      status = '失败：' + (e.message || e);
      statusColor = '#ff4444';
    } finally {
      isSyncing = false;
      render();
    }
  }

  // ============ 安装手环应用 ============

  async function installBandApp() {
    if (isInstalling) return;
    isInstalling = true;
    try {
      status = '正在读取安装包...';
      statusColor = '#ffaa00';
      render();

      const b64 = await OronBox.file.read(RPK_INNER_PATH, { encoding: 'base64' });
      if (!b64 || b64.length < 100) {
        throw new Error('插件包内未找到手环应用，请重新导入插件');
      }

      // 先卸载旧版：清掉手环端图标缓存，确保全新安装
      try {
        status = '正在检查手环上的旧版本...';
        render();
        const apps = await OronBox.device.apps.list();
        const old = (apps || []).find(a => a && a.packageName === VELA_PKG);
        if (old) {
          status = '正在卸载旧版本...';
          render();
          await OronBox.device.apps.uninstall(VELA_PKG);
          await delay(2000);
        }
      } catch (e) {
        // 卸载失败不阻塞，继续尝试安装
      }

      status = '正在写入设备...';
      statusColor = '#ffaa00';
      render();
      await OronBox.file.write(RPK_DATA_PATH, b64, { encoding: 'base64' });

      status = '正在安装到手环...';
      statusColor = '#ffaa00';
      render();
      await OronBox.device.install(RPK_DATA_PATH, {
        type: 'app',
        fileName: 'com.oronbox.sync.rpk',
      });

      status = '安装成功！请在手环查看';
      statusColor = '#44ff44';
    } catch (e) {
      status = '安装失败：' + (e.message || e);
      statusColor = '#ff4444';
    } finally {
      isInstalling = false;
      render();
    }
  }

  // ============ 手环回执监听 ============

  try {
    OronBox.interconnect.onMessage((msg) => {
      if (msg && msg.tag === '__ack__') {
        ackConfirmed = true;
        status = '手环已确认显示二维码';
        statusColor = '#44ff44';
        render();
      }
    });
  } catch (e) {}

  // ============ 渲染 ============

  function render() {
    return OronBox.ui.render(
      Column({ gap: 10, padding: 16 }, [
        Text('OronBox同步器', { size: 22, weight: 'bold', color: '#4488ff' }),

        Divider({ thickness: 1 }),

        Text('OronBox连接链接', { size: 12, color: '#aaaaaa' }),
        TextField({
          value: inputText,
          placeholder: '',
          multiline: true,
          onChange: v => { inputText = v; },
        }),

        Row({ gap: 8 }, [
          Button('清空', {
            onClick: () => {
              inputText = '';
              status = '已清空';
              statusColor = '#888888';
              render();
            },
          }),
          Button('同步到手环', {
            primary: true,
            onClick: OronBox.ui.action(syncToBand, render),
          }),
        ]),

        Divider({ thickness: 1 }),

        Text(status, { size: 12, color: statusColor }),

        Divider({ thickness: 1 }),

        Text('手环应用安装', { size: 13, weight: 'bold', color: '#aaaaaa' }),
        Button('安装手环应用', {
          onClick: OronBox.ui.action(installBandApp, render),
        }),
      ])
    );
  }

  render();
};