DROP TABLE IF EXISTS netflix_clean;

CREATE TABLE netflix_clean AS
SELECT
    title,
    genre,
    series_or_movie AS content_type,

    -- Runtime in minutes (only exact minutes)
    CASE
        WHEN runtime ~ '[0-9]+ min'
        THEN CAST(regexp_replace(runtime, '[^0-9]', '', 'g') AS INTEGER)
        ELSE NULL
    END AS runtime_minutes,

    -- Runtime category
    CASE
        WHEN runtime ILIKE '%< 30%' THEN '<30 mins'
        WHEN runtime ILIKE '%30-60%' THEN '30-60 mins'
        WHEN runtime ILIKE '%1-2%' THEN '1-2 hrs'
        WHEN runtime ILIKE '%> 2%' THEN '>2 hrs'
        WHEN runtime ILIKE '%Season%' THEN 'Series'
        ELSE 'Unknown'
    END AS runtime_category,

    -- Safe numeric conversions
    CAST(imdb_score AS NUMERIC) AS imdb_score,

    CASE
        WHEN imdb_votes ~ '^[0-9]+$'
        THEN CAST(imdb_votes AS BIGINT)
        ELSE NULL
    END AS imdb_votes,

    CAST(rotten_tomatoes_score AS NUMERIC) AS rotten_tomatoes_score,
    CAST(metacritic_score AS NUMERIC) AS metacritic_score,

    CAST(release_date AS DATE) AS release_date,
    CAST(netflix_release_date AS DATE) AS netflix_release_date

FROM netflix_raw
WHERE imdb_score IS NOT NULL;

--NEXT STEPS: MOVIES VS SERIES IMBS COMPARISON, RUNTIME ANALYSIS, GENRE ANALYSIS, CORRELATION ANALYSIS
SELECT
    content_type,
    COUNT(*) AS total_titles,
    ROUND(AVG(imdb_score), 2) AS avg_imdb_score
FROM netflix_clean GROUP BY content_type;

-- STEP 4.2 FIXED: Top genres by IMDb score
SELECT
    TRIM(gs) AS genre,
    COUNT(*) AS titles,
    ROUND(AVG(imdb_score), 2) AS avg_imdb_score
FROM netflix_clean
CROSS JOIN LATERAL unnest(string_to_array(genre, ',')) AS gs
GROUP BY TRIM(gs)
HAVING COUNT(*) > 50
ORDER BY avg_imdb_score DESC
LIMIT 10;

SELECT
    ROUND(corr(imdb_score, rotten_tomatoes_score)::NUMERIC, 3) AS imdb_vs_rt,
    ROUND(corr(imdb_score, metacritic_score)::NUMERIC, 3) AS imdb_vs_mc,
    ROUND(corr(rotten_tomatoes_score, metacritic_score)::NUMERIC, 3) AS rt_vs_mc
FROM netflix_clean
WHERE rotten_tomatoes_score IS NOT NULL
  AND metacritic_score IS NOT NULL;

