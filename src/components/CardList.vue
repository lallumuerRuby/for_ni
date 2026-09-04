<template>
  <div class="rounded-2xl border border-secondary-200 bg-white p-6 flex flex-col gap-3">
    <h2 class="text-lg font-semibold text-secondary-500">所有留言卡 ({{ cards.length }})</h2>

    <p v-if="cards.length === 0" class="text-secondary-300 text-sm">目前尚無卡片。</p>

    <ul class="flex flex-col gap-2">
      <li
        v-for="card in cards"
        :key="card.id"
        class="flex items-center gap-3 rounded-lg border border-secondary-100 p-3"
      >
        <img
          v-if="card.type === 'image' && card.image_url"
          :src="card.image_url"
          class="w-14 h-14 object-cover rounded-md flex-shrink-0"
        />
        <div class="flex-1 min-w-0">
          <span class="text-xs text-secondary-300">{{ card.type === 'image' ? '圖片卡片' : '純文字卡片' }}</span>
          <p class="text-sm text-secondary-500 truncate">{{ card.content || '(無文字)' }}</p>
        </div>
        <button
          class="text-xs text-red-400 hover:text-red-500 px-3 py-1 rounded-full border border-red-200 disabled:opacity-50"
          :disabled="deletingId === card.id"
          @click="handleDelete(card)"
        >
          {{ deletingId === card.id ? '刪除中...' : '刪除' }}
        </button>
      </li>
    </ul>

    <p v-if="errorMessage" class="text-red-400 text-sm">{{ errorMessage }}</p>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { supabase, CARDS_BUCKET } from '../lib/supabase'

const props = defineProps({
  cards: {
    type: Array,
    required: true,
  },
})

const emit = defineEmits(['deleted'])

const deletingId = ref(null)
const errorMessage = ref('')

async function handleDelete(card) {
  errorMessage.value = ''
  deletingId.value = card.id

  try {
    // 先刪除資料庫紀錄，再清理 Storage 內對應的圖片檔案，避免殘留無用檔案佔用容量
    const { error: deleteError } = await supabase.from('cards').delete().eq('id', card.id)
    if (deleteError) throw deleteError

    if (card.type === 'image' && card.image_path) {
      const { error: storageError } = await supabase.storage
        .from(CARDS_BUCKET)
        .remove([card.image_path])
      if (storageError) {
        console.error('Storage 刪除失敗:', storageError)
      }
    }

    emit('deleted', card.id)
  } catch (err) {
    console.error(err)
    errorMessage.value = '刪除失敗，請稍後再試。'
  } finally {
    deletingId.value = null
  }
}
</script>
