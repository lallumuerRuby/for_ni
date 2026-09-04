import { spawn } from 'node:child_process'
import localtunnel from 'localtunnel'
import qrcode from 'qrcode-terminal'

const PORT = Number(process.env.VITE_PORT || 5173)

const vite = spawn('npx', ['vite', '--host', '--port', String(PORT), '--strictPort'], {
  stdio: 'inherit',
  shell: true,
})

let tunnel = null

async function startTunnel() {
  try {
    tunnel = await localtunnel({ port: PORT })
    console.log('\n📱 手機掃描以下 QR Code 開啟開發伺服器（Tunnel，需連網）：')
    qrcode.generate(tunnel.url, { small: true })
    console.log(`   ${tunnel.url}\n`)

    tunnel.on('close', () => {
      console.log('Tunnel 已關閉')
    })
  } catch (err) {
    console.error('無法建立 tunnel，僅能使用本機/區網網址：', err.message)
  }
}

// 給 Vite 一點時間啟動再建立 tunnel
setTimeout(startTunnel, 1500)

function shutdown() {
  if (tunnel) tunnel.close()
  vite.kill()
  process.exit(0)
}

process.on('SIGINT', shutdown)
process.on('SIGTERM', shutdown)
vite.on('exit', (code) => {
  if (tunnel) tunnel.close()
  process.exit(code ?? 0)
})
