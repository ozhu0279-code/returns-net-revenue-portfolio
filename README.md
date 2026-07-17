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
- **AOV**--Average Order Value
- **UPO**--Units per Order
- **ASP**--Average Selling Price

## Data Quality & Assumption
- When processing the Online Retail dataset, I observed that it is not a conventional dynamic state table, but instead adopts journal-style offsetting records. If independent order numbers are directly counted as the denominator, the calculated cancellation rate will be unreasonably diluted due to the repeated inclusion of cancelled orders (C-orders). Therefore, I strictly restricted the denominator to only positive sales orders, which restored the true business cancellation rate and share.
- During the exploratory data analysis (EDA) phase, i found that the original dataset spans from 2009-12 to 2011-12. Aggregating the data directly would result in "December" appearing three times in the sample, while other months appear only twice. Given that our company operates in the gift wholesale industry, Q4—particularly December—exhibits strong seasonal price fluctuations and purchasing patterns. Therefore,in terms of the time dimension,we excluded the data from December 2009 to ensure data harmonization.
To eliminate "left-truncation bias" (preventing customers from 2009–12 being incorrectly classified as new) and "seasonal weighting bias" (avoiding distortions in annual price band and SKU contribution distributions caused by Christmas purchasing preferences), this report standardizes all dashboard data to a common baseline period of January 1, 2010, to December 31, 2011 (a full 24-month cycle).
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
- **Scale & Trend**In this section,i splited into 2 product types--all products including non-product stock codes,like M,POST and etc. (revenue trend) and product-only(revenue and quality trend,AOV,UPO and ASP trend,top 5 order amounts per month).
- For revenue trend,the 2 charts all show that net revenue ranged from £0.5M to £0.8M in the first and second quater.Until August,it began to increase and rised to peak,around £1.4M in November and plunged to around £0.6M in December.
- From data to business analysis (breakdown of revenue trend from August to December):I used the metric-AOV,UPO and ASP to show purchasing power,top 5 order amounts to find outlier that affected average value of whole month.
- In 2010,from August to December,AOV and ASP kept rising while UPO kept downward trend.From top 5 orders table,the order amount of the 5th order for December is higher than that in the months of August to October's.
- In 2011,AOV,ASP and UPO,all of them maintained the upward trend.Even AOV and UPO increased sharply in December.From top 5 orders table,there was a big order in December,which is over £100,000.
- To sum up,i thought that this business model from August to December is that after shopping spree in November,most small-scale individual customers were unwilling to purchase more by December,which led to seasonal retail contraction;instead,the market was dominated by high-value orders or large-scale corporate contracts at year-end,survivorship bias was triggered,causing average order value to surge against the trend.
- For quality trend,canceled revenue share was lower than cancel rate for the first 23 months,but it was higher than cancel rate by 10% in the last month,Dec. 2011.
- From data to business analysis (breakdown that canceled revenu share was higher than cancel rate in Dec. 2011): Based on the monthly top 5 order amounts as previously recorded, there was a large order of over 100,000 pounds in Dec. 2011. It is speculated that this might be due to the cancellation of this order.However,it turns out that this order had actually been cancelled upon checking the raw dateset.(invoice no.C581484,SKU 23843）
- **Country × Month**:The main country which contributed to the most canceled revenue is Unite Kingdom leading the second country almost by £10K every month.
- **SKU × Month**:The main SKU which take up the most canceled revenue is 23843,around £168.47K in Dec 2011.That's why canceled revenue share is more than cancel rate in Dec 2011. 
- **SKU / Price Band**：In this section, i made a sku scatter diagram, a price band chart and a product diagnostic table to find out which products could cause more canceled revenue and analyze the cancel reasons of these products.
- SKU scatter diagram:In this diagram, i divded it into 4 quadrants which are the first quadrant(fix now), the second quadrant(investigate), the third quadrant(star) and the fourth quadrant(stable) according to the p90 value of order volume-538 and p75 value of cancel rate-2.16%. So the high-risk skus should locate at the first quadrant-fix now because it is over p90 value of order volum and p75 cancel rate. In this analysis, i paid more attention to the first quadrant, and found that there are 5 products with relatively high canceled revenue in the first quadrant,which are over £3,000 for canceled revenue:21843，22138，22423，71477，85123A.
- Price band chart:In this chart,price band-1-4.99 is high risk band because it is over p90 order volum-31,758 and average canceled revenue share-3.92%.Also,the canceled revenue share of this band accounts for 72.6% of total canceled revenue.I suspect that products in this price range might be used as low-priced items to drive traffic.
- Product diagnostic table:This is to do hypothesis of product cancellation reasons combining with price band and cancel rate.If price band ranges from 1 to 4.99 and cancel rate is more than 10%,it may cause by stockout or logistics delay.If price band ranges from 20 to 49.99,or from 50 to 99.99,or exceeds 100 and cancel rate is over 5%,it may attribute to product quality issues.Besides,it should be buyer remorse and changed mind.Based on these reasons, i made a table to shows canceled revenue under different cancel reasons respectively in different time dimensions-peak season and regular seanson.It turns out that at peak season,most of canceled revenue come from reason-stock shortage / logistic delay,while the reason-buyer remorse / changed mind take up the most at regular season.However,as most of customer place orders in November,i focused more on the analysis of the reason-stockout or logistic delay at peak season. 
- From data to business analysis(breakdown of high risk products): From scatter diagram,there 5 high risk products, but when combining these with two criteria—price range of 1–4.99 and cancellation reasons due to stock shortage or logistics delay—only three products remain: 21843, 22138, and 71477. Therefore, i made canceled revenue trend for these 3 products.
- SKU: 21843-The trend was very stable over the first 22 months, but it surged to £1.34k in Dec. 2011.
- SKU: 22138-Overall trend was stable apart from a slight fluctuation in Sep. 2010.Although this type of product does not see massive spikes in monthly sales volume, it consistently maintains an unhealthy baseline cancellation rate; consequently, due to the "cumulative effect" visualized in the bubble chart, it ultimately ranks among the top five according to canceled revenue. For this product, the priority for next major sales events is not to guard against warehouse overload, but rather to overhaul the strategy for daily inventory synchronization.
- SKU: 71477-The surge occurred twice in Oct. 2010-£3.20k and in Jul. 2011-£1.99k in 2010 respectively. This is a typical "high-risk product". It exploded in October 2010 (£3.20k), right on the eve of the November sale (merchant stocking/pre-sale period). Supply and demand have been out of control in specific months (July and October) for two consecutive years, indicating that there are huge seasonal flaws in its supplier's production capacity or overseas procurement cycle, and it is the number one target of the supply chain's review of major promotions.
- **Customer Segments（RFM / New vs Returning）**：In this part,i did analysis of customer's purchase behavior by comparison of new and returning customers and RFM bubble chart, and analyzed the main canceled products according to RFM model.
- New vs. Returning Comparison: It clearly shows that gross revenue and cancel rate of returning customers are more than new customers'. So i emphasized to analyze returning customers using RFM model.
- RFM Bubble Chart: I divided it into 4 quadrants according to p90 value of average canceled revenue per user-£196.18 and p75 value of canceled revenue share-9.15%, and marked different risk levels: at risk(the first quadrant, high risk), new/promising(the second quadrant, leakage), lost(the third quadrant, safe), champions(the fourth quadrant, stable). As high risk field is at risk segment, i would break down the products in 'at risk' segment.
- Product of "At Risk" Segment: As the price band analysis before, band 1-4.99 takes up the majority of canceled revenue share, so this band requires close attention, and i excluded other bands,like <1, 5-9.99 and 10-19.99. In this band, 22328 account for the most canceled revenue, and 22138 and 22617 have high cancel rate. Therefore,i made a reveue trend for 22328 and quality trend for 22138 and 22617 from Jan. 2010 to Dec. 2011.
- SKU: 22328-The trend in churned value for the global portfolio closely mirrors that of the "At-Risk" segment; both experienced a sudden, sharp spike in April 2011. Sepcifically, "At Risk" customer segment lost £1,590, while the global loss was £1,600.
- SKU: 22138-The global cancel rate peaked in 2010-09 (at 34.21%). However, the cancel rate for "At Risk" peaked at 100% in 2010-10. The trends in July and August were opposite: The global cancel rate was rising, but the cancel rate for "At Risk" segment actually decreased.
- SKU: 22617-The "At Risk" customer segment experienced 100% cancel rates frequently in 2010-08, 2011-02 and 2011-03. The peak of the global cancel rate was in June 2010 (20.45%), while the rates during other periods were relatively scattered.

## Diagnose the Likely Root Cause
- 1️⃣Global Revenue Trend
- a).The reason for revenue keeping rising from  August to October: inventory buildup period for the year-end shopping season (Q4) and logistics lead time.
- Inventory buildup:Retailers usually need to purchase the gifts needed for the end of the year 2-3 months in advance. Starting from August, wholesalers will place large orders to have the goods delivered to various physical stores or warehouse centers in September and October.
- Logistics lead time:As it is a British company, considering the shipping time, customs clearance time, and warehouse turnover time, the wholesaler must complete the inventory entry before the peak season. Otherwise, missing the Christmas period would be a fatal disaster. Therefore, the growth in August-October is actually the result of "order lead time". 
- b).The reason for the peak period on November:Black Friday and restock.
- Black Friday: This is not only a shopping spree for retailers, but also a "last push" for wholesalers. At this time, many retailers will find that certain best-selling items are not selling well, and will carry out a "final large stock replenishment".
- Seasonal impulse spending: November not only includes Black Friday but also encompasses the initial shopping before Christmas, with gift demand peaking at this time.
- c).The reason for sharp drop in December:shifts in sales models.
- End of B2B procurement cycle: For wholesale operations, the deadline for Christmas orders is typically just before Christmas—early December. Once the first half of December passes, most stores have already stocked up on all their holiday inventory. They no longer need to purchase additional gifts, as there's not enough time to sell them before Christmas.
- Retail vs. wholesale timing gap: While retailers are busy selling products to consumers in December,company—as a supplier—has already completed its wholesale deliveries by then.
- Seasonal slowdown: From mid- to late December, global commerce enters the Christmas holiday period, causing B2B activities to come to a near halt, directly resulting in a steep decline in December revenue.
- 2️⃣Top Driver(country)
- As United Kingdom is the base of online retail,and the local team can seamlessly align with cultural backgrounds and consumer habits, offering faster pre-sales communication and after-sales service,local customers are more likely to choose this online store. Therefore, the order volume will be higher, which leads to an increase in the number of cancellations.
- 3️⃣ Product in "high risk"(fix now) field
- SKU: 21843-The canceled revenue peaked to £1.34k in November 2011,while it was stable for the rest of time.The root cause might be that a sudden surge in traffic caused severe, instantaneous overselling or necessitated logistical interception.This constitutes a "systemic logistics failure during peak periods."
- SKU: 22138-Overall trend was stable except a slight fluctuation in Sep. 2010. The reason could be that the system from different sales channels cannot synchronize the daily inventory from WMS.
- SKU: 71477-The revenue peaked twice in Oct. 2010-£3.20k and in Jul. 2011-£1.99k respectively.It indicates that there are huge seasonal flaws in its supplier's production capacity or overseas procurement cycle, and it is the number one target of the supply chain's review of major promotions.
- 4️⃣ Product in "At Risk" Segment
- SKU 22328-In April 2011, the total churn value (£1.60K) closely aligned with the churn value from the "At Risk" customer segment (£1.59K). It indicates that during major sales events or specific months (such as April), this product is highly susceptible to localized stockouts caused by bulk B2B purchases, instantly wiping out substantial gross profits from key, long-standing customers.
- SKU 22138-In 2010-09, the global cancel rate reached a high of 34.21%; subsequently, "At Risk" customer segment experienced 100% catastrophic cancellation in 2010-10. The reason may be that in the early days of tight supply and demand from July to August, the platform barely guaranteed the experience of returning customers by consuming inventory (the cancellation rate in "At Risk " segment dropped). However, after the market went out of control in September, the protection mechanism completely failed, resulting in 100% rejection of core regular customers when they tried to purchase in October.
- SKU 22617-The "At Risk" segment frequently recorded a 100% cancellation rate in August 2010 and February/March 2011, a pattern that was out of sync with the fluctuation cycle of the overall portfolio in June 2010. It indicates that the order volume of this product is fragmented, but due to data synchronization friction between ERP and WMS, the system has long-term "virtual inventory", resulting in 100% rejection of high-value returning customers who tried to repurchase.



