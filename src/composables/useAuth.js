import { ref, onMounted, onUnmounted } from 'vue'
import { supabase } from '../lib/supabase'

async function upsertProfile(user) {
  const { error } = await supabase.from('profiles').upsert({
    id: user.id,
    name: user.user_metadata.name,
    avatar_url: user.user_metadata.avatar_url,
    updated_at: new Date().toISOString(),
  })
  if (error) console.error('[upsertProfile]', error)
  else console.log('[upsertProfile] ok', user.user_metadata.name)
}

export function useAuth() {
  const user = ref(null)
  let subscription

  onMounted(async () => {
    const { data: { session } } = await supabase.auth.getSession()
    user.value = session?.user ?? null
    if (session?.user) upsertProfile(session.user)

    const { data } = supabase.auth.onAuthStateChange((event, session) => {
      user.value = session?.user ?? null
      if (event === 'SIGNED_IN' && session?.user) {
        upsertProfile(session.user)
      }
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
