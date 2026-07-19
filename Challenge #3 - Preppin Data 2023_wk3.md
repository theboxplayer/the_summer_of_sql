```sql
/*
Summer of SQL Challenge #3
Preppin' Data exercise from 2023 week 3 Join Transactions to Targets
*/

CREATE TABLE "pd2023_wk03_targets" (
  "online_or_in_person" varchar(25),
  "q1" bigint,
  "q2" bigint,
  "q3" bigint,
  "q4" bigint
);
------------------------
INSERT INTO "pd2023_wk03_targets" ("online_or_in_person","q1","q2","q3","q4")
VALUES
('Online',72500,70000,60000,60000),
('In-Person',75000,70000,70000,60000);
------------------------

SELECT * FROM "pd2023_wk03_targets";
SELECT * FROM "pd2023_wk01_v2";

------------------------
--Get the DSB bank rows with quarters and years, and id the transaction type (online or in person)
SELECT * 
, CASE 
    WHEN online_or_in_person = 1 THEN 'Online'
    WHEN online_or_in_person = 2 THEN 'In-Person'
    ELSE NULL
END AS online_or_in_person
, CONVERT(date, transaction_date, 103) AS date_converted
, DATEPART(quarter, CONVERT(date, transaction_date, 103)) AS qtr
, DATEPART(year, CONVERT(date, transaction_date, 103)) AS year
FROM "pd2023_wk01_v2"
WHERE transaction_code LIKE '%DSB%';

------------------------
--Take the above and modify to suit the GROUP BY
SELECT 
DATEPART(year, CONVERT(date, transaction_date, 103)) AS year
, DATEPART(quarter, CONVERT(date, transaction_date, 103)) AS qtr
, CASE 
    WHEN online_or_in_person = 1 THEN 'Online'
    WHEN online_or_in_person = 2 THEN 'In-Person'
    ELSE NULL
END AS online_or_in_person
, SUM(value_v2) AS total_value
FROM "pd2023_wk01_v2"
WHERE transaction_code LIKE '%DSB%'
GROUP BY
DATEPART(year, CONVERT(date, transaction_date, 103)) --AS year
, DATEPART(quarter, CONVERT(date, transaction_date, 103)) --AS qtr
, CASE 
    WHEN online_or_in_person = 1 THEN 'Online'
    WHEN online_or_in_person = 2 THEN 'In-Person'
    ELSE NULL
END;

/*
ANSWER
For the transactions file:
year	qtr	online_or_in_person	total_value
2023	1	In-Person	77576
2023	1	Online	74562
2023	2	In-Person	70634
2023	2	Online	69325
2023	3	In-Person	74189
2023	3	Online	59072
2023	4	In-Person	43223
2023	4	Online	61908
*/

------------------------
--PIVOT THE TARGETS:
------------------------

SELECT * FROM "pd2023_wk03_targets";

------------------------

SELECT
    online_or_in_person,
    qtr,
    VALUE AS target
FROM pd2023_wk03_targets
UNPIVOT
    (
    VALUE FOR qtr IN ([q1], [q2], [q3], [q4])
    ) AS unpivotted_qtr
ORDER BY
    qtr,
    online_or_in_person;

/*
online_or_in_person	qtr	target
In-Person	q1	75000
Online	q1	72500
In-Person	q2	70000
Online	q2	70000
In-Person	q3	70000
Online	q3	60000
In-Person	q4	60000
Online	q4	60000
*/

-----------------------------------------------------------
--Join the DSB transactions and the targets together
-----------------------------------------------------------

WITH txns AS
(
SELECT 
DATEPART(year, CONVERT(date, transaction_date, 103)) AS year
, CONVERT(varchar(5), DATEPART(quarter, CONVERT(date, transaction_date, 103))) AS qtr
, CASE 
    WHEN online_or_in_person = 1 THEN 'Online'
    WHEN online_or_in_person = 2 THEN 'In-Person'
    ELSE NULL
END AS online_or_in_person
, SUM(value_v2) AS total_value
FROM "pd2023_wk01_v2"
WHERE transaction_code LIKE '%DSB%'
GROUP BY
DATEPART(year, CONVERT(date, transaction_date, 103)) --AS year
, CONVERT(varchar(5), DATEPART(quarter, CONVERT(date, transaction_date, 103))) --AS qtr
, CASE 
    WHEN online_or_in_person = 1 THEN 'Online'
    WHEN online_or_in_person = 2 THEN 'In-Person'
    ELSE NULL
END
),
tgt AS
(
SELECT *
, RIGHT( CONVERT(varchar(5),qtr),1 ) AS qtr_as_string
    FROM (
        SELECT
        online_or_in_person,
        qtr,
        VALUE AS target
        FROM pd2023_wk03_targets
        UNPIVOT
        (
        VALUE FOR qtr IN ([q1], [q2], [q3], [q4])
        ) AS unpivotted_qtr
    ) AS a
)
SELECT
txns.year
, txns.qtr
, txns.online_or_in_person
, txns.total_value AS actual
, tgt.target
, SUM(target)-SUM(total_value) AS variance
, CASE
        WHEN SUM(target)-SUM(total_value) = 0 THEN 'Achieved'
        WHEN SUM(target)-SUM(total_value) > 0 THEN 'Exceeded'
        WHEN SUM(target)-SUM(total_value) < 0 THEN 'Not Met'
    END AS result
FROM txns LEFT JOIN tgt
ON (txns.qtr = tgt.qtr_as_string)
AND (txns.online_or_in_person = tgt.online_or_in_person)
GROUP BY
txns.year
, txns.qtr
, txns.online_or_in_person
, txns.total_value
, tgt.target;

/*
ANSWER
year	qtr	online_or_in_person	actual	target	variance	result
2023	1	In-Person	77576	75000	-2576	Not Met
2023	1	Online	74562	72500	-2062	Not Met
2023	2	In-Person	70634	70000	-634	Not Met
2023	2	Online	69325	70000	675	Exceeded
2023	3	In-Person	74189	70000	-4189	Not Met
2023	3	Online	59072	60000	928	Exceeded
2023	4	In-Person	43223	60000	16777	Exceeded
2023	4	Online	61908	60000	-1908	Not Met
*/

--Get only DSB transactions from txn data
--Sum the value for each quarter and txn type
--Get the target data and unpivot so that it's in same structure as the txn data
--Join the targets onto the transactions so that you can do the math correctly
```
