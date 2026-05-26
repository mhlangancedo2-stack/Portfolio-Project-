create database glb_HIV_database;
show tables;

select* 
from deaths;

select* 
from art_coverage;

select* 
from pmtct;

select* 
from adults_15_49;

select WHO_Region, sum(Count_median) as People_Living_With_HIV
from plwh
where `year` =2018
group by WHO_Region;

select distinct(country), left(country,3) as country_code
from adults_15_49;

select Country
from deaths
where Country like '%a';

select p.Country, d.`year`,p.Count_median, d.Count_median
from plwh p
join deaths d on p.Country =d.country
				and p.`Year`= d.`Year`
where p.`year`= 2010;

select sum(Count_median), "WHO Region"
from adults_15_49
where `year` = 2018
having sum(Count_median) > 100000;


select WHO_Region, substring(WHO_Region,2,3) as region_code,
count(substring(WHO_Region,2,3)) over(partition by substring(WHO_Region,2,3)) as 
total_count_per_region
from pmtct;


select Country, WHO_Region, Count_median,
dense_rank() over(partition by WHO_Region order by Count_median desc)  country_rank_per_region
from plwh;

with art_coverage_per_region as(
select distinct `WHO Region`,
sum(`Reported number of people receiving ART`) over(partition by `WHO Region`) art_coverage_by_WHO_region
from art_coverage)

select distinct `WHO Region`, art_coverage_by_WHO_region,
dense_rank() over(order by art_coverage_by_WHO_region desc) as region_rank
from art_coverage_per_region
where art_coverage_by_WHO_region > 500000
order by art_coverage_by_WHO_region desc;


ALTER TABLE pmtct
CHANGE `WHO Region` WHO_Region varchar(50);

ALTER TABLE plwh
CHANGE `WHO Region` WHO_Region varchar(50);

ALTER TABLE deaths
CHANGE `WHO Region` WHO_Region varchar(50);

ALTER TABLE art_pediatric
CHANGE `WHO Region` WHO_Region varchar(50);

ALTER TABLE art_coverage
CHANGE `WHO Region` WHO_Region varchar(50);

ALTER TABLE adults_15_49
CHANGE `WHO Region` WHO_Region varchar(50);

-- Listing all unique Country names from the plwh table and the number of characters in each name. 
-- and Ordering the results so the longest country names appear at the top.

select distinct country, length(country) as charactor_length
from plwh
order by charactor_length desc;

-- using the adult_prevalence table, calculating the average Count_median for each WHO Region for the year 2018. 
-- and also including regions where the average is greater than 1.0

select WHO_Region, avg(count_median) avg_count_median
from adults_15_49
where `year`=2018
group by WHO_Region
having avg_count_median > 1;

-- Select the Country and Count_median from the hiv_deaths table where the count is greater than 5,000. 
-- Sort the list by Count_median in descending order.

select country, count_median
from deaths
where Count_median >5000 and WHO_Region like '%Africa%' and `year`=2018
order by Count_median desc;

select*
from deaths;

-- Creating a single list of all countries mentioned in both the art_coverage and pediatric_art tables. 
-- Adding a column named Program_Type that labels records from the first table as "General ART" and the second as "Pediatric ART". 
-- and also ensuring there are no duplicate country-label pairs.

select distinct country,  'General ART' AS 'program_type' 
from art_coverage 
union
select distinct country, 'Pediatric ART' AS 'program_type'
from art_pediatric;

-- Identify regions in the pmtct_data table that have an average Percentage Recieved_median (PMTCT coverage) of 90% or higher.


select distinct WHO_Region, percentage_median,
avg(percentage_median ) over(partition by WHO_Region) as pmtct_perfomance 
from pmtct
where percentage_median >=90;

select*
from plwh;

select*
from deaths;

alter table pmtct
change `Percentage Recieved_median` percentage_median varchar (50);

--  Mortality Ratio Analysis: Constructing a query using a Common Table Expression (CTE) that combines data from plwh and hiv_deaths for the year 2018. 
-- Calculating a "Mortality Ratio" for each country (Total Deaths / Total People Living with HIV). Return the Country, WHO Region, and the Ratio.

