import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

// base 會在 GitHub Actions 中依 repo 名稱自動設定 (見 .github/workflows/deploy.yml)
// 本機開發或未設定時預設為 '/'
export default defineConfig({
  base: process.env.VITE_BASE_PATH || '/',
  plugins: [vue()],
  server: {
    host: true,
    allowedHosts: true
  }
})
