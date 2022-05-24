--1
select city "Города "from airports
group by city 
having count(airport_code) > 1
--группировка > количество ID аэропортов больше 1

--2
with cte as (
	select aircraft_code from aircrafts
	where "range" = (select max("range") from aircrafts)
)
select departure_airport_name "Имя аэропорта" from routes
where aircraft_code in (select aircraft_code from cte)
union 
select arrival_airport_name from routes
where aircraft_code in (select aircraft_code from cte)
--cte с результатми по самому "долголету", потом работа c routes, так как mat.view быстрее.
-- юнионом убираем копии и объединяем результаты

--3
select flight_no "Номер рейса", actual_departure-scheduled_departure "Задержка" from bookings.flights
where status = 'Departed' or status = 'Arrived'
order by 2 desc
limit 10
--фильтруем рейсы, вылет которых уже состоялся
--сортирум по убыванию + первые 10

--4