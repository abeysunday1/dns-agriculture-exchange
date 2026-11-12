-- Google OAuth role bootstrap. Email/password signups already provide account_type.
-- OAuth users choose their exchange role after returning from Google.
create or replace function public.handle_new_exchange_user()
returns trigger language plpgsql security definer set search_path='' as $$
declare requested_role text;
begin
 requested_role := new.raw_user_meta_data->>'account_type';
 if requested_role in ('buyer','supplier') then
  insert into public.exchange_profiles(user_id,full_name,account_type)
  values(new.id,nullif(trim(coalesce(new.raw_user_meta_data->>'full_name',new.raw_user_meta_data->>'name','')),''),requested_role)
  on conflict(user_id) do nothing;
 end if;
 return new;
end; $$;
revoke all on function public.handle_new_exchange_user() from public,anon,authenticated;

create or replace function public.ensure_exchange_profile_from_metadata()
returns boolean language plpgsql security definer set search_path='' as $$
declare v_type text; v_name text;
begin
 if auth.uid() is null then raise exception 'Authentication required'; end if;
 select raw_user_meta_data->>'account_type',
        nullif(trim(coalesce(raw_user_meta_data->>'full_name',raw_user_meta_data->>'name','')),'')
 into v_type,v_name
 from auth.users where id=auth.uid();
 if v_type not in ('buyer','supplier') then raise exception 'Choose buyer or supplier before continuing'; end if;
 insert into public.exchange_profiles(user_id,full_name,account_type)
 values(auth.uid(),v_name,v_type)
 on conflict(user_id) do nothing;
 return true;
end; $$;
revoke all on function public.ensure_exchange_profile_from_metadata() from public,anon;
grant execute on function public.ensure_exchange_profile_from_metadata() to authenticated;
