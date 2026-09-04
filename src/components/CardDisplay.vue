<template>
  <div
    class="w-full max-w-md rounded-2xl border border-accent-300 bg-white shadow-sm p-8 flex flex-col items-center gap-4 min-h-[280px] justify-center"
  >
    <template v-if="card">
      <img
        v-if="card.type === 'image' && card.image_url"
        :src="card.image_url"
        :alt="card.content || 'card image'"
        class="max-h-64 rounded-xl object-cover"
      />
      <p
        v-if="card.content"
        class="text-center text-lg leading-relaxed"
        :class="card.type === 'image' ? 'text-secondary-400 text-sm mt-2' : 'text-secondary-500'"
      >
        {{ card.content }}
      </p>
    </template>
    <p v-else class="text-secondary-300">快抽卡!</p>
  </div>
</template>

<script setup>
defineProps({
  card: {
    type: Object,
    default: null,
  },
})
</script>
