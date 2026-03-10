-- SCHEMAS of Netflix

DROP TABLE IF EXISTS netflix;
CREATE TABLE netflix
(
	show_id	VARCHAR(5),
	type    VARCHAR(10),
	title	VARCHAR(250),
	director VARCHAR(550),
	casts	VARCHAR(1050),
	country	VARCHAR(550),
	date_added	VARCHAR(55),
	release_year	INT,
	rating	VARCHAR(15),
	duration	VARCHAR(15),
	listed_in	VARCHAR(250),
	description VARCHAR(550)
);

SELECT * FROM netflix;

-- 1. Count the number of Movies vs TV Shows

SELECT 
	type,
	COUNT(*) as total_content
FROM netflix
GROUP BY type

-- 2. Find the most common rating for movies and TV shows
SELECT rating, COUNT(*) AS total
FROM netflix
GROUP BY rating
ORDER BY total DESC
LIMIT 1;



-- 3. List all movies released in a specific year (e.g., 2020)

SELECT title, release_year
FROM netflix
WHERE type = 'Movie' AND release_year = 2020;

--query for both movie and Tv shows
SELECT * 
FROM netflix
WHERE release_year = 2020



-- 4. Find the top 5 countries with the most content on Netflix

SELECT * 
FROM
(
	SELECT 
		-- country,
		UNNEST(STRING_TO_ARRAY(country, ',')) as country,
		COUNT(*) as total_content
	FROM netflix
	GROUP BY 1
)as t1
WHERE country IS NOT NULL
ORDER BY total_content DESC
LIMIT 5

--Another query same output 
SELECT 
    UNNEST(STRING_TO_ARRAY(country, ',')) AS country_name,
    COUNT(*) AS total
FROM netflix
GROUP BY country_name
ORDER BY total DESC
LIMIT 5;
/*explantion
Country column mein kuch rows mein likha hota hai "India, USA, UK" — matlab ek show kai countries ka hai.
STRING_TO_ARRAY se is line ko tod ke alag-alag kar do. UNNEST matlab "saari balls dabba se bahar nikaal do". 
Phir gino kitni baar kaunsa country aaya!*/



-- 5. Identify the longest movie

SELECT title, duration
FROM netflix
WHERE type = 'Movie'
ORDER BY SPLIT_PART(duration, ' ', 1)::INT DESC
LIMIT 1;
--Explanation
--Duration column mein likha hai "90 min", "120 min". SPLIT_PART se "90" nikaalo (space se pehle wala).
--::INT matlab — us number ko text se number banana. Phir sabse bada wala dikhao!



-- 6. Find content added in the last 5 years
SELECT*
FROM netflix
WHERE TO_DATE(date_added, 'Month DD, YYYY') >= CURRENT_DATE - INTERVAL '5 years'
--or
SELECT title, date_added
FROM netflix
WHERE TO_DATE(date_added, 'Month DD, YYYY') >= CURRENT_DATE - INTERVAL '5 years';
/*EXPLANATION
Netflix pe date likhi hai as text jaise "January 1, 2021". 
TO_DATE us text ko real calendar date banana ka kaam karta hai. 
Phir check karo — kya ye date aaj se 5 saal pehle ke baad ki hai?*/



-- 7. Find all the movies/TV shows by director 'Rajiv Chilaka'!
/*EXPLANATION--GOOD BECAUSE कैसे काम करती है:
STRING_TO_ARRAY(director, ',') → director column को comma पर split करके array बनाता है
"Rajiv Chilaka, David Fincher" → ["Rajiv Chilaka", " David Fincher"]
UNNEST(...) → उस array की हर value को अलग row में expand करता है
फिर exact match करता है = 'Rajiv Chilaka'*/
SELECT *FROM
(
SELECT 
	*,
	UNNEST(STRING_TO_ARRAY(director, ',')) as director_name
FROM 
netflix
)
WHERE 
	director_name = 'Rajiv Chilaka'


