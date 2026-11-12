-- STAGING ONLY. Apply only to the isolated DNS Agriculture Exchange staging project.
-- Idempotently provisions the two owner-approved staging administrator identities if present.
insert into dns_support.support_agents(user_id,role,display_name,active)
select u.id,'admin',
       case lower(u.email)
         when 'adisaabiodunsunday@gmail.com' then 'DNS Staging Owner'
         when 'adisaabiodunsunday+testadmin@gmail.com' then 'DNS Staging Test Admin'
       end,
       true
from auth.users u
where lower(u.email) in ('adisaabiodunsunday@gmail.com','adisaabiodunsunday+testadmin@gmail.com')
on conflict(user_id) do update
set role='admin',active=true,display_name=excluded.display_name;