with death_plwh as(
select deaths.country, plwh.WHO_Region,deaths.Count_median/plwh.Count_median as mortality_ratio
from plwh
join deaths on deaths.Country = plwh.Country
			and  deaths.`Year` = plwh.`Year`
where plwh.`Year` = 2018)

select country, WHO_Region, mortality_ratio
from death_plwh;

with death_plwh as(
select deaths.country, plwh.WHO_Region,deaths.Count_median as PLWH
from plwh
join deaths on deaths.Country = plwh.Country
			and  deaths.`Year` = plwh.`Year`
where plwh.`Year` = 2018)

select country, PLWH
from death_plwh;

select*
from plwh


select*
from art_coverage;

-- Using the art_coverage table, use a Window Function to rank countries within each WHO Region based on their Reported number of people receiving ART. 
-- The country with the highest number in each region should be ranked #1.

select WHO_region, country,
dense_rank() over(partition by WHO_Region order by `Reported number of people receiving ART` desc) as regional_ranking
from art_coverage;

alter table art_coverage
change `Reported number 0f people receiving ART` ppl_on_art varchar(50);

--  Data Standardization & Join: Notice that the plwh table uses a column named WHO_Region (with an underscore), while art_coverage uses WHO Region (with a space). 
-- Write a join query between these two tables that standardizes the region names to all uppercase and returns the Country,
-- WHO Region, and the Estimated number of people living with HIV_median.

select distinct ac.Country, upper(ac.`WHO Region`) as WHO_REGION, ac.`Estimated number of people living with HIV_median`
from plwh p
join art_coverage ac on p.Country = ac.Country;

--  Writing a query to find countries in the art_coverage table that have 'Nodata' in the Estimated ART coverage (%) column.
-- For these countries, display the country name and the Reported number of people receiving ART.

select country, `Reported number of people receiving ART`
from art_coverage
where `Estimated ART coverage among people living with HIV (%)` like 'Nodata';

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Calculating the ratio of HIV-related deaths to the total number of people living with HIV (PLWH) for every country. 
-- and ranking these countries globaly based on this ratio, ensuring we can see which countries are struggling the most despite their population size."

WITH RecentData AS (
    SELECT d.Country, d.Count_median AS Total_Deaths, p.Count_median AS Total_PLWH, d.Year
    FROM deaths d
    JOIN plwh p ON d.Country = p.Country AND d.Year = p.Year
    WHERE d.Year = (SELECT MAX(Year) FROM deaths)
)
SELECT 
    Country,
    Total_Deaths,
    Total_PLWH,
    round(Total_Deaths / Total_PLWH,2) AS Mortality_Ratio,
    DENSE_RANK() OVER(ORDER BY (Total_Deaths / Total_PLWH) DESC) AS Mortality_Rank
FROM RecentData
WHERE Total_PLWH > 0 
ORDER BY Mortality_Rank;


select* 
from art_coverage;


-- Providing a report that compares the average ART coverage percentage for children versus the general population across each WHO Region? 
-- hence looking for regions where the gap between these two metrics is greater than 15%

WITH RegionalCoverage AS (
    SELECT 
        ac.`WHO Region`,
        AVG(ac.`Estimated ART coverage among people living with HIV (%)_median`) AS Avg_Adult_ART,
        AVG(ap.`coverage among children (%)_median`) AS Avg_Pediatric_ART
    FROM art_coverage ac
    JOIN art_pediatric ap ON ac.Country = ap.Country
    GROUP BY ac.`WHO Region`)
SELECT `WHO Region`,
ROUND(Avg_Adult_ART, 2) AS Adult_ART,
ROUND(Avg_Pediatric_ART, 2) AS Pediatric_ART,
ROUND(Avg_Adult_ART - Avg_Pediatric_ART, 2) AS Coverage_Gap
FROM RegionalCoverage
WHERE (Avg_Adult_ART - Avg_Pediatric_ART) > 15
ORDER BY Coverage_Gap DESC;



alter table art_coverage
change `WHO_Region` `WHO Region` varchar(50);

