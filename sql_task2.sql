--1
select city "Cities" from airports
group by city 
having count(airport_code) > 1
--группировка > количество ID аэропортов больше 1

--2
with cte as (
	select aircraft_code from aircrafts
	where "range" = (select max("range") from aircrafts)
)
select departure_airport_name "Airport name" from routes
where aircraft_code in (select aircraft_code from cte)
union 
select arrival_airport_name from routes
where aircraft_code in (select aircraft_code from cte)
--cte с результатми по самому "долголету", потом работа c routes, так как mat.view быстрее.
-- юнионом убираем копии и объединяем результаты

--3
select flight_no "Flight#", actual_departure-scheduled_departure "Delay" from bookings.flights
where status = 'Departed' or status = 'Arrived'
order by 2 desc
limit 10
--фильтруем рейсы, вылет которых уже состоялся
--сортирум по убыванию + первые 10

--4
--#варинат1
--left join таблицы билетов и посадочных талонов, оставляем уникальные бронирования.
select distinct book_ref "Bookings" from tickets t
left join boarding_passes bp on bp.ticket_no = t.ticket_no
where bp.ticket_no is null

--#вариант2
--!!!Неправильный вариант с нахождением билетов, которые попали в бронирование но не попали в посадочные талоны
--для рейсов, которые уже отправились!!!

--находим билеты прошедшие регистрацию в рейсах, у которых отправление по графику
--наступает ранее момента bookings.now()
with cte as (
			select ticket_no from boarding_passes bp 
			where flight_id in (select flight_id from flights f where scheduled_departure < bookings.now())
),
--находим бронирования содержащие эти билеты. 
book as (
		select book_ref  from tickets t
		where  ticket_no in (select ticket_no from cte)
)
--все билеты, содержащиеся в этих бронированиях
select ticket_no from tickets
where book_ref in (select book_ref from book)
except
--минус билеты прошедшие регистрацию
select ticket_no from cte

--5
select 
	tab1.flight_id,
	count "occupied seats", 
	total - count "empty seats",--
	round((total - count)::numeric*100/total) "empty seats~%",
	departure_airport,
	actual_departure::date,
	--оконная с суммой занятых мест, группировка по аэропорту и дате. Сортировка - чтобы реализовать накопительный итог
	sum(count) over (partition by departure_airport, actual_departure::date order by actual_departure) "passengers left"
from (
	--кол-во мест, тех кто прошел регистрацию
	select flight_id, count(seat_no) from boarding_passes bp
	group by flight_id
) as tab1
join (
	--
	select departure_airport, flight_id, total, actual_departure  from flights f 
	--вместительность join flight_id
	join (
		--вместительность самолетов
		select aircraft_code, count(seat_no) total from seats s
		group by aircraft_code) as ts
	on f.aircraft_code = ts.aircraft_code
	--находим только улетевшие, для статистике по сумме убывших из аэропорта
	where actual_departure is not null
) as tab2
on tab1.flight_id = tab2.flight_id

--6
--Join таблиц flights - aircrafts, после находим процент. Из-за округления процент скачет 99~101
select 
	model "Model",
	round(count(flight_id)*1.0/(select count(flight_id) from flights)*100) "Percent%"
from flights f
join aircrafts a on a.aircraft_code = f.aircraft_code
group by model

--7
--Таких городов не нашел.
--Вылеты с ценами бизнес-класс
with busines as (
	select flight_id, amount from ticket_flights tf
	where fare_conditions = 'Business'
), econom as ( -- вылеты эконом 
	select flight_id, amount from ticket_flights tf1
	where  fare_conditions = 'Economy'
)
select distinct arrival_city from busines b --join таблиц по условиям разницы стоимостей + join представления, чтобы получить имя города
join econom e on e.flight_id = b.flight_id and e.amount > b.amount
join bookings.flights_v fv  on b.flight_id = fv.flight_id

--8
--декартово произведение с исключением повторов
create view no_direct_flights as (
	select distinct  r.departure_city, r2.arrival_city  from routes r, routes r2
	where r.departure_city > r2.arrival_city 
	except 
	--минус все рейсы с исключением повторов
	select distinct  departure_city, arrival_city from routes
	where departure_city > arrival_city
)
select concat_ws(' - ', departure_city, arrival_city) "no direct" from no_direct_flights ndf 


