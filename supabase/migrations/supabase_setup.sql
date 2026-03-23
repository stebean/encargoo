-- ============================================================
-- ENCARGOO – Supabase Database Setup
-- Run this in Supabase SQL Editor (Project → SQL Editor → New query)
-- ============================================================

-- 1. WORKSPACES
create table if not exists workspaces (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  access_code text not null unique,
  created_at  timestamptz default now()
);

-- 2. PROFILES (linked to auth.users)
create table if not exists profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  full_name    text,
  workspace_id uuid references workspaces(id) on delete set null,
  created_at   timestamptz default now()
);

-- Auto-create profile on sign-up
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, new.raw_user_meta_data->>'full_name');
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- 3. CLIENTS
create table if not exists clients (
  id           uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces(id) on delete cascade,
  name         text not null,
  phone        text,
  notes        text,
  created_at   timestamptz default now()
);

-- 4. ORDERS
create table if not exists orders (
  id            uuid primary key default gen_random_uuid(),
  workspace_id  uuid not null references workspaces(id) on delete cascade,
  client_id     uuid references clients(id) on delete set null,
  created_by    uuid not null references profiles(id) on delete cascade,
  created_at    timestamptz default now(),
  delivery_date date,
  status        text not null default 'pendiente'
                  check (status in ('pendiente','lista','entregada','atrasada')),
  notes         text
);

-- 5. ORDER PHOTOS
create table if not exists order_photos (
  id          uuid primary key default gen_random_uuid(),
  order_id    uuid not null references orders(id) on delete cascade,
  photo_url   text not null,
  description text default '',
  sort_order  int default 0,
  created_at  timestamptz default now()
);

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

alter table workspaces    enable row level security;
alter table profiles      enable row level security;
alter table clients       enable row level security;
alter table orders        enable row level security;
alter table order_photos  enable row level security;

-- Helper function to get current user's workspace_id
create or replace function get_user_workspace_id()
returns uuid as $$
  select workspace_id from profiles where id = auth.uid();
$$ language sql security definer stable;

-- Workspace policies
create policy "Users can read workspaces"
  on workspaces for select using (auth.uid() is not null);
create policy "Users can create workspaces"
  on workspaces for insert with check (auth.uid() is not null);

-- Profile policies
create policy "Users can read own profile"
  on profiles for select using (id = auth.uid());
create policy "Users can read profiles in same workspace"
  on profiles for select using (workspace_id = get_user_workspace_id());
create policy "Users can update own profile"
  on profiles for update using (id = auth.uid());

-- Client policies (only same workspace)
create policy "Workspace members read clients"
  on clients for select using (workspace_id = get_user_workspace_id());
create policy "Workspace members insert clients"
  on clients for insert with check (workspace_id = get_user_workspace_id());
create policy "Workspace members update clients"
  on clients for update using (workspace_id = get_user_workspace_id());
create policy "Workspace members delete clients"
  on clients for delete using (workspace_id = get_user_workspace_id());

-- Order policies (only same workspace)
create policy "Workspace members read orders"
  on orders for select using (workspace_id = get_user_workspace_id());
create policy "Workspace members insert orders"
  on orders for insert with check (workspace_id = get_user_workspace_id());
create policy "Workspace members update orders"
  on orders for update using (workspace_id = get_user_workspace_id());
create policy "Workspace members delete orders"
  on orders for delete using (workspace_id = get_user_workspace_id());

-- Order photos policies (via order's workspace)
create policy "Workspace members read photos"
  on order_photos for select
  using (order_id in (select id from orders where workspace_id = get_user_workspace_id()));
create policy "Workspace members insert photos"
  on order_photos for insert
  with check (order_id in (select id from orders where workspace_id = get_user_workspace_id()));
create policy "Workspace members update photos"
  on order_photos for update
  using (order_id in (select id from orders where workspace_id = get_user_workspace_id()));
create policy "Workspace members delete photos"
  on order_photos for delete
  using (auth.uid() is not null);

-- ============================================================
-- STORAGE BUCKET (run separately in Supabase Dashboard > Storage)
-- ============================================================
-- 1. Create bucket: order-photos
-- 2. Make it PUBLIC
-- 3. Add policy: allow authenticated users to upload/read
-- Or run:
-- insert into storage.buckets (id, name, public) values ('order-photos', 'order-photos', true);