## Suggestions
- Actionable Insights for High Risk Product in Peak Time
- For the pulse-type oversold SKU 21843: The daily performance of this product is extremely stable, but it showed extremely high sales elasticity and vulnerability during the Black Friday promotion in November. The supply chain team should introduce the "Available to Promise (ATP) circuit breaker mechanism" to strictly control the online channel sharing pool of this SKU on the eve of the big promotion to ensure that the front-end virtual inventory and the back-end real inventory are absolutely locked.
- Targeting the seasonal cycle break SKU 71477: This product experienced two sky-high cancellation spikes in July and October within the 24-month cycle. This clearly points to the supplier's seasonal capacity bottlenecks or raw material procurement cycle shortcomings. This product must be included in the "high-risk supply chain monitoring whitelist", and the defense line must be advanced 60 days in advance to block its cyclical supply and demand collapse through advance production lock orders and logistics quota locks.
- Regarding long-tail hidden blood loss SKU 22138: Data shows that its cancellation amount is spread equally throughout the year and does not have the characteristics of Black Friday/Christmas liquidation. Therefore, its optimization focus is not on temporary defense during the big promotion period, but falls under the category of "Business Process Refinement". The operations team needs to conduct daily technical audits of the SKU's online master data, multi-warehouse division logic, and order synchronization links to eliminate long-tail cancellations caused by systemic desynchronization.

