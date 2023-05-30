-- The dataset used for this project has been downloaded from the following link
-- https://www.kaggle.com/datasets/heesoo37/120-years-of-olympic-history-athletes-and-results?resource=download

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 1. How many olympics games have been held?

      SELECT COUNT(DISTINCT games) AS total_games FROM athlete_events

-- 2. List down all Olympics games held so far.

      SELECT DISTINCT Year, City, Season FROM athlete_events ORDER BY year

-- 3. Mention the total no of nations who participated IN each olympics game?

      SELECT Games, COUNT(DISTINCT noc) AS total_nations FROM athlete_events
      GROUP BY games ORDER BY games

-- 4. Which year saw the highest AND lowest no of countries participating IN olympics?

      SELECT year, total_countries FROM 
      (SELECT year, count(DISTINCT noc) AS total_countries, 
      rank() OVER (ORDER BY count(DISTINCT noc) DESC) AS rn  FROM athlete_events
      GROUP BY year) subq
      WHERE rn = 1

      UNION

      SELECT year, total_countries FROM 
      (SELECT year, count(DISTINCT noc) AS total_countries, 
      rank() OVER (ORDER BY count(DISTINCT noc)) AS rn  FROM athlete_events
      GROUP BY year) subq
      WHERE rn = 1

      ORDER BY total_countries DESC

-- 5. Which nation has participated IN all of the olympic games?

      SELECT COUNT(DISTINCT ae.games) AS total_games, nr.region AS nations FROM athlete_events ae
      INNER JOIN noc_regions nr ON
      ae.NOC = nr.NOC
      GROUP BY nr.region
      HAVING COUNT(DISTINCT ae.games) = (SELECT TOP 1 count(DISTINCT games) FROM athlete_events ORDER BY 1 DESC)
      ORDER BY nr.region

-- 6. Identify the sport which was played IN all summer olympics.

      SELECT Sport, COUNT(DISTINCT games) AS total_summer_games FROM athlete_events
      WHERE games LIKE '%summer%'
      GROUP BY Sport
      HAVING COUNT(DISTINCT games) = (SELECT COUNT(DISTINCT games) FROM athlete_events WHERE games LIKE '%summer%')
      ORDER BY sport

-- 7. Which Sports were just played only once IN the olympics.

    -- The first step is to write a subquery to SELECT the relevant data. In this CASE, our subquery returns the olympic games AND the sports
    -- played IN them
    -- The CTE_GAMES query gives us the total number of sports played. The count WITH value 1 denotes the sports played only once
    -- The final query uses a self JOIN to display the corrosponding olympic games WHEN the sport was played. 

      WITH cte_games AS

      (SELECT sport, count(sport) AS no_of_games FROM
      (SELECT DISTINCT games, sport
      FROM athlete_events ) a
      GROUP BY sport)

      SELECT t.games, cg.sport, cg.no_of_games FROM cte_games cg
       INNER JOIN athlete_events t ON
       t.sport = cg.sport
       WHERE cg.no_of_games = 1
       GROUP BY t.games, cg.Sport, cg.no_of_games
       ORDER BY cg.sport

-- 8. Fetch the total no of sports played IN each olympic games.

      SELECT games, count(sport) AS total_sports FROM (SELECT DISTINCT games, sport FROM athlete_events) a
      GROUP BY games
      ORDER BY total_sports DESC

-- 9. Fetch oldest athletes to win a gold medal

      WITH cte_games AS

      (SELECT *, DENSE_RANK() OVER (ORDER BY age DESC) AS rn FROM athlete_events
      WHERE medal = 'gold' AND age != 'NA')

      SELECT * FROM cte_games WHERE rn = 1

-- 10. Find the Ratio of male AND female athletes participated IN all olympic games.

    -- A simple looking question WITH a twist. Two things should be kept IN mind
    -- One, a single person can participate IN multiple events. To counter this, a subquery is created WITH DISTINCT names AND gENDers.
    -- Two, AS the result is a large number, a simple round does not work. The final result is cast AS DECIMAL AND precision is forced using (5,2)
    -- This rounds the value to two DECIMAL places. The final result gives Female to Male ratio

      WITH ratio_cte AS 

      (SELECT sum(CASE WHEN sex = 'M' THEN 1 ELSE 0 END) AS total_male,
      sum(CASE WHEN sex = 'F' THEN 1 ELSE 0 END) AS total_female
      FROM (SELECT DISTINCT name, sex FROM athlete_events) a)

      SELECT concat('1:', cast(round(total_male * 1.0 / total_female, 2) AS DECIMAL(5,2))) AS ratio FROM ratio_cte

-- 11. Fetch the TOP 5 athletes who have won the most gold medals.

      WITH cte_gold AS 

      (SELECT ae.name AS name, nr.region AS nation, count(ae.medal) AS total_gold_medals,
      DENSE_RANK() OVER (ORDER BY count(ae.medal) DESC) AS rn
      FROM athlete_events ae
      LEFT JOIN noc_regions nr
      ON ae.NOC = nr.noc
      WHERE Medal = 'Gold'
      GROUP BY ae.name, nr.region)

      SELECT name, nation, total_gold_medals FROM cte_gold
      WHERE rn < 6

