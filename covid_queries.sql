select location,count(location)
from coviddeaths
--where iso_code = 
--where location = 'Asia'
where continent is not null
group by location;

select * from coviddeaths
where weekly_icu_admissions <> '';

select location,date,sum(new_vaccinations::numeric)
from covidvaccinations
--where new_vaccinations <> '' and NOT new_vaccinations ~ '^[0-9]+$'
group by location,date;

-- Select Data that we are going to be using
select location,date,total_cases,new_cases,total_deaths,population  
from coviddeaths
where continent <> '' and total_deaths is not null
order by 1,2;

-- Get total cases vs total deaths (likelihood to contract Covid by country)
select location,date,total_cases,total_deaths,(total_deaths/total_cases)*100 as death_percentage
from coviddeaths
where continent <> '' and total_deaths is not null
order by 1,2;

-- Get total cases vs population (percentage of population that got Covid)
select location,date,total_cases,population,(total_cases/population)*100 as percent_population_infected
from coviddeaths
where continent <> '' and total_deaths is not null
order by 1,2;

-- Get countries with Highest Infection Rate compared to population
select location,population,max(total_cases) as highest_infection_count,max((total_cases/population)*100) as percent_population_infected
from coviddeaths
where continent <> '' and total_deaths is not null
group by location,population 
order by percent_population_infected desc;

-- Get countries with the highest death count per population
select location,max(total_deaths) as total_death_count
from coviddeaths
where continent <> '' and total_deaths is not null
group by location 
order by total_death_count desc;

-- Breakdown by continent
-- Get the continents with the highest death counts per population
select continent,max(total_deaths) as total_deaths_by_continent 
from coviddeaths
where continent != ''
group by continent
order by total_deaths_by_continent desc;

-- Global numbers
select	
	sum(new_cases) as total_cases,
	sum(new_deaths) as total_deaths,
	case
		when sum(new_deaths) = 0
		then 0
		else sum(new_deaths)/sum(new_cases)*100
	end
	as death_percentage
from coviddeaths
where continent <> ''
--group by date
order by 1,2;

-- Get total population vs vaccinations
with pop_vs_vac (continent,location,date,population,new_vaccinations,rolling_people_vaccinated)
as (
select
	d.continent,
	d.location,
	d.date,
	d.population,
	v.new_vaccinations,
	sum(v.new_vaccinations::numeric) over (partition by d.location order by d.location,d.date) as rolling_people_vaccinated
from coviddeaths d
join covidvaccinations v
	on d.location = v.location
	and d.date = v.date
where d.continent is not null
--order by 2,3
)

select
	*,
	(rolling_people_vaccinated/population)*100
from pop_vs_vac;

-- Create temp table
drop table if exists temp_percent_population_vaccinated;

create temp table temp_percent_population_vaccinated
(
	continent varchar(50),
	location varchar(50),
	date date,
	population float4,
	new_vaccinations float4,
	rolling_people_vaccinated float4	
);

insert into temp_percent_population_vaccinated (continent,location,date,population,new_vaccinations,rolling_people_vaccinated)
select
	d.continent,
	d.location,
	d.date::date,
	d.population,
	v.new_vaccinations::float4,
	sum(v.new_vaccinations::numeric) over (partition by d.location order by d.location,d.date) as rolling_people_vaccinated
from coviddeaths d
join covidvaccinations v
	on d.location = v.location
	and d.date = v.date
where d.continent is not null;

select
	*,
	(rolling_people_vaccinated/population)*100
from temp_percent_population_vaccinated;

-- create view to store data for visualizations
create view percent_population_vaccinated as
(
	select
		d.continent,
		d.location,
		d.date::date,
		d.population,
		v.new_vaccinations::float4,
		sum(v.new_vaccinations::numeric) over (partition by d.location order by d.location,d.date) as rolling_people_vaccinated
	from coviddeaths d
	join covidvaccinations v
		on d.location = v.location
		and d.date = v.date
	where d.continent is not null
);

select * from percent_population_vaccinated;

