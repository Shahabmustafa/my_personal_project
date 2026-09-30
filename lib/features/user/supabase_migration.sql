-- Ek branch me sirf ek manager (role='manager').
-- Existing rows validate nahi hote; sirf naye insert/role-change block hote hain.

create or replace function public.enforce_one_manager_per_branch_on_assign()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_role text;
begin
  select role into v_role from public.users where id = new.user_id;
  if v_role = 'manager' and exists (
    select 1
    from public.user_branches ub
    join public.users u on u.id = ub.user_id
    where ub.branch_id = new.branch_id
      and u.role = 'manager'
      and ub.user_id <> new.user_id
  ) then
    raise exception 'Is branch me pehle se aik manager hai. Aik branch me sirf aik manager ho sakta hai';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_one_manager_per_branch_assign on public.user_branches;
create trigger trg_one_manager_per_branch_assign
before insert or update of branch_id, user_id on public.user_branches
for each row execute function public.enforce_one_manager_per_branch_on_assign();

create or replace function public.enforce_one_manager_per_branch_on_role()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if new.role = 'manager' and old.role is distinct from 'manager' and exists (
    select 1
    from public.user_branches mine
    join public.user_branches other on other.branch_id = mine.branch_id
    join public.users u on u.id = other.user_id
    where mine.user_id = new.id
      and other.user_id <> new.id
      and u.role = 'manager'
  ) then
    raise exception 'Is branch me pehle se aik manager hai. Aik branch me sirf aik manager ho sakta hai';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_one_manager_per_branch_role on public.users;
create trigger trg_one_manager_per_branch_role
before update of role on public.users
for each row execute function public.enforce_one_manager_per_branch_on_role();
