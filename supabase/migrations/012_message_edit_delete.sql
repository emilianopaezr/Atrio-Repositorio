-- 012_message_edit_delete.sql
-- Allow users to edit and delete (soft-delete) their own messages.

-- 1. Add columns for edit/delete tracking
alter table public.messages
  add column if not exists edited_at timestamptz,
  add column if not exists is_deleted boolean not null default false;

-- 2. DELETE policy: only the sender can hard-delete their own message
drop policy if exists "Users can delete own messages" on public.messages;
create policy "Users can delete own messages"
on public.messages for delete
to authenticated
using (sender_id = auth.uid());

-- 3. Tighten UPDATE: anyone in the conversation can mark messages as read,
--    but only the sender can edit text/soft-delete. We keep the existing
--    broad UPDATE policy (used for is_read) and add an additional sender
--    check is not possible for the same operation. Instead, we add a
--    BEFORE UPDATE trigger that prevents non-senders from changing text,
--    image_url, edited_at or is_deleted.
create or replace function public.messages_guard_edits()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() <> old.sender_id then
    -- Non-senders may only flip is_read.
    if new.text is distinct from old.text
       or new.image_url is distinct from old.image_url
       or new.edited_at is distinct from old.edited_at
       or new.is_deleted is distinct from old.is_deleted
       or new.type is distinct from old.type then
      raise exception 'Only the sender can edit or delete this message';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists messages_guard_edits_trg on public.messages;
create trigger messages_guard_edits_trg
before update on public.messages
for each row execute function public.messages_guard_edits();