-- 12. Fetch the TOP 5 athletes who have won the most medals (gold/silver/bronze).

      WITH cte_medals AS 

      (SELECT ae.name AS name, nr.region AS nation, count(ae.medal) AS total_medals,
      DENSE_RANK() OVER (ORDER BY count(ae.medal) DESC) AS rn
      FROM athlete_events ae
      LEFT JOIN noc_regions nr
      ON ae.NOC = nr.noc
      WHERE ae.Medal IN ('Gold', 'Silver', 'Bronze')
      GROUP BY ae.name, nr.region)

      SELECT name, nation, total_medals FROM cte_medals
      WHERE rn < 6

-- 13. Fetch the TOP 5 most successful countries IN olympics. Success is defined BY no of medals won.

      WITH cte_medals AS 

      (SELECT nr.region AS nation, count(ae.medal) AS total_medals,
      DENSE_RANK() OVER (ORDER BY count(ae.medal) DESC) AS rn
      FROM athlete_events ae
      LEFT JOIN noc_regions nr
      ON ae.NOC = nr.noc
      WHERE ae.Medal IN ('Gold', 'Silver', 'Bronze')
      GROUP BY nr.region)

      SELECT nation, total_medals FROM cte_medals
      WHERE rn < 6

-- 14. List down total gold, silver AND bronze medals won BY each country.

      SELECT nr.region AS nation,
      SUM(CASE WHEN medal = 'Gold' THEN 1 ELSE 0 END) AS gold_medals,
      SUM(CASE WHEN medal = 'Silver' THEN 1 ELSE 0 END) AS silver_medals,
      SUM(CASE WHEN medal = 'Bronze' THEN 1 ELSE 0 END) AS bronze_medals
      FROM athlete_events ae
      INNER JOIN noc_regions nr
      ON nr.NOC = ae.NOC
      GROUP BY nr.region
      ORDER BY gold_medals DESC, silver_medals DESC, bronze_medals DESC

-- 15. List down total gold, silver AND bronze medals won BY each country corresponding to each olympic games.

      SELECT ae.games AS games, nr.region AS nation,
      SUM(CASE WHEN medal = 'Gold' THEN 1 ELSE 0 END) AS gold_medals,
      SUM(CASE WHEN medal = 'Silver' THEN 1 ELSE 0 END) AS silver_medals,
      SUM(CASE WHEN medal = 'Bronze' THEN 1 ELSE 0 END) AS bronze_medals
      FROM athlete_events ae
      INNER JOIN noc_regions nr
      ON nr.NOC = ae.NOC
      GROUP BY nr.region, ae.Games
      ORDER BY games, gold_medals DESC, silver_medals DESC, bronze_medals DESC

-- 16. Identify which country won the most gold, most silver AND most bronze medals IN each olympic games.

    -- An interesting question WITH a long but simple answer.
    -- My approach was to create 3 seperate CTEs WITH the required data AND merge them using JOIN.
    -- The subquery uses the window function RANK to get the country WITH highest medal tally of required type.
    -- The outer query is used to get the rank 1 FROM the subquery. 
    -- This is placed IN a CTE to provide a cleaner output. 


      WITH

      cte_gold AS

      (SELECT games, CONCAT(nation, ' - ', gold_medals) AS gold
      FROM
      (SELECT games AS games, nr.region AS nation,
      COUNT(ae.Medal) AS gold_medals, RANK() OVER (PARTITION BY ae.games ORDER BY count(ae.medal) DESC) AS rn
      FROM athlete_events ae
      INNER JOIN noc_regions nr
      ON nr.NOC = ae.NOC
      WHERE medal = 'Gold'
      GROUP BY nr.region, ae.Games) g
      WHERE rn = 1),

      cte_silver AS

      (SELECT games, CONCAT(nation, ' - ', silver_medals) AS silver
      FROM
      (SELECT games AS games, nr.region AS nation,
      COUNT(ae.Medal) AS silver_medals, RANK() OVER (PARTITION BY ae.games ORDER BY count(ae.medal) DESC) AS rn
      FROM athlete_events ae
      INNER JOIN noc_regions nr
      ON nr.NOC = ae.NOC
      WHERE medal = 'Silver'
      GROUP BY nr.region, ae.Games) s
      WHERE rn = 1),

      cte_bronze AS

      (SELECT games, CONCAT(nation, ' - ', bronze_medals) AS bronze
      FROM
      (SELECT games AS games, nr.region AS nation,
      COUNT(ae.Medal) AS bronze_medals, RANK() OVER (PARTITION BY ae.games ORDER BY count(ae.medal) DESC) AS rn
      FROM athlete_events ae
      INNER JOIN noc_regions nr
      ON nr.NOC = ae.NOC
      WHERE medal = 'Bronze'
      GROUP BY nr.region, ae.Games) b
      WHERE rn = 1)

      SELECT cte_gold.games, cte_gold.gold, cte_silver.silver, cte_bronze.bronze FROM cte_gold
      INNER JOIN cte_silver ON
      cte_gold.games = cte_silver.games
      INNER JOIN cte_bronze ON
      cte_gold.games = cte_bronze.games
      ORDER BY cte_gold.games

