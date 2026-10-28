insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'checklist-documents',
  'checklist-documents',
  false,
  10485760,
  array['application/pdf', 'image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
  public = false,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create table if not exists public.checklist_documents (
  storage_path text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  checklist_rid text not null,
  file_name text not null,
  content_type text not null,
  file_hash text not null check (file_hash ~ '^[0-9a-f]{64}$'),
  file_size bigint not null check (file_size > 0 and file_size <= 10485760),
  created_at timestamptz not null default now(),
  check (storage_path like (user_id::text || '/%'))
);
create index if not exists checklist_documents_owner_rid
  on public.checklist_documents(user_id, checklist_rid, created_at desc);
alter table public.checklist_documents enable row level security;
create policy "pengguna mengelola metadata dokumen sendiri"
  on public.checklist_documents
  for all
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "pengguna mengelola dokumen checklist sendiri"
on storage.objects
for all
to authenticated
using (
  bucket_id = 'checklist-documents'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'checklist-documents'
  and (storage.foldername(name))[1] = auth.uid()::text
);