## 🛠️ High-Risk SKUs Supply Chain Action Plan (Standard Operating Procedures)

Based on the dual-track diagnostic analysis comparing **Global** and **At Risk (VIP Returning)** customer cohorts, the following strategic remediation protocols have been established for critical SKUs within the £1-4.99 price band.

---

### 🚨 SKU 22328: B2B Bulk-Order Allocation & Inventory Cushioning
*   **Root Cause Pattern**: Single-point infrastructure shock. In April 2011, the global canceled revenue (£1.60K) perfectly converged with the At Risk cohort's loss (£1.59K), driven entirely by high-value B2B repeat buyers placing large-volume orders against insufficient localized stock.
*   **Immediate Remediation (0-30 Days)**:
    *   **Dynamic Safety Stock Cushioning**: Recalculate the safety stock levels for SKU 22328 using a higher service level factor (e.g., $Z = 2.33$ for a 99% fill rate) specifically tailored to buffer against historical April volatility spikes.
    *   **ERP Order-Splitting Disruption Mitigation**: Implement an automated threshold alert in the ERP system. Any individual contract or cart ordering over 15% of the available regional warehouse capacity must trigger an automated check rather than an immediate systemic rejection.
*   **Long-Term Strategy (Strategic)**:
    *   **VIP Inventory Reservation Channel**: Implement an inventory allocation algorithm in the Warehouse Management System (WMS) to reserve a 15% baseline inventory layer exclusive to "High-Frequency/Returning" customer tiers, shielding core revenue streams from random stock depletion by low-value guest users.

