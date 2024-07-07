
-- dataset : https://www.kaggle.com/datasets/heesoo37/120-years-of-olympic-history-athletes-and-results
create database olympics
USE olympics;
SELECT * FROM ATHLETE_EVENTS
SELECT * FROM noc_regions


--QUERIES:
-- 1.How many olympics games have been held?

SELECT COUNT(DISTINCT GAMES) FROM athlete_events

-- 2.List down all Olympics games held so far.

SELECT YEAR, SEASON, CITY FROM athlete_events
GROUP BY Season, City, YEAR
ORDER BY YEAR ASC

--OR
SELECT DISTINCT YEAR, SEASON, CITY FROM athlete_events
ORDER BY YEAR;



-- 3.Mention the total no of nations who participated in each olympics game?

 with all_countries as
        (select games, nr.region
        from athlete_events ah
        join noc_regions nr
		ON nr.noc= ah.noc
        group by games, nr.region)
    select games, count(1) as total_countries
    from all_countries
    group by games
    order by games;
	
	--Or // this method was tried but values veries 
	select games, COUNT(distinct team) as total_countries from athlete_events
	group by Games;


-- 4.Which year saw the highest and lowest no of countries participating in olympics?
with all_countries as
              (select games, nr.region
              from athlete_events ae                      
              join noc_regions nr
			  ON nr.noc=ae.noc
              group by games, nr.region),---||joined the two tables and extract the games and rejion fields  
										 --- and therefore grouping the games and the countries. 
          tot_countries as
              (select games, count(1) as total_countries
              from all_countries
              group by games)

      select distinct
      concat(first_value(games) over(order by total_countries)
      , ' - '
      , first_value(total_countries) over(order by total_countries)) as Lowest_Countries,

      concat(first_value(games) over(order by total_countries desc)
      , ' - '
      , first_value(total_countries) over(order by total_countries desc)) as Highest_Countries
      from tot_countries
      order by 1;

	  ----////////////////////////////////////////////////////////////////////////////////////////

WITH COUNTRIES AS (
    SELECT YEAR,COUNT(DISTINCT NOC) AS num_countries
    FROM ATHLETE_EVENTS
    GROUP BY YEAR
)

SELECT
    MAX(num_countries) AS highest_num_countries,
    (SELECT TOP 1 YEAR FROM COUNTRIES WHERE num_countries = (SELECT MAX(num_countries) FROM COUNTRIES)) AS highest_year,
    MIN(num_countries) AS lowest_num_countries,
    (SELECT TOP 1 YEAR FROM COUNTRIES WHERE num_countries = (SELECT MIN(num_countries) FROM COUNTRIES)) AS lowest_year
FROM COUNTRIES;






---5. Which nation has participated in all of the olympic games?

SELECT TEAM AS NATIONS,count(distinct games) as Total_participated_games  FROM athlete_events
GROUP BY Team
HAVING COUNT(DISTINCT Games) = (SELECT COUNT(DISTINCT Games) FROM athlete_events);

----- OR

with tot_games as
        (select count(distinct games) as total_games
        from athlete_events),
    countries as
        (select games, nr.region as country
        from athlete_events ae
        join noc_regions nr
		ON nr.noc=ae.noc
        group by games, nr.region),
    countries_participated as
        (select country, count(1) as total_participated_games
        from countries
        group by country)
select cp.*
from countries_participated cp
join tot_games tg 
on tg.total_games = cp.total_participated_games
order by total_participated_games;




-- 6.Identify the sport which was played in all summer olympics.
with table1 as
	(select COUNT( distinct games) as total_summer_games from athlete_events
	where Season= 'summer'),

table2 as
	( select distinct sport,games
	from athlete_events
	where Season = 'summer' 
	),

table3 as
	(select sport,count(games) as no_of_games
	from table2
	group by sport)

select * 
from table3
join table1
on table1.total_summer_games=table3.no_of_games;


-- 7.Which Sports were just played only once in the olympics?

Select distinct sport, no_of_games
from
		(select sport,count(distinct games) as no_of_games
		from athlete_events
		group by Sport
		)as table1

where no_of_games = 1;

---OR ////////////////////////////////////////////////////////////////
  with t1 as
          	(select distinct games, sport
          	from athlete_events),
          t2 as
          	(select sport, count(1) as no_of_games
          	from t1
          	group by sport)
      select t2.*, t1.games
      from t2
      join t1 on t1.sport = t2.sport
      where t2.no_of_games = 1
      order by t1.sport;


-- 8.Fetch the total no of sports played in each olympic games.

with table1 as
	(select distinct games,Sport 
	from athlete_events
	),

	table2 as
	(select Games, COUNT(1)as no_of_sport
	from table1
	group by Games
	)
select * from table2
order by no_of_sport desc;

---OR////////////////////////////////////////////////////

Select games,count(1) as no_of_sport
from
			(select distinct games, sport 
			from athlete_events) as table1
group by Games
order by no_of_sport desc;


