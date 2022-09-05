Cyclistic Case Study - Bike Sharing Company
================
Octave Antoni

Last updated : June 25th, 2022

# Introduction

The goal of this project was to use a websites statitstics to provide insights 
to a company wanting to optimize the audience of their content.

# 1. Page Statistics - Global

My first task was to answer the following questions :
-    How many new subscribers for the page over the time period? 
```SQL
SELECT 
(SELECT SUM(NumberOfFans)
FROM Project3.FanPerCountry
WHERE Date = (SELECT MAX(Date) FROM FanPerCountry)) 
-
(SELECT SUM(NumberOfFans) 
FROM Project3.FanPerCountry
WHERE Date = (SELECT MIN(Date) FROM FanPerCountry)) AS NewSubscribers

```
==> 41571

-    What is the daily average reach of the posts on the page over the period?
```SQL
SELECT ROUND(AVG(DailyPostsReach),0) AS AverageReach
FROM GlobalPage
```
==> 1862816

-    What is the daily average engagement rate on the page over the period ?
```SQL
SELECT ROUND(AVG(NewLikes),0) AS AverageNewLikes
FROM GlobalPage
```
==> 8943

# 2. Page Statistics - Top/worse countries and cities

-    What are the top 10 countries (considering the number of fans)?

```SQL
SELECT CountryName, NumberofFans
FROM
(
SELECT CountryCode, NumberOfFans
FROM FanPerCountry
WHERE Date = (SELECT MAX(Date) FROM FanPerCountry)
) A
INNER JOIN Popstats B
ON A.CountryCode = B.CountryCode
ORDER BY NumberOfFans DESC
LIMIT 10
```

|     Country                               |     Number of fans    |
|-------------------------------------------|-----------------------|
|     Ivory   Coast                         |     112160            |
|     Cameroon                              |     102211            |
|     Senegal                               |     83561             |
|     France                                |     73252             |
|     Madagascar                            |     72956             |
|     Democratic   Republic of the Congo    |     50705             |
|     Burkina   Faso                        |     43500             |
|     Mali                                  |     40578             |
|     Algeria                               |     39093             |
|     Guinea                                |     36821             |

-    What are the top 10 countries (considering the penetration ratio: % of the country population that are fans)?

```SQL
SELECT CountryName, ROUND(100*CAST(NumberOfFans AS FLOAT)/CAST(Population AS FLOAT),2) AS Penetration
FROM 
(
SELECT CountryCode, NumberOfFans
FROM FanPerCountry
WHERE Date = (SELECT MAX(Date) FROM FanPerCountry)
) A
INNER JOIN PopStats B
ON A.CountryCode = B.CountryCode
ORDER BY Penetration DESC
LIMIT 10

```

|     Country             |     Penetration ratio (%)    |
|-------------------------|------------------------------|
|     Reunion             |     2.41%                    |
|     French Polynesia    |     1.82%                    |
|     New Caledonia       |     1.79%                    |
|     Mauritius           |     1.77%                    |
|     Martinique          |     1.44%                    |
|     Guadeloupe          |     1.36%                    |
|     Gabon               |     1.13%                    |
|     Mayotte             |     0.73%                    |
|     Comoros             |     0.6%                     |
|     French Guiana       |     0.57%                    |

-    What are the bottom 10 cities (considering the number of fans) among countries with a population over 20 million?

```SQL
SELECT City, NumberOfFans
FROM 
(
SELECT City, NumberOfFans, CountryCode
FROM FanPerCity
WHERE Date = (SELECT MAX(Date) FROM FanPerCity)
) A
INNER JOIN 
(
SELECT CountryCode FROM PopStats WHERE Population > 20000000
) B
ON A.CountryCode = B.CountryCode
ORDER BY NumberOfFans
LIMIT 10
```

|     City            |     Number of fans    |
|---------------------|-----------------------|
|     Bejaia          |     2391              |
|     Fianarantsoa    |     2429              |
|     Ngaoundere      |     2429              |
|     Tizi Ouzou      |     2606              |
|     Montreal        |     2934              |
|     Oran            |     3008              |
|     Bouake          |     3599              |
|     Casablanca      |     4113              |
|     Cocody          |     4439              |
|     Luanda          |     4830              |

# 3. Page Statistics - Analysis by age group, gender and language


-    What is the split of page fans across age groups (in %)?

```SQL
SELECT AgeGroup, ROUND(FanNumber * 100.0 / SUM(FanNumber) OVER (),2) AS Percentage
FROM
(
SELECT AgeGroup, SUM(NumberOfFans) AS FanNumber
FROM FansPerGenderAge
WHERE Date = (SELECT MAX(Date) FROM FansPerGenderAge)
GROUP BY AgeGroup
)
```
|     Age group    |     Number of fans    |
|------------------|-----------------------|
|     13-17        |     2.09%             |
|     18-24        |     21.30%            |
|     25-34        |     35.80%            |
|     35-44        |     19.40%            |
|     45-54        |     9.45%             |
|     55-64        |     5.02%             |
|     65+          |     6.94%             |

