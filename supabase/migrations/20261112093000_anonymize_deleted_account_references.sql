-- Preserve support and deletion audit history while anonymizing deleted account references.
alter table dns_support.conversations alter column participant_user_id drop not null;
alter table dns_support.conversations drop constraint if exists conversations_participant_user_id_fkey;
alter table dns_support.conversations add constraint conversations_participant_user_id_fkey
 foreign key(participant_user_id) references auth.users(id) on delete set null;

alter table dns_support.messages alter column sender_user_id drop not null;
alter table dns_support.messages drop constraint if exists messages_sender_user_id_fkey;
alter table dns_support.messages add constraint messages_sender_user_id_fkey
 foreign key(sender_user_id) references auth.users(id) on delete set null;

alter table public.account_deletion_requests drop constraint if exists account_deletion_requests_reviewed_by_fkey;
alter table public.account_deletion_requests add constraint account_deletion_requests_reviewed_by_fkey
 foreign key(reviewed_by) references auth.users(id) on delete set null;
