-- Pencatatan pemakaian untuk membatasi penyalahgunaan Edge Function
-- (StudyBuddy AI dan Bukti Progres). Hanya Edge Function (service role)
-- yang boleh menulis/membaca; aplikasi tidak punya akses langsung.
create table if not exists public.usage_log (
  id bigint generated always as identity primary key,
  user_id uuid not null,
  kind text not null,
  created_at timestamptz not null default now()
);
create index if not exists usage_log_lookup
  on public.usage_log (user_id, kind, created_at desc);
alter table public.usage_log enable row level security; -- tanpa policy = tertutup

-- Salinan catatan segel di server (hash saja, bukan isi data pengguna).
create table if not exists public.seal_records (
  id bigint generated always as identity primary key,
  user_id uuid not null,
  hash text not null,
  tx_hash text not null,
  created_at timestamptz not null default now()
);
alter table public.seal_records enable row level security;
create policy "pengguna melihat segelnya sendiri" on public.seal_records
  for select using (auth.uid() = user_id);
