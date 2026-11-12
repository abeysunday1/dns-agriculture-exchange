-- Keep privileged helpers outside the exposed API and narrow callable privileges.
create or replace function private.ensure_exchange_profile_from_metadata()
returns boolean language plpgsql security definer set search_path='' as $$
declare v_type text; v_name text;
begin
 if auth.uid() is null then raise exception 'Authentication required'; end if;
 select raw_user_meta_data->>'account_type',
        nullif(trim(coalesce(raw_user_meta_data->>'full_name',raw_user_meta_data->>'name','')),'')
 into v_type,v_name from auth.users where id=auth.uid();
 if v_type not in ('buyer','supplier') then raise exception 'Choose buyer or supplier before continuing'; end if;
 insert into public.exchange_profiles(user_id,full_name,account_type)
 values(auth.uid(),v_name,v_type) on conflict(user_id) do nothing;
 return true;
end; $$;
revoke all on function private.ensure_exchange_profile_from_metadata() from public,anon;
grant usage on schema private to authenticated;
grant execute on function private.ensure_exchange_profile_from_metadata() to authenticated;

create or replace function public.ensure_exchange_profile_from_metadata()
returns boolean language sql security invoker set search_path='' as $$
 select private.ensure_exchange_profile_from_metadata();
$$;
revoke all on function public.ensure_exchange_profile_from_metadata() from public,anon;
grant execute on function public.ensure_exchange_profile_from_metadata() to authenticated;

alter function public.is_exchange_admin() security invoker;
revoke all on function public.is_exchange_admin() from public,anon;
grant execute on function public.is_exchange_admin() to authenticated;

revoke all on function public.handle_account_deletion_review() from public,anon,authenticated;
