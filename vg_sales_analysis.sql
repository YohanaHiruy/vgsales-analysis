/* =====================================================================
   VIDEO GAME SALES ANALYSIS
   Author  : Yohana Hiruy
   Dataset : vgsales.csv (16,598 games, sales in millions of units)
   Goal    : Find what drives video game sales by genre, publisher,
             platform, region and time
   Setup   : Import vgsales.csv into a table named vgsales_raw
   ===================================================================== */


/* ---------------------------------------------------------------------
   DATA CLEANING
   The raw table is never edited, results go into vgsales_clean.
   Fixes:
   - Missing years stored as the text 'N/A' become NULL
   - One impossible year (a DS game dated 2020) becomes NULL
   - Missing publishers get one label: 'Unknown'
   - Publisher name variants are merged (Square, SquareSoft -> Square Enix)
   - One exact duplicate row is removed
   --------------------------------------------------------------------- */
DROP TABLE IF EXISTS vgsales_clean;

CREATE TABLE vg_sales_raw AS
SELECT DISTINCT
    TRIM(Name)     AS Name,
    TRIM(Platform) AS Platform,
    CASE WHEN CAST(Year AS INT) BETWEEN 1980 AND 2017
         THEN CAST(Year AS INT)
         ELSE NULL
    END AS Year,
    TRIM(Genre)    AS Genre,
    CASE
        WHEN Publisher IS NULL OR TRIM(Publisher) IN ('', 'N/A', 'Unknown')
             THEN 'Unknown'
        WHEN Publisher IN ('SquareSoft', 'Square', 'Square EA')
             THEN 'Square Enix'
        WHEN Publisher LIKE 'Sony Computer Entertainment%'
             THEN 'Sony Computer Entertainment'
        WHEN Publisher IN ('Activision Value', 'Activision Blizzard')
             THEN 'Activision'
        ELSE TRIM(Publisher)
    END AS Publisher,
    NA_Sales, EU_Sales, JP_Sales, Other_Sales, Global_Sales
FROM vgsales_raw;


/* =====================================================================
  MY  ANALYSIS
   ===================================================================== */

-- Q1. Which genre is the best bet: biggest total or best per game?
  
SELECT Genre,
       ROUND(SUM(Global_Sales), 1) AS total_m,
       COUNT(*)                    AS games,
       ROUND(AVG(Global_Sales), 2) AS avg_per_game
FROM vg_sales_raw
GROUP BY Genre
ORDER BY total_m DESC;
 -- Insight: Action has the biggest total (1,751M), but Platform and
   -- Shooter earn more per game. Action only averages 0.53M because
   -- 3,316 games share the total.


-- Q2. How have sales changed over time?
  
SELECT Year,
       ROUND(SUM(Global_Sales), 1) AS sales_m
FROM vg_sales_raw
WHERE Year BETWEEN 1980 AND 2015
GROUP BY Year
ORDER BY Year;
 -- Insight: Sales peaked at 679M in 2008, then fell to 264M by 2015.
  -- 2016 onward is excluded because the data is incomplete there. 


 -- Q3 Which publishers dominate?
 
SELECT Publisher,
       ROUND(SUM(Global_Sales), 1) AS sales_m
FROM vg_sales_raw
WHERE Publisher <> 'Unknown'
GROUP BY Publisher
ORDER BY sales_m DESC
LIMIT 10;
 --  Insight: Nintendo leads (1,787M), followed by Electronic Arts and
   -- Activision. Unknown publishers are excluded from the ranking. 


-- Q4. Do regions like different genres? (genre mix per region, in %)
 
SELECT Genre,
       ROUND(SUM(NA_Sales) * 100.0 / (SELECT SUM(NA_Sales) FROM vgsales_clean), 1) AS na_pct,
       ROUND(SUM(EU_Sales) * 100.0 / (SELECT SUM(EU_Sales) FROM vgsales_clean), 1) AS eu_pct,
       ROUND(SUM(JP_Sales) * 100.0 / (SELECT SUM(JP_Sales) FROM vgsales_clean), 1) AS jp_pct
FROM vg_sales_raw
GROUP BY Genre
ORDER BY jp_pct DESC;
 -- Insight: Japan is 27.3% Role-Playing, more than double any other
   -- genre there. North America and Europe both lead with Action. 


-- Q5. Which platforms win each region?
   
SELECT Platform,
       ROUND(SUM(NA_Sales), 1) AS na_m,
       ROUND(SUM(EU_Sales), 1) AS eu_m,
       ROUND(SUM(JP_Sales), 1) AS jp_m
FROM vg_sales_raw
GROUP BY Platform
ORDER BY na_m DESC
LIMIT 10;
-- Insight: X360, PS2 and Wii lead North America, PS3 and PS2 lead
-- Europe, and Nintendo's DS leads Japan. Change ORDER BY to eu_m or
 --  jp_m to re-rank by another region. */


-- Q6. Do a few hits make most of the money?
  
SELECT CASE
         WHEN Global_Sales < 0.1 THEN '1 Tiny (<0.1M)'
         WHEN Global_Sales < 0.5 THEN '2 Small (0.1-0.5M)'
         WHEN Global_Sales < 1   THEN '3 Moderate (0.5-1M)'
         WHEN Global_Sales < 5   THEN '4 Hit (1-5M)'
         ELSE                         '5 Blockbuster (5M+)'
       END AS tier,
       COUNT(*)                                                             AS games,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1)                   AS pct_of_games,
       ROUND(SUM(Global_Sales), 1)                                          AS sales_m,
       ROUND(SUM(Global_Sales) * 100.0 / SUM(SUM(Global_Sales)) OVER (), 1) AS pct_of_sales
FROM vg_sales_raw
GROUP BY tier
ORDER BY tier;
   -- Insight: Yes. The top 1% of games make about 21% of sales, while the
   -- bottom half of all games make only about 6.5%. */


/* ---------------------------------------------------------------------
   NOTES
   - Sales are in millions of units, and the data covers physical-era
     sales only (from 1980 to 2016).
   - LIMIT works in  MySQL. Use TOP 10.
   - In SQL Server, repeat the CASE expression in Q6's GROUP BY.
   ---------------------------------------------------------------------- */