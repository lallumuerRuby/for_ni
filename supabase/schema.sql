-- Murmur for today — Supabase schema
-- 在 Supabase Dashboard 的 SQL Editor 執行本檔案即可建立資料表與權限。

-- 1. cards 資料表
create table if not exists public.cards (
  id uuid primary key default gen_random_uuid(),
  type text not null check (type in ('text', 'image')),
  content text,
  image_path text, -- Storage 內的檔案路徑，供刪除時同步清理，純文字卡片為 null
  created_at timestamptz not null default now()
);

-- 純文字卡片必須有內容；圖片卡片必須有 image_path
alter table public.cards
  add constraint cards_content_or_image check (
    (type = 'text' and content is not null)
    or (type = 'image' and image_path is not null)
  );

-- 2. 開啟 Row Level Security
alter table public.cards enable row level security;

-- 前台/後台皆使用 anon key，此為單人使用的簡易專案，開放 anon 完整存取。
-- 若未來需要多人或公開部署，建議改為僅 select 給 anon，寫入/刪除改用 service_role 或加上驗證。
create policy "Allow anon read cards"
  on public.cards for select
  to anon
  using (true);

create policy "Allow anon insert cards"
  on public.cards for insert
  to anon
  with check (true);

create policy "Allow anon delete cards"
  on public.cards for delete
  to anon
  using (true);

-- 3. Storage bucket：card-images
insert into storage.buckets (id, name, public)
values ('card-images', 'card-images', true)
on conflict (id) do nothing;

-- Storage RLS：允許 anon 上傳、讀取（公開 bucket 已可直接讀）、刪除 card-images 內的檔案
create policy "Allow anon read card-images"
  on storage.objects for select
  to anon
  using (bucket_id = 'card-images');

create policy "Allow anon upload card-images"
  on storage.objects for insert
  to anon
  with check (bucket_id = 'card-images');

create policy "Allow anon delete card-images"
  on storage.objects for delete
  to anon
  using (bucket_id = 'card-images');
