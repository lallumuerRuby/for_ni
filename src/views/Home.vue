<template>
  <!-- 載入中畫面 -->
  <div v-if="!imagesReady" class="min-h-screen bg-primary-100 flex flex-col items-center justify-center gap-4">
    <p class="text-secondary-400 text-sm" style="font-family: 'Shrikhand', cursive;">Guess Who?</p>
    <div class="w-48 h-2 bg-primary-200 rounded-full overflow-hidden">
      <div
        class="h-full bg-accent-400 rounded-full transition-all duration-300 ease-out"
        :style="{ width: loadProgress + '%' }"
      />
    </div>
    <p class="text-secondary-300 text-xs">{{ loadProgress }}%</p>
  </div>

  <Transition name="fade-page">
  <div
    v-if="imagesReady"
    class="relative h-screen overflow-hidden flex flex-col items-center justify-center gap-6 px-4 py-12"
    :style="{
      backgroundImage: `url(${sanrioBg})`,
      backgroundSize: 'cover',
      backgroundPosition: 'center',
      backgroundRepeat: 'no-repeat',
    }"
  >
    <!-- 右上角使用者資訊 -->
    <div class="absolute top-4 right-4 flex items-center gap-2">
      <template v-if="user">
        <img :src="user.user_metadata.avatar_url" class="w-8 h-8 rounded-full shadow" />
        <span class="text-xs text-secondary-400 hidden sm:inline">{{ user.user_metadata.name }}</span>
        <button
          class="text-xs text-secondary-300 hover:text-secondary-500 bg-white/60 px-2 py-1 rounded-full transition-colors"
          @click="signOut"
        >登出</button>
      </template>
    </div>

    <header class="text-center">
      <h1 class="text-5xl text-secondary-500" style="font-family: 'Shrikhand', cursive;">Guess Who?</h1>
      <p class="text-secondary-400 mt-2">♡〜٩( ˃́▿˂̀ )۶〜♡</p>
    </header>

    <!-- 未登入提示 -->
    <p v-if="!user" class="text-secondary-400 text-xs bg-white/60 px-3 py-1 rounded-full">
      點擊扭蛋機以 Google 登入 ♡
    </p>

    <!-- 扭蛋機 -->
    <button
      class="relative inline-block select-none transition-opacity disabled:pointer-events-none"
      :class="[{ shake: isShaking }, 'cursor-pointer']"
      :disabled="isShaking || loading || (user && cards.length === 0)"
      @click="handleDraw"
    >
      <img
        :src="eggMachine"
        alt="扭蛋機"
        class="w-80 drop-shadow-xl"
      />
    </button>

    <!-- <p v-if="drawnToday" class="text-secondary-400 text-sm bg-white/70 px-4 py-2 rounded-full">
      今天已經抽過囉！明天再來 ♡
    </p> -->

    <p v-if="errorMessage" class="text-red-400 text-sm bg-white/70 px-4 py-1 rounded-full">
      {{ errorMessage }}
    </p>
    <p v-else-if="user && !loading && !systemHasCards" class="text-secondary-400 text-sm bg-white/70 px-4 py-2 rounded-full">
      目前還沒有任何留言卡，快去留言吧！
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
      v-if="user"
      to="/admin"
      class="text-xs text-secondary-300 hover:text-secondary-400"
    >
      我要留言
    </router-link>
  </div>
  </Transition>
</template>

<script setup>
import { ref, onMounted, watch } from "vue";
import sanrioBg from "../assets/images/sanrio.jpg";
import eggMachine from "../assets/images/egg_machine.webp";
import { supabase, CARDS_BUCKET } from "../lib/supabase";
import { useAuth } from "../composables/useAuth";

const { user, signInWithGoogle, signOut } = useAuth();

const cards = ref([]);
const currentCard = ref(null);
const loading = ref(false);
const isShaking = ref(false);
const errorMessage = ref("");
const imagesReady = ref(false);
const loadProgress = ref(0);
const drawnToday = ref(false);
const systemHasCards = ref(true);

const DRAW_KEY = "last_draw_date";

function todayString() {
  return new Date().toLocaleDateString("zh-TW");
}

function checkDrawnToday() {
  // drawnToday.value = localStorage.getItem(DRAW_KEY) === todayString();
}

function markDrawnToday() {
  // localStorage.setItem(DRAW_KEY, todayString());
  // drawnToday.value = true;
}

function preloadImage(src, onProgress) {
  return new Promise((resolve) => {
    const img = new Image();
    img.onload = () => { onProgress(); resolve(); };
    img.onerror = () => { onProgress(); resolve(); };
    img.src = src;
  });
}

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
  if (!user.value) return;
  loading.value = true;
  errorMessage.value = "";

  const [cardsResult, hasCardsResult] = await Promise.all([
    supabase.from("cards").select("id, type, content, image_path"),
    supabase.rpc("has_any_cards"),
  ]);

  if (cardsResult.error) {
    errorMessage.value = "卡片載入失敗，請稍後再試。";
    console.error(cardsResult.error);
  } else {
    cards.value = (cardsResult.data || []).map(withPublicUrl);
  }

  systemHasCards.value = hasCardsResult.data ?? true;
  loading.value = false;
}

async function handleDraw() {
  if (!user.value) {
    await signInWithGoogle();
    return;
  }
  if (isShaking.value || loading.value || cards.value.length === 0/* || drawnToday.value*/) return;
  currentCard.value = null;
  isShaking.value = true;

  await new Promise((resolve) => setTimeout(resolve, 750));
  isShaking.value = false;

  const index = Math.floor(Math.random() * cards.value.length);
  currentCard.value = cards.value[index];
  markDrawnToday();
}

// 登入狀態就緒後才載卡（useAuth 的 session 是非同步取得的）
watch(user, (newUser) => {
  if (newUser) loadCards();
  else cards.value = [];
})

onMounted(async () => {
  const total = 2;
  let done = 0;
  const onProgress = () => {
    done += 1;
    loadProgress.value = Math.round((done / total) * 100);
  };
  await Promise.all([
    preloadImage(sanrioBg, onProgress),
    preloadImage(eggMachine, onProgress),
  ]);
  imagesReady.value = true;
  checkDrawnToday();
});
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

.fade-page-enter-active {
  transition: opacity 0.4s ease;
}
.fade-page-enter-from {
  opacity: 0;
}
</style>
