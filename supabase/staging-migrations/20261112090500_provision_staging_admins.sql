-- STAGING ONLY. Apply only to the isolated DNS Agriculture Exchange staging project.
-- Idempotently provisions the single owner-approved staging administrator if present.
insert into dns_support.support_agents(user_id,role,display_name,active)
select u.id,'admin','DNS Staging Owner',true
from auth.users u
where lower(u.email) = 'adisaabiodunsunday@gmail.com'
on conflict(user_id) do update
set role='admin',active=true,display_name=excluded.display_name;
