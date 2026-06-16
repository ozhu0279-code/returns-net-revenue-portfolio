## Reducing Returns to Improve Net Revenue: Returns/Cancellations Diagnostics & Action Plan (E-commerce)

## Business Goal
- Reduce return/cancellation rate
- Increase net revenue

## Source Dataset
**[Online Retail II]([https://archive.ics.uci.edu/dataset/502/online%2Bretail%2Bii?])**--This dataset originating from UCI Machine Learning Respository includes online retail transactions from 2009-2011.

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
- **Scale & Trend**In this section,i splited into 2 categories--all products(revenue trend) and product-only(revenue and qulity trend).
- For revenue trend,the 2 charts all show that net revenue ranged from £0.5M to £0.8M in the first and second quater.Until August,it was over £0.8M,and rised to peak around £1.4M in November and plunged to around £0.6M in December.
- For quality trend,canceled revenue share was lower than cancel rate for the first 24 months,but it was higher than cancel rate by 10% in the last month,Dec 2011.
- **Country × Month**:The main country which contributed to the most canceled revenue is Unite Kingdom leading the second country almost by £10K every month.
- **SKU × Month**:The main SKU which take up the most canceled revenue is 23843,around £168.47K in Dec 2011.That's why canceled revenue share is more than cancel rate in Dec 2011. 
- **SKU / Price band**：We made a sku scatter diagram to clearly find the of skus combined cancel rate and order volume,and it was divded into 4 quadrants which are fix now,investigate,star and stable.In this diagram,the high-risk skus are located at first quadrant-fix now and counted up to 38 products,which is over 90 percentile in order volum--541 and average cancel rate--4.04%.
- First quadrant-fix now,high order volume and high cancel share.This quadrant indicates that the more orders customers place,the more orders are cancelled.We cannot make revenue and lose revenue at the same,so i tagged this quadrant as high risk to fix these products as soon as possible.
- Second quadrant-investigate,low order volume and high cancel rate
- Third quadrant-stable,low order volume and low cancel rate
- Fourth quadrant-star,high order volume and low cancel rate
- The price bands of high cancel share are 1-4.99,50-99.99 and 100+,which accounted for 4.11%,4.03% and 7.43% respectively as they exceeded the average cancel share 3.92%.
- In this section,we also made product diagnostic table to do hypothesis of product cancellation reasons with price band and cancel rate.If price band ranges from 1 to 4.99 and cancel rate is more than 10%,it may cause by stockout or logistics delay.If price band ranges from 20 to 49.99,or from 50 to 99.99,or exceeds 100 and cancel rate is over 5%,it may attribute to product quality issues.Besides,it should be buyer remorse and mind changing.
- From this diagnostic table,we can find that no matter which product at first quadrant and high risk region and price range at price band chart,most of cancellation cause by buyer remorse and mind changing. 
- **Customer segments（RFM / new vs returning）**：In this page,we do analysis of customer behavior by comparison of new and returning customers and RFM model.
- In new and returning comparison table,we can clearly see that gross revenue and cancel rate of returning customers are more than new customers.So in the RFM model,we emphasized to analyze returning customers divided by loyal,new/promising,lost,at risk and other.
- In RFM model,we divided 4 quadrants following by fix now,investigate,star and stable.In the this diagram,at risk segment is located at the first quadrant because it is over 90 percentile of average canceled revenue-£215.17 and average canceled revenue share-7.29%.Average canceled revenue of at risk is £215.51 and canceled revenue share is 11.68%
- First quadrant-fix now,high average canceled revenue and high cancel share
- Second quadrant-investigate,low average canceled revenue and high cancel share
- Third quadrant-stable,low average canceled revenue and low cancel share
- Fourth quadrant-star,high average canceled revenue and low cancel share
- As at risk segment has more cancellations,so i combined these tables-SKU scatter,price band,comprison of new and returning customers and RFM table into a new chart to analyze which products lead to high cancel share with different price bands.
I marked the bar that canceled revenue is over average canceled revenue of at risk-£215.51 as orange and the bar that cancel rate is over 15% as red.So in the diagram,we can see that there are 9 products taking up more canceled revenue,which are 22328,22138,21323,79323W,37449,21527,22423,21843,85066.
From the observation of sku scatter,there are 5 products containing high cancel rate and high canceled revenue,which are 22138,21527,22423,21843,85066.

## Diagnose the Likely Root Cause
- 
- As United Kingdom is the base of online retail,and the local team can seamlessly align with cultural backgrounds and consumer habits, offering faster pre-sales communication and after-sales service,local customers are more likely to choose this online store. Therefore, the order volume will be higher, which leads to an increase in the number of cancellations.



## Suggestions
