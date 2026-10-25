/*
REQUIREMENTS

Combine the 12 monthly files

Create a 'file date' using the month found in the file name
- The Null value should be replaced as 1

Clean the Market Cap value to ensure it is the true value as 'Market Capitalisation'
- Remove any rows with 'n/a'

Categorise the Purchase Price into groupings
- 0 to 24,999.99 as 'Low'
- 25,000 to 49,999.99 as 'Medium'
- 50,000 to 74,999.99 as 'High'
- 75,000 to 100,000 as 'Very High'

Categorise the Market Cap into groupings
- Below $100M as 'Small'
- Between $100M and below $1B as 'Medium'
- Between $1B and below $100B as 'Large' 
- $100B and above as 'Huge'

Rank the highest 5 purchases per combination of: file date, Purchase Price Categorisation and Market Capitalisation Categorisation.
Output only records with a rank of 1 to 5


Challenge source: 
https://preppindata.blogspot.com/2023/02/2023-week-8-taking-stock.html
*/

select count(*) from pd2023_wk08_07;
select * from pd2023_wk08_06 limit 10;

with cte as (
select 1 as file, * from preppin_data.pd2023_wk08_01
union all
select 2 as file, * from preppin_data.pd2023_wk08_02
union all
select 3 as file, * from preppin_data.pd2023_wk08_03
union all
select 4 as file, * from preppin_data.pd2023_wk08_04
union all
select 5 as file, * from preppin_data.pd2023_wk08_05
union all
select 6 as file, * from preppin_data.pd2023_wk08_06
union all
select 7 as file, * from preppin_data.pd2023_wk08_07
union all
select 8 as file, * from preppin_data.pd2023_wk08_08
union all
select 9 as file, * from preppin_data.pd2023_wk08_09
union all
select 10 as file, * from preppin_data.pd2023_wk08_10
union all
select 11 as file, * from preppin_data.pd2023_wk08_11
union all
select 12 as file, * from preppin_data.pd2023_wk08_12
)
, categories as (
--select count(*) from cte--12,000 records
select
make_date(2023, file, 1) as file_date
--, "Market Cap"
/*, right("Market Cap",1) as unit --get the M or B at the end of this money amount*/
/*, case
	when right("Market Cap",1) = 'B' then 1000000000
	when right("Market Cap",1) = 'M' then 1000000
	end as unit_2 --get the millions or billions as a number
*/
/*, length("Market Cap") as len --how long is this text so that we can pull the numbers out of it*/
, substring("Market Cap",2, length("Market Cap")-2)::float as num_value
, substring("Market Cap",2, length("Market Cap")-2)::float * --multiply by next number million or billion
	case
	when right("Market Cap",1) = 'B' then 1000000000
	when right("Market Cap",1) = 'M' then 1000000
	end as market_cap_value --show the actual number of the market cap rather that text with M or B
, substring("Purchase Price", 2, length("Purchase Price")):: float as price
, case
	when substring("Purchase Price", 2, length("Purchase Price")):: float < 25000 then 'Low'
	when substring("Purchase Price", 2, length("Purchase Price")):: float < 50000 then 'Medium'
	when substring("Purchase Price", 2, length("Purchase Price")):: float < 75000 then 'High'
	when substring("Purchase Price", 2, length("Purchase Price")):: float <= 100000 then 'Very High' 
end as price_category
, case 
	when (substring("Market Cap",2, length("Market Cap")-2)::float *
		(case
		when right("Market Cap",1) = 'B' then 1000000000
		when right("Market Cap",1) = 'M' then 1000000
		end)) < 100000000 then 'Small'
	when (substring("Market Cap",2, length("Market Cap")-2)::float *
		(case
		when right("Market Cap",1) = 'B' then 1000000000
		when right("Market Cap",1) = 'M' then 1000000
		end)) < 1000000000 then 'Medium'
	when (substring("Market Cap",2, length("Market Cap")-2)::float *
		(case
		when right("Market Cap",1) = 'B' then 1000000000
		when right("Market Cap",1) = 'M' then 1000000
		end)) < 100000000000 then 'Large'
	when (substring("Market Cap",2, length("Market Cap")-2)::float *
		(case
		when right("Market Cap",1) = 'B' then 1000000000
		when right("Market Cap",1) = 'M' then 1000000
		end)) >= 100000000000 then 'Huge'
end as market_cap_category
, *
from cte
where "Market Cap" <> 'n/a' and "Market Cap" is not null
)
--select count(*) from categories --10,109 records (when the NA market caps are filtered out)
, ranked as(
select
RANK() over(partition by file_date, market_cap_category, price_category order by
price desc
) as rnk
, *
from categories
)
--select count(*) from ranked --10,109
select
market_cap_category as "Market Capitalisation Categorisation"
, price_category as "Purchase Price Categorisation"
, file_date as "File Date"
, "Ticker"
, "Sector"
, "Market"
, "Stock Name"
, market_cap_value as "Market Cap"
, price as "Purchase Price"
, rnk as "Rank"
from ranked 
where rnk <=5 and market_cap_value is not null
--831 records as per the Preppin' Data spec

