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

-- 1. profiles 表（存放 Google 帳號名稱供接收者選單使用）
create table if not exists public.profiles (
  id         uuid        primary key references auth.users(id) on delete cascade,
  name       text,
  avatar_url text,
  updated_at timestamptz default now()
);

alter table public.profiles enable row level security;

create policy "profiles_select" on public.profiles
  for select to authenticated using (true);

create policy "profiles_insert" on public.profiles
  for insert to authenticated with check (auth.uid() = id);

create policy "profiles_update" on public.profiles
  for update to authenticated using (auth.uid() = id);

-- 2. cards 資料表
create table if not exists public.cards (
  id             uuid        primary key default gen_random_uuid(),
  type           text        not null check (type in ('text', 'image')),
  content        text,
  image_path     text,       -- Storage 內的檔案路徑，純文字卡片為 null
  user_id        uuid        references auth.users(id),
  target_user_id uuid        references auth.users(id), -- null = 所有人可抽
  created_at     timestamptz not null default now()
);

-- 純文字卡片必須有內容；圖片卡片必須有 image_path
alter table public.cards
  add constraint cards_content_or_image check (
    (type = 'text'  and content    is not null)
    or (type = 'image' and image_path is not null)
  );

-- 3. 開啟 Row Level Security
alter table public.cards enable row level security;

-- 只能看到「給自己」或「給所有人（null）」的卡片
create policy "select_targeted_or_public"
  on public.cards for select
  to authenticated
  using (target_user_id is null or target_user_id = auth.uid());

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

-- 4. Storage bucket：card-images
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
