```sql
/*
Summer of SQL Challenge #3
Preppin' Data exercise from 2023 week 4

REQUIREMENTS

- We want to stack the tables on top of one another, since they have the same fields in each sheet.
    (Tableau Prep) Drag each table into the canvas and use a union step to stack them on top of one another
    (Tableau Prep) Use a wildcard union in the input step of one of the tables
- Some of the fields aren't matching up as we'd expect, due to differences in spelling. Merge these fields together
- Make a Joining Date field based on the Joining Day, Table Names and the year 2023
- Now we want to reshape our data so we have a field for each demographic, for each new customer
- Make sure all the data types are correct for each field
- Remove duplicates 
- If a customer appears multiple times take their earliest joining date

Output the data

Challenge source: 
https://preppindata.blogspot.com/2023/01/2023-week-4-new-customers.html

In summary, to get started, create the 12 tables and insert the data into them (12 months Jan to Dec 2023)
Union them, be aware there could be dupes
We want the records to be 1 ID per row, with that ID's joining date, Ethnicity, DOB, and Account Type in the columns
In the end there's 1 duplicate record that we can filter out by assigning a row number and keeping only the 1's
We use the PIVOT function to get the 3 demographics out of the rows and swung out to be columns instead (leave ID and joining date as-is)

*/

WITH CTE AS (
SELECT *, 'pd2023_wk04_january' AS table_name FROM [dbo].[pd2023_wk04_january]
UNION ALL

SELECT *, 'pd2023_wk04_february' AS table_name FROM [dbo].[pd2023_wk04_february]
UNION ALL

SELECT *, 'pd2023_wk04_march' AS table_name FROM [dbo].[pd2023_wk04_march]
UNION ALL

SELECT *, 'pd2023_wk04_april' AS table_name FROM [dbo].[pd2023_wk04_april]
UNION ALL

SELECT *, 'pd2023_wk04_may' AS table_name FROM [dbo].[pd2023_wk04_may]
UNION ALL

SELECT *, 'pd2023_wk04_june' AS table_name FROM [dbo].[pd2023_wk04_june]
UNION ALL

SELECT *, 'pd2023_wk04_july' AS table_name FROM [dbo].[pd2023_wk04_july]
UNION ALL

SELECT *, 'pd2023_wk04_august' AS table_name FROM [dbo].[pd2023_wk04_august]
UNION ALL

SELECT *, 'pd2023_wk04_september' AS table_name FROM [dbo].[pd2023_wk04_september]
UNION ALL

SELECT *, 'pd2023_wk04_october' AS table_name FROM [dbo].[pd2023_wk04_october]
UNION ALL

SELECT *, 'pd2023_wk04_november' AS table_name FROM [dbo].[pd2023_wk04_november]
UNION ALL

SELECT *, 'pd2023_wk04_december' AS table_name FROM [dbo].[pd2023_wk04_december]
) 
, PRE_PIVOT AS ( 
--set the data up to be ready prior to pivoting
SELECT 
ID
, DATEFROMPARTS(
	2023,	
	MONTH(PARSENAME(REPLACE(table_name, '_', '.'), 1) + '1,1') --month as number
	,[Joining Day]
	) AS joining_date
, demographic
, value
FROM CTE --we have 1 row per ID with their joining date, but the 3 demographics (and their corresponding values) need to swing out as columns (aka be pivoted)
)
, POST_PIVOT AS (
--now actually pivot the demographic column to be 3 columns
SELECT
    ID
    , joining_date
    , [Ethnicity]
    , [Date of Birth]
    , [Account Type]
    , ROW_NUMBER() OVER(PARTITION BY ID ORDER BY joining_date ASC) as row_num
		FROM
		(
			SELECT
				ID,
				joining_date,
				demographic,
				value
			FROM PRE_PIVOT --[dbo].[pd2023_wk04_pre_pivot]
		) AS source
PIVOT
(
    MAX(value)
    FOR demographic IN (
        [Ethnicity],
        [Date of Birth],
        [Account Type]
    )
) AS test --this is where the pivoting ends
) --this is where the POST_PIVOT CTE ends
SELECT
ID
, joining_date
, [Ethnicity]
, [Date of Birth]
, [Account Type]
FROM POST_PIVOT --there are 990 rows, if you do a count distinct on the IDs it tells us there is 1 dupe, so let's put on a where row number = 1
WHERE row_num = 1

```
