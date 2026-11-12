-- ASCII 상영관 저장소 설정
-- Supabase 대시보드 → SQL Editor → New query 에 전부 붙여넣고 Run 하세요.

-- 1) 상영작 테이블
create table if not exists public.shows (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid() references auth.users(id) on delete cascade,
  author_name text not null default '친구' check (char_length(author_name) <= 40),
  title       text not null check (char_length(title) between 1 and 40),
  note        text not null default '' check (char_length(note) <= 80),
  prompt      text not null default '' check (char_length(prompt) <= 20000),
  html        text not null check (char_length(html) between 20 and 230000),
  created_at  timestamptz not null default now()
);
-- 미리보기 사진 (작은 JPEG, 올릴 때 사이트가 자동으로 찍음)
alter table public.shows add column if not exists thumb text not null default '' check (char_length(thumb) <= 300000);
create index if not exists shows_created_at_idx on public.shows (created_at desc);

-- 2) 관리자 목록 (여기 있는 사람은 남의 상영작도 내릴 수 있음)
create table if not exists public.admins (
  user_id uuid primary key references auth.users(id) on delete cascade
);

-- 3) 접근 규칙
alter table public.shows  enable row level security;
alter table public.admins enable row level security;

drop policy if exists "누구나 상영작 보기"      on public.shows;
drop policy if exists "로그인하면 올리기"        on public.shows;
drop policy if exists "내 것 또는 관리자 삭제"   on public.shows;
drop policy if exists "관리자 본인 확인"         on public.admins;

create policy "누구나 상영작 보기" on public.shows
  for select to anon, authenticated using (true);

create policy "로그인하면 올리기" on public.shows
  for insert to authenticated with check (user_id = auth.uid());

create policy "내 것 또는 관리자 삭제" on public.shows
  for delete to authenticated using (
    user_id = auth.uid()
    or exists (select 1 from public.admins a where a.user_id = auth.uid())
  );

create policy "관리자 본인 확인" on public.admins
  for select to authenticated using (user_id = auth.uid());

-- 미리보기 사진만 고칠 수 있게 (내 것 또는 관리자)
revoke update on public.shows from anon, authenticated;
grant update (thumb) on public.shows to authenticated;
drop policy if exists "내 것 또는 관리자 썸네일 수정" on public.shows;
create policy "내 것 또는 관리자 썸네일 수정" on public.shows
  for update to authenticated
  using (user_id = auth.uid() or exists (select 1 from public.admins a where a.user_id = auth.uid()))
  with check (user_id = auth.uid() or exists (select 1 from public.admins a where a.user_id = auth.uid()));

-- 4) 도배 방지: 한 사람당 하루 20편까지
create or replace function public.limit_daily_shows()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if (select count(*) from public.shows
      where user_id = auth.uid() and created_at > now() - interval '1 day') >= 20 then
    raise exception '하루에 20편까지 올릴 수 있어요';
  end if;
  return new;
end;
$$;

drop trigger if exists shows_daily_limit on public.shows;
create trigger shows_daily_limit
  before insert on public.shows
  for each row execute function public.limit_daily_shows();

-- 5) 나를 관리자로 등록 (사이트에서 구글 로그인을 한 번 한 뒤에 실행)
--    아래 줄의 이메일을 내 구글 이메일로 바꾸고, 앞의 -- 를 지운 뒤 이 줄만 실행하세요.
-- insert into public.admins (user_id) select id from auth.users where email = '내구글이메일@gmail.com';
