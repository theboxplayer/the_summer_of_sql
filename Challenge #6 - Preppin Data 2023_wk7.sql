/*Used PostgreSQL for this one*/

/*
REQUIREMENTS

- For the Transaction Path table:
	 - Make sure field naming convention matches the other tables
	 - i.e. instead of Account_From it should be Account From
     
- For the Account Information table:
	 - Make sure there are no null values in the Account Holder ID
	 - Ensure there is one row per Account Holder ID
	 - Joint accounts will have 2 Account Holders, we want a row for each of them

- For the Account Holders table:
	 - Make sure the phone numbers start with 07

- Bring the tables together
- Filter out cancelled transactions 
- Filter to transactions greater than £1,000 in value 
- Filter out Platinum accounts


Challenge source: 
https://preppindata.blogspot.com/2023/02/2023-week-7-flagging-fraudulent.html
*/

-------------------------------------------------------------------
--ACCOUNT HOLDERS TABLE
select count(*) from pd2023_wk07_account_holders;
select * from pd2023_wk07_account_holders limit 10;

select 
account_holder_id
, name
, date_of_birth
--, contact_number
--, contact_number::text
, concat('0', contact_number::text) as contact_number
, first_line_of_address
from 
pd2023_wk07_account_holders
-------------------------------------------------------------------
--ACCOUNT INFORMATION TABLE

/* For the Account Information table:
- Make sure there are no null values in the Account Holder ID
- Ensure there is one row per Account Holder ID
- Joint accounts will have 2 Account Holders, we want a row for each of them*/

select count(*) from pd2023_wk07_account_information; --3,000 records
select * from pd2023_wk07_account_information limit 10;

select * from pd2023_wk07_account_information
where account_holder_id is null; -- no results, which is what we're looking for (no null acct holder id)

--confirm how many joint accounts we are talking about:
select
*
from 
pd2023_wk07_account_information
--where account_holder_id like '%,%'
where account_type = 'Joint' 
--72 account numbers have more than one account holder (joint accounts)

select
	unnest(string_to_array(account_holder_id, ',')) AS value
from pd2023_wk07_account_information; 
--here are the 72 account holder ids split up, each on to their own row

select count(*) from (
	select
	unnest(string_to_array(account_holder_id, ',')) AS value
from pd2023_wk07_account_information); 
--gives me 3,072 records, plus we know that there are 72 joint accounts so this will work

select count(*) from pd2023_wk07_account_information; --3,000


select
*
, unnest(string_to_array(account_holder_id, ',')) AS acct_holder_id_split
from pd2023_wk07_account_information;

--this is the table we'll use in the end:
select
account_number 
, account_type
, unnest(string_to_array(account_holder_id, ',')) AS account_holder_id
, balance_date 
, balance
from pd2023_wk07_account_information

-------------------------------------------------------------------
--TRANSACTION PATH TABLE
select count(*) from pd2023_wk07_transaction_path; --8,781 records
select * from pd2023_wk07_transaction_path limit 10;

select 
transaction_id
, account_from as "Account From"
, account_to as "Account To"
from pd2023_wk07_transaction_path;

-------------------------------------------------------------------
--TRANSACTION DETAIL TABLE
select count(*) from preppin_data.pd2023_wk07_transaction_detail; --8,781 which matches the count in the txn path able
select * from pd2023_wk07_transaction_detail limit 10;

-------------------------------------------------------------------
--COMBINE THE TABLES AND COMPLETE THE REQUIREMENTS
with txn_detail as (
select * from pd2023_wk07_transaction_detail
),
txn_path as (
select 
transaction_id
, account_from as "Account From"
, account_to as "Account To"
from pd2023_wk07_transaction_path
),
acct_info as (
select
account_number 
, account_type
, unnest(string_to_array(account_holder_id, ',')) AS account_holder_id
, balance_date 
, balance
from pd2023_wk07_account_information
),
acct_holders as (
select 
account_holder_id::text
, name
, date_of_birth
, concat('0', contact_number::text) as contact_number
, first_line_of_address
from 
pd2023_wk07_account_holders
)
--END OF CTEs, BEGIN CORE QUERY
select
txn_detail.transaction_id as "Transaction ID"
, "Account To"
, transaction_date as "Transaction Date"
, value as Value
--, cancelled
--, "Account From"
, account_number as "Account Number"
, account_type as "Account Type"
--, acct_info.account_holder_id
, balance_date as "Balance Date"
, balance as Balance
--skip acct holder id from acct_holders
, name as Name
, date_of_birth as "Date of Birth"
, contact_number as "Contact Number"
, first_line_of_address as "First Line of Address"
from txn_detail inner join txn_path on txn_detail.transaction_id = txn_path.transaction_id 
left join acct_info on acct_info.account_number = txn_path."Account From"
left join acct_holders on acct_info.account_holder_id = acct_holders.account_holder_id
where cancelled = 'N'
and value > 1000
and account_type <> 'Platinum';
--this gives 476 records as expected with column headers as per the Preppin Data requirements

