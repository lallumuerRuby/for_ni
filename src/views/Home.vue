<template>
  <div
    class="min-h-screen flex flex-col items-center justify-center gap-8 px-4 py-12"
    :style="{
      backgroundImage: `url(${sanrioBg})`,
      backgroundSize: 'cover',
      backgroundPosition: 'center',
      backgroundRepeat: 'no-repeat',
    }"
  >
    <header class="text-center">
      <h1 class="text-5xl text-secondary-500" style="font-family: 'Shrikhand', cursive;">Guess Who?</h1>
      <p class="text-secondary-400 mt-2">♡〜٩( ˃́▿˂̀ )۶〜♡</p>
    </header>

    <CardDisplay :card="currentCard" />

    <button
      class="rounded-full bg-accent-400 hover:bg-accent-500 text-white font-medium px-8 py-3 shadow-sm transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
      :disabled="loading || cards.length === 0"
      @click="drawCard"
    >
      {{ loading ? "抽取中..." : "GO!" }}
    </button>

    <p v-if="errorMessage" class="text-red-400 text-sm">{{ errorMessage }}</p>
    <p
      v-else-if="!loading && cards.length === 0"
      class="text-secondary-300 text-sm"
    >
      目前還沒有任何卡片，請先到後台新增。
    </p>

    <router-link
      to="/admin"
      class="text-xs text-secondary-300 hover:text-secondary-400 mt-4"
    >
      我要留言
    </router-link>
  </div>
</template>

<script setup>
import { ref, onMounted } from "vue";
import sanrioBg from "../assets/images/sanrio.jpg";
import { supabase, CARDS_BUCKET } from "../lib/supabase";
import CardDisplay from "../components/CardDisplay.vue";

const cards = ref([]);
const currentCard = ref(null);
const loading = ref(false);
const errorMessage = ref("");

function withPublicUrl(card) {
  if (card.type === "image" && card.image_path) {
    const { data } = supabase.storage
      .from(CARDS_BUCKET)
      .getPublicUrl(card.image_path);
    return { ...card, image_url: data.publicUrl };
  }
  return card;
}

async function loadCards() {
  loading.value = true;
  errorMessage.value = "";
  const { data, error } = await supabase
    .from("cards")
    .select("id, type, content, image_path");

  if (error) {
    errorMessage.value = "卡片載入失敗，請稍後再試。";
    console.error(error);
  } else {
    cards.value = (data || []).map(withPublicUrl);
  }
  loading.value = false;
}

function drawCard() {
  if (cards.value.length === 0) return;
  const index = Math.floor(Math.random() * cards.value.length);
  currentCard.value = cards.value[index];
}

onMounted(loadCards);
</script>
