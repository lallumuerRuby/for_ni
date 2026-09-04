import { ref, onMounted, onUnmounted } from 'vue'
import { supabase } from '../lib/supabase'

export function useAuth() {
  const user = ref(null)
  let subscription

  onMounted(async () => {
    const { data: { session } } = await supabase.auth.getSession()
    user.value = session?.user ?? null

    const { data } = supabase.auth.onAuthStateChange((_event, session) => {
      user.value = session?.user ?? null
    })
    subscription = data.subscription
  })

  onUnmounted(() => subscription?.unsubscribe())

  async function signInWithGoogle() {
    await supabase.auth.signInWithOAuth({
      provider: 'google',
      options: { redirectTo: window.location.origin + import.meta.env.BASE_URL },
    })
  }

  async function signOut() {
    await supabase.auth.signOut()
  }

  return { user, signInWithGoogle, signOut }
}
