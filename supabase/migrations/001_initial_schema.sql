-- Suad Muhtaseb platform: initial secure schema
-- Review and apply only to a dedicated Supabase project for this platform.
-- This file is NOT deployed by GitHub Pages and contains no credentials.

create extension if not exists pgcrypto;

create type public.platform_role as enum ('admin', 'suad');
create type public.content_status as enum ('draft', 'published', 'archived');

create table public.user_roles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role public.platform_role not null,
  created_at timestamptz not null default now()
);

create table public.content_paths (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  title_ar text not null,
  summary_ar text,
  status public.content_status not null default 'draft',
  created_by uuid references auth.users(id) on delete set null,
  reviewed_by uuid references auth.users(id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.assessment_questions (
  id uuid primary key default gen_random_uuid(),
  path_id uuid references public.content_paths(id) on delete cascade,
  question_key text not null unique,
  prompt_ar text not null,
  answer_type text not null check (answer_type in ('single_choice','multiple_choice','short_text','safety_check')),
  options jsonb not null default '[]'::jsonb,
  is_required boolean not null default true,
  sort_order integer not null default 0,
  status public.content_status not null default 'draft',
  created_by uuid references auth.users(id) on delete set null,
  updated_at timestamptz not null default now()
);

create table public.recommendation_rules (
  id uuid primary key default gen_random_uuid(),
  path_id uuid references public.content_paths(id) on delete set null,
  rule_key text not null unique,
  conditions jsonb not null default '{}'::jsonb,
  recommendation_ar text not null,
  urgency text not null default 'routine' check (urgency in ('routine','soon','urgent')),
  status public.content_status not null default 'draft',
  authored_by uuid references auth.users(id) on delete set null,
  approved_by uuid references auth.users(id) on delete set null,
  approved_at timestamptz,
  version integer not null default 1 check (version > 0),
  created_at timestamptz not null default now()
);

-- Store only the minimum data needed. Do not store patient names or contact details
-- in assessment_answers. Link assessments to an authenticated account.
create table public.assessments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  consent_version text not null,
  consented_at timestamptz not null default now(),
  status text not null default 'submitted' check (status in ('draft','submitted','reviewed','closed')),
  created_at timestamptz not null default now(),
  reviewed_at timestamptz
);

create table public.assessment_answers (
  id uuid primary key default gen_random_uuid(),
  assessment_id uuid not null references public.assessments(id) on delete cascade,
  question_key text not null,
  answer jsonb not null,
  created_at timestamptz not null default now(),
  unique (assessment_id, question_key)
);

create table public.assessment_recommendations (
  id uuid primary key default gen_random_uuid(),
  assessment_id uuid not null references public.assessments(id) on delete cascade,
  rule_key text references public.recommendation_rules(rule_key) on delete set null,
  rule_version integer,
  recommendation_ar text not null,
  urgency text not null check (urgency in ('routine','soon','urgent')),
  created_at timestamptz not null default now(),
  reviewed_by uuid references auth.users(id) on delete set null,
  reviewed_at timestamptz
);

create table public.session_requests (
  id uuid primary key default gen_random_uuid(),
  assessment_id uuid references public.assessments(id) on delete set null,
  user_id uuid not null references auth.users(id) on delete cascade,
  contact_preference text not null check (contact_preference in ('email','phone','messaging')),
  contact_value text not null,
  preferred_time text,
  user_message text,
  status text not null default 'new' check (status in ('new','contacted','scheduled','closed')),
  created_at timestamptz not null default now()
);

create table public.audit_events (
  id bigint generated always as identity primary key,
  actor_id uuid references auth.users(id) on delete set null,
  event_type text not null,
  entity_type text not null,
  entity_id uuid,
  created_at timestamptz not null default now()
);

create index assessments_user_created_idx on public.assessments(user_id, created_at desc);
create index assessment_answers_assessment_idx on public.assessment_answers(assessment_id);
create index session_requests_user_created_idx on public.session_requests(user_id, created_at desc);

-- Role lookup is isolated behind a security-definer function to avoid recursive RLS.
create or replace function public.has_platform_role(required_role public.platform_role)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.user_roles
    where user_id = (select auth.uid()) and role = required_role
  );
$$;

revoke all on function public.has_platform_role(public.platform_role) from public;
grant execute on function public.has_platform_role(public.platform_role) to authenticated;