-- 17. Identify which country won the most gold, most silver, most bronze medals AND the most medals IN each olympic games.

      WITH

      cte_gold AS

      (SELECT games, CONCAT(nation, ' - ', gold_medals) AS gold
      FROM
      (SELECT games AS games, nr.region AS nation,
      COUNT(ae.Medal) AS gold_medals, RANK() OVER (PARTITION BY ae.games ORDER BY count(ae.medal) DESC) AS rn
      FROM athlete_events ae
      INNER JOIN noc_regions nr
      ON nr.NOC = ae.NOC
      WHERE medal = 'Gold'
      GROUP BY nr.region, ae.Games) g
      WHERE rn = 1),

      cte_silver AS

      (SELECT games, CONCAT(nation, ' - ', silver_medals) AS silver
      FROM
      (SELECT games AS games, nr.region AS nation,
      COUNT(ae.Medal) AS silver_medals, RANK() OVER (PARTITION BY ae.games ORDER BY count(ae.medal) DESC) AS rn
      FROM athlete_events ae
      INNER JOIN noc_regions nr
      ON nr.NOC = ae.NOC
      WHERE medal = 'Silver'
      GROUP BY nr.region, ae.Games) s
      WHERE rn = 1),

      cte_bronze AS

      (SELECT games, CONCAT(nation, ' - ', bronze_medals) AS bronze
      FROM
      (SELECT games AS games, nr.region AS nation,
      COUNT(ae.Medal) AS bronze_medals, RANK() OVER (PARTITION BY ae.games ORDER BY count(ae.medal) DESC) AS rn
      FROM athlete_events ae
      INNER JOIN noc_regions nr
      ON nr.NOC = ae.NOC
      WHERE medal = 'Bronze'
      GROUP BY nr.region, ae.Games) b
      WHERE rn = 1),

      cte_total AS

      (SELECT games, CONCAT(nation, ' - ', total_medals) AS total
      FROM
      (SELECT ae.games AS games, nr.region AS nation, COUNT(ae.medal) AS total_medals,
      RANK() OVER (PARTITION BY ae.games ORDER BY count(ae.medal) DESC) AS rn
      FROM athlete_events ae
      INNER JOIN noc_regions nr 
      ON nr.NOC = ae.NOC
      WHERE medal IN ('Gold', 'Silver', 'Bronze')
      GROUP BY nr.region, ae.Games) tm
      WHERE rn = 1)

      SELECT cte_gold.games, cte_gold.gold, cte_silver.silver, cte_bronze.bronze, cte_total.total FROM cte_gold
      INNER JOIN cte_silver ON
      cte_gold.games = cte_silver.games
      INNER JOIN cte_bronze ON
      cte_gold.games = cte_bronze.games
      INNER JOIN cte_total ON
      cte_gold.games = cte_total.games
      ORDER BY cte_gold.games

-- 18. Which countries have never won gold medal but have won silver/bronze medals?

      WITH cte_medals AS

      (SELECT ae.games AS games, nr.region AS nation,
      SUM(CASE WHEN medal = 'Gold' THEN 1 ELSE 0 END) AS gold_medals,
      SUM(CASE WHEN medal = 'Silver' THEN 1 ELSE 0 END) AS silver_medals,
      SUM(CASE WHEN medal = 'Bronze' THEN 1 ELSE 0 END) AS bronze_medals
      FROM athlete_events ae
      INNER JOIN noc_regions nr
      ON nr.NOC = ae.NOC
      GROUP BY nr.region, ae.Games)

      SELECT games, nation, gold_medals, silver_medals, bronze_medals 
      FROM cte_medals
      WHERE gold_medals = 0 AND silver_medals != 0 AND bronze_medals != 0
      ORDER BY games, silver_medals DESC, bronze_medals DESC

-- 19. In which Sport/event, India has won highest medals.

      WITH cte_india AS
      (SELECT sport, count(medal) AS total_medals,
      rank() OVER (ORDER BY count(medal) DESC) AS rn  
      FROM athlete_events 
      WHERE noc = 'IND' AND medal IN ('Gold', 'Silver', 'Bronze')
      GROUP BY sport)

      SELECT sport, total_medals FROM cte_india
      WHERE rn = 1

-- 20. Break down all olympic games WHERE India won medal for Hockey AND how many medals IN each olympic games.

      SELECT team, sport, games, COUNT(medal) AS total_medals FROM athlete_events
      WHERE team = 'India' AND medal IN ('Gold', 'Silver', 'Bronze') AND Sport = 'Hockey'
      GROUP BY team, sport, games 
      ORDER BY total_medals DESC
      
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------

