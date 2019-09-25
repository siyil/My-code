/* Analysis on expired reservation fraud */
/* siyi.luo@ */
/* Last Updated: 9/25/2019 */

/* Reservation expired by new users */
select name, count(distinct id) as num_reservations_expired, count(distinct user_id) as num_users,
sum(case when total_completed_lifetime = 0 then 1 else 0 end) as zero_completed_lifetime, zero_completed_lifetime/num_reservations_expired as pct_zero_completed_lifetime,
sum(case when total_res_expired_lifetime = 1 then 1 else 0 end) as zero_expired_lifetime, zero_expired_lifetime/num_reservations_expired as pct_zero_expired_lifetime,
sum(case when created_at::date = user_created_at::date then 1 else 0 end) as first_day_users, first_day_users/num_reservations_expired as pct_first_day_users
from (
    select t.id, t.user_id, t.created_at, b.geohash, r.name, t.status, u.created_at as user_created_at,
            SUM(case when t.status = 'completed' then 1 else 0 end) over (partition by t.user_id order by t.created_at) as total_completed_lifetime,
            SUM(case when t.status = 'reservation_expired' then 1 else 0 end) over (partition by t.user_id order by t.created_at) as total_res_expired_lifetime
        from public.trips t
        join (select id, geohash from public.bikes) b on t.bike_id = b.id
        join (select distinct region_id, geohash from public.geohashes) as g
        on g.geohash = b.geohash
        JOIN public.regions as r
        ON r.id = g.region_id
        join public.users u on t.user_id = u.id
)
where name in ('Berlin', 'Hamburg', 'Cologne', 'Munich', 'Paris') and status = 'reservation_expired' and created_at between '2019-09-01' and '2019-09-25'
group by 1
order by 1

/* With time series */
select name, created_at::date, count(distinct id) as num_reservations_expired,
sum(case when total_completed_lifetime = 0 then 1 else 0 end) as zero_completed_lifetime, zero_completed_lifetime/num_reservations_expired as pct_zero_completed_lifetime,
sum(case when total_res_expired_lifetime = 1 then 1 else 0 end) as zero_expired_lifetime, zero_expired_lifetime/num_reservations_expired as pct_zero_expired_lifetime,
sum(case when created_at::date = user_created_at::date then 1 else 0 end) as first_day_users, first_day_users/num_reservations_expired as pct_first_day_users
from (
    select t.id, t.user_id, t.created_at, b.geohash, r.name, t.status, u.created_at as user_created_at,
            SUM(case when t.status = 'completed' then 1 else 0 end) over (partition by t.user_id order by t.created_at) as total_completed_lifetime,
            SUM(case when t.status = 'reservation_expired' then 1 else 0 end) over (partition by t.user_id order by t.created_at) as total_res_expired_lifetime
        from public.trips t
        join (select id, geohash from public.bikes) b on t.bike_id = b.id
        join (select distinct region_id, geohash from public.geohashes) as g
        on g.geohash = b.geohash
        JOIN public.regions as r
        ON r.id = g.region_id
        join public.users u on t.user_id = u.id
)
where name in ('Berlin', 'Hamburg', 'Cologne', 'Munich', 'Paris') and status = 'reservation_expired' and created_at between '2019-09-01' and '2019-09-25'
group by 1,2
order by 1,2



/* New user account */
select date, SUM(case when name = 'Berlin' then num_new_users end) as Berlin, SUM(case when name = 'Cologne' then num_new_users end) as Cologne,
SUM(case when name = 'Hamburg' then num_new_users end) as Hamburg, SUM(case when name = 'Munich' then num_new_users end) as Munich, SUM(case when name = 'Paris' then num_new_users end) as Paris
from (
  select gr.name, u.created_at::date as date, count(distinct u.id) as num_new_users
  from public.users u
  join (select g.region_id, g.geohash, r.name from public.geohashes as g join (select id, name from public.regions) as r on g.region_id = r.id) as gr
  on gr.geohash = u.geohash
  where gr.name in ('Berlin', 'Hamburg', 'Cologne', 'Munich', 'Paris') and u.created_at between '2019-09-01' and '2019-09-25'
  group by 1,2
 )
group by 1
order by 1