with Country_Perfomance as(
select 
	ac.Country,
	avg(ac.`Estimated ART coverage among people living with HIV (%)_median`) General_ART,
    avg(p_a.percentage_median) PMTCT_ART
from art_coverage ac
Join PMTCT p_a on ac.Country = p_a.Country
group by Country)


select country, General_ART, PMTCT_ART,
Case 
    when General_ART >= 90 and PMTCT_ART >= 90 then 'Elite Performance' 
	when General_ART <90 and PMTCT_ART < 90 then 'Uncategorized'
    when General_ART >=90 and PMTCT_ART < 90 then 'Improving'
    when PMTCT_ART >=90 and General_ART < 90 then 'Improving'
End as 'ART Coverage Category'
from Country_Perfomance
order by General_ART desc, PMTCT_ART desc;

-- Rolling Total of Yearly deaths in The African Continent 

with Africa as (
select WHO_Region, Country, `Year`, Count_median,
-- Use a Window Function to partition by the WHO_Region then order by country and year 
	sum(count_median) over(partition by WHO_Region order by Country asc, Year asc) as rolling_Total
from deaths)

select  WHO_Region, Country, `Year`, Count_median, rolling_Total
from Africa
where WHO_Region like '%Africa%';

select p.country, p.`Year`,
sum(p.Count_median) over(order by p.Country) 
from plwh p
join art_coverage ac on p.Country = ac.Country
    


select *
from plwh

-- Identifying Countries with a higher prevalence more than the average of their respective WHO_REGION

with disparity as (
select WHO_Region, `Year`, country, count_median, 
avg(count_median) over(partition by WHO_Region order by `Year`) as Regional_Average
from adults_15_49
WHERE Year = (SELECT MAX(Year) FROM adults_15_49) -- The subquery in this case helps in selectig the latest year  
)
select WHO_Region, country, count_median, round(Regional_Average,2)
from disparity
where count_median > Regional_Average
order by count_median desc

select `WHO Region`, Country, `Reported number of people receiving ART`,
dense_rank() over(partition by `WHO Region` order by `Reported number of people receiving ART`) as `RANK`
from art_coverage;

-- Calculating the  'Growth of the Burden' for the African region, Showing the number of deaths in a particular year and a rolling total

with commulative_Mortality as(
select distinct`Year`,
		sum(Count) over(partition by `Year` order by `Year`) as Total_Deaths
from deaths
where WHO_Region like '%Africa%')

select distinct `Year`, Total_Deaths,
		sum(Total_Deaths ) over(order by `Year`) as Rolling_Total
from commulative_Mortality;


-- FINDING THE LEADING COUNTRY IN PEOPLE WHO ARE ON ART IN EACH REGION, SHOWING ONLY THE HIGHEST COUNTRY IN PEOPLE ON ART IN EACH REGION AND THE NUMBER OF PEOPLE ON ART IN THAT LEADING COUNTRY 
with High as (
select `WHO Region`, Country, `Reported number of people receiving ART` as On_ART,
-- First use dense_rank to rank the countries by ART coverage per region 
		dense_rank() over(partition by `WHO Region` order by `Reported number of people receiving ART` desc) as `Rank`
from art_coverage)

-- Selected the columns/Variables I needed and the and specified in the where statement (where `Rank` = 1)
select `WHO Region`, Country, On_ART
from High
where `Rank` = 1;

with Unmet as (
select p.Country,
sum(p.Count_median) over(partition by p.`Year` order by ac.Country desc) `Living with HIV`, 
sum(`Reported number of people receiving ART`) over(partition by p.`Year` order by ac.Country desc) On_ART
from plwh p
join art_coverage ac on p.Country = ac.Country 
Where `Year` in (2010,2018))

select Country, `Living with HIV`, On_ART,
		`Living with HIV`- On_ART as Unmet_Need
from Unmet;

with xxx as (
select distinct WHO_Region,
(count(Country) over(partition by WHO_Region order by WHO_Region)
from adults_15_49)
-- where `Year` =2018;

select WHO_Region, distinct Total_Countries
from xxx


