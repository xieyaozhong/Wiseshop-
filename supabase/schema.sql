-- WiseShop OS production-ready Supabase schema
-- Multi-tenant by shop_id with Row Level Security.

create extension if not exists pgcrypto;

create table if not exists public.shops (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  district text,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.shop_members (
  shop_id uuid not null references public.shops(id) on delete cascade,
  user_id uuid not null,
  role text not null default 'staff' check (role in ('owner','manager','staff')),
  created_at timestamptz not null default now(),
  primary key (shop_id, user_id)
);

create or replace function public.is_shop_member(target_shop uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.shop_members
    where shop_id = target_shop and user_id = auth.uid()
  );
$$;

create or replace function public.bootstrap_shop_owner()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.shop_members(shop_id,user_id,role)
  values (new.id,new.created_by,'owner')
  on conflict do nothing;
  return new;
end;
$$;

drop trigger if exists trg_bootstrap_shop_owner on public.shops;
create trigger trg_bootstrap_shop_owner
after insert on public.shops
for each row execute function public.bootstrap_shop_owner();

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  shop_id uuid not null references public.shops(id) on delete cascade,
  sku text,
  name text not null,
  stock numeric not null default 0,
  reorder_point numeric not null default 0,
  cost numeric not null default 0,
  price numeric not null default 0,
  lead_days integer not null default 3,
  active boolean not null default true,
  updated_at timestamptz not null default now(),
  unique(shop_id, sku)
);

create table if not exists public.customers (
  id uuid primary key default gen_random_uuid(),
  shop_id uuid not null references public.shops(id) on delete cascade,
  name text not null,
  phone text,
  line_user_id text,
  tag text default '新客',
  total_spent numeric not null default 0,
  visit_count integer not null default 0,
  last_visit timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  shop_id uuid not null references public.shops(id) on delete cascade,
  customer_id uuid references public.customers(id) on delete set null,
  order_no text not null,
  channel text not null default '門市',
  status text not null default '待處理',
  amount numeric not null default 0,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(shop_id, order_no)
);

create table if not exists public.expenses (
  id uuid primary key default gen_random_uuid(),
  shop_id uuid not null references public.shops(id) on delete cascade,
  name text not null,
  category text,
  amount numeric not null default 0,
  occurred_on date not null default current_date,
  created_at timestamptz not null default now()
);

create table if not exists public.automation_events (
  id uuid primary key default gen_random_uuid(),
  shop_id uuid not null references public.shops(id) on delete cascade,
  event_type text not null,
  severity text not null default 'info',
  payload jsonb not null default '{}'::jsonb,
  acknowledged_at timestamptz,
  created_at timestamptz not null default now()
);

alter table public.shops enable row level security;
alter table public.shop_members enable row level security;
alter table public.products enable row level security;
alter table public.customers enable row level security;
alter table public.orders enable row level security;
alter table public.expenses enable row level security;
alter table public.automation_events enable row level security;

create policy "shops_select_member" on public.shops for select using (public.is_shop_member(id));
create policy "shops_insert_owner" on public.shops for insert with check (created_by = auth.uid());
create policy "shops_update_member" on public.shops for update using (public.is_shop_member(id));

create policy "members_select_member" on public.shop_members for select using (public.is_shop_member(shop_id));
create policy "members_manage_owner" on public.shop_members for all using (
  exists(select 1 from public.shop_members m where m.shop_id=shop_members.shop_id and m.user_id=auth.uid() and m.role='owner')
) with check (
  exists(select 1 from public.shop_members m where m.shop_id=shop_members.shop_id and m.user_id=auth.uid() and m.role='owner')
);

create policy "products_member" on public.products for all using (public.is_shop_member(shop_id)) with check (public.is_shop_member(shop_id));
create policy "customers_member" on public.customers for all using (public.is_shop_member(shop_id)) with check (public.is_shop_member(shop_id));
create policy "orders_member" on public.orders for all using (public.is_shop_member(shop_id)) with check (public.is_shop_member(shop_id));
create policy "expenses_member" on public.expenses for all using (public.is_shop_member(shop_id)) with check (public.is_shop_member(shop_id));
create policy "events_member" on public.automation_events for all using (public.is_shop_member(shop_id)) with check (public.is_shop_member(shop_id));

create index if not exists idx_products_shop on public.products(shop_id);
create index if not exists idx_orders_shop_created on public.orders(shop_id, created_at desc);
create index if not exists idx_customers_shop on public.customers(shop_id);
create index if not exists idx_events_shop_created on public.automation_events(shop_id, created_at desc);
