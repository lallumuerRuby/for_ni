-- Murmur for today — Supabase schema
-- 在 Supabase Dashboard 的 SQL Editor 執行本檔案即可建立資料表與權限。

-- ============================================================
-- 若從舊版（anon 策略）遷移，先執行此區塊移除舊 policy：
-- DROP POLICY IF EXISTS "Allow anon read cards"   ON public.cards;
-- DROP POLICY IF EXISTS "Allow anon insert cards" ON public.cards;
-- DROP POLICY IF EXISTS "Allow anon delete cards" ON public.cards;
-- DROP POLICY IF EXISTS "Allow anon read card-images"   ON storage.objects;
-- DROP POLICY IF EXISTS "Allow anon upload card-images" ON storage.objects;
-- DROP POLICY IF EXISTS "Allow anon delete card-images" ON storage.objects;
-- ============================================================

-- 1. cards 資料表
create table if not exists public.cards (
  id         uuid        primary key default gen_random_uuid(),
  type       text        not null check (type in ('text', 'image')),
  content    text,
  image_path text,       -- Storage 內的檔案路徑，純文字卡片為 null
  user_id    uuid        references auth.users(id),
  created_at timestamptz not null default now()
);

-- 純文字卡片必須有內容；圖片卡片必須有 image_path
alter table public.cards
  add constraint cards_content_or_image check (
    (type = 'text'  and content    is not null)
    or (type = 'image' and image_path is not null)
  );

-- 2. 開啟 Row Level Security
alter table public.cards enable row level security;

-- 登入使用者可讀取所有人的卡片（首頁抽卡為共享卡池）
create policy "select_all_authenticated"
  on public.cards for select
  to authenticated
  using (true);

-- 登入使用者只能新增屬於自己的卡片
create policy "insert_own_cards"
  on public.cards for insert
  to authenticated
  with check (auth.uid() = user_id);

-- 登入使用者只能刪除自己的卡片
create policy "delete_own_cards"
  on public.cards for delete
  to authenticated
  using (auth.uid() = user_id);

-- 3. Storage bucket：card-images
insert into storage.buckets (id, name, public)
values ('card-images', 'card-images', true)
on conflict (id) do nothing;

-- Storage RLS：已登入者可上傳與刪除（公開 bucket 不需 select policy 即可讀取）
create policy "auth_upload_card_images"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'card-images');

create policy "auth_delete_card_images"
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'card-images');
