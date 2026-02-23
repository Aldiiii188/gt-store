-- Run this in Supabase SQL Editor (once)

-- 1) Products (CPS BGL, CPS BLACK, MRAY)
create table if not exists public.products (
  code text primary key,
  name text not null,
  price bigint not null default 0,
  stock int not null default 0,
  image_url text
);

insert into public.products (code, name, price, stock, image_url)
values
  ('CPS_BGL', 'CPS Blue Gem Lock (CPS BGL)', 0, 0, null),
  ('CPS_BLACK', 'CPS Black Gem Lock', 0, 0, null),
  ('MRAY', 'MRAY', 0, 0, null)
on conflict (code) do nothing;

-- 2) Settings (store open/close + seller info)
create table if not exists public.settings (
  id int primary key default 1,
  store_open boolean not null default true,
  closed_message text not null default 'Store Sedang Tutup
Anda tetap dapat melihat produk dan melakukan pesanan, namun pesanan Anda akan diproses ketika Admin sudah ready / toko kembali buka.',
  seller_world_name text not null default '821',
  seller_world_owner text not null default 'Aldie',
  seller_whatsapp text not null default '6281553417616'
);

insert into public.settings (id) values (1)
on conflict (id) do nothing;

-- 3) Orders
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'order_type') THEN
        CREATE TYPE public.order_type AS ENUM ('SELL', 'BUY');
    END IF;
END
$$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'order_status') THEN
        CREATE TYPE public.order_status AS ENUM ('PENDING', 'PROCESSING', 'SENT', 'CANCELLED');
    END IF;
END
$$;

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  public_id text unique not null,
  type public.order_type not null,
  category text not null references public.products(code),
  payment_method text not null,
  customer_world text,
  customer_growid text,
  proof_url text,
  notes text,
  status public.order_status not null default 'PENDING',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- keep updated_at fresh
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_orders_updated_at on public.orders;
create trigger trg_orders_updated_at
before update on public.orders
for each row execute function public.set_updated_at();

-- public_id generator: GT-XXXXXX (6 chars)
create or replace function public.make_public_id()
returns text language plpgsql as $$
declare
  chars text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  out text := 'GT-';
  i int;
begin
  for i in 1..6 loop
    out := out || substr(chars, 1 + floor(random()*length(chars))::int, 1);
  end loop;
  return out;
end;
$$;

create or replace function public.ensure_public_id()
returns trigger language plpgsql as $$
begin
  if new.public_id is null or new.public_id = '' then
    new.public_id := public.make_public_id();
  end if;
  return new;
end;
$$;

drop trigger if exists trg_orders_public_id on public.orders;
create trigger trg_orders_public_id
before insert on public.orders
for each row execute function public.ensure_public_id();

-- 4) Storage bucket (create manually too):
-- Create bucket name: proofs
-- Set it Public (simple) OR keep Private + use signed URLs in code (advanced).

-- 5) RLS (IMPORTANT)
-- For simplicity, we allow public read for products+settings, and public insert/select limited fields for orders by public_id.
-- Admin operations will be done from client using anon key + RLS policy is required; safer approach is to use service role via server.
-- This template keeps it simple. You can tighten later.

alter table public.products enable row level security;
alter table public.settings enable row level security;
alter table public.orders enable row level security;

-- PRODUCTS: anyone can read
drop policy if exists "products_read" on public.products;
create policy "products_read" on public.products for select using (true);

-- SETTINGS: anyone can read
drop policy if exists "settings_read" on public.settings;
create policy "settings_read" on public.settings for select using (true);

-- ORDERS: anyone can insert
drop policy if exists "orders_insert" on public.orders;
create policy "orders_insert" on public.orders for insert with check (true);

-- ORDERS: customer can read limited by public_id equality through query
drop policy if exists "orders_select" on public.orders;
create policy "orders_select" on public.orders for select using (true);

-- Admin write policies:
-- For a quick start, allow authenticated users to update products/settings/orders.
-- Then restrict with ADMIN_EMAIL in the UI (already done). For stronger security, add JWT claims / admin table.
drop policy if exists "products_admin_write" on public.products;
create policy "products_admin_write" on public.products for update using (auth.role() = 'authenticated');

drop policy if exists "settings_admin_write" on public.settings;
create policy "settings_admin_write" on public.settings for update using (auth.role() = 'authenticated');

drop policy if exists "orders_admin_write" on public.orders;
create policy "orders_admin_write" on public.orders for update using (auth.role() = 'authenticated');
