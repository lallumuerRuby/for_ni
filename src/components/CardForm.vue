<template>
  <form
    class="rounded-2xl border border-secondary-200 bg-white p-6 flex flex-col gap-4"
    @submit.prevent="handleSubmit"
  >
    <h2 class="text-lg font-semibold text-secondary-500">新增留言</h2>

    <div class="flex gap-2">
      <button
        type="button"
        class="flex-1 rounded-lg px-4 py-2 text-sm font-medium transition-colors"
        :class="type === 'text' ? 'bg-primary-400 text-white' : 'bg-primary-200 text-secondary-400'"
        @click="type = 'text'"
      >
        我想留言
      </button>
      <button
        type="button"
        class="flex-1 rounded-lg px-4 py-2 text-sm font-medium transition-colors"
        :class="type === 'image' ? 'bg-primary-400 text-white' : 'bg-primary-200 text-secondary-400'"
        @click="type = 'image'"
      >
        我想傳照片
      </button>
    </div>

    <div class="flex flex-col gap-1">
      <label class="text-sm text-secondary-400">文字內容</label>
      <textarea
        v-model="content"
        rows="3"
        class="rounded-lg border border-secondary-200 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-accent-300"
        :required="type === 'text'"
        placeholder="輸入想講的話..."
      />
    </div>

    <div v-if="type === 'image'" class="flex flex-col gap-1">
      <label class="text-sm text-secondary-400">選擇圖片</label>
      <input type="file" accept="image/*" @change="onFileChange" class="text-sm" />
      <p v-if="selectedFile" class="text-xs text-secondary-300">
        已選擇：{{ selectedFile.name }}
      </p>
    </div>

    <!-- 接收者選擇 -->
    <div class="flex flex-col gap-2">
      <label class="text-sm text-secondary-400">給誰抽？</label>

      <!-- 所有人 -->
      <label class="flex items-center gap-2 cursor-pointer">
        <input
          type="radio"
          name="target"
          :value="null"
          v-model="targetUserId"
          class="accent-accent-400"
        />
        <span class="text-sm text-secondary-500">所有人都可以抽</span>
      </label>

      <!-- 其他使用者 -->
      <label
        v-for="profile in profiles"
        :key="profile.id"
        class="flex items-center gap-2 cursor-pointer"
      >
        <input
          type="radio"
          name="target"
          :value="profile.id"
          v-model="targetUserId"
          class="accent-accent-400"
        />
        <img
          v-if="profile.avatar_url"
          :src="profile.avatar_url"
          class="w-6 h-6 rounded-full"
        />
        <span class="text-sm text-secondary-500">{{ profile.name }}</span>
      </label>

      <p v-if="profiles.length === 0" class="text-xs text-secondary-300">
        目前只有你一個人登入過，還沒有其他人可以選。
      </p>
    </div>

    <button
      type="submit"
      class="rounded-full bg-accent-400 hover:bg-accent-500 text-white font-medium px-6 py-2 self-start disabled:opacity-50"
      :disabled="submitting"
    >
      {{ submitting ? "上傳中..." : "新增留言卡" }}
    </button>

    <p v-if="errorMessage" class="text-red-400 text-sm">{{ errorMessage }}</p>
  </form>
</template>

<script setup>
import { ref, onMounted } from "vue";
import { supabase } from "../lib/supabase";
import { uploadCardImage } from "../utils/imageCompress";

const props = defineProps({
  user: { type: Object, required: true },
})
const emit = defineEmits(["created"]);

const type = ref("text");
const content = ref("");
const selectedFile = ref(null);
const submitting = ref(false);
const errorMessage = ref("");
const targetUserId = ref(null);
const profiles = ref([]);

onMounted(async () => {
  const { data } = await supabase
    .from('profiles')
    .select('id, name, avatar_url')
    .neq('id', props.user.id)
  profiles.value = data || []
})

function onFileChange(event) {
  selectedFile.value = event.target.files[0] || null;
}

function resetForm() {
  content.value = "";
  selectedFile.value = null;
  targetUserId.value = null;
}

async function handleSubmit() {
  errorMessage.value = "";

  if (type.value === "image" && !selectedFile.value) {
    errorMessage.value = "請選擇一張圖片。";
    return;
  }

  submitting.value = true;
  try {
    let imagePath = null;

    if (type.value === "image") {
      const { path } = await uploadCardImage(selectedFile.value);
      imagePath = path;
    }

    const { error } = await supabase.from("cards").insert({
      type: type.value,
      content: content.value || null,
      image_path: imagePath,
      user_id: props.user.id,
      target_user_id: targetUserId.value,
    });

    if (error) throw error;

    resetForm();
    emit("created");
  } catch (err) {
    console.error(err);
    errorMessage.value = "新增失敗，請稍後再試。";
  } finally {
    submitting.value = false;
  }
}
</script>
