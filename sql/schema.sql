-- KoOo Mini POS Cloud 3.0
-- Run the entire file in Supabase Dashboard > SQL Editor.
-- RLS is enabled. Never expose service_role keys in browser code.
create extension if not exists pgcrypto;

create table if not exists public.stores(
 id uuid primary key default gen_random_uuid(),
 name text not null,
 created_at timestamptz not null default now()
);
create table if not exists public.store_members(
 store_id uuid not null references public.stores(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 role text not null default 'staff' check(role in ('owner','admin','staff')),
 created_at timestamptz not null default now(),
 primary key(store_id,user_id)
);
create table if not exists public.products(
 id uuid primary key default gen_random_uuid(), store_id uuid not null references public.stores(id) on delete cascade,
 name text not null, sku text default '', category text default 'General', unit text default 'pcs',
 cost numeric(14,2) not null default 0 check(cost>=0), price numeric(14,2) not null default 0 check(price>=0),
 stock numeric(14,3) not null default 0 check(stock>=0), low_stock numeric(14,3) not null default 5,
 updated_at timestamptz not null default now()
);
create unique index if not exists products_store_sku_unique on public.products(store_id,sku) where sku<>'';
create table if not exists public.customers(
 id uuid primary key default gen_random_uuid(), store_id uuid not null references public.stores(id) on delete cascade,
 name text not null, phone text default '', note text default '', balance numeric(14,2) not null default 0,
 updated_at timestamptz not null default now()
);
create table if not exists public.sales(
 id uuid primary key, store_id uuid not null references public.stores(id) on delete cascade,
 receipt_no text not null, sold_at timestamptz not null default now(),
 customer_id uuid references public.customers(id) on delete set null,
 payment text not null, subtotal numeric(14,2) not null, discount numeric(14,2) not null default 0,
 total numeric(14,2) not null, cost_total numeric(14,2) not null default 0,
 paid numeric(14,2) not null default 0, due numeric(14,2) not null default 0,
 created_by uuid references auth.users(id), unique(store_id,receipt_no)
);
create table if not exists public.sale_items(
 id uuid primary key default gen_random_uuid(), store_id uuid not null references public.stores(id) on delete cascade,
 sale_id uuid not null references public.sales(id) on delete cascade,
 product_id uuid references public.products(id) on delete set null,
 product_name text not null, qty numeric(14,3) not null, unit_price numeric(14,2) not null,
 unit_cost numeric(14,2) not null
);
create table if not exists public.expenses(
 id uuid primary key default gen_random_uuid(), store_id uuid not null references public.stores(id) on delete cascade,
 expense_date date not null default current_date, category text not null, note text default '',
 amount numeric(14,2) not null check(amount>0), created_by uuid references auth.users(id)
);
create table if not exists public.customer_payments(
 id uuid primary key default gen_random_uuid(), store_id uuid not null references public.stores(id) on delete cascade,
 customer_id uuid not null references public.customers(id) on delete cascade,
 amount numeric(14,2) not null check(amount>0), paid_at timestamptz not null default now(), note text default ''
);

create or replace function public.is_store_member(p_store uuid)
returns boolean language sql stable security definer set search_path=public
as $$ select exists(select 1 from public.store_members m where m.store_id=p_store and m.user_id=auth.uid()) $$;
create or replace function public.store_role(p_store uuid)
returns text language sql stable security definer set search_path=public
as $$ select role from public.store_members where store_id=p_store and user_id=auth.uid() limit 1 $$;

alter table public.stores enable row level security;
alter table public.store_members enable row level security;
alter table public.products enable row level security;
alter table public.customers enable row level security;
alter table public.sales enable row level security;
alter table public.sale_items enable row level security;
alter table public.expenses enable row level security;
alter table public.customer_payments enable row level security;

create policy "members read stores" on public.stores for select using(public.is_store_member(id));
create policy "members read roster" on public.store_members for select using(public.is_store_member(store_id));
create policy "members read products" on public.products for select using(public.is_store_member(store_id));
create policy "admins manage products" on public.products for all using(public.store_role(store_id) in ('owner','admin')) with check(public.store_role(store_id) in ('owner','admin'));
create policy "members read customers" on public.customers for select using(public.is_store_member(store_id));
create policy "staff manage customers" on public.customers for all using(public.is_store_member(store_id)) with check(public.is_store_member(store_id));
create policy "members read sales" on public.sales for select using(public.is_store_member(store_id));
create policy "members read sale items" on public.sale_items for select using(public.is_store_member(store_id));
create policy "members read expenses" on public.expenses for select using(public.is_store_member(store_id));
create policy "admins manage expenses" on public.expenses for all using(public.store_role(store_id) in ('owner','admin')) with check(public.store_role(store_id) in ('owner','admin'));
create policy "members read customer payments" on public.customer_payments for select using(public.is_store_member(store_id));

-- Create a store for the signed-in user. First user becomes owner.
create or replace function public.create_my_store(p_name text)
returns uuid language plpgsql security definer set search_path=public
as $$
declare v_store uuid;
begin
 if auth.uid() is null then raise exception 'Sign in required'; end if;
 if exists(select 1 from public.store_members where user_id=auth.uid()) then
   raise exception 'This account already belongs to a store';
 end if;
 insert into public.stores(name) values(left(trim(p_name),100)) returning id into v_store;
 insert into public.store_members(store_id,user_id,role) values(v_store,auth.uid(),'owner');
 return v_store;
end; $$;
revoke all on function public.create_my_store(text) from public;
grant execute on function public.create_my_store(text) to authenticated;

-- Invite an existing registered user by email is intentionally not exposed to browser.
-- Owner should add team members through a trusted server/Edge Function in a later deployment.

-- Atomic, idempotent sale posting. A duplicate sale UUID is not posted twice.
create or replace function public.post_sale(p_sale jsonb)
returns jsonb language plpgsql security definer set search_path=public
as $$
declare v_store uuid := (p_sale->>'store_id')::uuid; v_sale uuid := (p_sale->>'id')::uuid;
 v_item jsonb; v_product public.products%rowtype; v_total numeric:=0; v_cost numeric:=0;
 v_sub numeric:=0; v_discount numeric:=0; v_due numeric:=0; v_paid numeric:=0; v_customer uuid;
begin
 if not public.is_store_member(v_store) then raise exception 'Not a member of this store'; end if;
 if exists(select 1 from public.sales where id=v_sale) then return jsonb_build_object('ok',true,'duplicate',true); end if;
 v_customer := nullif(p_sale->>'customer_id','')::uuid;
 v_discount := coalesce((p_sale->>'discount')::numeric,0);
 v_paid := coalesce((p_sale->>'paid')::numeric,0);
 for v_item in select * from jsonb_array_elements(p_sale->'items') loop
   select * into v_product from public.products where id=(v_item->>'product_id')::uuid and store_id=v_store for update;
   if not found then raise exception 'Product not found'; end if;
   if (v_item->>'qty')::numeric <= 0 then raise exception 'Quantity must be positive'; end if;
   if v_product.stock < (v_item->>'qty')::numeric then raise exception 'Insufficient stock: %',v_product.name; end if;
   v_sub := v_sub + v_product.price * (v_item->>'qty')::numeric;
   v_cost := v_cost + v_product.cost * (v_item->>'qty')::numeric;
 end loop;
 if v_discount < 0 or v_discount > v_sub then raise exception 'Invalid discount'; end if;
 v_total := v_sub - v_discount;
 if v_paid < 0 or v_paid > v_total then raise exception 'Invalid paid amount'; end if;
 v_due := v_total - v_paid;
 insert into public.sales(id,store_id,receipt_no,sold_at,customer_id,payment,subtotal,discount,total,cost_total,paid,due,created_by)
 values(v_sale,v_store,p_sale->>'receipt_no',coalesce((p_sale->>'sold_at')::timestamptz,now()),v_customer,p_sale->>'payment',v_sub,v_discount,v_total,v_cost,v_paid,v_due,auth.uid());
 for v_item in select * from jsonb_array_elements(p_sale->'items') loop
   select * into v_product from public.products where id=(v_item->>'product_id')::uuid and store_id=v_store for update;
   update public.products set stock=stock-(v_item->>'qty')::numeric,updated_at=now() where id=v_product.id;
   insert into public.sale_items(store_id,sale_id,product_id,product_name,qty,unit_price,unit_cost)
   values(v_store,v_sale,v_product.id,v_product.name,(v_item->>'qty')::numeric,v_product.price,v_product.cost);
 end loop;
 if v_due>0 and v_customer is not null then update public.customers set balance=balance+v_due,updated_at=now() where id=v_customer and store_id=v_store; end if;
 return jsonb_build_object('ok',true,'sale_id',v_sale);
end; $$;
revoke all on function public.post_sale(jsonb) from public;
grant execute on function public.post_sale(jsonb) to authenticated;

-- Realtime publication for cross-device refresh.
do $$ begin
 alter publication supabase_realtime add table public.products;
exception when duplicate_object then null; when undefined_object then null; end $$;
do $$ begin
 alter publication supabase_realtime add table public.sales;
exception when duplicate_object then null; when undefined_object then null; end $$;