-- 9.Fetch details of the oldest athletes to win a gold medal.

with detail as
            (select name,sex,age
              ,team,games,city,sport, event, medal
            from athlete_events),
        ranking as
            (select *, rank() over(order by age desc) as rnk
            from detail
            where medal='Gold')
    select *
    from ranking
    where rnk = 1;


-- 10.Find the Ratio of male and female athletes participated in all olympic games.
WITH athlete_counts AS 
	(SELECT  SEX,
    COUNT(*) AS total_athletes
    FROM ATHLETE_EVENTS GROUP BY SEX)
SELECT
  ROUND(
    (SELECT total_athletes FROM athlete_counts WHERE SEX = 'M') * 1.0,
    2) AS male_ratio,

   ROUND(
    (SELECT total_athletes FROM athlete_counts WHERE SEX = 'F') * 1.0,
    2) AS female_ratio ;

-- 11.Fetch the top 5 athletes who have won the most gold medals.


SELECT top(5)name,team, COUNT(*) AS gold_medals
FROM athlete_events
WHERE medal = 'Gold'
GROUP BY name,Team
ORDER BY gold_medals DESC;


-- 12.Fetch the top 5 athletes who have won the most medals (gold/silver/bronze).
SELECT top(5)name,team,sport, COUNT(*) AS medals
FROM athlete_events
where Medal in ('gold','silver','bronze')
GROUP BY name,Team,Sport
ORDER BY medals DESC;

-- 13.Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won.
WITH total_countries AS (
    SELECT nr.region, ae.medal
    FROM athlete_events ae
    JOIN noc_regions nr
	ON ae.noc = nr.noc
),

medal_count AS (
    SELECT region,
    COUNT(*) AS total_medals
    FROM total_countries
    WHERE medal IS NOT NULL AND medal != 'NA'
    GROUP BY region
),

ranked_countries AS (
    SELECT 
        region,
        total_medals,
        ROW_NUMBER() OVER (ORDER BY total_medals DESC) AS rank
    FROM medal_count
)

SELECT 
    region,
    total_medals
FROM ranked_countries
WHERE rank <= 5
ORDER BY rank;

	

-- 14.List down total gold, silver and broze medals won by each country.

---- PIVOT Table was used in this query

Select * from

		(select nr.region , ae.Medal
		from athlete_events ae
		join noc_regions nr
		on nr.NOC=ae.NOC
		Where Medal <> 'NA'
		)as tb1

Pivot
	(
		count(medal)
		for medal in ([gold], [silver], [bronze])

	) as tb2

order by gold desc, silver desc, bronze desc;


-- 15.List down total gold, silver and broze medals won by each country corresponding to each olympic games.

SELECT games, region,
COUNT(CASE WHEN medal = 'Gold' THEN medal END) AS Gold_medal,
COUNT(CASE WHEN medal = 'Silver' THEN medal END) AS Silver_medal,
COUNT(CASE WHEN medal = 'Bronze' THEN medal END) AS Bronze_medal
FROM athlete_events AS a
JOIN noc_regions AS n 
ON a.NOC = n.NOC
GROUP BY games,region
order by games;

-- 16.Identify which country won the most gold, most silver and most bronze medals in each olympic games.
WITH Medal_Counts AS (
    SELECT 
        NR.REGION AS COUNTRY, 
        AE.GAMES, 
        COUNT(CASE WHEN AE.MEDAL = 'Gold' THEN 1 END) AS Gold_Medals,
        COUNT(CASE WHEN AE.MEDAL = 'Silver' THEN 1 END) AS Silver_Medals,
        COUNT(CASE WHEN AE.MEDAL = 'Bronze' THEN 1 END) AS Bronze_Medals
    FROM ATHLETE_EVENTS AE
    JOIN NOC_REGIONS NR ON NR.NOC = AE.NOC
    GROUP BY NR.REGION, AE.GAMES
),

Gold_Winners AS (
    SELECT COUNTRY, GAMES, Gold_Medals,
           ROW_NUMBER() OVER (PARTITION BY GAMES ORDER BY Gold_Medals DESC) AS rn
    FROM Medal_Counts
),

Silver_Winners AS (
    SELECT COUNTRY, GAMES, Silver_Medals,
           ROW_NUMBER() OVER (PARTITION BY GAMES ORDER BY Silver_Medals DESC) AS rn
    FROM Medal_Counts
),

Bronze_Winners AS (
    SELECT COUNTRY, GAMES, Bronze_Medals,
           ROW_NUMBER() OVER (PARTITION BY GAMES ORDER BY Bronze_Medals DESC) AS rn
    FROM Medal_Counts
)

SELECT 
    G.GAMES,
    G.COUNTRY AS Most_Gold_Country,
    G.Gold_Medals AS Most_Gold_Medals,
    S.COUNTRY AS Most_Silver_Country,
    S.Silver_Medals AS Most_Silver_Medals,
    B.COUNTRY AS Most_Bronze_Country,
    B.Bronze_Medals AS Most_Bronze_Medals
