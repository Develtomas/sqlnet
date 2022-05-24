--1
select city "Города "from airports
group by city 
having count(airport_code) > 1
--группировка > число ID аэропортов больше 1

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
-- Юнионом убираем копии и объединяем результаты

--3