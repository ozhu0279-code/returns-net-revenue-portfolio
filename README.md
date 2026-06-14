## Reducing Returns to Improve Net Revenue: Returns/Cancellations Diagnostics & Action Plan (E-commerce)

## Business Goal
- Reduce return/cancellation rate
- Increase net revenue

## Source Dataset
**[Online Retail II](https://archive.ics.uci.edu/dataset/502/online%2Bretail%2Bii?utm_source=chatgpt.com)**--This dataset originating from UCI Machine Learning Respository includes online retail transactions from 2009-2011.

## Metrics & KPI
- **Return/Cancellation**--The 'invoice' number beginning with upper letter 'C' or lower one 'c' refers to cancellation/return.
- **Cancel Rate**--canceled_orders divided by all_orders.
- **Canceled Revenue Share**--canceled_revenue / gross_revenue`
- **Net Revenue**--gross revenue minus canceled revenue.
- **High-impact driver**--Top 10 Countries and SKUs by canceled revenue.

## Data Quality & Assumption
- When processing the Online Retail dataset, I observed that it is not a conventional dynamic state table, but instead adopts journal-style offsetting records. If independent order numbers are directly counted as the denominator, the calculated cancellation rate will be unreasonably diluted due to the repeated inclusion of cancelled orders (C-orders). Therefore, I strictly restricted the denominator to only positive sales orders, which restored the true business cancellation rate and share.
- For time-series KPI trends (revenue, cancel rate, canceled revenue share), we keep all transactions including missing CustomerID to avoid selection bias.
- For customer-level segmentation (RFM), we restrict to records with non-null CustomerID.
- **Limitation** Here, "cancellation/return" is used to approximately represent "post-sale return pressure", which is not equivalent to the entire process of actual returns, but is sufficient for identifying driving factors and optimization opportunities.

## KPI Overview
- Cancel Rate:18.74%
- Canceled revenue share:3.65%
- Top 10 countries by canceled revenue(DESC):
United Kingdom,EIRE,France,Spain,Germany,Denmark,Netherlands,Japan,Channel Island,USA
- Top 10 SKUs by canceled revenue(DESC):
23843,23166,22423,85123A,21108,71477,79323W,23113,48185,84078A

## Deep Dive
- **Scale & Trend**In this section,i splited into 2 parts-all products(revenue trend) and product-only(revenue and qulity trend).For revenue trend,the 2 charts all show that net revenue ranged from £0.5M to £0.8M in the first and second quater.Until August,it was over £0.8M,and rised to around £1.4M in November and plunged to around £0.6M in December.
For quality trend,canceled revenue share is lower than cancel rate for 
- **Country × Month**:The main country which contributed to the most canceled revenue is Unite Kingdom because it ranks the first place and leads the second country almost by 20K every month.
- **SKU × Month**:The main SKUs which take up the most canceled revenue are M and AMAZONFEE.Nov 2010 is the watershed because M is the contributor to the most canceled revenue before it,and AMAZONFEE and M are 2 major contributors after that time.
- **SKU / Price band**：We made a sku scatter diagram to clearly find the popularity of skus combined cancel rate and order volume,and it was divded into 5 quadrants which are fix now,monitor,star,investigate and other.In this diagram,the high-riks skus is located at fix now quadrant and counted up to 18 that followed by21232,21314,21527,21539,21843,22064,22138,22198,22423,22456,22467,22617,22776,22960,71477,82483,84949,85066.
The price bands of high cancel rate are 50-99.99 and 100+,which represent the cancel rate 13.59% and 23.01% respectively as they exceeded the average cancel rate 10.9%.
**※‌**In this section,we excluded the skus which are not the actual products,like M,AMAZONFEE,POST and so on.
- **Customer segments（RFM / new vs returning）**：In this page,we compared first purchase date with invoice date to confirm the new or returning customers.If invoice date is same as first purchase date,that is New customer.If invoice date is later than first purchase date,that is Returning customer,otherwise,that belongs to 'Other'.All first purchase invoice should be valid,but part of first purchase status shows cancelled,so these customers should be pre-first-purchase cancel.As cancel rate of pre-first-purchase cancel is 100%,so we excluded it in the comparison bar graph of new and returning customers,where we used cancel rate and order volume to compare.
Also we used RFM model to further analyze the canceled revenue and cancel rate amongst different segments.We gave the marks to recency,frequecy and monetary that if recency score is greater than or equal to 4,frequecy score is greater than or equal to 4 and monetary score is greater than or equal to 4,these customers belong to Champions.
If recency score is greater than or equal to 4,frequecy score is over or equal to 3,these customers belong to Loyal.
The mark of New or Promising customers is that recency score is greater than or equal to 4 and frequecy score is less than or equal to 2,while At risk customers' mark is that recency score is less than or equal to 2 and frequency score is greater than or equal to 3.
Lost customers' mark should be equal to 1.
From comparison bar graph,we can see Returning customers are more reliable to cancel orders.Amongst returning customers,champions customers take up the most canceled revenue ,and lost customers have higher cancel rate.

## Diagnose the Likely Root Cause

## Suggestions
