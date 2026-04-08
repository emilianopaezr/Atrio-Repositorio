-- 013_reports_table.sql
-- User-generated reports for conversations, users, listings, etc.
-- Used by the chat "Reportar" action and any future report-content flow.

create table if not exists public.reports (
  id              uuid primary key default gen_random_uuid(),
  reporter_id     uuid not null references auth.users(id) on delete cascade,
  target_type     text not null check (target_type in ('user','conversation','listing','message','review')),
  target_id       uuid not null,
  reason          text not null,
  details         text,
  status          text not null default 'pending' check (status in ('pending','reviewing','resolved','dismissed')),
  created_at      timestamptz not null default now(),
  resolved_at     timestamptz
);

create index if not exists idx_reports_reporter on public.reports(reporter_id);
create index if not exists idx_reports_target on public.reports(target_type, target_id);
create index if not exists idx_reports_status on public.reports(status);

alter table public.reports enable row level security;

-- A user can create reports as themselves
drop policy if exists "Users can create own reports" on public.reports;
create policy "Users can create own reports"
on public.reports for insert
to authenticated
with check (reporter_id = auth.uid());

-- A user can read their own reports (for transparency / "your reports" view)
drop policy if exists "Users can read own reports" on public.reports;
create policy "Users can read own reports"
on public.reports for select
to authenticated
using (reporter_id = auth.uid());

-- No update / delete from clients - moderation handled server-side / dashboard.
