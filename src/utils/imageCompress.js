import imageCompression from 'browser-image-compression'
import { supabase, CARDS_BUCKET } from '../lib/supabase'

/**
 * 壓縮圖片並轉為 WebP：寬高上限 1000px、品質 0.7、目標檔案大小 ~150KB。
 * browser-image-compression 沒有直接的「品質」參數，改用 initialQuality。
 */
async function compressImage(file) {
  const options = {
    maxWidthOrHeight: 1000,
    maxSizeMB: 0.2, // 約 200KB 上限
    initialQuality: 0.7,
    fileType: 'image/webp',
    useWebWorker: true,
  }

  const compressed = await imageCompression(file, options)

  // 確保副檔名與檔名一致為 .webp
  const webpName = file.name.replace(/\.[^.]+$/, '') + '.webp'
  return new File([compressed], webpName, { type: 'image/webp' })
}

/**
 * 壓縮並上傳圖片到 Supabase Storage，回傳可存進 cards 表的 image_path 與公開 URL。
 * @param {File} file - 使用者選擇的原始圖片檔案
 * @returns {Promise<{ path: string, publicUrl: string }>}
 */
export async function uploadCardImage(file) {
  const compressedFile = await compressImage(file)

  const path = `cards/${Date.now()}-${Math.random().toString(36).slice(2)}-${compressedFile.name}`

  const { error: uploadError } = await supabase.storage
    .from(CARDS_BUCKET)
    .upload(path, compressedFile, {
      contentType: 'image/webp',
      cacheControl: '3600',
      upsert: false,
    })

  if (uploadError) throw uploadError

  const { data } = supabase.storage.from(CARDS_BUCKET).getPublicUrl(path)

  return { path, publicUrl: data.publicUrl }
}