alter table public.user_roles enable row level security;
alter table public.content_paths enable row level security;
alter table public.assessment_questions enable row level security;
alter table public.recommendation_rules enable row level security;
alter table public.assessments enable row level security;
alter table public.assessment_answers enable row level security;
alter table public.assessment_recommendations enable row level security;
alter table public.session_requests enable row level security;
alter table public.audit_events enable row level security;

-- Role rows are not directly readable or writable from the client. Assign roles
-- through a trusted server-side process only.
create policy "users can read published paths"
on public.content_paths for select to anon, authenticated
using (status = 'published');

create policy "admin and Suad can manage paths"
on public.content_paths for all to authenticated
using (public.has_platform_role('admin') or public.has_platform_role('suad'))
with check (public.has_platform_role('admin') or public.has_platform_role('suad'));

create policy "read questions for published paths"
on public.assessment_questions for select to anon, authenticated
using (status = 'published' and (path_id is null or exists (
  select 1 from public.content_paths p where p.id = path_id and p.status = 'published'
)));

create policy "admin and Suad can manage questions"
on public.assessment_questions for all to authenticated
using (public.has_platform_role('admin') or public.has_platform_role('suad'))
with check (public.has_platform_role('admin') or public.has_platform_role('suad'));

create policy "read approved published recommendations"
on public.recommendation_rules for select to anon, authenticated
using (status = 'published' and approved_at is not null);

create policy "admin and Suad can manage recommendation rules"
on public.recommendation_rules for all to authenticated
using (public.has_platform_role('admin') or public.has_platform_role('suad'))
with check (public.has_platform_role('admin') or public.has_platform_role('suad'));

-- A patient can access only their own submissions. Suad can review assessments
-- and recommendations. The platform admin is deliberately not granted patient
-- answer access by this schema.
create policy "patients can read own assessments"
on public.assessments for select to authenticated
using (user_id = (select auth.uid()));

create policy "patients can create own assessments"
on public.assessments for insert to authenticated
with check (user_id = (select auth.uid()));

create policy "Suad can review assessments"
on public.assessments for select to authenticated
using (public.has_platform_role('suad'));

create policy "Suad can update assessment review status"
on public.assessments for update to authenticated
using (public.has_platform_role('suad'))
with check (public.has_platform_role('suad'));

create policy "patients can read own answers"
on public.assessment_answers for select to authenticated
using (exists (select 1 from public.assessments a where a.id = assessment_id and a.user_id = (select auth.uid())));

create policy "patients can add answers to own assessments"
on public.assessment_answers for insert to authenticated
with check (exists (select 1 from public.assessments a where a.id = assessment_id and a.user_id = (select auth.uid())));

create policy "Suad can review answers"
on public.assessment_answers for select to authenticated
using (public.has_platform_role('suad'));

create policy "patients can read own recommendations"
on public.assessment_recommendations for select to authenticated
using (exists (select 1 from public.assessments a where a.id = assessment_id and a.user_id = (select auth.uid())));

create policy "Suad can manage recommendations"
on public.assessment_recommendations for all to authenticated
using (public.has_platform_role('suad'))
with check (public.has_platform_role('suad'));

create policy "patients can create own session requests"
on public.session_requests for insert to authenticated
with check (user_id = (select auth.uid()));

create policy "patients can read own session requests"
on public.session_requests for select to authenticated
using (user_id = (select auth.uid()));

create policy "Suad can manage session requests"
on public.session_requests for all to authenticated
using (public.has_platform_role('suad'))
with check (public.has_platform_role('suad'));

create policy "admin can read audit events"
on public.audit_events for select to authenticated
using (public.has_platform_role('admin'));

create policy "Suad can read audit events"
on public.audit_events for select to authenticated
using (public.has_platform_role('suad'));

-- Important deployment notes:
-- 1) This schema alone does not create users or assign the first admin/Suad role.
--    Assign roles only from a trusted server-side/admin process.
-- 2) Do not expose service_role keys in browser code or GitHub Pages.
-- 3) Add retention/deletion procedures and review applicable privacy obligations
--    before collecting real sensitive data.
-- 4) Safety-related answers require a clearly displayed emergency disclaimer and
--    a human-reviewed escalation process; do not rely on an automated rule alone.
