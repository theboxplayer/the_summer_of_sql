--Used PostgreSQL for this one

/*
REQUIREMENTS

- Create the bank code by splitting out off the letters from the Transaction code, call this field 'Bank'
- Change transaction date to the just be the month of the transaction
- Total up the transaction values so you have one row for each bank and month combination
- Rank each bank for their value of transactions each month against the other banks. 1st is the highest value of transactions, 3rd the lowest. 
- Without losing all of the other data fields, find:
	- The average rank a bank has across all of the months, call this field 'Avg Rank per Bank'
	- The average transaction value per rank, call this field 'Avg Transaction Value per Rank'

Output each query

Challenge source: 
https://preppindata.blogspot.com/2023/02/2023-week-5-dsb-ranking.html
*/


--Create the bank code by splitting out off the letters from the Transaction code, call this field 'Bank'
select count (*) from pd2023_wk05;
select * from pd2023_wk05;

select 
split_part(transaction_code, '-', 1) as bank --get bank code
, *
, split_part(transaction_date, ' ', 1) as txn_date --convert the text to cut off the time
, to_date(split_part(transaction_date, ' ', 1), 'DD/MM/YYYY') as txn_date2 --conver what's left to a date
, to_char(to_date(split_part(transaction_date, ' ', 1), 'DD/MM/YYYY'), 'Month') as month --get the month from the date
, extract(MONTH from to_date(split_part(transaction_date, ' ', 1), 'DD/MM/YYYY')) as month_number
from pd2023_wk05;


--Rank each bank for their value of transactions each month against the other banks.
--1st is the highest value of transactions, 3rd the lowest. 
select 
extract(MONTH from to_date(split_part(transaction_date, ' ', 1), 'DD/MM/YYYY')) as month_number
, to_char(to_date(split_part(transaction_date, ' ', 1), 'DD/MM/YYYY'), 'Month') as month
, split_part(transaction_code, '-', 1) as bank
, rank() over (partition by /*month*/ to_char(to_date(split_part(transaction_date, ' ', 1), 'DD/MM/YYYY'), 'Month')
order by /*sum_value descending*/ sum(value) desc) as rnk
, sum(value) as sum_value
, count(*) as num_txn
from pd2023_wk05
group by
extract(MONTH from to_date(split_part(transaction_date, ' ', 1), 'DD/MM/YYYY'))
, to_char(to_date(split_part(transaction_date, ' ', 1), 'DD/MM/YYYY'), 'Month')
, split_part(transaction_code, '-', 1)
order by
extract(MONTH from to_date(split_part(transaction_date, ' ', 1), 'DD/MM/YYYY')) asc
, split_part(transaction_code, '-', 1);


/*Without losing all of the other data fields, find:
The average rank a bank has across all of the months, call this field 'Avg Rank per Bank'
The average transaction value per rank, call this field 'Avg Transaction Value per Rank'*/
with cte as (
select 
extract(MONTH from to_date(split_part(transaction_date, ' ', 1), 'DD/MM/YYYY')) as month_number
, to_char(to_date(split_part(transaction_date, ' ', 1), 'DD/MM/YYYY'), 'Month') as month
, split_part(transaction_code, '-', 1) as bank
, rank() over (partition by /*month*/ to_char(to_date(split_part(transaction_date, ' ', 1), 'DD/MM/YYYY'), 'Month')
order by /*sum_value descending*/ sum(value) desc) as rnk
, sum(value) as sum_value
, count(*) as num_txn
from pd2023_wk05
group by
extract(MONTH from to_date(split_part(transaction_date, ' ', 1), 'DD/MM/YYYY'))
, to_char(to_date(split_part(transaction_date, ' ', 1), 'DD/MM/YYYY'), 'Month')
, split_part(transaction_code, '-', 1)
order by
extract(MONTH from to_date(split_part(transaction_date, ' ', 1), 'DD/MM/YYYY')) asc
, split_part(transaction_code, '-', 1)
)
--select * from cte;
, cte_avg_rank_across_all_mos as (
select
bank
, avg(rnk) as avg_rank_per_bank
from cte
group by bank
)
--select * from cte_avg_rank_across_all_mos;
, cte_avg_txn_value_per_rank as (
select
rnk
, avg(sum_value) as avg_txn_value_per_rank
from cte
group by rnk
)
select 
--* 
cte.bank
--, cte.month_number --to sort months numerically vs. alpha
, cte.month
, cte.sum_value
, cte.rnk
, round(avg_rank_per_bank, 2) as avg_rank_per_bank
, round(avg_txn_value_per_rank, 0) as avg_txn_value_per_rank
from cte
inner join cte_avg_rank_across_all_mos as x on cte.bank = x.bank
inner join cte_avg_txn_value_per_rank as y on cte.rnk = y.rnk
order by 
cte.bank
, cte.month_number;

/*
bank|month    |sum_value|rnk|avg_rank_per_bank|avg_txn_value_per_rank|
----+---------+---------+---+-----------------+----------------------+
DS  |January  |    50207|  2|             1.92|                 48634|
DS  |February |    31204|  2|             1.92|                 48634|
DS  |March    |    36799|  3|             1.92|                 34621|
DS  |April    |    40785|  2|             1.92|                 48634|
DS  |May      |    38715|  3|             1.92|                 34621|
DS  |June     |    55182|  2|             1.92|                 48634|
DS  |July     |    55002|  3|             1.92|                 34621|
DS  |August   |   102237|  1|             1.92|                 66968|
DS  |September|    41996|  1|             1.92|                 66968|
DS  |October  |    70993|  1|             1.92|                 66968|
DS  |November |    96868|  1|             1.92|                 66968|
DS  |December |    33952|  2|             1.92|                 48634|
DSB |January  |    45036|  3|             2.33|                 34621|
DSB |February |    28622|  3|             2.33|                 34621|
DSB |March    |    78480|  2|             2.33|                 48634|
DSB |April    |    30317|  3|             2.33|                 34621|
DSB |May      |    45000|  2|             2.33|                 48634|
DSB |June     |    64642|  1|             2.33|                 66968|
DSB |July     |    71515|  1|             2.33|                 66968|
DSB |August   |    38167|  3|             2.33|                 34621|
DSB |September|    23579|  2|             2.33|                 48634|
DSB |October  |    41707|  3|             2.33|                 34621|
DSB |November |    42639|  2|             2.33|                 48634|
DSB |December |    20785|  3|             2.33|                 34621|
DTB |January  |    67063|  1|             1.75|                 66968|
DTB |February |    43400|  1|             1.75|                 66968|
DTB |March    |    80358|  1|             1.75|                 66968|
DTB |April    |    42360|  1|             1.75|                 66968|
DTB |May      |    58384|  1|             1.75|                 66968|
DTB |June     |    19720|  3|             1.75|                 34621|
DTB |July     |    57589|  2|             1.75|                 48634|
DTB |August   |    66063|  2|             1.75|                 48634|
DTB |September|    23195|  3|             1.75|                 34621|
DTB |October  |    58924|  2|             1.75|                 48634|
DTB |November |    37385|  3|             1.75|                 34621|
DTB |December |    63797|  1|             1.75|                 66968|
*/
