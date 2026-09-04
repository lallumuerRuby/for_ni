<template>
  <div
    class="min-h-screen flex flex-col items-center justify-center gap-6 px-4 py-12"
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

    <!-- 扭蛋機 -->
    <div class="relative inline-block select-none">
      <img
        ref="machineRef"
        :src="eggMachine"
        alt="扭蛋機"
        class="w-80 drop-shadow-xl"
        :class="{ shake: isShaking }"
      />
      <!-- 透明按鈕疊在右下角藍色兔子面板 -->
      <button
        class="absolute rounded-lg transition-opacity duration-200 opacity-0 hover:opacity-30 hover:bg-white active:opacity-40 disabled:pointer-events-none"
        style="bottom: 8%; right: 4%; width: 33%; height: 17%;"
        :disabled="isShaking || loading || cards.length === 0"
        @click="handleDraw"
        title="轉動扭蛋機！"
      />
    </div>

    <p v-if="errorMessage" class="text-red-400 text-sm bg-white/70 px-4 py-1 rounded-full">
      {{ errorMessage }}
    </p>
    <p v-else-if="!loading && cards.length === 0" class="text-secondary-400 text-sm bg-white/70 px-4 py-2 rounded-full">
      目前還沒有任何卡片，請先到後台新增。
    </p>

    <!-- 彈出的卡片 Modal -->
    <Transition name="bounce-card">
      <div
        v-if="currentCard && !isShaking"
        class="fixed inset-0 z-50 flex items-center justify-center px-6"
        @click.self="currentCard = null"
      >
        <!-- 半透明遮罩 -->
        <div class="absolute inset-0 bg-black/30 backdrop-blur-sm" @click="currentCard = null" />

        <!-- 卡片本體 -->
        <div class="relative bg-white rounded-2xl border border-accent-300 shadow-2xl p-8 max-w-sm w-full flex flex-col items-center gap-4">
          <!-- 關閉按鈕 -->
          <button
            class="absolute top-3 right-3 w-7 h-7 flex items-center justify-center rounded-full bg-secondary-100 hover:bg-secondary-200 text-secondary-400 hover:text-secondary-600 transition-colors text-sm font-bold leading-none"
            @click="currentCard = null"
          >
            ✕
          </button>

          <img
            v-if="currentCard.type === 'image' && currentCard.image_url"
            :src="currentCard.image_url"
            :alt="currentCard.content || 'card image'"
            class="max-h-56 rounded-xl object-cover"
          />
          <p
            v-if="currentCard.content"
            class="text-center text-lg leading-relaxed"
            :class="currentCard.type === 'image' ? 'text-secondary-400 text-sm' : 'text-secondary-500'"
          >
            {{ currentCard.content }}
          </p>
        </div>
      </div>
    </Transition>

    <router-link
      to="/admin"
      class="text-xs text-secondary-300 hover:text-secondary-400"
    >
      我要留言
    </router-link>
  </div>
</template>

<script setup>
import { ref, onMounted } from "vue";
import sanrioBg from "../assets/images/sanrio.jpg";
import eggMachine from "../assets/images/egg_machine.png";
import { supabase, CARDS_BUCKET } from "../lib/supabase";

const cards = ref([]);
const currentCard = ref(null);
const loading = ref(false);
const isShaking = ref(false);
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

async function handleDraw() {
  if (isShaking.value || loading.value || cards.value.length === 0) return;
  currentCard.value = null;
  isShaking.value = true;

  await new Promise((resolve) => setTimeout(resolve, 750));
  isShaking.value = false;

  const index = Math.floor(Math.random() * cards.value.length);
  currentCard.value = cards.value[index];
}

onMounted(loadCards);
</script>

<style scoped>
@keyframes shake {
  0%, 100% { transform: rotate(0deg) translateX(0); }
  12%  { transform: rotate(-8deg) translateX(-4px); }
  25%  { transform: rotate(8deg)  translateX(4px); }
  37%  { transform: rotate(-6deg) translateX(-3px); }
  50%  { transform: rotate(6deg)  translateX(3px); }
  62%  { transform: rotate(-4deg) translateX(-2px); }
  75%  { transform: rotate(4deg)  translateX(2px); }
  87%  { transform: rotate(-2deg) translateX(-1px); }
}

.shake {
  animation: shake 0.75s ease-in-out;
  transform-origin: center bottom;
}

@keyframes bounceIn {
  0%   { transform: scale(0.3) translateY(-40px); opacity: 0; }
  55%  { transform: scale(1.08) translateY(6px);  opacity: 1; }
  75%  { transform: scale(0.95) translateY(-3px); }
  90%  { transform: scale(1.02) translateY(1px); }
  100% { transform: scale(1)    translateY(0);    opacity: 1; }
}

.bounce-card-enter-active {
  animation: bounceIn 0.55s cubic-bezier(0.34, 1.56, 0.64, 1);
}

.bounce-card-leave-active {
  transition: opacity 0.15s ease-out, transform 0.15s ease-out;
}

.bounce-card-leave-to {
  opacity: 0;
  transform: scale(0.9);
}
</style>
