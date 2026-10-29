-- LAM VAN: SQL BO SUNG SAU KHI DA CHAY SCHEMA CO BAN
-- Chay toan bo trong Supabase > SQL Editor.

create or replace function public.place_lamvan_order(
  p_customer jsonb,
  p_items jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_item jsonb;
  v_product public.products%rowtype;
  v_qty integer;
  v_size text;
  v_color text;
  v_total numeric(12,2) := 0;
  v_items jsonb := '[]'::jsonb;
  v_order_id text;
  v_name text;
  v_phone text;
  v_address text;
  v_note text;
begin
  if p_customer is null or jsonb_typeof(p_customer) <> 'object' then
    raise exception 'Thông tin khách hàng không hợp lệ';
  end if;
  v_name := btrim(coalesce(p_customer->>'name',''));
  v_phone := btrim(coalesce(p_customer->>'phone',''));
  v_address := btrim(coalesce(p_customer->>'address',''));
  v_note := left(btrim(coalesce(p_customer->>'note','')),500);
  if v_name = '' or v_phone = '' or v_address = '' then
    raise exception 'Vui lòng nhập họ tên, số điện thoại và địa chỉ';
  end if;
  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'Giỏ hàng đang trống';
  end if;

  for v_item in select value from jsonb_array_elements(p_items)
  loop
    v_qty := (v_item->>'qty')::integer;
    v_size := btrim(coalesce(v_item->>'size',''));
    v_color := btrim(coalesce(v_item->>'color',''));
    if v_qty is null or v_qty < 1 or v_qty > 50 then
      raise exception 'Số lượng sản phẩm không hợp lệ';
    end if;

    select * into v_product
    from public.products
    where id = v_item->>'productId' and active = true
    for update;

    if not found then raise exception 'Sản phẩm không còn kinh doanh'; end if;
    if v_qty > v_product.stock then
      raise exception 'Sản phẩm "%" không đủ tồn kho', v_product.name;
    end if;
    if not (v_size = any(v_product.sizes)) then
      raise exception 'Size của sản phẩm "%" không hợp lệ', v_product.name;
    end if;
    if not exists (
      select 1 from jsonb_array_elements(v_product.colors) c
      where c->>'name' = v_color
    ) then
      raise exception 'Màu của sản phẩm "%" không hợp lệ', v_product.name;
    end if;

    v_total := v_total + v_product.price * v_qty;
    v_items := v_items || jsonb_build_array(jsonb_build_object(
      'key', v_product.id || '|' || v_size || '|' || v_color,
      'productId', v_product.id,
      'name', v_product.name,
      'price', v_product.price,
      'image', coalesce(v_product.image,''),
      'size', v_size,
      'color', v_color,
      'qty', v_qty
    ));
    update public.products set stock = stock - v_qty where id = v_product.id;
  end loop;

  v_order_id := 'LV-' || to_char(now() at time zone 'Asia/Ho_Chi_Minh','YYMMDD') || '-' || upper(substr(gen_random_uuid()::text,1,6));
  insert into public.orders(id, customer_name, phone, address, note, items, total, status, payment)
  values(v_order_id, v_name, v_phone, v_address, v_note, v_items, v_total, 'Mới đặt', 'COD');

  return jsonb_build_object('order_id',v_order_id,'total',v_total,'status','Mới đặt');
end;
$$;

revoke all on function public.place_lamvan_order(jsonb,jsonb) from public;
grant execute on function public.place_lamvan_order(jsonb,jsonb) to anon, authenticated;

-- Bucket anh san pham: doc cong khai, chi admin moi duoc tai len / sua / xoa.
insert into storage.buckets (id, name, public)
values ('product-images','product-images',true)
on conflict (id) do update set public = true;

drop policy if exists "LAM VAN public can view product images" on storage.objects;
drop policy if exists "LAM VAN admins can upload product images" on storage.objects;
drop policy if exists "LAM VAN admins can update product images" on storage.objects;
drop policy if exists "LAM VAN admins can delete product images" on storage.objects;

create policy "LAM VAN public can view product images"
on storage.objects for select to anon, authenticated
using (bucket_id = 'product-images');

create policy "LAM VAN admins can upload product images"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'product-images' and exists (
    select 1 from public.admin_users a where a.user_id = (select auth.uid())
  )
);

create policy "LAM VAN admins can update product images"
on storage.objects for update to authenticated
using (
  bucket_id = 'product-images' and exists (
    select 1 from public.admin_users a where a.user_id = (select auth.uid())
  )
)
with check (
  bucket_id = 'product-images' and exists (
    select 1 from public.admin_users a where a.user_id = (select auth.uid())
  )
);

create policy "LAM VAN admins can delete product images"
on storage.objects for delete to authenticated
using (
  bucket_id = 'product-images' and exists (
    select 1 from public.admin_users a where a.user_id = (select auth.uid())
  )
);
