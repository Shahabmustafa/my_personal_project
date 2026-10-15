-- Purchase expense → stock ki sale price bhi.
-- Purchase Invoice ka expense jitna har unit par aata hai, utna variant ki
-- sale price mein bhi jud kar stock_inventory.sale_price mein jata hai
-- (e.g. 1500 + 60 = 1560). NULL = products.sale_price hi chalta hai.
-- Applied to live database.

alter table public.stock_inventory
  add column if not exists sale_price numeric(12,2);

create or replace view public.v_head_office_stock as
 select s.id,
    s.barcode,
    s.product_id,
    s.size_id,
    s.color_id,
    s.brand_id,
    s.category_id,
    s.type_id,
    s.company_id,
    s.quantity,
    s.discount,
    s.created_at,
    s.updated_at,
    coalesce(s.sale_price, p.sale_price)::numeric(12,2) as sale_price,
    coalesce(s.purchase_price, p.purchase_price)::numeric(12,2) as purchase_price,
    p.article_name as product_name,
    sz.number as size_name,
    c.name as color_name,
    br.name as brand_name,
    cat.name as category_name,
    t.name as type_name,
    co.name as company_name,
    lower(coalesce(p.article_name, '') || ' ' || coalesce(s.barcode, '') || ' '
      || coalesce(sz.number, '') || ' ' || coalesce(c.name, '') || ' '
      || coalesce(br.name, '') || ' ' || coalesce(cat.name, '') || ' '
      || coalesce(t.name, '') || ' ' || coalesce(co.name, '')) as search_text
   from stock_inventory s
     left join products p on p.id = s.product_id
     left join sizes sz on sz.id = s.size_id
     left join colors c on c.id = s.color_id
     left join brands br on br.id = s.brand_id
     left join categories cat on cat.id = s.category_id
     left join types t on t.id = s.type_id
     left join companies co on co.id = s.company_id;
