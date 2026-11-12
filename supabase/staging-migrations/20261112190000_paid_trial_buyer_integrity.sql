-- Keep paid-trial and repeat-buyer stages tied to verified payment records.
create or replace function public.enforce_buyer_paid_stage()
returns trigger language plpgsql set search_path = '' as $$
declare paid_count integer;
begin
  if new.stage in ('paid_trial_buyer','repeat_buyer') then
    select count(*) into paid_count
    from public.buyer_orders
    where prospect_id = new.id and payment_status = 'paid' and paid_at is not null;
    if new.stage = 'paid_trial_buyer' and paid_count < 1 then
      raise exception 'A prospect cannot be marked as a paid trial buyer without a verified paid order.';
    end if;
    if new.stage = 'repeat_buyer' and paid_count < 2 then
      raise exception 'A prospect cannot be marked as a repeat buyer without at least two verified paid orders.';
    end if;
  end if;
  return new;
end;
$$;
drop trigger if exists buyer_prospects_enforce_paid_stage on public.buyer_prospects;
create trigger buyer_prospects_enforce_paid_stage
before insert or update of stage on public.buyer_prospects
for each row execute function public.enforce_buyer_paid_stage();

create or replace function public.sync_buyer_paid_buyer_stage()
returns trigger language plpgsql set search_path = '' as $$
declare paid_count integer;
begin
  if new.payment_status = 'paid' and new.paid_at is not null then
    select count(*) into paid_count
    from public.buyer_orders
    where prospect_id = new.prospect_id and payment_status = 'paid' and paid_at is not null;
    update public.buyer_prospects
    set stage = case when paid_count >= 2 then 'repeat_buyer' else 'paid_trial_buyer' end
    where id = new.prospect_id and stage not in ('lost','disqualified');
  end if;
  return new;
end;
$$;
drop trigger if exists buyer_orders_sync_paid_stage on public.buyer_orders;
create trigger buyer_orders_sync_paid_stage
after insert or update of payment_status, paid_at on public.buyer_orders
for each row execute function public.sync_buyer_paid_buyer_stage();