-    What is the split of page fans by gender (in %)?

```SQL
SELECT Gender, ROUND(FanNumber * 100.0 / SUM(FanNumber) OVER (),2) AS Percentage
FROM
(
SELECT Gender, SUM(NumberOfFans) AS FanNumber
FROM FansPerGenderAge
WHERE Date = (SELECT MAX(Date) FROM FansPerGenderAge)
GROUP BY Gender
)
```

|     Gender         |     Number of fans    |
|--------------------|-----------------------|
|     Female         |     56.41%            |
|     Male           |     43.50%            |
|     Undisclosed    |     0.09%             |

- What is the number and percentage of the fans that have declared English as their primary language?

```SQL
SELECT Language, SUM(NumberOfFans) AS FanNumber
FROM FansPerLanguage
WHERE Date = (SELECT MAX(Date) FROM FansPerLanguage) AND Language = 'en'
GROUP BY Language
```
==> 49418

```SQL
SELECT ROUND(Percentage,2) AS Percentage 
FROM
(
SELECT Language, SUM(NumberOfFans) * 100.0 / (SUM(SUM(NumberOfFans)) OVER()) AS Percentage
FROM FansPerLanguage
WHERE Date = (SELECT MAX(Date) FROM FansPerLanguage)
GROUP BY Language
)
WHERE Language = 'en'
```
==> 5.09%

- Based on the number of fans who have declared English as their primary language and living in the US, what is the potential buying power that can be accessed ? (Please use the average income data per country for this question. It is estimated that on average, 0.01% of the annual income is dedicated to online magazine subscriptions in the US)

```SQL
SELECT NumberOfFans * AverageIncome * 0.0001 AS USMarket
FROM 
(
SELECT NumberOfFans, CountryCode
FROM FansPerLanguage
WHERE Language = "en" AND CountryCode = 'US' AND Date = (SELECT MAX(Date) FROM FansPerLanguage)
) A
INNER JOIN PopStats B 
ON A.CountryCode = B.CountryCode
```
==> 200323$

# 4. Post Statistics - Engagement per time of day / day of the week


-    What is the split of the EngagedFans ratio per time of the day ?

```SQL
SELECT CASE
WHEN Hour < 5 THEN '00:00-04:59'
WHEN Hour >= 5 AND Hour < 9 THEN '05:00-08:59'
WHEN Hour >= 9 AND Hour < 12 THEN '09:00-11:59'
WHEN Hour >= 12 AND Hour < 15 THEN '12:00-14:59'
WHEN Hour >= 15 AND Hour < 19 THEN '15:00-18:59'
WHEN Hour >= 19 AND Hour < 22 THEN '19:00-21:59'
WHEN Hour >= 22 AND Hour <= 24 THEN '22:00 or later'
ELSE 'NA' END AS Timeslot,
ROUND(SUM(NumFan) * 100.0 / SUM(SUM(NumFan)) OVER (),2) AS EngagementRatio
FROM
(SELECT CAST(strftime('%H',CreatedTime) AS INTEGER) AS Hour , SUM(EngagedFans) AS NumFan
FROM PostsInsights
GROUP BY Hour)
GROUP BY Timeslot
```
|     Time of day (range)    |     Engagement ratio (%)    |
|----------------------------|-----------------------------|
|     05:00 - 08:59          |     33.96%                  |
|     09:00 -11:59           |     15.34%                  |
|     12:00 - 14:59          |     12.70%                  |
|     15:00 - 18:59          |     17.40%                  |
|     19:00 - 21:59          |     13.12%                  |
|     22:00 or later         |     7.48%                   |

-    What is the split of the EngagedFans ratio per day of the week?

```SQL
SELECT CASE CAST(strftime('%w',CreatedTime) AS INTEGER)
WHEN 0 THEN 'Sunday'
WHEN 1 THEN 'Monday'
WHEN 2 THEN 'Tuesday'
WHEN 3 THEN 'Wednesday'
WHEN 4 THEN 'Thursday'
WHEN 5 THEN 'Friday'
WHEN 6 THEN 'Saturday'
ELSE 'NA' END AS Day, 
ROUND(SUM(EngagedFans)*100.0/SUM(SUM(EngagedFans)) OVER (),2) AS EngagementRatio
FROM PostsInsights
GROUP BY Day
```

|     Day of the week    |     Engagement ratio (%)    |
|------------------------|-----------------------------|
|     Monday             |     19.23%                  |
|     Tuesday            |     18.67%                  |
|     Wednesday          |     15.38%                  |
|     Thursday           |     6.32%                   |
|     Friday             |     8.58%                   |
|     Saturday           |     19.73%                  |
|     Sunday             |     12.08%                  |


# 5. Recommendations:

-    **Publish as much content as possible in the 0500-0900 timeslot**
-    **Focus on Monday, Tuesday and Saturday**
-    **It would be beneficial to target a bit more content at women which are the majority of our fans**

