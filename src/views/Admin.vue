<template>
  <div class="min-h-screen flex flex-col items-center gap-8 px-4 py-12">
    <header class="text-center">
      <h1 class="text-2xl font-bold text-secondary-500">( ˘ ³˘)♥ 留言板 ( ˘ ³˘)♥</h1>
      <router-link to="/" class="text-xs text-secondary-300 hover:text-secondary-400">
        返回抽卡
      </router-link>
    </header>

    <div class="w-full max-w-xl flex flex-col gap-6">
      <CardForm @created="loadCards" />
      <CardList :cards="cards" @deleted="onDeleted" />
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { supabase, CARDS_BUCKET } from '../lib/supabase'
import CardForm from '../components/CardForm.vue'
import CardList from '../components/CardList.vue'

const cards = ref([])

function withPublicUrl(card) {
  if (card.type === 'image' && card.image_path) {
    const { data } = supabase.storage.from(CARDS_BUCKET).getPublicUrl(card.image_path)
    return { ...card, image_url: data.publicUrl }
  }
  return card
}

async function loadCards() {
  const { data, error } = await supabase
    .from('cards')
    .select('id, type, content, image_path, created_at')
    .order('created_at', { ascending: false })

  if (error) {
    console.error(error)
    return
  }
  cards.value = (data || []).map(withPublicUrl)
}

function onDeleted(id) {
  cards.value = cards.value.filter((c) => c.id !== id)
}

onMounted(loadCards)
</script>
