Create database Transportaion_and_Mobility;
use Transportaion_and_Mobility;
select * from city_target_passenger_rating;
select* from dim_city;
select count(*) from fact_trips;
-- Business Request 1-City level fare and Summery Report
-- Total Trips--
select count(trip_id) as total_Trip from fact_Trips;
-- Average fare per Km---
-- Total Revenune--
select sum(fare_amount)as Total_Revenue from fact_trips;
-- Avg fare per KM--
select sum(fare_amount)/sum(`distance_travelled(km)`) as avg_per_KM from fact_trips;
-- Avg Fare per Trip--
select sum(Fare_Amount)/count(trip_id) as avd_fare_per_trip from fact_trips;
-- %contribution _To_total_Trip citiwise


-- Answer of Business Request 1-City level fare and Summery Report
select city_name as CityName ,count(trip_id) as Total_Trip, sum(fare_amount)as Total_Revenue,
sum(fare_amount)/sum(`distance_travelled(km)`) as avg_per_KM,sum(Fare_Amount)/count(trip_id) as avg_fare_per_trip,
round(count(trip_id)*100.0 /(select count(*) from fact_trips),2) as TripcontributionPercentage  from
fact_trips t
join dim_city c
on t.city_id=c.city_id
group by c.city_name
order by TripcontributionPercentage desc;


select c.city_name,
count(t.trip_id) as city_trips,
round(count(trip_id)*100.0 /(select count(*) from fact_trips),2) as TripcontributionPercentage 
from fact_trips t
join dim_city c
on t.city_id=c.city_id
group by c.city_name
order by TripcontributionPercentage desc;


-- Monthly city level Trips target performance report
select count(trip_id) as actualTrip from fact_trips;
select sum(total_target_trips) as targettrips from monthly_target_trips;


-- Corrected Query
SELECT 
    dc.city_name,
               mtt.Month_name,
                t.actualtrip,
    mtt.targettrips
FROM  
    (SELECT city_id, monthname(STR_TO_DATE(date, '%Y-%m-%d')) ,COUNT(trip_id) AS actualtrip 
     FROM fact_trips WHERE date IS NOT NULL
     GROUP BY city_id, monthname(STR_TO_DATE(date, '%Y-%m-%d')) 
) t 
JOIN 
    (SELECT city_id, monthname(month) AS month_name,SUM(total_target_trips) AS targettrips 
     FROM monthly_target_trips 
     GROUP BY city_id,monthname(month)) mtt  
ON t.city_id = mtt.city_id  
JOIN dim_city dc  
ON t.city_id = dc.city_id;




-- get monthname from date table
SELECT monthname(STR_TO_DATE(date, '%Y-%m-%d')) AS trip_year
FROM fact_trips
WHERE date IS NOT NULL;




-- business requst -3 City-level Repeat Passenger trip frequency Report
    
with base as (
select 
    dc.city_name,
    rtd.trip_count,
    rtd.repeat_passenger_count,
   round( rtd.repeat_passenger_count * 100.0 /
   SUM(rtd.repeat_passenger_count) OVER (PARTITION BY rtd.city_id),2)
    AS trip_frequency_pct 

FROM dim_repeat_trip_distribution rtd
JOIN dim_city dc
    ON rtd.city_id = dc.city_id)
select 
city_name,
SUM(CASE WHEN trip_count = 2 THEN trip_frequency_pct END) AS `2-Trips`,
    SUM(CASE WHEN trip_count = 3 THEN trip_frequency_pct END) AS `3-Trips`,
    SUM(CASE WHEN trip_count = 4 THEN trip_frequency_pct END) AS `4-Trips`,
    SUM(CASE WHEN trip_count = 5 THEN trip_frequency_pct END) AS `5-Trips`,
    SUM(CASE WHEN trip_count = 6 THEN trip_frequency_pct END) AS `6-Trips`,
    SUM(CASE WHEN trip_count = 7 THEN trip_frequency_pct END) AS `7-Trips`,
    SUM(CASE WHEN trip_count = 8 THEN trip_frequency_pct END) AS `8-Trips`,
    SUM(CASE WHEN trip_count = 9 THEN trip_frequency_pct END) AS `9-Trips`,
    SUM(CASE WHEN trip_count = 10 THEN trip_frequency_pct END) AS `10-Trips`
FROM base
GROUP BY city_name
ORDER BY city_name;




-- 4. Identify cities with Highest and lowest cities with total_new passenger

(select city_name, sum(new_passengers) as Total_new_passenger ,'Top 3' as City_Category from fact_passenger_summary fs
join dim_city dc
on fs.city_id =dc.city_id
group by city_name
order by Total_new_passenger desc 
limit 3)
union
(select city_name, sum(new_passengers) as Total_new_passenger ,'Bottom 3' as City_Category from fact_passenger_summary fs
join dim_city dc
on fs.city_id =dc.city_id
group by city_name
order by Total_new_passenger Asc 
limit 3);





-- 5. Identify month with highest revenue for each city


select city_name,month_name,total_revenue,round((total_revenue/city_total.city_revenue)*100,2) as percentage_contribution
from (
-- revenue per city per month
select ft.city_id,monthname(STR_TO_DATE(date, '%Y-%m-%d')) as month_name,
sum(fare_amount) as total_revenue from fact_trips ft
group by ft.city_id,monthname(STR_TO_DATE(date, '%Y-%m-%d')) )sub

join ( -- total revenue per city
select ft.city_id,sum(ft.fare_amount) as city_revenue
from fact_trips ft
group by ft.city_id) as city_total
ON sub.city_id = city_total.city_id
JOIN dim_city dc
    ON sub.city_id = dc.city_id
WHERE (sub.city_id, sub.total_revenue) IN (
    -- pick the max revenue month per city
    SELECT city_id, MAX(total_revenue)
    FROM (
        SELECT 
            ft.city_id,
            MONTHNAME(STR_TO_DATE(ft.date, '%Y-%m-%d')) AS month_name,
            SUM(ft.fare_amount) AS total_revenue
        FROM fact_trips ft
        GROUP BY ft.city_id, MONTHNAME(STR_TO_DATE(ft.date, '%Y-%m-%d'))
    ) t
    GROUP BY city_id
)
ORDER BY dc.city_name;





-- q.6 Repeate passenger Rate Analysis--

select City_name, monthname(month) as Month_name, sum(repeat_passengers) as Repeat_passenger ,
sum(total_passengers) as total_passengers , round((sum(repeat_passengers)/sum(total_passengers))*100,2) as Monthly_repeate_passenger_rate
from fact_passenger_summary fp
join dim_city dc
on fp.city_id= dc.city_id
group by city_name,monthname(month) 
order by city_name;