FROM Gold_Winners G
JOIN Silver_Winners S ON G.GAMES = S.GAMES AND S.rn = 1
JOIN Bronze_Winners B ON G.GAMES = B.GAMES AND B.rn = 1
WHERE G.rn = 1
ORDER BY G.GAMES;


-- 17.Identify which country won the most gold, most silver, most bronze medals and the most medals in each olympic games.
WITH Medal_Counts AS (
    SELECT 
        NR.REGION AS COUNTRY, 
        AE.GAMES, 
        COUNT(CASE WHEN AE.MEDAL = 'Gold' THEN 1 END) AS Gold_Medals,
        COUNT(CASE WHEN AE.MEDAL = 'Silver' THEN 1 END) AS Silver_Medals,
        COUNT(CASE WHEN AE.MEDAL = 'Bronze' THEN 1 END) AS Bronze_Medals,
        COUNT(AE.MEDAL) AS Total_Medals
    FROM ATHLETE_EVENTS AE
    JOIN NOC_REGIONS NR ON NR.NOC = AE.NOC
    GROUP BY NR.REGION, AE.GAMES
),

Ranked_Medals AS (
    SELECT 
        COUNTRY, 
        GAMES, 
        Gold_Medals, 
        Silver_Medals, 
        Bronze_Medals, 
        Total_Medals,
        ROW_NUMBER() OVER (PARTITION BY GAMES ORDER BY Gold_Medals DESC) AS Gold_Rank,
        ROW_NUMBER() OVER (PARTITION BY GAMES ORDER BY Silver_Medals DESC) AS Silver_Rank,
        ROW_NUMBER() OVER (PARTITION BY GAMES ORDER BY Bronze_Medals DESC) AS Bronze_Rank,
        ROW_NUMBER() OVER (PARTITION BY GAMES ORDER BY Total_Medals DESC) AS Total_Rank
    FROM Medal_Counts
)

SELECT 
    GAMES,
    MAX(CASE WHEN Gold_Rank = 1 THEN COUNTRY END) AS Most_Gold_Country,
    MAX(CASE WHEN Gold_Rank = 1 THEN Gold_Medals END) AS Most_Gold_Medals,
    MAX(CASE WHEN Silver_Rank = 1 THEN COUNTRY END) AS Most_Silver_Country,
    MAX(CASE WHEN Silver_Rank = 1 THEN Silver_Medals END) AS Most_Silver_Medals,
    MAX(CASE WHEN Bronze_Rank = 1 THEN COUNTRY END) AS Most_Bronze_Country,
    MAX(CASE WHEN Bronze_Rank = 1 THEN Bronze_Medals END) AS Most_Bronze_Medals,
    MAX(CASE WHEN Total_Rank = 1 THEN COUNTRY END) AS Most_Total_Medals_Country,
    MAX(CASE WHEN Total_Rank = 1 THEN Total_Medals END) AS Most_Total_Medals
FROM Ranked_Medals
GROUP BY GAMES
ORDER BY GAMES;



-- 18.Which countries have never won gold medal but have won silver/bronze medals?
WITH T1 AS (
    SELECT NR.REGION, AE.MEDAL
    FROM athlete_events AE
    JOIN noc_regions NR ON NR.NOC = AE.NOC
),

medal_counts AS (
    SELECT 
        REGION AS COUNTRY,
        COUNT(CASE WHEN MEDAL = 'Gold' THEN 1 END) AS Gold_medal,
        COUNT(CASE WHEN MEDAL = 'Silver' THEN 1 END) AS Silver_medal,
        COUNT(CASE WHEN MEDAL = 'Bronze' THEN 1 END) AS Bronze_medal
    FROM T1
    GROUP BY REGION
)

SELECT COUNTRY, Silver_medal, Bronze_medal
FROM medal_counts
WHERE Gold_medal = 0 AND (Silver_medal > 0 OR Bronze_medal > 0);



-- 19.In which Sport/event, India has won highest medals.

with T1 as
	(select nr.region, ae.sport , ae.event,COUNT( ae.Medal)as Medals
	from athlete_events ae
	join noc_regions nr
	on nr.noc=ae.noc
	where region = 'india' and Medal in ('gold','silver','bronze')
	group by nr.region,ae.sport,ae.event 
	)

	SELECT sport, event, Medals
	FROM T1
	WHERE Medals = (SELECT MAX(Medals) FROM T1);
	
	
	
		

-- 20.Break down all olympic games where india won medal for Hockey and how many medals in each olympic games.
with T1 as
	(select nr.region, ae.Games ,ae.sport, COUNT( ae.Medal)as Medals
	from athlete_events ae
	join noc_regions nr
	on nr.noc=ae.noc
	where region = 'india' and Medal in ('gold','silver','bronze')
	group by nr.region,ae.Games,ae.sport
	)

	Select * from T1 
	where Sport = 'Hockey' 
	order by medals desc