SELECT runtime_category,COUNT(*)
FROM netflix_clean
GROUP BY runtime_category
ORDER BY COUNT(*) DESC;
