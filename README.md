# Murmur for today

一個溫馨小巧的抽卡網站：前台隨機抽取一張文字或圖片卡片，後台可管理卡片內容。使用 Vite + Vue 3 + Tailwind CSS + Supabase 建置，並透過 GitHub Actions 部署到 GitHub Pages。

## 技術棧

- 前端：Vite + Vue 3 + Vue Router（hash 模式）+ Tailwind CSS
- 後端：Supabase（PostgreSQL + Storage，透過 `@supabase/supabase-js`）
- 圖片壓縮：`browser-image-compression`（上傳前轉 WebP、壓縮至 1000px / ~150KB 內）
- 部署：GitHub Actions → GitHub Pages

## 本機開發

```bash
npm install
cp .env.example .env   # 填入你的 Supabase URL 與 anon key
npm run dev
```

## Supabase 設定

1. 在 Supabase Dashboard 的 SQL Editor 執行 [`supabase/schema.sql`](supabase/schema.sql)，會建立：
   - `cards` 資料表（`id`, `type`, `content`, `image_path`, `created_at`）
   - `card-images` public storage bucket
   - 對應的 RLS policies（開放 anon 讀寫，適合單人使用的簡易專案）
2. 到 Project Settings → API，取得 `Project URL` 與 `anon public` key，填入 `.env`。

> 注意：目前 RLS 對 `anon` 角色開放完整的新增/刪除權限，`/admin` 路由也沒有登入驗證，僅適合個人使用或搭配「不公開連結」的方式管理。若要多人使用或正式公開，建議加上 Supabase Auth 驗證，並將寫入/刪除權限收斂到已登入使用者或 `service_role`。

## GitHub Pages 部署

1. 到 repo 的 **Settings → Pages**，Source 選擇 **GitHub Actions**。
2. 到 **Settings → Secrets and variables → Actions**，新增兩個 repository secrets：
   - `VITE_SUPABASE_URL`
   - `VITE_SUPABASE_ANON_KEY`
3. push 到 `main` 分支即會自動觸發 [`.github/workflows/deploy.yml`](.github/workflows/deploy.yml)：
   - 自動安裝依賴、build
   - 依 repo 名稱自動計算 Vite 的 `base` 路徑（`https://<user>.github.io/<repo>/`），若 repo 名稱是 `<user>.github.io` 則 base 為 `/`
   - 透過 `actions/deploy-pages` 部署

## 專案結構

```
src/
  components/
    CardDisplay.vue   # 前台抽卡展示卡片
    CardForm.vue      # 後台新增卡片表單（含圖片壓縮上傳）
    CardList.vue      # 後台卡片列表與刪除（含 Storage 清理）
  lib/supabase.js      # Supabase client 初始化
  utils/imageCompress.js # 圖片壓縮 + 上傳到 Storage
  views/
    Home.vue           # 前台首頁
    Admin.vue          # 後台管理頁
supabase/schema.sql     # 資料表 + Storage bucket + RLS policies
.github/workflows/deploy.yml
```

## 色彩計畫

`tailwind.config.js` 已加入 `primary` / `secondary` / `accent` 三組自訂色階（100～500），可於 class 中直接使用，例如 `bg-primary-100`、`text-secondary-500`、`bg-accent-400`。