/*BAD BEACUSE 
director column में anywhere "Rajiv Chilaka" text ढूंढती है
ILIKE = case-insensitive LIKE
% = कोई भी characters पहले या बाद में हो सकते हैं
Problem:
अगर director column में है → "Rajiv Chilaka, David Fincher"
तो यह match करेगी ✅ — सही है
-लेकिन अगर किसी का नाम है → "Rajiv Chilaka Sharma" (अलग director)
तो यह भी match करेगी ❌ — False Positive! */
	SELECT title, director
FROM netflix
WHERE director ILIKE '%Rajiv Chilaka%';




-- 8. List all TV shows with more than 5 seasons

SELECT *
FROM netflix
WHERE TYPE = 'TV Show'
AND SPLIT_PART(duration, ' ', 1)::INT > 5
--EXPLANATION:TV Shows ki duration mein likha hota hai "3 Seasons".
--Pehle number nikalo "3", phir check karo — kya ye 5 se zyada hai? Agar haan, toh dikhao!




-- 9. Count the number of content items in each genre

SELECT 
	UNNEST(STRING_TO_ARRAY(listed_in, ',')) as genre,
	COUNT(*) as total_content
FROM netflix
GROUP BY 1
--EXPLANATION:listed_in column mein genres hain jaise "Comedies, Dramas, International". Pehle unhe alag-alag karo (STRING_TO_ARRAY), 
--phir expand karo (UNNEST), phir gino har genre ka content!



-- 10. Find each year and the average numbers of content release by India on netflix. 
-- return top 5 year with highest avg content release !


SELECT 
	country,
	release_year,
	COUNT(show_id) as total_release,
	ROUND(
		COUNT(show_id)::numeric/
								(SELECT COUNT(show_id) FROM netflix WHERE country = 'India')::numeric * 100 
		,2
		)
		as avg_release
FROM netflix
WHERE country = 'India' 
GROUP BY country, 2
ORDER BY avg_release DESC 
LIMIT 5




-- 11. List all movies that are documentaries
SELECT * FROM netflix
WHERE listed_in LIKE '%Documentaries'
AND type='Movie';



-- 12. Find all content without a director
SELECT * FROM netflix
WHERE director IS NULL




-- 13. Find how many movies actor 'Salman Khan' appeared in last 10 years!

SELECT * FROM netflix
WHERE 
	casts LIKE '%Salman Khan%'
	AND 
	release_year > EXTRACT(YEAR FROM CURRENT_DATE) - 10
	
/*EXPLANATION:First, the query selects movies where the actor is Salman Khan.
EXTRACT(YEAR FROM CURRENT_DATE) gets the current year from the system.
Subtracting 10 gives the year 10 years ago.
Release_year > ... ensures that only movies released within the last 10 years are returned.*/




-- 14. Find the top 10 actors who have appeared in the highest number of movies produced in India.

SELECT 
	UNNEST(STRING_TO_ARRAY(casts, ',')) as actor,
	COUNT(*) as appearances
FROM netflix
WHERE country = 'India'
GROUP BY actor
ORDER BY appearances DESC
LIMIT 10


/*EXplantaion:Separate the actors listed in the Cast column (which contains values like "Actor1, Actor2, Actor3").
Split them into individual actors and expand them into separate rows.
Then count how many times each actor appears in India’s content and display the top 10 actors with the highest counts.*/





/*Question 15:
Categorize the content based on the presence of the keywords 'kill' and 'violence' in 
the description field. Label content containing these keywords as 'Bad' and all other 
content as 'Good'. Count how many items fall into each category.
*/

SELECT 
    category,
	TYPE,
    COUNT(*) AS content_count
FROM (
    SELECT 
		*,
        CASE 
            WHEN description ILIKE '%kill%' OR description ILIKE '%violence%' THEN 'Bad'
            ELSE 'Good'
        END AS category
    FROM netflix
) AS categorized_content
GROUP BY 1,2
ORDER BY 2