/*Market Capitalisation Categorisation|Purchase Price Categorisation|File Date |Ticker|Sector               |Market|Stock Name                                                    |Market Cap        |Purchase Price|Rank|
------------------------------------+-----------------------------+----------+------+---------------------+------+--------------------------------------------------------------+------------------+--------------+----+
Huge                                |Low                          |2023-01-01|UNH   |Health Care          |NYSE  |UnitedHealth Group Incorporated                               |      175030000000|      23687.36|   1|
Huge                                |Low                          |2023-01-01|BA    |Capital Goods        |NYSE  |Boeing Company (The)                                          |      118570000000|      15340.41|   2|
Huge                                |Low                          |2023-01-01|RY    |Finance              |NYSE  |Royal Bank Of Canada                                          |      103480000000|       3052.98|   3|
Huge                                |Medium                       |2023-01-01|XOM   |Energy               |NYSE  |Exxon Mobil Corporation                                       |      353770000000|      39345.93|   1|
Huge                                |Medium                       |2023-01-01|JNJ   |Health Care          |NYSE  |Johnson & Johnson                                             |      361920000000|      27289.36|   2|
Huge                                |Very High                    |2023-01-01|BP    |Energy               |NYSE  |BP p.l.c.                                                     |      117990000000|      86921.67|   1|
Large                               |High                         |2023-01-01|A     |Capital Goods        |NYSE  |Agilent Technologies, Inc.                                    |       19120000000|      74995.16|   1|
Large                               |High                         |2023-01-01|OSK   |Capital Goods        |NYSE  |Oshkosh Corporation                                           |        5070000000|      74935.82|   2|
Large                               |High                         |2023-01-01|PLAY  |Consumer Services    |NASDAQ|Dave & Buster's Entertainment, Inc.                           |        2840000000|      74621.72|   3|
Large                               |High                         |2023-01-01|DOC   |Consumer Services    |NYSE  |Physicians Realty Trust                                       |        3260000000|      74155.03|   4|
Large                               |High                         |2023-01-01|CSOD  |Technology           |NASDAQ|Cornerstone OnDemand, Inc.                                    |2089999999.9999998|      74079.42|   5|
Large                               |Low                          |2023-01-01|DRE   |Consumer Services    |NYSE  |Duke Realty Corporation                                       |       10250000000|      24954.71|   1|
Large                               |Low                          |2023-01-01|GXP   |Public Utilities     |NYSE  |Great Plains Energy Inc                                       |        6450000000|      24803.63|   2|
Large                               |Low                          |2023-01-01|MBI   |Finance              |NYSE  |MBIA, Inc.                                                    |        1140000000|      24797.53|   3|
Large                               |Low                          |2023-01-01|BSAC  |Finance              |NYSE  |Banco Santander Chile                                         |       11960000000|      24647.37|   4|
Large                               |Low                          |2023-01-01|INVH  |Finance              |NYSE  |Invitation Homes Inc.                                         |        6590000000|       24575.1|   5|
Large                               |Medium                       |2023-01-01|SHOP  |Technology           |NYSE  |Shopify Inc.                                                  |        7350000000|      49796.86|   1|
Large                               |Medium                       |2023-01-01|FTAI  |n/a                  |NYSE  |Fortress Transportation and Infrastructure Investors LLC      |        1190000000|      49694.92|   2|
Large                               |Medium                       |2023-01-01|AR    |Energy               |NYSE  |Antero Resources Corporation                                  |        7130000000|      49504.15|   3|
Large                               |Medium                       |2023-01-01|LUX   |Health Care          |NYSE  |Luxottica Group, S.p.A.                                       |       29050000000|      49426.81|   4|
Large                               |Medium                       |2023-01-01|BWP   |Public Utilities     |NYSE  |Boardwalk Pipeline Partners L.P.                              |        4380000000|      49357.51|   5|
Large                               |Very High                    |2023-01-01|SLF   |Finance              |NYSE  |Sun Life Financial Inc.                                       |       20990000000|      99652.96|   1|
Large                               |Very High                    |2023-01-01|HLS   |Health Care          |NYSE  |HealthSouth Corporation                                       |        4240000000|      99572.76|   2|
Large                               |Very High                    |2023-01-01|KEX   |Consumer Services    |NYSE  |Kirby Corporation                                             |        3480000000|      99539.57|   3|
Large                               |Very High                    |2023-01-01|EGO   |Basic Industries     |NYSE  |Eldorado Gold Corporation                                     |        1970000000|      99358.56|   4|
Large                               |Very High                    |2023-01-01|ANTM  |Health Care          |NYSE  |Anthem, Inc.                                                  |       50340000000|      99259.06|   5|
Medium                              |High                         |2023-01-01|EVBS  |Finance              |NASDAQ|Eastern Virginia Bankshares, Inc.                             |         142790000|      74337.53|   1|
Medium                              |High                         |2023-01-01|EXA   |Technology           |NASDAQ|Exa Corporation                                               |         203270000|      74152.06|   2|
Medium                              |High                         |2023-01-01|JPI   |n/a                  |NYSE  |Nuveen Preferred and Income Term Fund                         |         560060000|      73970.74|   3|
Medium                              |High                         |2023-01-01|GPAC  |Health Care          |NASDAQ|Global Partner Acquisition Corp.                              |         193670000|      73954.07|   4|
Medium                              |High                         |2023-01-01|KMG   |Basic Industries     |NYSE  |KMG Chemicals, Inc.                                           |         581400000|      73116.32|   5|
Medium                              |Low                          |2023-01-01|GAM   |n/a                  |NYSE  |General American Investors, Inc.                              |         923880000|      24861.42|   1|
Medium                              |Low                          |2023-01-01|JHD   |n/a                  |NYSE  |Nuveen High Income December 2019 Target Term Fund             |         277100000|      24418.39|   2|
Medium                              |Low                          |2023-01-01|ACP   |n/a                  |NYSE  |Avenue Income Credit Strategies Fund                          |         185390000|      23996.86|   3|
Medium                              |Low                          |2023-01-01|RYAM  |Basic Industries     |NYSE  |Rayonier Advanced Materials Inc.                              |         705420000|      23253.12|   4|
Medium                              |Low                          |2023-01-01|QDEL  |Health Care          |NASDAQ|Quidel Corporation                                            |         854720000|      22312.37|   5|
Medium                              |Medium                       |2023-01-01|MSFG  |Finance              |NASDAQ|MainSource Financial Group, Inc.                              |         861230000|      49784.38|   1|
Medium                              |Medium                       |2023-01-01|FGP   |Consumer Services    |NYSE  |Ferrellgas Partners, L.P.                                     |         508110000|      49493.75|   2|
Medium                              |Medium                       |2023-01-01|PKOH  |Capital Goods        |NASDAQ|Park-Ohio Holdings Corp.                                      |         480350000|      49364.16|   3|
Medium                              |Medium                       |2023-01-01|WLFC  |Consumer Durables    |NASDAQ|Willis Lease Finance Corporation                              |         170650000|      48648.41|   4|
Medium                              |Medium                       |2023-01-01|CBA   |n/a                  |NYSE  |ClearBridge American Energy MLP Fund Inc.                     |         508590000|      48507.84|   5|
Medium                              |Very High                    |2023-01-01|KCAP  |n/a                  |NASDAQ|KCAP Financial, Inc.                                          |128800000.00000001|      99956.14|   1|
Medium                              |Very High                    |2023-01-01|CCN   |Finance              |NASDAQ|CardConnect Corp.                                             |         472080000|      99811.53|   2|
Medium                              |Very High                    |2023-01-01|FEM   |n/a                  |NASDAQ|First Trust Emerging Markets AlphaDEX Fund                    |         274060000|       98925.1|   3|
Medium                              |Very High                    |2023-01-01|LLEX  |Energy               |NASDAQ|Lilis Energy, Inc.                                            |267730000.00000003|      98911.08|   4|
Medium                              |Very High                    |2023-01-01|CAMT  |Capital Goods        |NASDAQ|Camtek Ltd.                                                   |         197240000|      98851.52|   5|
Small                               |High                         |2023-01-01|BLH   |n/a                  |NYSE  |Blackrock New York Municipal 2018 Term Trust                  |          53990000|       74802.5|   1|
Small                               |High                         |2023-01-01|AETI  |Energy               |NASDAQ|American Electric Technologies, Inc.                          |          12310000|      74611.89|   2|
Small                               |High                         |2023-01-01|VSTM  |Health Care          |NASDAQ|Verastem, Inc.                                                |          74720000|      74416.07|   3|
Small                               |High                         |2023-01-01|RPRX  |Health Care          |NASDAQ|Repros Therapeutics Inc.                                      |         9140000.0|      74395.33|   4|
Small                               |High                         |2023-01-01|OPHT  |Health Care          |NASDAQ|Ophthotech Corporation                                        |          93930000|      74136.15|   5|
Small                               |Low                          |2023-01-01|PANL  |Transportation       |NASDAQ|Pangaea Logistics Solutions Ltd.                              |          99120000|      24071.47|   1|
Small                               |Low                          |2023-01-01|SCON  |Technology           |NASDAQ|Superconductor Technologies Inc.                              |          17480000|      23763.24|   2|
Small                               |Low                          |2023-01-01|PAGG  |n/a                  |NASDAQ|PowerShares Global Agriculture Portfolio                      |          22370000|       23587.5|   3|
Small                               |Low                          |2023-01-01|LINK  |Technology           |NASDAQ|Interlink Electronics, Inc.                                   |          60660000|      23502.42|   4|
Small                               |Low                          |2023-01-01|ONCS  |Health Care          |NASDAQ|OncoSec Medical Incorporated                                  |          21800000|      23002.82|   5|
Small                               |Medium                       |2023-01-01|IZEA  |Consumer Services    |NASDAQ|IZEA Inc.                                                     |          12380000|      48496.19|   1|
Small                               |Medium                       |2023-01-01|CWAY  |Finance              |NASDAQ|Coastway Bancorp, Inc.                                        |          91140000|      47391.07|   2|
Small                               |Medium                       |2023-01-01|HIHO  |Capital Goods        |NASDAQ|Highway Holdings Limited                                      |          12900000|       45683.5|   3|
Small                               |Medium                       |2023-01-01|EGT   |Consumer Durables    |NASDAQ|Entertainment Gaming Asia Incorporated                        |          33920000|      43712.69|   4|
Small                               |Medium                       |2023-01-01|LPTX  |Health Care          |NASDAQ|LEAP THERAPEUTICS, INC.                                       |          54950000|      43500.13|   5|
Small                               |Very High                    |2023-01-01|FCAN  |n/a                  |NASDAQ|First Trust Canada AlphaDEX Fund                              |         5610000.0|      99610.74|   1|
Small                               |Very High                    |2023-01-01|EPIX  |Health Care          |NASDAQ|ESSA Pharma Inc.                                              |          19790000|      98758.62|   2|
Small                               |Very High                    |2023-01-01|FLKS  |Health Care          |NASDAQ|Flex Pharma, Inc.                                             |          64330000|      96663.47|   3|
Small                               |Very High                    |2023-01-01|ELTK  |Technology           |NASDAQ|Eltek Ltd.                                                    |         6800000.0|      96189.86|   4|
Small                               |Very High                    |2023-01-01|MN    |Finance              |NYSE  |Manning & Napier, Inc.                                        |          63230000|      95514.58|   5|
Huge                                |High                         |2023-02-01|KHC   |Consumer Non-Durables|NASDAQ|The Kraft Heinz Company                                       |      108870000000|      70939.69|   1|
Huge                                |High                         |2023-02-01|DIS   |Consumer Services    |NYSE  |Walt Disney Company (The)                                     |      165110000000|      64358.89|   2|
Huge                                |Low                          |2023-02-01|HD    |Consumer Services    |NYSE  |Home Depot, Inc. (The)                                        |      187270000000|      11127.23|   1|
Huge                                |Medium                       |2023-02-01|V     |Miscellaneous        |NYSE  |Visa Inc.                                                     |      217120000000|      47838.95|   1|
Huge                                |Medium                       |2023-02-01|ORCL  |Technology           |NYSE  |Oracle Corporation                                            |      185530000000|      44152.27|   2|
Huge                                |Medium                       |2023-02-01|VZ    |Public Utilities     |NYSE  |Verizon Communications Inc.                                   |      190220000000|      39428.93|   3|
Huge                                |Medium                       |2023-02-01|V     |Miscellaneous        |NYSE  |Visa Inc.                                                     |      217120000000|      34556.47|   4|
Huge                                |Very High                    |2023-02-01|TM    |Capital Goods        |NYSE  |Toyota Motor Corp Ltd Ord                                     |      156020000000|      87493.53|   1|
Large                               |High                         |2023-02-01|SRCE  |Finance              |NASDAQ|1st Source Corporation                                        |        1270000000|      74668.62|   1|
Large                               |High                         |2023-02-01|CAVM  |Technology           |NASDAQ|Cavium, Inc.                                                  |        4480000000|      74537.05|   2|
Large                               |High                         |2023-02-01|EVHC  |Health Care          |NYSE  |Envision Healthcare Corporation                               |        6890000000|      74347.83|   3|
Large                               |High                         |2023-02-01|TWTR  |Technology           |NYSE  |Twitter, Inc.                                                 |       12180000000|      74088.77|   4|
Large                               |High                         |2023-02-01|HAS   |Consumer Non-Durables|NASDAQ|Hasbro, Inc.                                                  |       13710000000|      74026.09|   5|
Large                               |Low                          |2023-02-01|AF    |Finance              |NYSE  |Astoria Financial Corporation                                 |        2060000000|      24701.47|   1|
Large                               |Low                          |2023-02-01|LSI   |Consumer Services    |NYSE  |Life Storage, Inc.                                            |        3500000000|      24608.82|   2|
Large                               |Low                          |2023-02-01|MET   |Finance              |NYSE  |MetLife, Inc.                                                 |       57580000000|      24515.47|   3|
Large                               |Low                          |2023-02-01|DGRW  |n/a                  |NASDAQ|WisdomTree U.S. Quality Dividend Growth Fund                  |        1450000000|      24085.27|   4|
Large                               |Low                          |2023-02-01|CFR   |Finance              |NYSE  |Cullen/Frost Bankers, Inc.                                    |        6190000000|      24052.69|   5|
Large                               |Medium                       |2023-02-01|QUOT  |Consumer Services    |NYSE  |Quotient Technology Inc.                                      |        1040000000|      49737.92|   1|
Large                               |Medium                       |2023-02-01|FCNCA |Finance              |NASDAQ|First Citizens BancShares, Inc.                               |        4470000000|       49184.4|   2|
Large                               |Medium                       |2023-02-01|TQQQ  |n/a                  |NASDAQ|ProShares UltraPro QQQ                                        |        1720000000|      47917.48|   3|
Large                               |Medium                       |2023-02-01|SANM  |Technology           |NASDAQ|Sanmina Corporation                                           |        2830000000|      47702.06|   4|
Large                               |Medium                       |2023-02-01|TRP   |Public Utilities     |NYSE  |TransCanada Corporation                                       |       41810000000|      47659.42|   5|
Large                               |Very High                    |2023-02-01|CORE  |Consumer Non-Durables|NASDAQ|Core-Mark Holding Company, Inc.                               |        1590000000|      99979.04|   1|
Large                               |Very High                    |2023-02-01|ROIC  |Consumer Services    |NASDAQ|Retail Opportunity Investments Corp.                          |        2150000000|      99797.16|   2|
Large                               |Very High                    |2023-02-01|ENS   |Consumer Non-Durables|NYSE  |Enersys                                                       |        3350000000|      99299.19|   3|
Large                               |Very High                    |2023-02-01|BEDU  |Consumer Services    |NYSE  |Bright Scholar Education Holdings Limited                     |        1380000000|      98879.69|   4|
Large                               |Very High                    |2023-02-01|DGI   |Consumer Services    |NYSE  |DigitalGlobe, Inc                                             |        1960000000|      98856.26|   5|
Medium                              |High                         |2023-02-01|APTI  |Technology           |NASDAQ|Apptio, Inc.                                                  |         654410000|      74931.58|   1|
Medium                              |High                         |2023-02-01|KND   |Health Care          |NYSE  |Kindred Healthcare, Inc.                                      |         907720000|      74171.85|   2|
Medium                              |High                         |2023-02-01|FORR  |Consumer Services    |NASDAQ|Forrester Research, Inc.                                      |         700650000|      73792.28|   3|
Medium                              |High                         |2023-02-01|GSOL  |Consumer Services    |NASDAQ|Global Sources Ltd.                                           |         488080000|      73554.57|   4|
Medium                              |High                         |2023-02-01|OMNT  |Miscellaneous        |NASDAQ|Ominto, Inc.                                                  |         151540000|      73396.07|   5|
Medium                              |Low                          |2023-02-01|DHIL  |Finance              |NASDAQ|Diamond Hill Investment Group, Inc.                           |         701480000|      24715.57|   1|
Medium                              |Low                          |2023-02-01|DVAX  |Health Care          |NASDAQ|Dynavax Technologies Corporation                              |         383030000|      24430.22|   2|
Medium                              |Low                          |2023-02-01|QQEW  |n/a                  |NASDAQ|First Trust NASDAQ-100 Equal Weighted Index Fund              |         556300000|      23828.72|   3|
Medium                              |Low                          |2023-02-01|OIA   |n/a                  |NYSE  |Invesco Municipal Income Opportunities Trust                  |         376320000|      23736.81|   4|
Medium                              |Low                          |2023-02-01|ESTE  |Energy               |NYSE  |Earthstone Energy, Inc.                                       |         608380000|      23362.83|   5|
Medium                              |Medium                       |2023-02-01|FENG  |Consumer Services    |NYSE  |Phoenix New Media Limited                                     |         203150000|      49434.62|   1|
Medium                              |Medium                       |2023-02-01|DRRX  |Health Care          |NASDAQ|DURECT Corporation                                            |         185980000|      48977.73|   2|
Medium                              |Medium                       |2023-02-01|GNRT  |Transportation       |NYSE  |Gener8 Maritime, Inc.                                         |         462920000|      48846.94|   3|
Medium                              |Medium                       |2023-02-01|LDR   |Capital Goods        |NYSE  |Landauer, Inc.                                                |513320000.00000006|      47205.61|   4|
Medium                              |Medium                       |2023-02-01|VVUS  |Health Care          |NASDAQ|VIVUS, Inc.                                                   |         121540000|      45993.62|   5|
Medium                              |Very High                    |2023-02-01|MPB   |Finance              |NASDAQ|Mid Penn Bancorp                                              |         114750000|      99994.68|   1|
Medium                              |Very High                    |2023-02-01|THQ   |n/a                  |NYSE  |Tekla Healthcare Opportunies Fund                             |         772410000|      99728.24|   2|
Medium                              |Very High                    |2023-02-01|ASMB  |Health Care          |NASDAQ|Assembly Biosciences, Inc.                                    |         377450000|       99224.2|   3|
Medium                              |Very High                    |2023-02-01|RARX  |Health Care          |NASDAQ|Ra Pharmaceuticals, Inc.                                      |         480690000|      99180.45|   4|
Medium                              |Very High                    |2023-02-01|NERV  |Health Care          |NASDAQ|Minerva Neurosciences, Inc                                    |         356040000|      98203.42|   5|
Small                               |High                         |2023-02-01|GRID  |n/a                  |NASDAQ|First Trust NASDAQ Clean Edge Smart Grid Infrastructure Index |          21910000|      74505.88|   1|
Small                               |High                         |2023-02-01|GLBR  |Finance              |NASDAQ|Global Brokerage, Inc.                                        |          12290000|      74197.99|   2|
Small                               |High                         |2023-02-01|AXAR  |Finance              |NASDAQ|Axar Acquisition Corp.                                        |          83790000|      74010.12|   3|
Small                               |High                         |2023-02-01|ASFI  |Finance              |NASDAQ|Asta Funding, Inc.                                            |          56440000|      72561.29|   4|
Small                               |High                         |2023-02-01|IFEU  |n/a                  |NASDAQ|iShares FTSE EPRA/NAREIT Europe Index Fund                    |          42370000|      72093.02|   5|
Small                               |Low                          |2023-02-01|PAVM  |Health Care          |NASDAQ|PAVmed Inc.                                                   |          63590000|       24699.2|   1|
Small                               |Low                          |2023-02-01|LKOR  |n/a                  |NASDAQ|FlexShares Credit-Scored US Long Corporate Bond Index Fund    |          13340000|      24667.34|   2|
Small                               |Low                          |2023-02-01|HYND  |n/a                  |NASDAQ|WisdomTree Negative Duration High Yield Bond Fund             |16530000.000000002|      23121.43|   3|
Small                               |Low                          |2023-02-01|SYMX  |Basic Industries     |NASDAQ|Synthesis Energy Systems, Inc.                                |          61120000|      22782.41|   4|
Small                               |Low                          |2023-02-01|ANDA  |Finance              |NASDAQ|Andina Acquisition Corp. II                                   |          53580000|      22721.93|   5|
Small                               |Medium                       |2023-02-01|ARCI  |Consumer Services    |NASDAQ|Appliance Recycling Centers of America, Inc.                  |         4390000.0|      49738.01|   1|
Small                               |Medium                       |2023-02-01|AKER  |Health Care          |NASDAQ|Akers Biosciences Inc                                         |          11120000|      49686.26|   2|
Small                               |Medium                       |2023-02-01|BONT  |Consumer Services    |NASDAQ|The Bon-Ton Stores, Inc.                                      |          10540000|      49262.09|   3|
Small                               |Medium                       |2023-02-01|CVO   |Consumer Durables    |NYSE  |Cenveo Inc                                                    |          52170000|      48871.85|   4|
Small                               |Medium                       |2023-02-01|MNI   |Consumer Services    |NYSE  |McClatchy Company (The)                                       |          85510000|      48567.77|   5|
Small                               |Very High                    |2023-02-01|OBCI  |Consumer Durables    |NASDAQ|Ocean Bio-Chem, Inc.                                          |          37260000|      99288.11|   1|
Small                               |Very High                    |2023-02-01|STLR  |Finance              |NASDAQ|Stellar Acquisition III Inc.                                  |          90190000|      99129.78|   2|
Small                               |Very High                    |2023-02-01|FLGT  |Health Care          |NASDAQ|Fulgent Genetics, Inc.                                        |          92710000|      98714.61|   3|
Small                               |Very High                    |2023-02-01|MTGEP |Consumer Services    |NASDAQ|MTGE Investment Corp.                                         |          52000000|      97624.85|   4|
Small                               |Very High                    |2023-02-01|LGCYP |Energy               |NASDAQ|Legacy Reserves LP                                            |          13080000|      95959.91|   5|
Huge                                |High                         |2023-03-01|AAPL  |Technology           |NASDAQ|Apple Inc.                                                    |      741770000000|      72661.97|   1|
Huge                                |High                         |2023-03-01|SNY   |Health Care          |NYSE  |Sanofi                                                        |      123340000000|      71475.09|   2|
Huge                                |High                         |2023-03-01|MSFT  |Technology           |NASDAQ|Microsoft Corporation                                         |540440000000.00006|      64599.58|   3|
Huge                                |High                         |2023-03-01|INTC  |Technology           |NASDAQ|Intel Corporation                                             |      165800000000|      63780.91|   4|
Huge                                |High                         |2023-03-01|ORCL  |Technology           |NYSE  |Oracle Corporation                                            |      185530000000|      62188.07|   5|
Huge                                |Low                          |2023-03-01|WFC   |Finance              |NYSE  |Wells Fargo & Company                                         |      269310000000|      23692.96|   1|
Huge                                |Low                          |2023-03-01|UNH   |Health Care          |NYSE  |UnitedHealth Group Incorporated                               |      175030000000|      17656.83|   2|
Huge                                |Medium                       |2023-03-01|TM    |Capital Goods        |NYSE  |Toyota Motor Corp Ltd Ord                                     |      156020000000|      32917.59|   1|
Huge                                |Medium                       |2023-03-01|KHC   |Consumer Non-Durables|NASDAQ|The Kraft Heinz Company                                       |      108870000000|      29722.35|   2|
Huge                                |Very High                    |2023-03-01|NVS   |Health Care          |NYSE  |Novartis AG                                                   |      191210000000|      99934.21|   1|
Huge                                |Very High                    |2023-03-01|MRK   |Health Care          |NYSE  |Merck & Company, Inc.                                         |      172230000000|      85268.38|   2|
Huge                                |Very High                    |2023-03-01|HON   |Capital Goods        |NYSE  |Honeywell International Inc.                                  |      102630000000|      77741.94|   3|
Large                               |High                         |2023-03-01|SHO   |Consumer Services    |NYSE  |Sunstone Hotel Investors, Inc.                                |        3650000000|      74811.27|   1|
Large                               |High                         |2023-03-01|PAA   |Energy               |NYSE  |Plains All American Pipeline, L.P.                            |       17990000000|      73912.72|   2|
Large                               |High                         |2023-03-01|KEYS  |Capital Goods        |NYSE  |Keysight Technologies Inc.                                    |        7040000000|      73202.42|   3|
Large                               |High                         |2023-03-01|NKTR  |Health Care          |NASDAQ|Nektar Therapeutics                                           |        2820000000|       73093.4|   4|
Large                               |High                         |2023-03-01|EFX   |Finance              |NYSE  |Equifax, Inc.                                                 |       17140000000|      72971.97|   5|
Large                               |Low                          |2023-03-01|AIR   |Capital Goods        |NYSE  |AAR Corp.                                                     |        1210000000|      24811.85|   1|
Large                               |Low                          |2023-03-01|APOG  |Capital Goods        |NASDAQ|Apogee Enterprises, Inc.                                      |        1600000000|      24671.93|   2|
Large                               |Low                          |2023-03-01|PLD   |Consumer Services    |NYSE  |Prologis, Inc.                                                |       30830000000|      24629.79|   3|
Large                               |Low                          |2023-03-01|FLR   |Basic Industries     |NYSE  |Fluor Corporation                                             |        6300000000|      24086.75|   4|
Large                               |Low                          |2023-03-01|EGL   |Consumer Services    |NYSE  |Engility Holdings, Inc.                                       |        1050000000|      23881.87|   5|
Large                               |Medium                       |2023-03-01|WETF  |Finance              |NASDAQ|WisdomTree Investments, Inc.                                  |        1360000000|      49538.72|   1|
Large                               |Medium                       |2023-03-01|EVHC  |Health Care          |NYSE  |Envision Healthcare Corporation                               |        6890000000|      49371.25|   2|
Large                               |Medium                       |2023-03-01|INOV  |Technology           |NASDAQ|Inovalon Holdings, Inc.                                       |        1990000000|      49224.41|   3|
Large                               |Medium                       |2023-03-01|PATK  |Basic Industries     |NASDAQ|Patrick Industries, Inc.                                      |        1270000000|      49182.58|   4|
Large                               |Medium                       |2023-03-01|SPNC  |Health Care          |NASDAQ|The Spectranetics Corporation                                 |        1300000000|       48883.7|   5|
Large                               |Very High                    |2023-03-01|CAL   |Consumer Non-Durables|NYSE  |Caleres, Inc.                                                 |        1150000000|      99457.94|   1|
Large                               |Very High                    |2023-03-01|HXL   |Basic Industries     |NYSE  |Hexcel Corporation                                            |        4680000000|      98925.83|   2|
Large                               |Very High                    |2023-03-01|UVV   |Consumer Services    |NYSE  |Universal Corporation                                         |        1680000000|      98894.56|   3|
Large                               |Very High                    |2023-03-01|MLNX  |Technology           |NASDAQ|Mellanox Technologies, Ltd.                                   |        2160000000|      98340.82|   4|
Large                               |Very High                    |2023-03-01|ACM   |Consumer Services    |NYSE  |AECOM                                                         |        5080000000|      98201.59|   5|
Medium                              |High                         |2023-03-01|AKAO  |Health Care          |NASDAQ|Achaogen, Inc.                                                |         890000000|       74668.2|   1|
Medium                              |High                         |2023-03-01|IVTY  |Health Care          |NASDAQ|Invuity, Inc.                                                 |         104390000|      74555.12|   2|
Medium                              |High                         |2023-03-01|OSG   |Transportation       |NYSE  |Overseas Shipholding Group, Inc.                              |         192450000|      74348.08|   3|
Medium                              |High                         |2023-03-01|OXFD  |Health Care          |NASDAQ|Oxford Immunotec Global PLC                                   |         344130000|      74208.39|   4|
Medium                              |High                         |2023-03-01|CAMT  |Capital Goods        |NASDAQ|Camtek Ltd.                                                   |         197240000|      74129.42|   5|
Medium                              |Low                          |2023-03-01|TTI   |Energy               |NYSE  |Tetra Technologies, Inc.                                      |         364090000|      24278.12|   1|
Medium                              |Low                          |2023-03-01|BREW  |Consumer Non-Durables|NASDAQ|Craft Brew Alliance, Inc.                                     |         320720000|      24027.44|   2|
Medium                              |Low                          |2023-03-01|CO    |Finance              |NYSE  |China Cord Blood Corporation                                  |         666520000|      23993.25|   3|
Medium                              |Low                          |2023-03-01|BAS   |Energy               |NYSE  |Basic Energy Services, Inc.                                   |         595410000|      23713.82|   4|
Medium                              |Low                          |2023-03-01|RPD   |Technology           |NASDAQ|Rapid7, Inc.                                                  |         739260000|      23553.48|   5|
Medium                              |Medium                       |2023-03-01|FSBW  |Finance              |NASDAQ|FS Bancorp, Inc.                                              |         139320000|      49918.12|   1|
Medium                              |Medium                       |2023-03-01|ECHO  |Transportation       |NASDAQ|Echo Global Logistics, Inc.                                   |         594580000|      49856.99|   2|
Medium                              |Medium                       |2023-03-01|TOWR  |Capital Goods        |NYSE  |Tower International, Inc.                                     |         446680000|      48380.45|   3|
Medium                              |Medium                       |2023-03-01|CXE   |n/a                  |NYSE  |Colonial High Income Municipal Trust                          |         165710000|      48172.35|   4|
Medium                              |Medium                       |2023-03-01|FLXN  |Health Care          |NASDAQ|Flexion Therapeutics, Inc.                                    |         546870000|      48000.52|   5|
Medium                              |Very High                    |2023-03-01|DLNG  |Consumer Services    |NYSE  |Dynagas LNG Partners LP                                       |517440000.00000006|       99739.7|   1|
Medium                              |Very High                    |2023-03-01|BPT   |Energy               |NYSE  |BP Prudhoe Bay Royalty Trust                                  |         445120000|      99716.89|   2|
Medium                              |Very High                    |2023-03-01|EACQ  |Capital Goods        |NASDAQ|Easterly Acquisition Corp.                                    |         251250000|      99678.28|   3|
Medium                              |Very High                    |2023-03-01|EPZM  |Health Care          |NASDAQ|Epizyme, Inc.                                                 |         796590000|      99543.14|   4|
Medium                              |Very High                    |2023-03-01|IFN   |n/a                  |NYSE  |India Fund, Inc. (The)                                        |         774330000|      99498.54|   5|
Small                               |High                         |2023-03-01|VRIG  |n/a                  |NASDAQ|PowerShares Variable Rate Investment Grade Portfolio          |          69290000|      74913.42|   1|
Small                               |High                         |2023-03-01|ELTK  |Technology           |NASDAQ|Eltek Ltd.                                                    |         6800000.0|      74326.92|   2|
Small                               |High                         |2023-03-01|CREG  |Miscellaneous        |NASDAQ|China Recycling Energy Corporation                            |          11630000|      72425.08|   3|
Small                               |High                         |2023-03-01|ZBIO  |n/a                  |NASDAQ|ProShares UltraPro Short NASDAQ Biotechnology                 |         6580000.0|      70276.45|   4|
Small                               |High                         |2023-03-01|SNAK  |Consumer Non-Durables|NASDAQ|Inventure Foods, Inc.                                         |          83670000|       69625.7|   5|
Small                               |Low                          |2023-03-01|PYZ   |n/a                  |NASDAQ|PowerShares DWA Basic Materials Momentum Portfolio            |          95770000|      23847.38|   1|
Small                               |Low                          |2023-03-01|DWLV  |n/a                  |NASDAQ|PowerShares DWA Momentum & Low Volatility Rotation Portfolio  |         4200000.0|      22170.33|   2|
Small                               |Low                          |2023-03-01|JAGX  |Health Care          |NASDAQ|Jaguar Animal Health, Inc.                                    |         8660000.0|       22028.9|   3|
Small                               |Low                          |2023-03-01|GEVO  |Basic Industries     |NASDAQ|Gevo, Inc.                                                    |         9390000.0|       21315.4|   4|
Small                               |Low                          |2023-03-01|MARPS |Energy               |NASDAQ|Marine Petroleum Trust                                        |         6920000.0|      20604.55|   5|
Small                               |Medium                       |2023-03-01|SBOT  |Health Care          |NASDAQ|Stellar Biotechnologies, Inc.                                 |          11350000|      49483.58|   1|
Small                               |Medium                       |2023-03-01|ARCW  |Capital Goods        |NASDAQ|ARC Group Worldwide, Inc.                                     |          61780000|      48341.36|   2|
Small                               |Medium                       |2023-03-01|TUTT  |n/a                  |NASDAQ|Tuttle Tactical Management U.S. Core ETF                      |          54070000|      47968.81|   3|
Small                               |Medium                       |2023-03-01|RMCF  |Consumer Non-Durables|NASDAQ|Rocky Mountain Chocolate Factory, Inc.                        |          68380000|      47373.07|   4|
Small                               |Medium                       |2023-03-01|STRM  |Technology           |NASDAQ|Streamline Health Solutions, Inc.                             |          21440000|      46658.42|   5|
Small                               |Very High                    |2023-03-01|ROYT  |Energy               |NYSE  |Pacific Coast Oil Trust                                       |          61730000|      99754.65|   1|
Small                               |Very High                    |2023-03-01|FORD  |Consumer Non-Durables|NASDAQ|Forward Industries, Inc.                                      |         9570000.0|      99382.92|   2|
Small                               |Very High                    |2023-03-01|BCTF  |Finance              |NASDAQ|Bancorp 34, Inc.                                              |          47360000|      97804.66|   3|
Small                               |Very High                    |2023-03-01|AMMA  |Consumer Services    |NASDAQ|Alliance MMA, Inc.                                            |          10910000|      96568.65|   4|
Small                               |Very High                    |2023-03-01|TROV  |Health Care          |NASDAQ|TrovaGene, Inc.                                               |          29240000|      96244.27|   5|
Huge                                |High                         |2023-04-01|CMCSA |Consumer Services    |NASDAQ|Comcast Corporation                                           |      195790000000|      73906.69|   1|
Huge                                |High                         |2023-04-01|PFE   |Health Care          |NYSE  |Pfizer, Inc.                                                  |      196760000000|      72346.96|   2|
Huge                                |Low                          |2023-04-01|SNY   |Health Care          |NYSE  |Sanofi                                                        |      123340000000|       4933.43|   1|
Huge                                |Medium                       |2023-04-01|BA    |Capital Goods        |NYSE  |Boeing Company (The)                                          |      118570000000|      48273.04|   1|
Huge                                |Medium                       |2023-04-01|PTR   |Energy               |NYSE  |PetroChina Company Limited                                    |      116380000000|      40852.83|   2|
Huge                                |Medium                       |2023-04-01|CVX   |Energy               |NYSE  |Chevron Corporation                                           |      205280000000|      29937.46|   3|
Huge                                |Very High                    |2023-04-01|ORCL  |Technology           |NYSE  |Oracle Corporation                                            |      185530000000|      90852.97|   1|
Huge                                |Very High                    |2023-04-01|MRK   |Health Care          |NYSE  |Merck & Company, Inc.                                         |      172230000000|      87754.61|   2|
Huge                                |Very High                    |2023-04-01|TIG   |Health Care          |NASDAQ|TiGenix                                                       |      103100000000|      85697.37|   3|
Huge                                |Very High                    |2023-04-01|CMCSA |Consumer Services    |NASDAQ|Comcast Corporation                                           |      195790000000|      81907.58|   4|
Huge                                |Very High                    |2023-04-01|GE    |Energy               |NYSE  |General Electric Company                                      |      251830000000|      79900.69|   5|
Large                               |High                         |2023-04-01|SKX   |Consumer Non-Durables|NYSE  |Skechers U.S.A., Inc.                                         |        4350000000|      74495.13|   1|
Large                               |High                         |2023-04-01|SBGL  |Basic Industries     |NYSE  |Sibanye Gold Limited                                          |        2550000000|      74409.16|   2|
Large                               |High                         |2023-04-01|FIT   |Technology           |NYSE  |Fitbit, Inc.                                                  |        1160000000|      74355.04|   3|
Large                               |High                         |2023-04-01|LW    |Consumer Non-Durables|NYSE  |Lamb Weston Holdings, Inc.                                    |        6580000000|      73947.71|   4|
Large                               |High                         |2023-04-01|WMS   |Capital Goods        |NYSE  |Advanced Drainage Systems, Inc.                               |        1130000000|      73635.15|   5|
Large                               |Low                          |2023-04-01|LXFT  |Technology           |NYSE  |Luxoft Holding, Inc.                                          |2049999999.9999998|      24947.74|   1|
Large                               |Low                          |2023-04-01|HII   |Capital Goods        |NYSE  |Huntington Ingalls Industries, Inc.                           | 8560000000.000001|      24675.93|   2|
Large                               |Low                          |2023-04-01|PPG   |Basic Industries     |NYSE  |PPG Industries, Inc.                                          |       28480000000|      24105.88|   3|
Large                               |Low                          |2023-04-01|SPG   |Consumer Services    |NYSE  |Simon Property Group, Inc.                                    |       50030000000|      23682.02|   4|
Large                               |Low                          |2023-04-01|TNET  |Miscellaneous        |NYSE  |TriNet Group, Inc.                                            |        2170000000|      23463.07|   5|
Large                               |Medium                       |2023-04-01|GGG   |Capital Goods        |NYSE  |Graco Inc.                                                    |        6280000000|      49492.93|   1|
Large                               |Medium                       |2023-04-01|MS    |Finance              |NYSE  |Morgan Stanley                                                |       82280000000|      49108.55|   2|
Large                               |Medium                       |2023-04-01|ABT   |Health Care          |NYSE  |Abbott Laboratories                                           |       83660000000|      48477.86|   3|
Large                               |Medium                       |2023-04-01|THO   |Consumer Non-Durables|NYSE  |Thor Industries, Inc.                                         |        5530000000|      48034.38|   4|
Large                               |Medium                       |2023-04-01|AAV   |Energy               |NYSE  |Advantage Oil & Gas Ltd                                       |        1150000000|      47877.61|   5|
Large                               |Very High                    |2023-04-01|SNPS  |Technology           |NASDAQ|Synopsys, Inc.                                                |       11090000000|       99646.5|   1|
Large                               |Very High                    |2023-04-01|TRNO  |Finance              |NYSE  |Terreno Realty Corporation                                    |        1630000000|      99621.04|   2|
Large                               |Very High                    |2023-04-01|DGI   |Consumer Services    |NYSE  |DigitalGlobe, Inc                                             |        1960000000|      99574.64|   3|
Large                               |Very High                    |2023-04-01|FL    |Consumer Services    |NYSE  |Foot Locker, Inc.                                             |        6830000000|      98942.99|   4|
Large                               |Very High                    |2023-04-01|IART  |Capital Goods        |NASDAQ|Integra LifeSciences Holdings Corporation                     |        3990000000|      98738.19|   5|
Medium                              |High                         |2023-04-01|JPC   |n/a                  |NYSE  |Nuveen Preferred Income Opportunites Fund                     |         999980000|       74937.8|   1|
Medium                              |High                         |2023-04-01|CZNC  |Finance              |NASDAQ|Citizens & Northern Corp                                      |         287820000|      74886.85|   2|
Medium                              |High                         |2023-04-01|NEOS  |Health Care          |NASDAQ|Neos Therapeutics, Inc.                                       |         195150000|      74227.86|   3|
Medium                              |High                         |2023-04-01|FINL  |Consumer Services    |NASDAQ|The Finish Line, Inc.                                         |         551940000|      74009.62|   4|
Medium                              |High                         |2023-04-01|VVI   |Miscellaneous        |NYSE  |Viad Corp                                                     |         940530000|      72829.95|   5|
Medium                              |Low                          |2023-04-01|NVGS  |Transportation       |NYSE  |Navigator Holdings Ltd.                                       |         405380000|      24944.68|   1|
Medium                              |Low                          |2023-04-01|NAZ   |n/a                  |NYSE  |Nuveen Arizona Quality Municipal Income Fund                  |         167960000|      24814.77|   2|
Medium                              |Low                          |2023-04-01|JHY   |n/a                  |NYSE  |Nuveen High Income 2020 Target Term Fund                      |         145490000|      24793.17|   3|
Medium                              |Low                          |2023-04-01|UEPS  |Finance              |NASDAQ|Net 1 UEPS Technologies, Inc.                                 |         556900000|      24615.51|   4|
Medium                              |Low                          |2023-04-01|MRTN  |Transportation       |NASDAQ|Marten Transport, Ltd.                                        |         905460000|      24546.66|   5|
Medium                              |Medium                       |2023-04-01|WEYS  |Consumer Non-Durables|NASDAQ|Weyco Group, Inc.                                             |         291310000|      49986.44|   1|
Medium                              |Medium                       |2023-04-01|INO   |Health Care          |NASDAQ|Inovio Pharmaceuticals, Inc.                                  |         585080000|      49913.33|   2|
Medium                              |Medium                       |2023-04-01|TWIN  |Technology           |NASDAQ|Twin Disc, Incorporated                                       |         194790000|      48749.14|   3|
Medium                              |Medium                       |2023-04-01|MOV   |Consumer Non-Durables|NYSE  |Movado Group Inc.                                             |         512470000|      47857.51|   4|
Medium                              |Medium                       |2023-04-01|JHG   |Finance              |NYSE  |Janus Henderson Group plc                                     |         367060000|      47830.43|   5|
Medium                              |Very High                    |2023-04-01|RRD   |Miscellaneous        |NASDAQ|R.R. Donnelley & Sons Company                                 |         864500000|      99982.79|   1|
Medium                              |Very High                    |2023-04-01|SBRAP |Consumer Services    |NASDAQ|Sabra Healthcare REIT, Inc.                                   |         146630000|      99611.62|   2|
Medium                              |Very High                    |2023-04-01|USDP  |Transportation       |NYSE  |USD Partners LP                                               |         300480000|      99437.08|   3|
Medium                              |Very High                    |2023-04-01|FRP   |Public Utilities     |NASDAQ|FairPoint Communications, Inc.                                |         423980000|      99164.81|   4|
Medium                              |Very High                    |2023-04-01|ACBI  |Finance              |NASDAQ|Atlantic Capital Bancshares, Inc.                             |         482160000|      98972.02|   5|
Small                               |High                         |2023-04-01|KONE  |Technology           |NASDAQ|Kingtone Wirelessinfo Solution Holding Ltd                    |         5160000.0|      74999.62|   1|
Small                               |High                         |2023-04-01|PMPT  |n/a                  |NASDAQ|iSectors Post-MPT Growth ETF                                  |          11340000|       74887.3|   2|
Small                               |High                         |2023-04-01|PQ    |Energy               |NYSE  |Petroquest Energy Inc                                         |          46900000|      73694.08|   3|
Small                               |High                         |2023-04-01|TLF   |Consumer Non-Durables|NASDAQ|Tandy Leather Factory, Inc.                                   |          76520000|      72741.97|   4|
Small                               |High                         |2023-04-01|PFBX  |Finance              |NASDAQ|Peoples Financial Corporation                                 |          66090000|      72675.37|   5|
Small                               |Low                          |2023-04-01|ALQA  |Health Care          |NASDAQ|Alliqua BioMedical, Inc.                                      |          17010000|      23084.18|   1|
Small                               |Low                          |2023-04-01|BLH   |n/a                  |NYSE  |Blackrock New York Municipal 2018 Term Trust                  |          53990000|      22250.34|   2|
Small                               |Low                          |2023-04-01|MIRN  |Health Care          |NASDAQ|Mirna Therapeutics, Inc.                                      |          31070000|      21905.34|   3|
Small                               |Low                          |2023-04-01|PRCP  |Capital Goods        |NASDAQ|Perceptron, Inc.                                              |          68490000|      21546.33|   4|
Small                               |Low                          |2023-04-01|SOFO  |Technology           |NASDAQ|Sonic Foundry, Inc.                                           |          17760000|      21383.49|   5|
Small                               |Medium                       |2023-04-01|DWAT  |n/a                  |NASDAQ|Arrow DWA Tactical ETF                                        |         8670000.0|      49905.45|   1|
Small                               |Medium                       |2023-04-01|NTIC  |Capital Goods        |NASDAQ|Northern Technologies International Corporation               |          73300000|      49660.59|   2|
Small                               |Medium                       |2023-04-01|CADC  |Basic Industries     |NASDAQ|China Advanced Construction Materials Group, Inc.             |         5730000.0|       49544.4|   3|
Small                               |Medium                       |2023-04-01|DGLD  |Finance              |NASDAQ|VelocityShares 3x Inverse Gold ETN                            |          18660000|      48531.32|   4|
Small                               |Medium                       |2023-04-01|HBIO  |Capital Goods        |NASDAQ|Harvard Bioscience, Inc.                                      |          86550000|      48320.17|   5|
Small                               |Very High                    |2023-04-01|AFMD  |Health Care          |NASDAQ|Affimed N.V.                                                  |          87880000|      99959.38|   1|
Small                               |Very High                    |2023-04-01|RTTR  |Health Care          |NASDAQ|Ritter Pharmaceuticals, Inc.                                  |         9140000.0|      98807.33|   2|
Small                               |Very High                    |2023-04-01|ONVI  |Miscellaneous        |NASDAQ|Onvia, Inc.                                                   |          30650000|      98193.88|   3|
Small                               |Very High                    |2023-04-01|DVCR  |Health Care          |NASDAQ|Diversicare Healthcare Services Inc.                          |          62000000|      98059.53|   4|
Small                               |Very High                    |2023-04-01|ARLZ  |Health Care          |NASDAQ|Aralez Pharmaceuticals Inc.                                   |          79480000|      97660.24|   5|
Huge                                |High                         |2023-05-01|TIG   |Health Care          |NASDAQ|TiGenix                                                       |      103100000000|      66390.82|   1|
Huge                                |High                         |2023-05-01|PTR   |Energy               |NYSE  |PetroChina Company Limited                                    |      116380000000|      62771.16|   2|
Huge                                |High                         |2023-05-01|MMM   |Health Care          |NYSE  |3M Company                                                    |      127360000000|      60479.11|   3|
Huge                                |High                         |2023-05-01|IBM   |Technology           |NYSE  |International Business Machines Corporation                   |      145980000000|      59375.02|   4|
Huge                                |High                         |2023-05-01|MCD   |Consumer Services    |NYSE  |McDonald's Corporation                                        |      123880000000|      57256.94|   5|
Huge                                |Low                          |2023-05-01|MRK   |Health Care          |NYSE  |Merck & Company, Inc.                                         |      172230000000|       7712.91|   1|
Huge                                |Medium                       |2023-05-01|PTR   |Energy               |NYSE  |PetroChina Company Limited                                    |      116380000000|      29397.19|   1|
Huge                                |Very High                    |2023-05-01|MMM   |Health Care          |NYSE  |3M Company                                                    |      127360000000|      96110.73|   1|
Huge                                |Very High                    |2023-05-01|KO    |Consumer Non-Durables|NYSE  |Coca-Cola Company (The)                                       |      193590000000|      94005.53|   2|
Large                               |High                         |2023-05-01|SPIL  |Technology           |NASDAQ|Siliconware Precision Industries Company, Ltd.                |        5070000000|       74783.5|   1|
Large                               |High                         |2023-05-01|SO    |Public Utilities     |NYSE  |Southern Company (The)                                        |       51250000000|      74715.06|   2|
Large                               |High                         |2023-05-01|RGA   |Finance              |NYSE  |Reinsurance Group of America, Incorporated                    | 8289999999.999999|      74232.12|   3|
Large                               |High                         |2023-05-01|BABY  |Health Care          |NASDAQ|Natus Medical Incorporated                                    |        1160000000|      74231.26|   4|
Large                               |High                         |2023-05-01|CPK   |Public Utilities     |NYSE  |Chesapeake Utilities Corporation                              |        1230000000|      73871.46|   5|
Large                               |Low                          |2023-05-01|EGBN  |Finance              |NASDAQ|Eagle Bancorp, Inc.                                           |        2160000000|      24336.62|   1|
Large                               |Low                          |2023-05-01|D     |Public Utilities     |NYSE  |Dominion Energy, Inc.                                         |       50770000000|      24227.43|   2|
Large                               |Low                          |2023-05-01|WCG   |Health Care          |NYSE  |WellCare Health Plans, Inc.                                   |        7770000000|      23159.56|   3|
Large                               |Low                          |2023-05-01|CR    |Capital Goods        |NYSE  |Crane Company                                                 |        4720000000|      23155.31|   4|
Large                               |Low                          |2023-05-01|CAH   |Health Care          |NYSE  |Cardinal Health, Inc.                                         |       23690000000|      22425.07|   5|
Large                               |Medium                       |2023-05-01|CP    |Transportation       |NYSE  |Canadian Pacific Railway Limited                              |       22760000000|      49976.54|   1|
Large                               |Medium                       |2023-05-01|KB    |Finance              |NYSE  |KB Financial Group Inc                                        |       19260000000|      49949.66|   2|
Large                               |Medium                       |2023-05-01|TECD  |Technology           |NASDAQ|Tech Data Corporation                                         |        3670000000|      49765.42|   3|
Large                               |Medium                       |2023-05-01|KMPR  |Finance              |NYSE  |Kemper Corporation                                            |2049999999.9999998|      49657.62|   4|
Large                               |Medium                       |2023-05-01|BCC   |Consumer Services    |NYSE  |Boise Cascade, L.L.C.                                         |        1140000000|      49509.01|   5|
Large                               |Very High                    |2023-05-01|AVB   |Consumer Services    |NYSE  |AvalonBay Communities, Inc.                                   |       27020000000|      99971.11|   1|
Large                               |Very High                    |2023-05-01|GBDC  |n/a                  |NASDAQ|Golub Capital BDC, Inc.                                       |        1110000000|      99839.23|   2|
Large                               |Very High                    |2023-05-01|MNST  |Consumer Non-Durables|NASDAQ|Monster Beverage Corporation                                  |       28570000000|      99649.45|   3|
Large                               |Very High                    |2023-05-01|WES   |Public Utilities     |NYSE  |Western Gas Partners, LP                                      | 8390000000.000001|      99514.72|   4|
Large                               |Very High                    |2023-05-01|ESLT  |Capital Goods        |NASDAQ|Elbit Systems Ltd.                                            |        5290000000|      99445.93|   5|
Medium                              |High                         |2023-05-01|LMAT  |Health Care          |NASDAQ|LeMaitre Vascular, Inc.                                       |512549999.99999994|      74651.76|   1|
Medium                              |High                         |2023-05-01|QQXT  |n/a                  |NASDAQ|First Trust NASDAQ-100 Ex-Technology Sector Index Fund        |         101070000|      74154.09|   2|
Medium                              |High                         |2023-05-01|ESSA  |Finance              |NASDAQ|ESSA Bancorp, Inc.                                            |         175650000|      74026.74|   3|
Medium                              |High                         |2023-05-01|CSTR  |Finance              |NASDAQ|CapStar Financial Holdings, Inc.                              |         196970000|      73302.36|   4|
Medium                              |High                         |2023-05-01|FVC   |n/a                  |NASDAQ|First Trust Dorsey Wright Dynamic Focus 5 ETF                 |         318660000|      72653.09|   5|
Medium                              |Low                          |2023-05-01|GBAB  |n/a                  |NYSE  |Guggenheim Taxable Municipal Managed Duration Trst            |         398310000|      24961.37|   1|
Medium                              |Low                          |2023-05-01|PTCT  |Health Care          |NASDAQ|PTC Therapeutics, Inc.                                        |         700740000|      24810.05|   2|
Medium                              |Low                          |2023-05-01|BGIO  |n/a                  |NYSE  |BlackRock 2022 Global Income Opportunity Trust                |         209970000|      24685.68|   3|
Medium                              |Low                          |2023-05-01|FSFR  |n/a                  |NASDAQ|Fifth Street Senior Floating Rate Corp.                       |         219230000|      24514.43|   4|
Medium                              |Low                          |2023-05-01|SGY   |Energy               |NYSE  |Stone Energy Corporation                                      |         470400000|      24346.17|   5|
Medium                              |Medium                       |2023-05-01|EMCI  |Finance              |NASDAQ|EMC Insurance Group Inc.                                      |         588240000|       49732.2|   1|
Medium                              |Medium                       |2023-05-01|FMCI  |Finance              |NASDAQ|Forum Merger Corporation                                      |         217090000|      49649.44|   2|
Medium                              |Medium                       |2023-05-01|TLGT  |Health Care          |NASDAQ|Teligent, Inc.                                                |         459340000|      49375.42|   3|
Medium                              |Medium                       |2023-05-01|PGTI  |Capital Goods        |NYSE  |PGT Innovations, Inc.                                         |         610360000|      49373.11|   4|
Medium                              |Medium                       |2023-05-01|RVSB  |Finance              |NASDAQ|Riverview Bancorp Inc                                         |         148350000|      49298.53|   5|
Medium                              |Very High                    |2023-05-01|DGICB |Finance              |NASDAQ|Donegal Group, Inc.                                           |         395710000|      99801.39|   1|
Medium                              |Very High                    |2023-05-01|ACET  |Health Care          |NASDAQ|Aceto Corporation                                             |         437060000|      99113.45|   2|
Medium                              |Very High                    |2023-05-01|MYI   |n/a                  |NYSE  |Blackrock MuniYield Quality Fund III, Inc.                    |         975820000|      98236.89|   3|
Medium                              |Very High                    |2023-05-01|LNN   |Capital Goods        |NYSE  |Lindsay Corporation                                           |         914460000|      98208.86|   4|
Medium                              |Very High                    |2023-05-01|TSI   |n/a                  |NYSE  |TCW Strategic Income Fund, Inc.                               |         271820000|       98154.0|   5|
Small                               |High                         |2023-05-01|IPDN  |Technology           |NASDAQ|Professional Diversity Network, Inc.                          |          31400000|      74320.88|   1|
Small                               |High                         |2023-05-01|AKTX  |Health Care          |NASDAQ|Akari Therapeutics Plc                                        |          56290000|      74144.16|   2|
Small                               |High                         |2023-05-01|FPT   |n/a                  |NYSE  |Federated Premier Intermediate Municipal Income Fund          |          94960000|       73712.1|   3|
Small                               |High                         |2023-05-01|AGTC  |Health Care          |NASDAQ|Applied Genetic Technologies Corporation                      |          91320000|      72955.03|   4|
Small                               |High                         |2023-05-01|DWAQ  |n/a                  |NASDAQ|PowerShares DWA NASDAQ Momentum Portfolio                     |          35540000|      72826.15|   5|
Small                               |Low                          |2023-05-01|PTX   |Health Care          |NASDAQ|Pernix Therapeutics Holdings, Inc.                            |          44570000|      23490.65|   1|
Small                               |Low                          |2023-05-01|RLOG  |Consumer Services    |NASDAQ|Rand Logistics, Inc.                                          |         6700000.0|      23152.12|   2|
Small                               |Low                          |2023-05-01|FLKS  |Health Care          |NASDAQ|Flex Pharma, Inc.                                             |          64330000|      23130.19|   3|
Small                               |Low                          |2023-05-01|CBIO  |Health Care          |NASDAQ|Catalyst Biosciences, Inc.                                    |          18830000|      23021.48|   4|
Small                               |Low                          |2023-05-01|SGRP  |Miscellaneous        |NASDAQ|SPAR Group, Inc.                                              |          21070000|      22969.32|   5|
Small                               |Medium                       |2023-05-01|MARK  |Consumer Services    |NASDAQ|Remark Holdings, Inc.                                         |          57310000|      48745.09|   1|
Small                               |Medium                       |2023-05-01|WYIGU |Finance              |NASDAQ|JM Global Holding Company                                     |          67860000|       48225.7|   2|
Small                               |Medium                       |2023-05-01|FTXL  |n/a                  |NASDAQ|First Trust Nasdaq Semiconductor ETF                          |          21580000|      47878.22|   3|
Small                               |Medium                       |2023-05-01|AXR   |Consumer Services    |NYSE  |AMREP Corporation                                             |          56380000|      47057.47|   4|
Small                               |Medium                       |2023-05-01|PTIE  |Health Care          |NASDAQ|Pain Therapeutics, Inc.                                       |          27030000|      46914.07|   5|
Small                               |Very High                    |2023-05-01|DTYL  |Finance              |NASDAQ|iPath US Treasury 10-year Bull ETN                            |         5270000.0|       99565.5|   1|
Small                               |Very High                    |2023-05-01|RADA  |Consumer Non-Durables|NASDAQ|RADA Electronic Industries Ltd.                               |          36150000|      98743.23|   2|
Small                               |Very High                    |2023-05-01|FLN   |n/a                  |NASDAQ|First Trust Latin America AlphaDEX Fund                       |          35140000|      97059.76|   3|
Small                               |Very High                    |2023-05-01|TEAR  |Health Care          |NASDAQ|TearLab Corporation                                           |         9010000.0|      96069.44|   4|
Small                               |Very High                    |2023-05-01|GFA   |Basic Industries     |NYSE  |Gafisa SA                                                     |          95340000|      94675.84|   5|
Huge                                |High                         |2023-06-01|JNJ   |Health Care          |NYSE  |Johnson & Johnson                                             |      361920000000|      63276.99|   1|
Huge                                |High                         |2023-06-01|SNY   |Health Care          |NYSE  |Sanofi                                                        |      123340000000|      62990.84|   2|
Huge                                |Low                          |2023-06-01|DIS   |Consumer Services    |NYSE  |Walt Disney Company (The)                                     |      165110000000|      14255.13|   1|
Huge                                |Low                          |2023-06-01|VZ    |Public Utilities     |NYSE  |Verizon Communications Inc.                                   |      190220000000|       7682.81|   2|
Huge                                |Medium                       |2023-06-01|KHC   |Consumer Non-Durables|NASDAQ|The Kraft Heinz Company                                       |      108870000000|      46371.32|   1|
Huge                                |Medium                       |2023-06-01|UNH   |Health Care          |NYSE  |UnitedHealth Group Incorporated                               |      175030000000|      42275.72|   2|
Huge                                |Very High                    |2023-06-01|V     |Miscellaneous        |NYSE  |Visa Inc.                                                     |      217120000000|      92173.88|   1|
Huge                                |Very High                    |2023-06-01|SAP   |Technology           |NYSE  |SAP SE                                                        |      126800000000|      82246.47|   2|
Large                               |High                         |2023-06-01|SBCF  |Finance              |NASDAQ|Seacoast Banking Corporation of Florida                       |1070000000.0000001|      74931.39|   1|
Large                               |High                         |2023-06-01|TSRO  |Health Care          |NASDAQ|TESARO, Inc.                                                  |        7770000000|      74914.77|   2|
Large                               |High                         |2023-06-01|GLNG  |Consumer Services    |NASDAQ|Golar LNG Limited                                             |        2180000000|      74722.36|   3|
Large                               |High                         |2023-06-01|OR    |Basic Industries     |NYSE  |Osisko Gold Royalties Ltd                                     |        1280000000|      74616.51|   4|
Large                               |High                         |2023-06-01|TGI   |Capital Goods        |NYSE  |Triumph Group, Inc.                                           |        1580000000|      74520.13|   5|
Large                               |Low                          |2023-06-01|R     |Consumer Services    |NYSE  |Ryder System, Inc.                                            |        3600000000|      24883.59|   1|
Large                               |Low                          |2023-06-01|EQT   |Energy               |NYSE  |EQT Corporation                                               |       10190000000|      24850.08|   2|
Large                               |Low                          |2023-06-01|RNG   |Technology           |NYSE  |Ringcentral, Inc.                                             |        2670000000|      24763.73|   3|
Large                               |Low                          |2023-06-01|MSG   |Consumer Services    |NYSE  |MSG Networks Inc.                                             |        4600000000|      24477.69|   4|
Large                               |Low                          |2023-06-01|COH   |Consumer Non-Durables|NYSE  |Coach, Inc.                                                   |       13000000000|      24157.07|   5|
Large                               |Medium                       |2023-06-01|ATO   |Public Utilities     |NYSE  |Atmos Energy Corporation                                      |        9010000000|      49960.42|   1|
Large                               |Medium                       |2023-06-01|ESV   |Energy               |NYSE  |ENSCO plc                                                     |        1740000000|      49296.37|   2|
Large                               |Medium                       |2023-06-01|CABO  |Consumer Services    |NYSE  |Cable One, Inc.                                               |4139999999.9999995|      49205.43|   3|
Large                               |Medium                       |2023-06-01|GWB   |Finance              |NYSE  |Great Western Bancorp, Inc.                                   |        2340000000|      49148.13|   4|
Large                               |Medium                       |2023-06-01|SCI   |Consumer Services    |NYSE  |Service Corporation International                             |        6050000000|      48562.55|   5|
Large                               |Very High                    |2023-06-01|ARES  |Finance              |NYSE  |Ares Management L.P.                                          |        3790000000|      99597.83|   1|
Large                               |Very High                    |2023-06-01|CNO   |Finance              |NYSE  |CNO Financial Group, Inc.                                     |        3530000000|       98661.4|   2|
Large                               |Very High                    |2023-06-01|SIR   |Consumer Services    |NASDAQ|Select Income REIT                                            |        2210000000|      98606.66|   3|
Large                               |Very High                    |2023-06-01|SITE  |Consumer Non-Durables|NYSE  |SiteOne Landscape Supply, Inc.                                |        1970000000|      98281.12|   4|
Large                               |Very High                    |2023-06-01|VCSH  |n/a                  |NASDAQ|Vanguard Short-Term Corporate Bond ETF                        |       19140000000|      98089.43|   5|
Medium                              |High                         |2023-06-01|UNB   |Finance              |NASDAQ|Union Bankshares, Inc.                                        |         207260000|      74574.28|   1|
Medium                              |High                         |2023-06-01|BSET  |Consumer Durables    |NASDAQ|Bassett Furniture Industries, Incorporated                    |         342510000|      74480.97|   2|
Medium                              |High                         |2023-06-01|KRNT  |Capital Goods        |NASDAQ|Kornit Digital Ltd.                                           |         643740000|      74095.37|   3|
Medium                              |High                         |2023-06-01|RA    |n/a                  |NYSE  |Brookfield Real Assets Income Fund Inc.                       |         858040000|      73963.38|   4|
Medium                              |High                         |2023-06-01|IGD   |n/a                  |NYSE  |Voya Global Equity Dividend and Premium Opportunity Fund      |         729050000|      73485.54|   5|
Medium                              |Low                          |2023-06-01|BRT   |Consumer Services    |NYSE  |BRT Apartments Corp.                                          |         109520000|      24670.25|   1|
Medium                              |Low                          |2023-06-01|TITN  |Consumer Services    |NASDAQ|Titan Machinery Inc.                                          |         403050000|      24326.46|   2|
Medium                              |Low                          |2023-06-01|ACRX  |Health Care          |NASDAQ|AcelRx Pharmaceuticals, Inc.                                  |         108910000|      24139.95|   3|
Medium                              |Low                          |2023-06-01|HCHC  |Capital Goods        |NYSE  |HC2 Holdings, Inc.                                            |         244930000|      23794.32|   4|
Medium                              |Low                          |2023-06-01|JHA   |n/a                  |NYSE  |Nuveen High Income 2020 Target Term Fund                      |         296920000|      23582.79|   5|
Medium                              |Medium                       |2023-06-01|FARM  |Consumer Non-Durables|NASDAQ|Farmer Brothers Company                                       |         517130000|      49220.67|   1|
Medium                              |Medium                       |2023-06-01|NM    |Transportation       |NYSE  |Navios Maritime Holdings Inc.                                 |         133530000|       48957.8|   2|
Medium                              |Medium                       |2023-06-01|ITIC  |Finance              |NASDAQ|Investors Title Company                                       |         365710000|       48805.1|   3|
Medium                              |Medium                       |2023-06-01|AMRK  |Basic Industries     |NASDAQ|A-Mark Precious Metals, Inc.                                  |         112500000|      48678.25|   4|
Medium                              |Medium                       |2023-06-01|VCRA  |Consumer Durables    |NYSE  |Vocera Communications, Inc.                                   |         763420000|      48182.78|   5|
Medium                              |Very High                    |2023-06-01|ELEC  |Finance              |NASDAQ|Electrum Special Acquisition Corporation                      |         252500000|      98733.53|   1|
Medium                              |Very High                    |2023-06-01|HTD   |n/a                  |NYSE  |John Hancock Tax Advantaged Dividend Income Fund              |         901610000|       98596.3|   2|
Medium                              |Very High                    |2023-06-01|SGMO  |Health Care          |NASDAQ|Sangamo Therapeutics, Inc.                                    |535950000.00000006|      98510.78|   3|
Medium                              |Very High                    |2023-06-01|ACFC  |Finance              |NASDAQ|Atlantic Coast Financial Corporation                          |         119140000|      98337.86|   4|
Medium                              |Very High                    |2023-06-01|FBIO  |Health Care          |NASDAQ|Fortress Biotech, Inc.                                        |         222970000|      97961.94|   5|
Small                               |High                         |2023-06-01|MOSY  |Technology           |NASDAQ|MoSys, Inc.                                                   |          14150000|      74191.57|   1|
Small                               |High                         |2023-06-01|HBK   |Finance              |NASDAQ|Hamilton Bancorp, Inc.                                        |          49800000|      73200.09|   2|
Small                               |High                         |2023-06-01|ORIG  |Energy               |NASDAQ|Ocean Rig UDW Inc.                                            |          13200000|      72480.61|   3|
Small                               |High                         |2023-06-01|EYES  |n/a                  |NASDAQ|Second Sight Medical Products, Inc.                           |          62000000|      71766.77|   4|
Small                               |High                         |2023-06-01|DXTR  |Health Care          |NASDAQ|Dextera Surgical Inc.                                         |         2970000.0|      71473.97|   5|
Small                               |Low                          |2023-06-01|PY    |n/a                  |NASDAQ|Principal Shareholder Yield Index ETF                         |         7210000.0|      24086.99|   1|
Small                               |Low                          |2023-06-01|FPA   |n/a                  |NASDAQ|First Trust Asia Pacific Ex-Japan AlphaDEX Fund               |          45770000|      23996.29|   2|
Small                               |Low                          |2023-06-01|CBIO  |Health Care          |NASDAQ|Catalyst Biosciences, Inc.                                    |          18830000|      21976.83|   3|
Small                               |Low                          |2023-06-01|MDVX  |Health Care          |NASDAQ|Medovex Corp.                                                 |          18220000|      21651.12|   4|
Small                               |Low                          |2023-06-01|FBSS  |Finance              |NASDAQ|Fauquier Bankshares, Inc.                                     |          70550000|      21021.95|   5|
Small                               |Medium                       |2023-06-01|DAVE  |Consumer Services    |NASDAQ|Famous Dave's of America, Inc.                                |          24350000|      49427.98|   1|
Small                               |Medium                       |2023-06-01|HOS   |Consumer Services    |NYSE  |Hornbeck Offshore Services                                    |          97070000|      48689.45|   2|
Small                               |Medium                       |2023-06-01|SRET  |n/a                  |NASDAQ|Global X SuperDividend REIT ETF                               |         3090000.0|      47654.27|   3|
Small                               |Medium                       |2023-06-01|FBZ   |n/a                  |NASDAQ|First Trust Brazil AlphaDEX Fund                              |          25390000|      47325.13|   4|
Small                               |Medium                       |2023-06-01|PRAN  |Health Care          |NASDAQ|Prana Biotechnology Ltd                                       |          18770000|      47041.11|   5|
Small                               |Very High                    |2023-06-01|FCEL  |Miscellaneous        |NASDAQ|FuelCell Energy, Inc.                                         |          65530000|       99071.0|   1|
Small                               |Very High                    |2023-06-01|CASI  |Health Care          |NASDAQ|CASI Pharmaceuticals, Inc.                                    |          55380000|      98738.91|   2|
Small                               |Very High                    |2023-06-01|UBCP  |Finance              |NASDAQ|United Bancorp, Inc.                                          |          63570000|      98586.61|   3|
Small                               |Very High                    |2023-06-01|TUES  |Consumer Services    |NASDAQ|Tuesday Morning Corp.                                         |          83440000|      97735.51|   4|
Small                               |Very High                    |2023-06-01|LTRX  |Technology           |NASDAQ|Lantronix, Inc.                                               |          40450000|      96750.42|   5|
Huge                                |High                         |2023-07-01|T     |Public Utilities     |NYSE  |AT&T Inc.                                                     |      239530000000|      59545.82|   1|
Huge                                |High                         |2023-07-01|BABA  |Miscellaneous        |NYSE  |Alibaba Group Holding Limited                                 |      341220000000|      55867.43|   2|
Huge                                |High                         |2023-07-01|PG    |Basic Industries     |NYSE  |Procter & Gamble Company (The)                                |      229320000000|      55544.98|   3|
Huge                                |High                         |2023-07-01|MMM   |Health Care          |NYSE  |3M Company                                                    |      127360000000|      53387.28|   4|
Huge                                |High                         |2023-07-01|GOOGL |Technology           |NASDAQ|Alphabet Inc.                                                 |      663120000000|      52801.45|   5|
Huge                                |Low                          |2023-07-01|CVX   |Energy               |NYSE  |Chevron Corporation                                           |      205280000000|      20087.02|   1|
Huge                                |Low                          |2023-07-01|MO    |Consumer Non-Durables|NYSE  |Altria Group                                                  |      149280000000|       6833.44|   2|
Huge                                |Low                          |2023-07-01|GOOGL |Technology           |NASDAQ|Alphabet Inc.                                                 |      663120000000|        777.75|   3|
Huge                                |Medium                       |2023-07-01|JNJ   |Health Care          |NYSE  |Johnson & Johnson                                             |      361920000000|      49062.01|   1|
Huge                                |Medium                       |2023-07-01|HD    |Consumer Services    |NYSE  |Home Depot, Inc. (The)                                        |      187270000000|      37792.97|   2|
Huge                                |Medium                       |2023-07-01|JPM   |Finance              |NYSE  |J P Morgan Chase & Co                                         |      306180000000|      25046.55|   3|
Huge                                |Very High                    |2023-07-01|AAPL  |Technology           |NASDAQ|Apple Inc.                                                    |      741770000000|      97064.12|   1|
Huge                                |Very High                    |2023-07-01|HSBC  |Finance              |NYSE  |HSBC Holdings plc                                             |      176430000000|      95720.42|   2|
Huge                                |Very High                    |2023-07-01|PM    |Consumer Non-Durables|NYSE  |Philip Morris International Inc                               |      189230000000|      95224.24|   3|
Huge                                |Very High                    |2023-07-01|MMM   |Health Care          |NYSE  |3M Company                                                    |      127360000000|      91660.76|   4|
Large                               |High                         |2023-07-01|LOW   |Consumer Services    |NYSE  |Lowe's Companies, Inc.                                        | 67370000000.00001|      74938.25|   1|
Large                               |High                         |2023-07-01|BPL   |Energy               |NYSE  |Buckeye Partners L.P.                                         |        8620000000|      74395.94|   2|
Large                               |High                         |2023-07-01|IPXL  |Health Care          |NASDAQ|Impax Laboratories, Inc.                                      |        1020000000|      73831.61|   3|
Large                               |High                         |2023-07-01|EGO   |Basic Industries     |NYSE  |Eldorado Gold Corporation                                     |        1970000000|      73819.66|   4|
Large                               |High                         |2023-07-01|AMN   |Technology           |NYSE  |AMN Healthcare Services Inc                                   |        1730000000|      73791.51|   5|
Large                               |Low                          |2023-07-01|MRC   |Capital Goods        |NYSE  |MRC Global Inc.                                               |        1630000000|      24936.74|   1|
Large                               |Low                          |2023-07-01|RGEN  |Health Care          |NASDAQ|Repligen Corporation                                          |        1300000000|      24717.29|   2|
Large                               |Low                          |2023-07-01|MFA   |Consumer Services    |NYSE  |MFA Financial, Inc.                                           |        3200000000|       24664.5|   3|
Large                               |Low                          |2023-07-01|AMD   |Technology           |NASDAQ|Advanced Micro Devices, Inc.                                  |       10810000000|      23948.95|   4|
Large                               |Low                          |2023-07-01|CXW   |Consumer Services    |NYSE  |CoreCivic, Inc.                                               |        3310000000|      23832.09|   5|
Large                               |Medium                       |2023-07-01|YY    |Technology           |NASDAQ|YY Inc.                                                       |        3060000000|      49705.78|   1|
Large                               |Medium                       |2023-07-01|GKOS  |Health Care          |NYSE  |Glaukos Corporation                                           |        1390000000|      49704.57|   2|
Large                               |Medium                       |2023-07-01|ERJ   |Capital Goods        |NYSE  |Embraer-Empresa Brasileira de Aeronautica                     |        3450000000|      49000.27|   3|
Large                               |Medium                       |2023-07-01|WWE   |Consumer Services    |NYSE  |World Wrestling Entertainment, Inc.                           |        1600000000|      48620.09|   4|
Large                               |Medium                       |2023-07-01|COL   |Capital Goods        |NYSE  |Rockwell Collins, Inc.                                        |       17430000000|      48555.71|   5|
Large                               |Very High                    |2023-07-01|MMC   |Finance              |NYSE  |Marsh & McLennan Companies, Inc.                              |       41270000000|      99552.77|   1|
Large                               |Very High                    |2023-07-01|OFC   |Consumer Services    |NYSE  |Corporate Office Properties Trust                             |        3520000000|      98696.05|   2|
Large                               |Very High                    |2023-07-01|NEU   |Basic Industries     |NYSE  |NewMarket Corporation                                         |        5530000000|      98668.88|   3|
Large                               |Very High                    |2023-07-01|VONG  |n/a                  |NASDAQ|Vanguard Russell 1000 Growth ETF                              |        1180000000|      98462.08|   4|
Large                               |Very High                    |2023-07-01|CNNX  |Public Utilities     |NYSE  |Cone Midstream Partners LP                                    |        1170000000|      98211.51|   5|
Medium                              |High                         |2023-07-01|MG    |Consumer Services    |NYSE  |Mistras Group Inc                                             |         617060000|      74883.88|   1|
Medium                              |High                         |2023-07-01|OBSV  |Health Care          |NASDAQ|ObsEva SA                                                     |         161490000|      74303.37|   2|
Medium                              |High                         |2023-07-01|ASIX  |Basic Industries     |NYSE  |AdvanSix Inc.                                                 |         897420000|      74236.29|   3|
Medium                              |High                         |2023-07-01|VEC   |Consumer Services    |NYSE  |Vectrus, Inc.                                                 |         340820000|      74215.39|   4|
Medium                              |High                         |2023-07-01|IEUS  |n/a                  |NASDAQ|iShares MSCI Europe Small-Cap ETF                             |         126720000|      74170.42|   5|
Medium                              |Low                          |2023-07-01|HEQ   |n/a                  |NYSE  |John Hancock Hedged Equity & Income Fund                      |         206260000|      24803.62|   1|
Medium                              |Low                          |2023-07-01|MCA   |n/a                  |NYSE  |Blackrock MuniYield California Insured Fund, Inc.             |517809999.99999994|      23827.85|   2|
Medium                              |Low                          |2023-07-01|JP    |Consumer Services    |NYSE  |Jupai Holdings Limited                                        |258290000.00000003|      23788.26|   3|
Medium                              |Low                          |2023-07-01|SBCP  |Finance              |NASDAQ|Sunshine Bancorp, Inc.                                        |         173850000|      23644.35|   4|
Medium                              |Low                          |2023-07-01|CTT   |Consumer Services    |NYSE  |CatchMark Timber Trust, Inc.                                  |         452920000|      23614.49|   5|
Medium                              |Medium                       |2023-07-01|CDXC  |Consumer Durables    |NASDAQ|ChromaDex Corporation                                         |         153950000|      49959.02|   1|
Medium                              |Medium                       |2023-07-01|AMRC  |Basic Industries     |NYSE  |Ameresco, Inc.                                                |         308890000|      49549.41|   2|
Medium                              |Medium                       |2023-07-01|MCA   |n/a                  |NYSE  |Blackrock MuniYield California Insured Fund, Inc.             |517809999.99999994|      49401.76|   3|
Medium                              |Medium                       |2023-07-01|JHG   |Finance              |NYSE  |Janus Henderson Group plc                                     |         367060000|      49000.83|   4|
Medium                              |Medium                       |2023-07-01|SP    |Consumer Services    |NASDAQ|SP Plus Corporation                                           |         676910000|       48915.8|   5|
Medium                              |Very High                    |2023-07-01|GNMA  |n/a                  |NASDAQ|iShares GNMA Bond ETF                                         |         174890000|      99605.26|   1|
Medium                              |Very High                    |2023-07-01|LDR   |Capital Goods        |NYSE  |Landauer, Inc.                                                |513320000.00000006|       99523.5|   2|
Medium                              |Very High                    |2023-07-01|PER   |Energy               |NYSE  |SandRidge Permian Trust                                       |         150940000|      99134.55|   3|
Medium                              |Very High                    |2023-07-01|HK    |Energy               |NYSE  |Halcon Resources Corporation                                  |         660530000|      99073.46|   4|
Medium                              |Very High                    |2023-07-01|CCXI  |Health Care          |NASDAQ|ChemoCentryx, Inc.                                            |         351670000|      98401.54|   5|
Small                               |High                         |2023-07-01|SITO  |Miscellaneous        |NASDAQ|SITO Mobile, Ltd.                                             |          71560000|      74604.41|   1|
Small                               |High                         |2023-07-01|ESG   |n/a                  |NASDAQ|FlexShares STOXX US ESG Impact Index Fund                     |         8610000.0|      73317.95|   2|
Small                               |High                         |2023-07-01|MSBF  |Finance              |NASDAQ|MSB Financial Corp.                                           |          99400000|      69252.63|   3|
Small                               |High                         |2023-07-01|PPSI  |Consumer Durables    |NASDAQ|Pioneer Power Solutions, Inc.                                 |          56680000|       67168.2|   4|
Small                               |High                         |2023-07-01|RELL  |Consumer Non-Durables|NASDAQ|Richardson Electronics, Ltd.                                  |          75940000|      67167.98|   5|
Small                               |Low                          |2023-07-01|ELON  |Technology           |NASDAQ|Echelon Corporation                                           |          24700000|      24556.81|   1|
Small                               |Low                          |2023-07-01|IFEU  |n/a                  |NASDAQ|iShares FTSE EPRA/NAREIT Europe Index Fund                    |          42370000|      24134.77|   2|
Small                               |Low                          |2023-07-01|OTIV  |Technology           |NASDAQ|On Track Innovations Ltd                                      |          51370000|      23968.41|   3|
Small                               |Low                          |2023-07-01|AMTX  |Basic Industries     |NASDAQ|Aemetis, Inc                                                  |          29540000|      23845.56|   4|
Small                               |Low                          |2023-07-01|CARZ  |n/a                  |NASDAQ|First Trust NASDAQ Global Auto Index Fund                     |          18490000|      23374.58|   5|
Small                               |Medium                       |2023-07-01|SEED  |Consumer Non-Durables|NASDAQ|Origin Agritech Limited                                       |32450000.000000004|      48603.15|   1|
Small                               |Medium                       |2023-07-01|MBRX  |Health Care          |NASDAQ|Moleculin Biotech, Inc.                                       |          14380000|      48281.66|   2|
Small                               |Medium                       |2023-07-01|GNVC  |Health Care          |NASDAQ|GenVec, Inc.                                                  |16350000.000000002|      46929.79|   3|
Small                               |Medium                       |2023-07-01|YTEN  |Basic Industries     |NASDAQ|Yield10 Bioscience, Inc.                                      |         1440000.0|      46925.56|   4|
Small                               |Medium                       |2023-07-01|ICAD  |Health Care          |NASDAQ|icad inc.                                                     |          68610000|      45976.56|   5|
Small                               |Very High                    |2023-07-01|DWAQ  |n/a                  |NASDAQ|PowerShares DWA NASDAQ Momentum Portfolio                     |          35540000|      99843.63|   1|
Small                               |Very High                    |2023-07-01|HOTR  |Consumer Services    |NASDAQ|Chanticleer Holdings, Inc.                                    |         6310000.0|      99399.76|   2|
Small                               |Very High                    |2023-07-01|TRIL  |Health Care          |NASDAQ|Trillium Therapeutics Inc.                                    |          49000000|      99022.19|   3|
Small                               |Very High                    |2023-07-01|SKIS  |Consumer Services    |NASDAQ|Peak Resorts, Inc.                                            |          59430000|      97259.06|   4|
Small                               |Very High                    |2023-07-01|AVIR  |Health Care          |NASDAQ|Aviragen Therapeutics, Inc.                                   |          20870000|       96846.6|   5|
Huge                                |High                         |2023-08-01|GOOG  |Technology           |NASDAQ|Alphabet Inc.                                                 |      650090000000|      66206.88|   1|
Huge                                |High                         |2023-08-01|JNJ   |Health Care          |NYSE  |Johnson & Johnson                                             |      361920000000|      65338.79|   2|
Huge                                |High                         |2023-08-01|WMT   |Consumer Services    |NYSE  |Wal-Mart Stores, Inc.                                         |      226810000000|       62430.2|   3|
Huge                                |Low                          |2023-08-01|TSM   |Technology           |NYSE  |Taiwan Semiconductor Manufacturing Company Ltd.               |      186020000000|      18267.63|   1|
Huge                                |Low                          |2023-08-01|CVX   |Energy               |NYSE  |Chevron Corporation                                           |      205280000000|      13896.74|   2|
Huge                                |Medium                       |2023-08-01|HON   |Capital Goods        |NYSE  |Honeywell International Inc.                                  |      102630000000|      32373.73|   1|
Huge                                |Very High                    |2023-08-01|HD    |Consumer Services    |NYSE  |Home Depot, Inc. (The)                                        |      187270000000|      95429.11|   1|
Large                               |High                         |2023-08-01|GG    |Basic Industries     |NYSE  |Goldcorp Inc.                                                 |       11220000000|       74783.8|   1|
Large                               |High                         |2023-08-01|IPG   |Technology           |NYSE  |Interpublic Group of Companies, Inc. (The)                    |        9640000000|      74769.34|   2|
Large                               |High                         |2023-08-01|ERF   |Energy               |NYSE  |Enerplus Corporation                                          |        1950000000|      74734.78|   3|
Large                               |High                         |2023-08-01|AMOV  |Public Utilities     |NYSE  |America Movil, S.A.B. de C.V.                                 |       51950000000|       74705.7|   4|
Large                               |High                         |2023-08-01|JRVR  |Finance              |NASDAQ|James River Group Holdings, Ltd.                              |        1180000000|      74618.92|   5|
Large                               |Low                          |2023-08-01|BSM   |Energy               |NYSE  |Black Stone Minerals, L.P.                                    |        3000000000|       24381.9|   1|
Large                               |Low                          |2023-08-01|SEP   |Public Utilities     |NYSE  |Spectra Energy Partners, LP                                   |       13130000000|      24372.21|   2|
Large                               |Low                          |2023-08-01|GPS   |Consumer Services    |NYSE  |Gap, Inc. (The)                                               |        9060000000|      24067.34|   3|
Large                               |Low                          |2023-08-01|IEP   |Capital Goods        |NASDAQ|Icahn Enterprises L.P.                                        |        8250000000|      24014.97|   4|
Large                               |Low                          |2023-08-01|XLRN  |Health Care          |NASDAQ|Acceleron Pharma Inc.                                         |        1150000000|      23419.53|   5|
Large                               |Medium                       |2023-08-01|APPF  |Technology           |NASDAQ|AppFolio, Inc.                                                |        1080000000|      49842.73|   1|
Large                               |Medium                       |2023-08-01|MWA   |Capital Goods        |NYSE  |MUELLER WATER PRODUCTS                                        |        1830000000|      49246.68|   2|
Large                               |Medium                       |2023-08-01|BRKR  |Capital Goods        |NASDAQ|Bruker Corporation                                            |        4430000000|      49245.38|   3|
Large                               |Medium                       |2023-08-01|ULTI  |Technology           |NASDAQ|The Ultimate Software Group, Inc.                             |        6350000000|      49125.24|   4|
Large                               |Medium                       |2023-08-01|JWN   |Consumer Services    |NYSE  |Nordstrom, Inc.                                               |        7890000000|       48812.1|   5|
Large                               |Very High                    |2023-08-01|MTOR  |Capital Goods        |NYSE  |Meritor, Inc.                                                 |        1410000000|      98657.98|   1|
Large                               |Very High                    |2023-08-01|HI    |Consumer Durables    |NYSE  |Hillenbrand Inc                                               |        2310000000|      98467.47|   2|
Large                               |Very High                    |2023-08-01|ONCE  |Health Care          |NASDAQ|Spark Therapeutics, Inc.                                      |        1820000000|      98247.23|   3|
Large                               |Very High                    |2023-08-01|BPY   |Finance              |NYSE  |Brookfield Property Partners L.P.                             |        5910000000|      97134.54|   4|
Large                               |Very High                    |2023-08-01|INFY  |Technology           |NYSE  |Infosys Limited                                               |       33530000000|      96898.17|   5|
Medium                              |High                         |2023-08-01|CLDT  |Consumer Services    |NYSE  |Chatham Lodging Trust (REIT)                                  |         776550000|      74196.58|   1|
Medium                              |High                         |2023-08-01|HONE  |Finance              |NASDAQ|HarborOne Bancorp, Inc.                                       |         655590000|      72839.67|   2|
Medium                              |High                         |2023-08-01|BSL   |n/a                  |NYSE  |Blackstone GSO Senior Floating Rate Term Fund                 |         271310000|      72701.83|   3|
Medium                              |High                         |2023-08-01|IDRA  |Health Care          |NASDAQ|Idera Pharmaceuticals, Inc.                                   |         237150000|      72016.13|   4|
Medium                              |High                         |2023-08-01|PHD   |n/a                  |NYSE  |Pioneer Floating Rate Trust                                   |         293390000|      71810.27|   5|
Medium                              |Low                          |2023-08-01|PHH   |Finance              |NYSE  |PHH Corp                                                      |         743070000|      24410.07|   1|
Medium                              |Low                          |2023-08-01|TCI   |Consumer Services    |NYSE  |Transcontinental Realty Investors, Inc.                       |         230240000|      24356.24|   2|
Medium                              |Low                          |2023-08-01|ESPR  |Health Care          |NASDAQ|Esperion Therapeutics, Inc.                                   |         754280000|      24258.14|   3|
Medium                              |Low                          |2023-08-01|IDE   |n/a                  |NYSE  |Voya Infrastructure, Industrials and Materials Fund           |         296890000|      24036.38|   4|
Medium                              |Low                          |2023-08-01|CYAD  |Health Care          |NASDAQ|Celyad SA                                                     |         445000000|      22655.78|   5|
Medium                              |Medium                       |2023-08-01|KBWR  |n/a                  |NASDAQ|PowerShares KBW Regional Banking Portfolio                    |         164430000|      49979.91|   1|
Medium                              |Medium                       |2023-08-01|LMIA  |Capital Goods        |NASDAQ|LMI Aerospace, Inc.                                           |         191030000|      49902.73|   2|
Medium                              |Medium                       |2023-08-01|GPM   |n/a                  |NYSE  |Guggenheim Enhanced Equity Income Fund                        |         392460000|      49627.77|   3|
Medium                              |Medium                       |2023-08-01|FPRX  |Health Care          |NASDAQ|Five Prime Therapeutics, Inc.                                 |         809460000|      49494.77|   4|
Medium                              |Medium                       |2023-08-01|FGB   |n/a                  |NYSE  |First Trust Specialty Finance and Financial Opportunities Fund|         103460000|      48542.48|   5|
Medium                              |Very High                    |2023-08-01|KEM   |Capital Goods        |NYSE  |Kemet Corporation                                             |         651310000|      99911.79|   1|
Medium                              |Very High                    |2023-08-01|VCRA  |Consumer Durables    |NYSE  |Vocera Communications, Inc.                                   |         763420000|      99808.72|   2|
Medium                              |Very High                    |2023-08-01|ARDC  |n/a                  |NYSE  |Ares Dynamic Credit Allocation Fund, Inc.                     |         378210000|      99728.76|   3|
Medium                              |Very High                    |2023-08-01|CCM   |Health Care          |NYSE  |Concord Medical Services Holdings Limited                     |         153070000|      99535.36|   4|
Medium                              |Very High                    |2023-08-01|BGX   |n/a                  |NYSE  |Blackstone GSO Long Short Credit Income Fund                  |         207430000|      98834.66|   5|
Small                               |High                         |2023-08-01|TIL   |Finance              |NASDAQ|Till Capital Ltd.                                             |          13150000|      74684.52|   1|
Small                               |High                         |2023-08-01|AKER  |Health Care          |NASDAQ|Akers Biosciences Inc                                         |          11120000|      74400.39|   2|
Small                               |High                         |2023-08-01|SGRP  |Miscellaneous        |NASDAQ|SPAR Group, Inc.                                              |          21070000|      72386.78|   3|
Small                               |High                         |2023-08-01|ESGE  |n/a                  |NASDAQ|iShares MSCI EM ESG Optimized ETF                             |          54380000|      72167.02|   4|
Small                               |High                         |2023-08-01|SLNO  |Health Care          |NASDAQ|Soleno Therapeutics, Inc.                                     |          27600000|      71520.66|   5|
Small                               |Low                          |2023-08-01|HUNT  |Transportation       |NASDAQ|Hunter Maritime Acquisition Corp.                             |          42180000|      24912.09|   1|
Small                               |Low                          |2023-08-01|ADHD  |Health Care          |NASDAQ|Alcobra Ltd.                                                  |          30870000|      24561.24|   2|
Small                               |Low                          |2023-08-01|LTRX  |Technology           |NASDAQ|Lantronix, Inc.                                               |          40450000|      23764.09|   3|
Small                               |Low                          |2023-08-01|THLD  |Health Care          |NASDAQ|Threshold Pharmaceuticals, Inc.                               |          27590000|      23467.85|   4|
Small                               |Low                          |2023-08-01|DWLV  |n/a                  |NASDAQ|PowerShares DWA Momentum & Low Volatility Rotation Portfolio  |         4200000.0|      22142.47|   5|
Small                               |Medium                       |2023-08-01|PSL   |n/a                  |NASDAQ|PowerShares DWA Consumer Staples Momentum Portfolio           |          78330000|      49205.79|   1|
Small                               |Medium                       |2023-08-01|KOSS  |Consumer Non-Durables|NASDAQ|Koss Corporation                                              |          14100000|      47984.29|   2|
Small                               |Medium                       |2023-08-01|PFI   |n/a                  |NASDAQ|PowerShares DWA Financial Momentum Portfolio                  |          78450000|      47030.96|   3|
Small                               |Medium                       |2023-08-01|AEHR  |Capital Goods        |NASDAQ|Aehr Test Systems                                             |          79320000|      46857.85|   4|
Small                               |Medium                       |2023-08-01|TGA   |Energy               |NASDAQ|Transglobe Energy Corp                                        |          92420000|      45874.74|   5|
Small                               |Very High                    |2023-08-01|HFBL  |Finance              |NASDAQ|Home Federal Bancorp, Inc. of Louisiana                       |          48460000|      99258.91|   1|
Small                               |Very High                    |2023-08-01|STPP  |Finance              |NASDAQ|iPath US Treasury Steepener ETN                               |         3250000.0|      98186.87|   2|
Small                               |Very High                    |2023-08-01|VBFC  |Finance              |NASDAQ|Village Bank and Trust Financial Corp.                        |          44250000|      97956.95|   3|
Small                               |Very High                    |2023-08-01|FCEL  |Miscellaneous        |NASDAQ|FuelCell Energy, Inc.                                         |          65530000|      96915.59|   4|
Small                               |Very High                    |2023-08-01|URRE  |Basic Industries     |NASDAQ|Uranium Resources, Inc.                                       |          34590000|       96094.6|   5|
Huge                                |High                         |2023-09-01|BA    |Capital Goods        |NYSE  |Boeing Company (The)                                          |      118570000000|      67164.75|   1|
Huge                                |High                         |2023-09-01|HD    |Consumer Services    |NYSE  |Home Depot, Inc. (The)                                        |      187270000000|      67055.91|   2|
Huge                                |High                         |2023-09-01|PEP   |Consumer Non-Durables|NYSE  |Pepsico, Inc.                                                 |      166930000000|      63465.25|   3|
Huge                                |Low                          |2023-09-01|WFC   |Finance              |NYSE  |Wells Fargo & Company                                         |      269310000000|      24028.29|   1|
Huge                                |Low                          |2023-09-01|VZ    |Public Utilities     |NYSE  |Verizon Communications Inc.                                   |      190220000000|      23351.82|   2|
Huge                                |Low                          |2023-09-01|WFC   |Finance              |NYSE  |Wells Fargo & Company                                         |      269310000000|      12409.03|   3|
Huge                                |Low                          |2023-09-01|CMCSA |Consumer Services    |NASDAQ|Comcast Corporation                                           |      195790000000|       1022.75|   4|
Huge                                |Very High                    |2023-09-01|GSK   |Health Care          |NYSE  |GlaxoSmithKline PLC                                           |      107750000000|      94009.24|   1|
Huge                                |Very High                    |2023-09-01|KHC   |Consumer Non-Durables|NASDAQ|The Kraft Heinz Company                                       |      108870000000|      78750.16|   2|
Large                               |High                         |2023-09-01|CPLA  |Consumer Services    |NASDAQ|Capella Education Company                                     |        1040000000|      74975.01|   1|
Large                               |High                         |2023-09-01|CPRT  |Consumer Durables    |NASDAQ|Copart, Inc.                                                  |        7200000000|      74248.21|   2|
Large                               |High                         |2023-09-01|HSC   |Capital Goods        |NYSE  |Harsco Corporation                                            |        1350000000|      74003.42|   3|
Large                               |High                         |2023-09-01|EFII  |Technology           |NASDAQ|Electronics for Imaging, Inc.                                 |        2300000000|      73756.89|   4|
Large                               |High                         |2023-09-01|JUNO  |Health Care          |NASDAQ|Juno Therapeutics, Inc.                                       |        2470000000|      73434.46|   5|
Large                               |Low                          |2023-09-01|EUFN  |n/a                  |NASDAQ|iShares MSCI Europe Financials Sector Index Fund              |        1150000000|      24556.43|   1|
Large                               |Low                          |2023-09-01|HAL   |Energy               |NYSE  |Halliburton Company                                           |       38420000000|      24045.08|   2|
Large                               |Low                          |2023-09-01|MIK   |Consumer Services    |NASDAQ|The Michaels Companies, Inc.                                  |        3530000000|      23962.95|   3|
Large                               |Low                          |2023-09-01|INGR  |Consumer Non-Durables|NYSE  |Ingredion Incorporated                                        |        8520000000|      23822.65|   4|
Large                               |Low                          |2023-09-01|FCB   |Finance              |NYSE  |FCB Financial Holdings, Inc.                                  |2009999999.9999998|       23794.8|   5|
Large                               |Medium                       |2023-09-01|EMR   |Energy               |NYSE  |Emerson Electric Company                                      |       39110000000|      49494.66|   1|
Large                               |Medium                       |2023-09-01|NTAP  |Technology           |NASDAQ|NetApp, Inc.                                                  |       10290000000|      49109.01|   2|
Large                               |Medium                       |2023-09-01|EEQ   |Energy               |NYSE  |Enbridge Energy Management LLC                                |        1270000000|      48995.54|   3|
Large                               |Medium                       |2023-09-01|AMKR  |Technology           |NASDAQ|Amkor Technology, Inc.                                        |        2520000000|      48968.44|   4|
Large                               |Medium                       |2023-09-01|PAC   |Transportation       |NYSE  |Grupo Aeroportuario Del Pacifico, S.A. de C.V.                |        5930000000|      48934.53|   5|
Large                               |Very High                    |2023-09-01|LKFN  |Finance              |NASDAQ|Lakeland Financial Corporation                                |        1160000000|      99910.52|   1|
Large                               |Very High                    |2023-09-01|KLIC  |Technology           |NASDAQ|Kulicke and Soffa Industries, Inc.                            |        1460000000|      99897.54|   2|
Large                               |Very High                    |2023-09-01|FSV   |Finance              |NASDAQ|FirstService Corporation                                      |        2150000000|      99263.34|   3|
Large                               |Very High                    |2023-09-01|YEXT  |Technology           |NYSE  |Yext, Inc.                                                    |        1200000000|       99229.8|   4|
Large                               |Very High                    |2023-09-01|MTX   |Basic Industries     |NYSE  |Minerals Technologies Inc.                                    |        2500000000|      99097.44|   5|
Medium                              |High                         |2023-09-01|VRAY  |Health Care          |NASDAQ|ViewRay, Inc.                                                 |         370120000|      74986.67|   1|
Medium                              |High                         |2023-09-01|MLR   |Capital Goods        |NYSE  |Miller Industries, Inc.                                       |         289480000|      74252.84|   2|
Medium                              |High                         |2023-09-01|LAND  |Consumer Services    |NASDAQ|Gladstone Land Corporation                                    |         133560000|      74019.01|   3|
Medium                              |High                         |2023-09-01|FTEO  |n/a                  |NASDAQ|FRONTEO, Inc.                                                 |         254840000|      73963.06|   4|
Medium                              |High                         |2023-09-01|DLNG  |Consumer Services    |NYSE  |Dynagas LNG Partners LP                                       |517440000.00000006|      73826.53|   5|
Medium                              |Low                          |2023-09-01|ATAX  |Finance              |NASDAQ|America First Multifamily Investors, L.P.                     |         358500000|      24639.19|   1|
Medium                              |Low                          |2023-09-01|AFB   |n/a                  |NYSE  |Alliance National Municipal Income Fund Inc                   |         392940000|      24020.67|   2|
Medium                              |Low                          |2023-09-01|EOI   |n/a                  |NYSE  |Eaton Vance Enhance Equity Income Fund                        |534710000.00000006|      23974.86|   3|
Medium                              |Low                          |2023-09-01|ANW   |Energy               |NYSE  |Aegean Marine Petroleum Network Inc.                          |         224840000|       23757.2|   4|
Medium                              |Low                          |2023-09-01|PEBK  |Finance              |NASDAQ|Peoples Bancorp of North Carolina, Inc.                       |         175040000|      23666.18|   5|
Medium                              |Medium                       |2023-09-01|FMCI  |Finance              |NASDAQ|Forum Merger Corporation                                      |         217090000|      49603.22|   1|
Medium                              |Medium                       |2023-09-01|FOMX  |Consumer Durables    |NASDAQ|Foamix Pharmaceuticals Ltd.                                   |         164160000|      48955.83|   2|
Medium                              |Medium                       |2023-09-01|DLTH  |Consumer Services    |NASDAQ|Duluth Holdings Inc.                                          |         558540000|      48944.21|   3|
Medium                              |Medium                       |2023-09-01|FTSM  |n/a                  |NASDAQ|First Trust Enhanced Short Maturity ETF                       |         966470000|      48815.24|   4|
Medium                              |Medium                       |2023-09-01|TSBK  |Finance              |NASDAQ|Timberland Bancorp, Inc.                                      |         177780000|      48621.11|   5|
Medium                              |Very High                    |2023-09-01|JHD   |n/a                  |NYSE  |Nuveen High Income December 2019 Target Term Fund             |         277100000|      99770.29|   1|
Medium                              |Very High                    |2023-09-01|KIO   |n/a                  |NYSE  |KKR Income Opportunities Fund                                 |         271700000|      98969.32|   2|
Medium                              |Very High                    |2023-09-01|MPO   |Energy               |NYSE  |MIDSTATES PETROLEUM COMPANY, INC.                             |         364190000|      97778.79|   3|
Medium                              |Very High                    |2023-09-01|NBB   |n/a                  |NYSE  |Nuveen Build America Bond Fund                                |         555700000|      96635.42|   4|
Medium                              |Very High                    |2023-09-01|FOF   |n/a                  |NYSE  |Cohen & Steers Closed-End Opportunity Fund, Inc.              |         351000000|      96261.32|   5|
Small                               |High                         |2023-09-01|SSFN  |Finance              |NASDAQ|Stewardship Financial Corp                                    |          83390000|       74424.7|   1|
Small                               |High                         |2023-09-01|AEY   |Consumer Services    |NASDAQ|ADDvantage Technologies Group, Inc.                           |          16610000|      73252.86|   2|
Small                               |High                         |2023-09-01|PQ    |Energy               |NYSE  |Petroquest Energy Inc                                         |          46900000|      73110.06|   3|
Small                               |High                         |2023-09-01|DWCH  |Technology           |NASDAQ|Datawatch Corporation                                         |          96200000|       72721.3|   4|
Small                               |High                         |2023-09-01|OPHC  |Finance              |NASDAQ|OptimumBank Holdings, Inc.                                    |         2910000.0|      72535.21|   5|
Small                               |Low                          |2023-09-01|NTIC  |Capital Goods        |NASDAQ|Northern Technologies International Corporation               |          73300000|      24487.17|   1|
Small                               |Low                          |2023-09-01|OLD   |n/a                  |NASDAQ|The Long-Term Care ETF                                        |         2700000.0|      24207.47|   2|
Small                               |Low                          |2023-09-01|LRAD  |Consumer Non-Durables|NASDAQ|LRAD Corporation                                              |          51200000|      22730.57|   3|
Small                               |Low                          |2023-09-01|IRMD  |Health Care          |NASDAQ|iRadimed Corporation                                          |          92990000|      22445.24|   4|
Small                               |Low                          |2023-09-01|AEY   |Consumer Services    |NASDAQ|ADDvantage Technologies Group, Inc.                           |          16610000|      21828.43|   5|
Small                               |Medium                       |2023-09-01|XOMA  |Health Care          |NASDAQ|XOMA Corporation                                              |          48400000|      49899.45|   1|
Small                               |Medium                       |2023-09-01|BIOP  |Health Care          |NASDAQ|Bioptix, Inc                                                  |          19420000|      48518.18|   2|
Small                               |Medium                       |2023-09-01|AIRT  |Transportation       |NASDAQ|Air T, Inc.                                                   |          38810000|       46681.4|   3|
Small                               |Medium                       |2023-09-01|SRTS  |Health Care          |NASDAQ|Sensus Healthcare, Inc.                                       |          52750000|      45440.72|   4|
Small                               |Medium                       |2023-09-01|FKO   |n/a                  |NASDAQ|First Trust South Korea AlphaDEX Fund                         |         5410000.0|      45330.21|   5|
Small                               |Very High                    |2023-09-01|AVNW  |Technology           |NASDAQ|Aviat Networks, Inc.                                          |          93710000|      99898.79|   1|
Small                               |Very High                    |2023-09-01|ONCS  |Health Care          |NASDAQ|OncoSec Medical Incorporated                                  |          21800000|      98784.35|   2|
Small                               |Very High                    |2023-09-01|JYNT  |Miscellaneous        |NASDAQ|The Joint Corp.                                               |          48270000|      97883.17|   3|
Small                               |Very High                    |2023-09-01|CTHR  |Consumer Durables    |NASDAQ|Charles & Colvard Ltd                                         |          19680000|      97881.35|   4|
Small                               |Very High                    |2023-09-01|MILN  |n/a                  |NASDAQ|Global X Millennials Thematic ETF                             |         4360000.0|      97859.67|   5|
Huge                                |High                         |2023-10-01|TIG   |Health Care          |NASDAQ|TiGenix                                                       |      103100000000|      71434.86|   1|
Huge                                |High                         |2023-10-01|UL    |Basic Industries     |NYSE  |Unilever PLC                                                  |      157690000000|      62997.49|   2|
Huge                                |Low                          |2023-10-01|ORCL  |Technology           |NYSE  |Oracle Corporation                                            |      185530000000|      10090.53|   1|
Huge                                |Low                          |2023-10-01|CMCSA |Consumer Services    |NASDAQ|Comcast Corporation                                           |      195790000000|       7696.13|   2|
Huge                                |Low                          |2023-10-01|JPM   |Finance              |NYSE  |J P Morgan Chase & Co                                         |      306180000000|       5294.73|   3|
Huge                                |Medium                       |2023-10-01|MSFT  |Technology           |NASDAQ|Microsoft Corporation                                         |540440000000.00006|      46645.14|   1|
Huge                                |Medium                       |2023-10-01|MDT   |Health Care          |NYSE  |Medtronic plc                                                 |      120570000000|      43741.32|   2|
Huge                                |Very High                    |2023-10-01|BAC   |Finance              |NYSE  |Bank of America Corporation                                   |      233170000000|      88453.19|   1|
Large                               |High                         |2023-10-01|CYH   |Health Care          |NYSE  |Community Health Systems, Inc.                                |        1030000000|      74297.45|   1|
Large                               |High                         |2023-10-01|ARRS  |Technology           |NASDAQ|ARRIS International plc                                       |        5440000000|      74179.13|   2|
Large                               |High                         |2023-10-01|Y     |Finance              |NYSE  |Alleghany Corporation                                         |        9370000000|      74064.16|   3|
Large                               |High                         |2023-10-01|HEP   |Energy               |NYSE  |Holly Energy Partners, L.P.                                   |2049999999.9999998|       73994.0|   4|
Large                               |High                         |2023-10-01|ENB   |Energy               |NYSE  |Enbridge Inc                                                  |       63730000000|      73764.73|   5|
Large                               |Low                          |2023-10-01|DDC   |Basic Industries     |NYSE  |Dominion Diamond Corporation                                  |        1030000000|      24592.57|   1|
Large                               |Low                          |2023-10-01|GOL   |Transportation       |NYSE  |Gol Linhas Aereas Inteligentes S.A.                           |        6060000000|       24236.5|   2|
Large                               |Low                          |2023-10-01|EDN   |Public Utilities     |NYSE  |Empresa Distribuidora Y Comercializadora Norte S.A. (Edenor)  |        1410000000|      23851.25|   3|
Large                               |Low                          |2023-10-01|OAS   |Energy               |NYSE  |Oasis Petroleum Inc.                                          |        1940000000|      23636.92|   4|
Large                               |Low                          |2023-10-01|BGS   |Consumer Non-Durables|NYSE  |B&G Foods, Inc.                                               |        2450000000|      22604.98|   5|
Large                               |Medium                       |2023-10-01|HSNI  |Consumer Services    |NASDAQ|HSN, Inc.                                                     |        1680000000|      49985.48|   1|
Large                               |Medium                       |2023-10-01|PBR   |Energy               |NYSE  |Petroleo Brasileiro S.A.- Petrobras                           |       52700000000|      49733.13|   2|
Large                               |Medium                       |2023-10-01|PXD   |Energy               |NYSE  |Pioneer Natural Resources Company                             |       27010000000|       49057.3|   3|
Large                               |Medium                       |2023-10-01|HGV   |Consumer Services    |NYSE  |Hilton Grand Vacations Inc.                                   |        3620000000|      49006.88|   4|
Large                               |Medium                       |2023-10-01|TPH   |Capital Goods        |NYSE  |TRI Pointe Group, Inc.                                        |        1980000000|      48946.23|   5|
Large                               |Very High                    |2023-10-01|AAL   |Transportation       |NASDAQ|American Airlines Group, Inc.                                 |       24030000000|      99340.47|   1|
Large                               |Very High                    |2023-10-01|JELD  |Basic Industries     |NYSE  |JELD-WEN Holding, Inc.                                        |        3600000000|       99030.7|   2|
Large                               |Very High                    |2023-10-01|BBVA  |Finance              |NYSE  |Banco Bilbao Viscaya Argentaria S.A.                          |       53980000000|      99027.34|   3|
Large                               |Very High                    |2023-10-01|RLI   |Finance              |NYSE  |RLI Corp.                                                     |        2500000000|      98812.27|   4|
Large                               |Very High                    |2023-10-01|ITCB  |Finance              |NYSE  |Ita? CorpBanca                                                |        4740000000|       98729.3|   5|
Medium                              |High                         |2023-10-01|RRGB  |Consumer Services    |NASDAQ|Red Robin Gourmet Burgers, Inc.                               |         828170000|      74844.45|   1|
Medium                              |High                         |2023-10-01|VBTX  |Finance              |NASDAQ|Veritex Holdings, Inc.                                        |         425820000|      74509.82|   2|
Medium                              |High                         |2023-10-01|GASS  |Transportation       |NASDAQ|StealthGas, Inc.                                              |         122370000|       74354.6|   3|
Medium                              |High                         |2023-10-01|ONEQ  |n/a                  |NASDAQ|Fidelity Nasdaq Composite Index Tracking Stock                |         798860000|       74324.9|   4|
Medium                              |High                         |2023-10-01|PGC   |Finance              |NASDAQ|Peapack-Gladstone Financial Corporation                       |531919999.99999994|       73357.9|   5|
Medium                              |Low                          |2023-10-01|CCS   |Capital Goods        |NYSE  |Century Communities, Inc.                                     |         551700000|      24600.23|   1|
Medium                              |Low                          |2023-10-01|SPXX  |n/a                  |NYSE  |Nuveen S&P 500 Dynamic Overwrite Fund                         |         250200000|      24563.52|   2|
Medium                              |Low                          |2023-10-01|CHMG  |Finance              |NASDAQ|Chemung Financial Corp                                        |         185560000|      24214.36|   3|
Medium                              |Low                          |2023-10-01|MACK  |Health Care          |NASDAQ|Merrimack Pharmaceuticals, Inc.                               |         153620000|      24118.01|   4|
Medium                              |Low                          |2023-10-01|HIIQ  |Finance              |NASDAQ|Health Insurance Innovations, Inc.                            |         392380000|      23013.07|   5|
Medium                              |Medium                       |2023-10-01|ITCI  |Health Care          |NASDAQ|Intra-Cellular Therapies Inc.                                 |         471110000|      49809.34|   1|
Medium                              |Medium                       |2023-10-01|TRNC  |Consumer Services    |NASDAQ|tronc, Inc.                                                   |         422690000|       49502.6|   2|
Medium                              |Medium                       |2023-10-01|FISI  |Finance              |NASDAQ|Financial Institutions, Inc.                                  |         443540000|      49483.65|   3|
Medium                              |Medium                       |2023-10-01|WNEB  |Finance              |NASDAQ|Western New England Bancorp, Inc.                             |         332530000|      49422.93|   4|
Medium                              |Medium                       |2023-10-01|ESCA  |Consumer Non-Durables|NASDAQ|Escalade, Incorporated                                        |         182920000|      49304.34|   5|
Medium                              |Very High                    |2023-10-01|STON  |Consumer Services    |NYSE  |StoneMor Partners L.P.                                        |         345320000|      99845.03|   1|
Medium                              |Very High                    |2023-10-01|MERC  |Basic Industries     |NASDAQ|Mercer International Inc.                                     |         769940000|      99152.32|   2|
Medium                              |Very High                    |2023-10-01|IMOS  |Technology           |NASDAQ|ChipMOS TECHNOLOGIES INC.                                     |         899860000|      98999.48|   3|
Medium                              |Very High                    |2023-10-01|MUI   |n/a                  |NYSE  |Blackrock Muni Intermediate Duration Fund Inc                 |         539980000|      98860.88|   4|
Medium                              |Very High                    |2023-10-01|BRSS  |Capital Goods        |NYSE  |Global Brass and Copper Holdings, Inc.                        |         675150000|      98376.42|   5|
Small                               |High                         |2023-10-01|OASM  |Health Care          |NASDAQ|Oasmia Pharmaceutical AB                                      |          38240000|      72922.81|   1|
Small                               |High                         |2023-10-01|ALOT  |Technology           |NASDAQ|AstroNova, Inc.                                               |          90180000|      72689.82|   2|
Small                               |High                         |2023-10-01|PEZ   |n/a                  |NASDAQ|PowerShares DWA Consumer Cyclicals Momentum Portfolio         |          58530000|      72378.59|   3|
Small                               |High                         |2023-10-01|PLXP  |Health Care          |NASDAQ|PLx Pharma Inc.                                               |         1040000.0|      69627.59|   4|
Small                               |High                         |2023-10-01|PFBX  |Finance              |NASDAQ|Peoples Financial Corporation                                 |          66090000|       69169.2|   5|
Small                               |Low                          |2023-10-01|PANL  |Transportation       |NASDAQ|Pangaea Logistics Solutions Ltd.                              |          99120000|      24824.84|   1|
Small                               |Low                          |2023-10-01|INOD  |Technology           |NASDAQ|Innodata Inc.                                                 |          41400000|      24206.09|   2|
Small                               |Low                          |2023-10-01|SOHO  |Consumer Services    |NASDAQ|Sotherly Hotels Inc.                                          |          91070000|      23897.84|   3|
Small                               |Low                          |2023-10-01|ZSAN  |Health Care          |NASDAQ|Zosano Pharma Corporation                                     |          52530000|      23682.55|   4|
Small                               |Low                          |2023-10-01|CPHC  |Consumer Services    |NASDAQ|Canterbury Park Holding Corporation                           |          47650000|       23553.0|   5|
Small                               |Medium                       |2023-10-01|APDN  |Consumer Services    |NASDAQ|Applied DNA Sciences Inc                                      |          26320000|      48801.46|   1|
Small                               |Medium                       |2023-10-01|FFHL  |Capital Goods        |NASDAQ|Fuwei Films (Holdings) Co., Ltd.                              |          10060000|      48363.57|   2|
Small                               |Medium                       |2023-10-01|TPIV  |Health Care          |NASDAQ|TapImmune Inc.                                                |          33540000|      47228.81|   3|
Small                               |Medium                       |2023-10-01|CHEK  |Health Care          |NASDAQ|Check-Cap Ltd.                                                |          29390000|      46787.55|   4|
Small                               |Medium                       |2023-10-01|PNBK  |Finance              |NASDAQ|Patriot National Bancorp Inc.                                 |          60360000|      45652.92|   5|
Small                               |Very High                    |2023-10-01|SYNL  |Basic Industries     |NASDAQ|Synalloy Corporation                                          |          96770000|      99576.99|   1|
Small                               |Very High                    |2023-10-01|ALOT  |Technology           |NASDAQ|AstroNova, Inc.                                               |          90180000|      99256.95|   2|
Small                               |Very High                    |2023-10-01|TLF   |Consumer Non-Durables|NASDAQ|Tandy Leather Factory, Inc.                                   |          76520000|       98740.9|   3|
Small                               |Very High                    |2023-10-01|NWY   |Consumer Services    |NYSE  |New York & Company, Inc.                                      |          86050000|      98710.89|   4|
Small                               |Very High                    |2023-10-01|IROQ  |Finance              |NASDAQ|IF Bancorp, Inc.                                              |          77630000|      98433.17|   5|
Huge                                |High                         |2023-11-01|CMCSA |Consumer Services    |NASDAQ|Comcast Corporation                                           |      195790000000|      71159.65|   1|
Huge                                |High                         |2023-11-01|PG    |Basic Industries     |NYSE  |Procter & Gamble Company (The)                                |      229320000000|      68764.33|   2|
Huge                                |High                         |2023-11-01|MO    |Consumer Non-Durables|NYSE  |Altria Group                                                  |      149280000000|      64346.84|   3|
Huge                                |High                         |2023-11-01|VZ    |Public Utilities     |NYSE  |Verizon Communications Inc.                                   |      190220000000|      61608.85|   4|
Huge                                |High                         |2023-11-01|CMCSA |Consumer Services    |NASDAQ|Comcast Corporation                                           |      195790000000|      51843.86|   5|
Huge                                |Medium                       |2023-11-01|BP    |Energy               |NYSE  |BP p.l.c.                                                     |      117990000000|      48834.11|   1|
Huge                                |Medium                       |2023-11-01|INTC  |Technology           |NASDAQ|Intel Corporation                                             |      165800000000|      39922.37|   2|
Huge                                |Medium                       |2023-11-01|CHL   |Public Utilities     |NYSE  |China Mobile (Hong Kong) Ltd.                                 |      220680000000|      29071.16|   3|
Huge                                |Medium                       |2023-11-01|INTC  |Technology           |NASDAQ|Intel Corporation                                             |      165800000000|      27192.54|   4|
Large                               |High                         |2023-11-01|TEP   |Public Utilities     |NYSE  |Tallgrass Energy Partners, LP                                 |        3400000000|      74452.16|   1|
Large                               |High                         |2023-11-01|VGSH  |n/a                  |NASDAQ|Vanguard Short-Term Government ETF                            |        1460000000|      73877.62|   2|
Large                               |High                         |2023-11-01|FCN   |Consumer Services    |NYSE  |FTI Consulting, Inc.                                          |        1340000000|      73375.47|   3|
Large                               |High                         |2023-11-01|VXUS  |n/a                  |NASDAQ|Vanguard Total International Stock ETF                        |        8570000000|      73332.32|   4|
Large                               |High                         |2023-11-01|TIF   |Consumer Services    |NYSE  |Tiffany & Co.                                                 |       11480000000|      73225.24|   5|
Large                               |Low                          |2023-11-01|ZBRA  |Technology           |NASDAQ|Zebra Technologies Corporation                                |        5500000000|      24991.86|   1|
Large                               |Low                          |2023-11-01|SLCA  |Basic Industries     |NYSE  |U.S. Silica Holdings, Inc.                                    |        2750000000|      24610.74|   2|
Large                               |Low                          |2023-11-01|FIVE  |Consumer Services    |NASDAQ|Five Below, Inc.                                              |        2650000000|      23819.39|   3|
Large                               |Low                          |2023-11-01|SQM   |Basic Industries     |NYSE  |Sociedad Quimica y Minera S.A.                                |        9060000000|      23658.39|   4|
Large                               |Low                          |2023-11-01|OLLI  |Consumer Services    |NASDAQ|Ollie's Bargain Outlet Holdings, Inc.                         |        2500000000|       23577.2|   5|
Large                               |Medium                       |2023-11-01|LAMR  |Consumer Services    |NASDAQ|Lamar Advertising Company                                     |        7220000000|      49863.44|   1|
Large                               |Medium                       |2023-11-01|R     |Consumer Services    |NYSE  |Ryder System, Inc.                                            |        3600000000|      49457.52|   2|
Large                               |Medium                       |2023-11-01|IXUS  |n/a                  |NASDAQ|iShares Core MSCI Total International Stock ETF               |        6260000000|      49060.11|   3|
Large                               |Medium                       |2023-11-01|FAST  |Consumer Services    |NASDAQ|Fastenal Company                                              |       12840000000|      48670.86|   4|
Large                               |Medium                       |2023-11-01|IPG   |Technology           |NYSE  |Interpublic Group of Companies, Inc. (The)                    |        9640000000|      48191.92|   5|
Large                               |Very High                    |2023-11-01|QCP   |Consumer Services    |NYSE  |Quality Care Properties, Inc.                                 |        1650000000|      99802.33|   1|
Large                               |Very High                    |2023-11-01|SBS   |Public Utilities     |NYSE  |Companhia de saneamento Basico Do Estado De Sao Paulo - Sabesp|        6550000000|      98817.08|   2|
Large                               |Very High                    |2023-11-01|LOPE  |Consumer Services    |NASDAQ|Grand Canyon Education, Inc.                                  |        3900000000|      98706.05|   3|
Large                               |Very High                    |2023-11-01|EVT   |n/a                  |NYSE  |Eaton Vance Tax Advantaged Dividend Income Fund               |        1600000000|      98601.19|   4|
Large                               |Very High                    |2023-11-01|L     |Finance              |NYSE  |Loews Corporation                                             |       16210000000|      98278.82|   5|
Medium                              |High                         |2023-11-01|MRTN  |Transportation       |NASDAQ|Marten Transport, Ltd.                                        |         905460000|      73840.42|   1|
Medium                              |High                         |2023-11-01|BFK   |n/a                  |NYSE  |BlackRock Municipal Income Trust                              |         638920000|      73646.68|   2|
Medium                              |High                         |2023-11-01|PSCF  |n/a                  |NASDAQ|PowerShares S&P SmallCap Financials Portfolio                 |         243510000|      73297.71|   3|
Medium                              |High                         |2023-11-01|DHX   |Miscellaneous        |NYSE  |DHI Group, Inc.                                               |128990000.00000001|      72988.63|   4|
Medium                              |High                         |2023-11-01|MBFIP |Finance              |NASDAQ|MB Financial Inc.                                             |         104920000|      72881.21|   5|
Medium                              |Low                          |2023-11-01|EARN  |Consumer Services    |NYSE  |Ellington Residential Mortgage REIT                           |         140160000|      24999.72|   1|
Medium                              |Low                          |2023-11-01|NVTR  |Health Care          |NASDAQ|Nuvectra Corporation                                          |132490000.00000001|      24963.74|   2|
Medium                              |Low                          |2023-11-01|JOF   |n/a                  |NYSE  |Japan Smaller Capitalization Fund Inc                         |         327820000|      24483.34|   3|
Medium                              |Low                          |2023-11-01|WMC   |Consumer Services    |NYSE  |Western Asset Mortgage Capital Corporation                    |         442250000|      24390.99|   4|
Medium                              |Low                          |2023-11-01|NCV   |n/a                  |NYSE  |AllianzGI Convertible & Income Fund                           |         618690000|       23671.2|   5|
Medium                              |Medium                       |2023-11-01|IDRA  |Health Care          |NASDAQ|Idera Pharmaceuticals, Inc.                                   |         237150000|      49278.33|   1|
Medium                              |Medium                       |2023-11-01|PLOW  |Capital Goods        |NYSE  |Douglas Dynamics, Inc.                                        |         689020000|      48873.06|   2|
Medium                              |Medium                       |2023-11-01|ALJJ  |Miscellaneous        |NASDAQ|ALJ Regional Holdings, Inc.                                   |         113530000|      48353.48|   3|
Medium                              |Medium                       |2023-11-01|ICFI  |Consumer Services    |NASDAQ|ICF International, Inc.                                       |         882650000|      48226.04|   4|
Medium                              |Medium                       |2023-11-01|RUTH  |Consumer Services    |NASDAQ|Ruth's Hospitality Group, Inc.                                |         708870000|      48069.14|   5|
Medium                              |Very High                    |2023-11-01|JCE   |n/a                  |NYSE  |Nuveen Core Equity Alpha Fund                                 |         234720000|      99835.42|   1|
Medium                              |Very High                    |2023-11-01|SNDX  |Health Care          |NASDAQ|Syndax Pharmaceuticals, Inc.                                  |         204470000|      99626.29|   2|
Medium                              |Very High                    |2023-11-01|KANG  |Health Care          |NASDAQ|iKang Healthcare Group, Inc.                                  |         980680000|      99531.82|   3|
Medium                              |Very High                    |2023-11-01|PGTI  |Capital Goods        |NASDAQ|PGT Innovations, Inc.                                         |         610360000|      99504.15|   4|
Medium                              |Very High                    |2023-11-01|CHSCN |Consumer Services    |NASDAQ|CHS Inc                                                       |         497620000|      99252.74|   5|
Small                               |High                         |2023-11-01|AGND  |n/a                  |NASDAQ|WisdomTree Barclays Negative Duration U.S. Aggregate Bond Fund|          12990000|      74862.48|   1|
Small                               |High                         |2023-11-01|UBOH  |Finance              |NASDAQ|United Bancshares, Inc.                                       |          69910000|       74385.3|   2|
Small                               |High                         |2023-11-01|FMY   |n/a                  |NYSE  |First Trust                                                   |          59410000|      73973.29|   3|
Small                               |High                         |2023-11-01|TNDM  |Health Care          |NASDAQ|Tandem Diabetes Care, Inc.                                    |          44420000|      72231.68|   4|
Small                               |High                         |2023-11-01|PXS   |Transportation       |NASDAQ|Pyxis Tankers Inc.                                            |          26870000|      71717.35|   5|
Small                               |Low                          |2023-11-01|FNCX  |Technology           |NASDAQ|Function(x) Inc.                                              |          14240000|      23591.52|   1|
Small                               |Low                          |2023-11-01|CALI  |Consumer Services    |NASDAQ|China Auto Logistics Inc.                                     | 8189999.999999999|      21765.54|   2|
Small                               |Low                          |2023-11-01|RWLK  |Health Care          |NASDAQ|ReWalk Robotics Ltd                                           |          20840000|       21107.4|   3|
Small                               |Low                          |2023-11-01|WILC  |Consumer Non-Durables|NASDAQ|G. Willi-Food International,  Ltd.                            |          92420000|       21023.5|   4|
Small                               |Low                          |2023-11-01|MSDI  |Technology           |NASDAQ|Monster Digital, Inc.                                         |4110000.0000000005|      20964.05|   5|
Small                               |Medium                       |2023-11-01|OLD   |n/a                  |NASDAQ|The Long-Term Care ETF                                        |         2700000.0|      49686.71|   1|
Small                               |Medium                       |2023-11-01|PN    |Finance              |NYSE  |Patriot National, Inc.                                        | 64459999.99999999|      49231.68|   2|
Small                               |Medium                       |2023-11-01|OCRX  |Health Care          |NASDAQ|Ocera Therapeutics, Inc.                                      |          25450000|      48633.57|   3|
Small                               |Medium                       |2023-11-01|IFEU  |n/a                  |NASDAQ|iShares FTSE EPRA/NAREIT Europe Index Fund                    |          42370000|      47671.06|   4|
Small                               |Medium                       |2023-11-01|SOHO  |Consumer Services    |NASDAQ|Sotherly Hotels Inc.                                          |          91070000|      47631.42|   5|
Small                               |Very High                    |2023-11-01|RELY  |Consumer Non-Durables|NASDAQ|Real Industry, Inc.                                           |          90880000|       99981.8|   1|
Small                               |Very High                    |2023-11-01|GALE  |Health Care          |NASDAQ|Galena Biopharma, Inc.                                        |          20660000|      99001.84|   2|
Small                               |Very High                    |2023-11-01|LKOR  |n/a                  |NASDAQ|FlexShares Credit-Scored US Long Corporate Bond Index Fund    |          13340000|      98672.32|   3|
Small                               |Very High                    |2023-11-01|JSYN  |Finance              |NASDAQ|Jensyn Acquistion Corp.                                       |          52880000|      97741.45|   4|
Small                               |Very High                    |2023-11-01|CHFS  |Health Care          |NASDAQ|CHF Solutions, Inc.                                           |         5220000.0|      97660.22|   5|
Huge                                |High                         |2023-12-01|TSM   |Technology           |NYSE  |Taiwan Semiconductor Manufacturing Company Ltd.               |      186020000000|      69056.61|   1|
Huge                                |High                         |2023-12-01|T     |Public Utilities     |NYSE  |AT&T Inc.                                                     |      239530000000|      57536.21|   2|
Huge                                |Low                          |2023-12-01|MO    |Consumer Non-Durables|NYSE  |Altria Group                                                  |      149280000000|      24269.42|   1|
Huge                                |Medium                       |2023-12-01|SNY   |Health Care          |NYSE  |Sanofi                                                        |      123340000000|      46333.18|   1|
Huge                                |Medium                       |2023-12-01|V     |Miscellaneous        |NYSE  |Visa Inc.                                                     |      217120000000|      33472.83|   2|
Huge                                |Medium                       |2023-12-01|KO    |Consumer Non-Durables|NYSE  |Coca-Cola Company (The)                                       |      193590000000|       31850.9|   3|
Huge                                |Very High                    |2023-12-01|HSBC  |Finance              |NYSE  |HSBC Holdings plc                                             |      176430000000|      99014.84|   1|
Huge                                |Very High                    |2023-12-01|CMCSA |Consumer Services    |NASDAQ|Comcast Corporation                                           |      195790000000|      97671.88|   2|
Huge                                |Very High                    |2023-12-01|SAP   |Technology           |NYSE  |SAP SE                                                        |      126800000000|      78869.76|   3|
Large                               |High                         |2023-12-01|CHS   |Consumer Services    |NYSE  |Chico's FAS, Inc.                                             |        1200000000|      74981.51|   1|
Large                               |High                         |2023-12-01|AWK   |Public Utilities     |NYSE  |American Water Works                                          |       14720000000|       74877.8|   2|
Large                               |High                         |2023-12-01|KYO   |Technology           |NYSE  |Kyocera Corporation                                           |       21430000000|      74724.46|   3|
Large                               |High                         |2023-12-01|AEL   |Finance              |NYSE  |American Equity Investment Life Holding Company               |        2220000000|      74402.16|   4|
Large                               |High                         |2023-12-01|PEGI  |Public Utilities     |NASDAQ|Pattern Energy Group Inc.                                     |        2080000000|      74286.29|   5|
Large                               |Low                          |2023-12-01|DATA  |Technology           |NYSE  |Tableau Software, Inc.                                        |        4840000000|      24498.64|   1|
Large                               |Low                          |2023-12-01|MNST  |Consumer Non-Durables|NASDAQ|Monster Beverage Corporation                                  |       28570000000|      23825.81|   2|
Large                               |Low                          |2023-12-01|PXD   |Energy               |NYSE  |Pioneer Natural Resources Company                             |       27010000000|       23512.6|   3|
Large                               |Low                          |2023-12-01|HYLS  |n/a                  |NASDAQ|First Trust High Yield Long/Short ETF                         |        1230000000|       23434.9|   4|
Large                               |Low                          |2023-12-01|WNS   |Miscellaneous        |NYSE  |WNS (Holdings) Limited                                        |        1630000000|      22965.18|   5|
Large                               |Medium                       |2023-12-01|WDR   |Finance              |NYSE  |Waddell & Reed Financial, Inc.                                |        1560000000|      49925.01|   1|
Large                               |Medium                       |2023-12-01|ENBL  |Public Utilities     |NYSE  |Enable Midstream Partners, LP                                 |        6430000000|      49489.54|   2|
Large                               |Medium                       |2023-12-01|TDC   |Technology           |NYSE  |Teradata Corporation                                          |        3660000000|      49255.48|   3|
Large                               |Medium                       |2023-12-01|QVCB  |Consumer Services    |NASDAQ|Liberty Interactive Corporation                               |       10920000000|       49186.9|   4|
Large                               |Medium                       |2023-12-01|PNFP  |Finance              |NASDAQ|Pinnacle Financial Partners, Inc.                             |        3270000000|      49019.57|   5|
Large                               |Very High                    |2023-12-01|HRL   |Consumer Non-Durables|NYSE  |Hormel Foods Corporation                                      |       17940000000|      99994.59|   1|
Large                               |Very High                    |2023-12-01|CNHI  |Capital Goods        |NYSE  |CNH Industrial N.V.                                           |       15850000000|       99977.7|   2|
Large                               |Very High                    |2023-12-01|FISV  |Technology           |NASDAQ|Fiserv, Inc.                                                  |       26470000000|      99492.37|   3|
Large                               |Very High                    |2023-12-01|BKH   |Public Utilities     |NYSE  |Black Hills Corporation                                       |        3840000000|      99041.03|   4|
Large                               |Very High                    |2023-12-01|KR    |Consumer Services    |NYSE  |Kroger Company (The)                                          |       20340000000|      98708.29|   5|
Medium                              |High                         |2023-12-01|CMRE  |Transportation       |NYSE  |Costamare Inc.                                                |         710190000|      74049.76|   1|
Medium                              |High                         |2023-12-01|REGI  |Basic Industries     |NASDAQ|Renewable Energy Group, Inc.                                  |         477600000|       73563.2|   2|
Medium                              |High                         |2023-12-01|PFSW  |Miscellaneous        |NASDAQ|PFSweb, Inc.                                                  |         136890000|      73540.05|   3|
Medium                              |High                         |2023-12-01|PDLI  |Health Care          |NASDAQ|PDL BioPharma, Inc.                                           |         367040000|      73471.57|   4|
Medium                              |High                         |2023-12-01|RIC   |Basic Industries     |NYSE  |Richmont Mines, Inc.                                          |         458830000|      73447.04|   5|
Medium                              |Low                          |2023-12-01|ATLO  |Finance              |NASDAQ|Ames National Corporation                                     |         283980000|      24834.62|   1|
Medium                              |Low                          |2023-12-01|JTA   |n/a                  |NYSE  |Nuveen Tax-Advantaged Total Return Strategy Fund              |         174980000|      24389.27|   2|
Medium                              |Low                          |2023-12-01|BSD   |n/a                  |NYSE  |BlackRock Strategic Municipal Trust Inc. (The)                |         101120000|      23639.18|   3|
Medium                              |Low                          |2023-12-01|OCIP  |Basic Industries     |NYSE  |OCI Partners LP                                               |         782980000|      23499.88|   4|
Medium                              |Low                          |2023-12-01|FTGC  |n/a                  |NASDAQ|First Trust Global Tactical Commodity Strategy Fund           |         148400000|      23467.21|   5|
Medium                              |Medium                       |2023-12-01|IEUS  |n/a                  |NASDAQ|iShares MSCI Europe Small-Cap ETF                             |         126720000|      49564.15|   1|
Medium                              |Medium                       |2023-12-01|FVC   |n/a                  |NASDAQ|First Trust Dorsey Wright Dynamic Focus 5 ETF                 |         318660000|      49366.63|   2|
Medium                              |Medium                       |2023-12-01|TTI   |Energy               |NYSE  |Tetra Technologies, Inc.                                      |         364090000|      48925.34|   3|
Medium                              |Medium                       |2023-12-01|SA    |Basic Industries     |NYSE  |Seabridge Gold, Inc.                                          |         559330000|      48821.28|   4|
Medium                              |Medium                       |2023-12-01|PTSI  |Transportation       |NASDAQ|P.A.M. Transportation Services, Inc.                          |         129340000|       48733.1|   5|
Medium                              |Very High                    |2023-12-01|CTT   |Consumer Services    |NYSE  |CatchMark Timber Trust, Inc.                                  |         452920000|      99520.02|   1|
Medium                              |Very High                    |2023-12-01|NEWT  |n/a                  |NASDAQ|Newtek Business Services Corp.                                |         283590000|      99497.72|   2|
Medium                              |Very High                    |2023-12-01|KFRC  |Technology           |NASDAQ|Kforce, Inc.                                                  |         498130000|       99243.8|   3|
Medium                              |Very High                    |2023-12-01|DEA   |Consumer Services    |NYSE  |Easterly Government Properties, Inc.                          |         779290000|       99234.0|   4|
Medium                              |Very High                    |2023-12-01|PTGX  |Health Care          |NASDAQ|Protagonist Therapeutics, Inc.                                |         177840000|      98986.78|   5|
Small                               |High                         |2023-12-01|CUBA  |n/a                  |NASDAQ|The Herzfeld Caribbean Basin Fund, Inc.                       |          43730000|       73570.8|   1|
Small                               |High                         |2023-12-01|NXN   |n/a                  |NYSE  |Nuveen Insured New York Select Tax-Free Income Portfolio      |          54360000|      71672.12|   2|
Small                               |High                         |2023-12-01|AVNW  |Technology           |NASDAQ|Aviat Networks, Inc.                                          |          93710000|      70596.71|   3|
Small                               |High                         |2023-12-01|PRKR  |Technology           |NASDAQ|ParkerVision, Inc.                                            |          41590000|      70305.45|   4|
Small                               |High                         |2023-12-01|MZF   |n/a                  |NYSE  |Managed Duration Investment Grade Municipal Fund              |          94050000|      69346.35|   5|
Small                               |Low                          |2023-12-01|SBOT  |Health Care          |NASDAQ|Stellar Biotechnologies, Inc.                                 |          11350000|      24673.59|   1|
Small                               |Low                          |2023-12-01|FKU   |n/a                  |NASDAQ|First Trust United Kingdom AlphaDEX Fund                      |          27490000|      23513.72|   2|
Small                               |Low                          |2023-12-01|CREG  |Miscellaneous        |NASDAQ|China Recycling Energy Corporation                            |          11630000|      22532.76|   3|
Small                               |Low                          |2023-12-01|MTR   |Energy               |NYSE  |Mesa Royalty Trust                                            |          22460000|      21851.41|   4|
Small                               |Low                          |2023-12-01|SSNT  |Miscellaneous        |NASDAQ|SilverSun Technologies, Inc.                                  |16120000.000000002|       21532.2|   5|
Small                               |Medium                       |2023-12-01|LINC  |Consumer Services    |NASDAQ|Lincoln Educational Services Corporation                      |          80580000|       49548.7|   1|
Small                               |Medium                       |2023-12-01|CNTF  |n/a                  |NASDAQ|China TechFaith Wireless Communication Technology Limited     |          33670000|      47599.22|   2|
Small                               |Medium                       |2023-12-01|LBF   |n/a                  |NYSE  |Scudder Global High Income Fund, Inc.                         |          56460000|      46592.33|   3|
Small                               |Medium                       |2023-12-01|MTBC  |Technology           |NASDAQ|Medical Transcription Billing, Corp.                          |          19070000|      46529.94|   4|
Small                               |Medium                       |2023-12-01|XTLB  |Health Care          |NASDAQ|XTL Biopharmaceuticals Ltd.                                   |          13780000|      44545.82|   5|
Small                               |Very High                    |2023-12-01|ORMP  |Health Care          |NASDAQ|Oramed Pharmaceuticals Inc.                                   |          98910000|      99965.64|   1|
Small                               |Very High                    |2023-12-01|QAT   |n/a                  |NASDAQ|iShares MSCI Qatar Capped ETF                                 |          38960000|      99349.08|   2|
Small                               |Very High                    |2023-12-01|APEN  |Health Care          |NASDAQ|Apollo Endosurgery, Inc.                                      |          72330000|      98709.71|   3|
Small                               |Very High                    |2023-12-01|PTIE  |Health Care          |NASDAQ|Pain Therapeutics, Inc.                                       |          27030000|      98696.95|   4|
Small                               |Very High                    |2023-12-01|ARTW  |Capital Goods        |NASDAQ|Art's-Way Manufacturing Co., Inc.                             |          12260000|      98615.62|   5|*/