/* New users who expire reservations */
select date,
SUM(case when name = 'Berlin' then num_new_users end) as Berlin, SUM(case when name = 'Berlin' then num_new_users_expired_reservation end) as Berlin_expired,
SUM(case when name = 'Cologne' then num_new_users end) as Cologne, SUM(case when name = 'Cologne' then num_new_users_expired_reservation end) as Cologne_expired,
SUM(case when name = 'Hamburg' then num_new_users end) as Hamburg, SUM(case when name = 'Hamburg' then num_new_users_expired_reservation end) as Hamburg_expired,
SUM(case when name = 'Munich' then num_new_users end) as Munich, SUM(case when name = 'Munich' then num_new_users_expired_reservation end) as Munich_expired,
SUM(case when name = 'Paris' then num_new_users end) as Paris, SUM(case when name = 'Paris' then num_new_users_expired_reservation end) as Paris_expired
from (
    select gr.name, u.created_at::date as date, count(distinct u.id) as num_new_users,
    sum(case when u.id in (
      select t.user_id from public.trips t
      join (select id, geohash from public.bikes) b on t.bike_id = b.id
      join (select g1.region_id, g1.geohash, r1.name from public.geohashes as g1 join (select id, name from public.regions) as r1 on g1.region_id = r1.id) as gr1
      on gr1.geohash = b.geohash
     and gr1.name in ('Berlin', 'Hamburg', 'Cologne', 'Munich', 'Paris') and t.status = 'reservation_expired' and t.created_at between '2019-09-01' and '2019-09-25'
    ) then 1 else 0 end) as num_new_users_expired_reservation
    from public.users u
    join (select g.region_id, g.geohash, r.name from public.geohashes as g join (select id, name from public.regions) as r on g.region_id = r.id) as gr
    on gr.geohash = u.geohash
    where gr.name in ('Berlin', 'Hamburg', 'Cologne', 'Munich', 'Paris') and u.created_at between '2019-09-01' and '2019-09-25'
    group by 1,2
)
group by 1
order by 1


/* Uncollected Revenue */
select name, created_at::date, sum(uncollected_revenue), sum(case when status = 'reservation_expired' then uncollected_revenue else 0 end) as uncollected_revenue_expired
from (
    select t.id, t.user_id, t.created_at, b.geohash, r.name, t.status, u.created_at as user_created_at, m.uncollected_revenue,
            SUM(case when t.status = 'completed' then 1 else 0 end) over (partition by t.user_id order by t.created_at) as total_completed_lifetime,
            SUM(case when t.status = 'reservation_expired' then 1 else 0 end) over (partition by t.user_id order by t.created_at) as total_res_expired_lifetime
        from public.trips t
        join dm.revenue_report_2019usd as m on t.id = m.trip_id
        join (select id, geohash from public.bikes) b on t.bike_id = b.id
        join (select distinct region_id, geohash from public.geohashes) as g
        on g.geohash = b.geohash
        JOIN public.regions as r
        ON r.id = g.region_id
        join public.users u on t.user_id = u.id
)
where name in ('Berlin', 'Hamburg', 'Cologne', 'Munich', 'Paris') and created_at between '2019-09-01' and '2019-09-25'
group by 1,2
order by 1,2

select date,
SUM(case when name = 'Berlin' then uncollected_revenue end) as Berlin,
SUM(case when name = 'Cologne' then uncollected_revenue end) as Cologne,
SUM(case when name = 'Hamburg' then uncollected_revenue end) as Hamburg,
SUM(case when name = 'Munich' then uncollected_revenue end) as Munich,
SUM(case when name = 'Paris' then uncollected_revenue end) as Paris,
SUM(case when name = 'Berlin' then uncollected_revenue_expired end) as Berlin_expired,
SUM(case when name = 'Cologne' then uncollected_revenue_expired end) as Cologne_expired,
SUM(case when name = 'Hamburg' then uncollected_revenue_expired end) as Hamburg_expired,
SUM(case when name = 'Munich' then uncollected_revenue_expired end) as Munich_expired,
SUM(case when name = 'Paris' then uncollected_revenue_expired end) as Paris_expired
from (
    select name, created_at::date as date, sum(uncollected_revenue) as uncollected_revenue, sum(case when status = 'reservation_expired' then uncollected_revenue else 0 end) as uncollected_revenue_expired
    from (
        select t.id, t.user_id, t.created_at, b.geohash, r.name, t.status, u.created_at as user_created_at, m.uncollected_revenue,
                SUM(case when t.status = 'completed' then 1 else 0 end) over (partition by t.user_id order by t.created_at) as total_completed_lifetime,
                SUM(case when t.status = 'reservation_expired' then 1 else 0 end) over (partition by t.user_id order by t.created_at) as total_res_expired_lifetime
            from public.trips t
            join dm.revenue_report_2019usd as m on t.id = m.trip_id
            join (select id, geohash from public.bikes) b on t.bike_id = b.id
            join (select distinct region_id, geohash from public.geohashes) as g
            on g.geohash = b.geohash
            JOIN public.regions as r
            ON r.id = g.region_id
            join public.users u on t.user_id = u.id
    )
    where name in ('Berlin', 'Hamburg', 'Cologne', 'Munich', 'Paris') and created_at between '2019-09-01' and '2019-09-25'
    group by 1,2
)
group by 1
order by 1
