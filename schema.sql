-- Hotel Sportsbooking backend til Supabase/Postgres
-- Kør hele denne fil i Supabase SQL Editor.

create extension if not exists pgcrypto;

drop view if exists public_bookings;
drop function if exists book_activity(uuid, text, text, text);
drop function if exists cancel_booking(uuid, text);
drop table if exists bookings;
drop table if exists activities;

create table activities (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  activity_date date not null,
  start_time time not null,
  location text not null,
  capacity integer not null check (capacity > 0),
  created_at timestamptz not null default now()
);

create table bookings (
  id uuid primary key default gen_random_uuid(),
  activity_id uuid not null references activities(id) on delete cascade,
  guest_name text not null,
  room_number text not null,
  cancellation_code text not null,
  created_at timestamptz not null default now(),
  unique (activity_id, room_number, guest_name)
);

create index bookings_activity_id_idx on bookings(activity_id);

-- Offentlig visning uden cancellation_code.
create view public_bookings as
select
  id as booking_id,
  activity_id,
  guest_name,
  room_number,
  created_at
from bookings;

-- Demo-aktiviteter. Ret datoerne til de datoer hotellet ønsker.
insert into activities (title, activity_date, start_time, location, capacity) values
('Morgenyoga', current_date + 1, '08:00', 'Strandterrassen', 8),
('Padel introhold', current_date + 1, '10:00', 'Padelbane 1', 4),
('Guidet løbetur', current_date + 2, '07:30', 'Receptionen', 12),
('Aqua fitness', current_date + 2, '11:00', 'Poolområdet', 10);

-- Funktion med lås, så to gæster ikke kan tage den sidste plads samtidig.
create or replace function book_activity(
  p_activity_id uuid,
  p_guest_name text,
  p_room_number text,
  p_cancellation_code text
)
returns table (
  booking_id uuid
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_capacity integer;
  v_booked integer;
  v_booking_id uuid;
begin
  if length(trim(p_guest_name)) < 2 then
    raise exception 'Navn skal udfyldes.';
  end if;

  if length(trim(p_room_number)) < 1 then
    raise exception 'Værelsesnummer skal udfyldes.';
  end if;

  select capacity
    into v_capacity
    from activities
   where id = p_activity_id
   for update;

  if v_capacity is null then
    raise exception 'Aktiviteten findes ikke.';
  end if;

  select count(*)
    into v_booked
    from bookings
   where activity_id = p_activity_id;

  if v_booked >= v_capacity then
    raise exception 'Holdet er fyldt.';
  end if;

  insert into bookings (
    activity_id,
    guest_name,
    room_number,
    cancellation_code
  )
  values (
    p_activity_id,
    trim(p_guest_name),
    trim(p_room_number),
    p_cancellation_code
  )
  returning id into v_booking_id;

  return query select v_booking_id;
end;
$$;

create or replace function cancel_booking(
  p_booking_id uuid,
  p_cancellation_code text
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  delete from bookings
   where id = p_booking_id
     and cancellation_code = p_cancellation_code;

  if not found then
    raise exception 'Bookingen kunne ikke afbookes fra denne enhed.';
  end if;

  return true;
end;
$$;

-- RLS
alter table activities enable row level security;
alter table bookings enable row level security;

-- Alle må se aktiviteter.
create policy "Public can read activities"
on activities
for select
to anon
using (true);

-- Man må ikke læse bookings-tabellen direkte.
-- Gæster læser i stedet public_bookings-viewet, der ikke viser cancellation_code.

grant usage on schema public to anon;
grant select on activities to anon;
grant select on public_bookings to anon;
grant execute on function book_activity(uuid, text, text, text) to anon;
grant execute on function cancel_booking(uuid, text) to anon;
