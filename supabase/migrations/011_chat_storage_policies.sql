-- 011_chat_storage_policies.sql
-- Ensure the 'chat' storage bucket exists, is private, and has correct
-- row-level security policies so authenticated users can upload images
-- to a folder owned by themselves: {auth.uid()}/{conversationId}/{file}

-- 1. Make sure the bucket exists and is private
insert into storage.buckets (id, name, public)
values ('chat', 'chat', false)
on conflict (id) do update set public = false;

-- 2. Drop any previous policies that target the chat bucket so we start clean
do $$
declare
  pol record;
begin
  for pol in
    select policyname
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and (qual ilike '%''chat''%' or with_check ilike '%''chat''%')
  loop
    execute format('drop policy if exists %I on storage.objects', pol.policyname);
  end loop;
end$$;

-- 3. INSERT: an authenticated user can upload only into their own root folder
create policy "chat_insert_own_folder"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'chat'
  and (storage.foldername(name))[1] = auth.uid()::text
);

-- 4. SELECT: an authenticated user can read any object in the chat bucket
--    (chat images are exchanged via signed URLs anyway, but participants
--     of a conversation also need raw access in case the URL expires).
create policy "chat_select_authenticated"
on storage.objects for select
to authenticated
using (bucket_id = 'chat');

-- 5. UPDATE / DELETE: only the owner (first folder = auth.uid())
create policy "chat_update_own_folder"
on storage.objects for update
to authenticated
using (
  bucket_id = 'chat'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'chat'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "chat_delete_own_folder"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'chat'
  and (storage.foldername(name))[1] = auth.uid()::text
);
