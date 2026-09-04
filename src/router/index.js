import { createRouter, createWebHashHistory } from 'vue-router'
import Home from '../views/Home.vue'
import Admin from '../views/Admin.vue'
import { supabase } from '../lib/supabase'

// 使用 hash 模式，避免 GitHub Pages 對 history 模式路由需要額外的 404.html 轉址設定
const router = createRouter({
  history: createWebHashHistory(),
  routes: [
    { path: '/', name: 'home', component: Home },
    { path: '/admin', name: 'admin', component: Admin },
  ],
})

router.beforeEach(async (to) => {
  if (to.name === 'admin') {
    const { data: { session } } = await supabase.auth.getSession()
    if (!session) return { name: 'home' }
  }
})

export default router
