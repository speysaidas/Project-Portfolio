SELECT *
FROM wle.worldlifexpectancy;


# Identifying if there are any duplicates.
# There should only realy be one country in one year,
# therefore I will concat those two columns and count occurances to see
# whether there are results above 1.

SELECT 
	Country,
	YEAR,
	concat(Country, Year) AS CountryYear,
	count(concat(Country, Year)) AS Occurences
FROM wle.worldlifexpectancy
GROUP BY Country, YEAR, CountryYear
HAVING Occurences > 1; 


# Now to delete those duplicates I am assigning row numbers.
# In this case, duplicates will receive a row number of 2.
# I need this step to be able to filter out and eventually delete duplicates by row_id.
# Since I can't just use a WHERE statement directly after a window function,
# I am using a CTE and refering to it.

WITH cte_row_num AS 
(
	SELECT 
		Row_ID,
		concat(Country, Year),
		ROW_NUMBER() OVER(PARTITION BY concat(Country, Year) ORDER BY concat(Country, Year)) AS row_num
	FROM wle.worldlifexpectancy
)
SELECT *
FROM cte_row_num
WHERE row_num > 1;


# Deleting duplicates.
# I can always check the result by running the previous query again. There should be no duplicate data left.

WITH cte_row_num AS 
(
    SELECT 
        row_id,
        ROW_NUMBER() OVER (
            PARTITION BY Country, Year 
            ORDER BY row_id
        ) AS row_num
    FROM wle.worldlifexpectancy
)
DELETE FROM wle.worldlifexpectancy
WHERE row_id IN (
    SELECT row_id
    FROM cte_row_num
    WHERE row_num > 1
);


# Just by browsing through I can already see some missing values in the status column.
# Looking closer into missing data.

SELECT *
FROM wle.worldlifexpectancy 
WHERE Status = '';


SELECT
	DISTINCT(Status)
FROM wle.worldlifexpectancy 
WHERE Status != '';


# I can see that, for example, in 2014 Afghanistan has a blank 'Status' value
# although every other populated year says it's a 'Developing' country. 
# Keeping in mind that there are only two distinct 'Status' values,
# I can populate blank fields with the same result from another year.

SELECT
	DISTINCT(Country)
FROM wle.worldlifexpectancy 
WHERE Status = 'Developing';

# Joining the table to itself in order to fill empty statuse
# with 'Developing' where that country has other rows marked as 'Developing'.


UPDATE wle.worldlifexpectancy w1
JOIN wle.worldlifexpectancy w2
	ON w1.Country = w2.Country
SET w1.Status = 'Developing'
WHERE w1.Status = ''
AND w2.Status != ''
AND w2.Status = 'Developing';


# And I do the same thing with 'Developed' status. 

UPDATE wle.worldlifexpectancy w1
JOIN wle.worldlifexpectancy w2
	ON w1.Country = w2.Country
SET w1.Status = 'Developed'
WHERE w1.Status = ''
AND w2.Status != ''
AND w2.Status = 'Developed';


# Looking into missing Life expectancy column values

SELECT *
FROM wle.worldlifexpectancy 
WHERE Lifeexpectancy = '';


# I get two blank fields, which I could populate with the average
# life expectancy by country, although it seems that the numbers tend 
# to increase slightly every year.
# Therefore, for a more accurate result, I will populate blank values
# with the average life expectancy of a previous year and a year after.


SELECT
	w1.Country,
	w1.Year,
	w1.Lifeexpectancy,
	w2.Country,
	w2.Year,
	w2.Lifeexpectancy,
	w3.Country,
	w3.Year,
	w3.Lifeexpectancy,
	round((w2.Lifeexpectancy + w3.Lifeexpectancy)/2, 1) AS AvgLifeExpectancy
FROM wle.worldlifexpectancy w1 
JOIN wle.worldlifexpectancy w2
	ON w1.Country = w2.Country 
	AND w1.YEAR = w2.YEAR - 1
JOIN wle.worldlifexpectancy w3
	ON w1.Country = w3.Country 
	AND w1.YEAR = w3.YEAR + 1
WHERE w1.Lifeexpectancy = '';

	
UPDATE wle.worldlifexpectancy w1
JOIN wle.worldlifexpectancy w2
	ON w1.Country = w2.Country 
	AND w1.YEAR = w2.YEAR - 1
JOIN wle.worldlifexpectancy w3
	ON w1.Country = w3.Country 
	AND w1.YEAR = w3.YEAR + 1
SET w1.Lifeexpectancy = round((w2.Lifeexpectancy + w3.Lifeexpectancy))/2
WHERE w1.Lifeexpectancy = '';
	
	
	
	