---

### 🚨 SKU 22138: Lead-Lag Depletion Mitigation & Early-Warning Triggers
*   **Root Cause Pattern**: Systemic supply chain exhaustion with a distinct lead-lag correlation. Global cancellation spikes in September 2010 (34.21%) acted as an unmonitored leading indicator, resulting in a catastrophic 100% systemic cancellation rate for VIP customers in October 2010 once safety stocks were completely depleted.
*   **Immediate Remediation (0-30 Days)**:
    *   **Global Cancellation Rate Thresholds**: Establish a cross-departmental Early Warning System (EWS). Set a hard operational ceiling: if the **Global Cancel Rate** for SKU 22138 breaches **15%** in any rolling 14-day window, the SKU is flagged for mandatory procurement intervention.
    *   **Proactive VIP Backorder Automation**: In the event of a breach, automatically route affected VIP accounts to a preferred backorder sequence with guaranteed delivery dates and complimentary shipping, preserving customer lifetime value (LTV) during supply constraints.
*   **Long-Term Strategy (Strategic)**:
    *   **Vendor Managed Inventory (VMI)**: Transition SKU 22138 to a VMI framework with top-tier suppliers, establishing clear Lead Time SLAs (< 7 business days) to prevent seasonal inventory drawdowns from impacting high-margin client cohorts.

---

### 🚨 SKU 22617: Long-Tail Data Synchronization & Phantom Stock Eradication
*   **Root Cause Pattern**: Architectural inventory desynchronization. Recurrent 100% cancellation spikes within the At Risk cohort (August 2010, February/March 2011) paired with mismatched global peaks indicate low absolute volume but persistent "phantom stock" discrepancies between the digital storefront and physical warehouse bins.
*   **Immediate Remediation (0-30 Days)**:
    *   **Targeted Cycle Counting**: Issue an immediate warehouse directive for an intensive, physical cycle count of SKU 22617 to align physical bin quantities with the ERP master database.
    *   **Frontend Hard-Fails Integration**: Program a localized storefront rule: when physical inventory drops below 5 units, the website must immediately switch to a "Hard Out of Stock" state for this SKU, removing the option to add to cart rather than risking a backend post-purchase cancellation.
*   **Long-Term Strategy (Strategic)**:
    *   **API Middleware Optimization**: Audit the integration interval between the Warehouse Management System (WMS) and the e-commerce middleware layer, reducing inventory sync latency from standard batch processing to near real-time messaging queues.
