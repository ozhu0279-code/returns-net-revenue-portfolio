# Reducing Returns to Improve Net Revenue: Returns/Cancellations Diagnostics & Action Plan (E-commerce)

## Business Goal

## 📊 Interactive Tableau Dashboard
Click the preview image below to view and interact with the live dashboard on Tableau Public:

[Tableau Dashboard Preview](https://public.tableau.com/views/E-commerceReturnsNetRevenuePortfolioDiagnostics/ExecutiveOverview?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)
![image](https://github.com/ozhu0279-code/returns-net-revenue-portfolio/blob/main/Dashboard_Preview.gif)

- Reduce return/cancellation rates across SKU and customer tiers
- Protect gross profit margins and increase net revenue
- Establish Standard Operating Procedures (SOPs) to mitigate supply chain bottlenecks for key high-risk SKUs

## Source Dataset
**[Online Retail II Dataset](https://archive.ics.uci.edu/dataset/502/online%2Bretail%2Bii)** — Originating from the UCI Machine Learning Repository, this dataset contains all transactional history for a UK-based online retail wholesaler between 2009 and 2011.

## Metrics & KPI Definitions
- **Return / Cancellation**: Identified by invoice numbers starting with 'C' or 'c'.
- **Cancel Rate**: `canceled_orders / positive_sales_orders`
- **Canceled Revenue Share**: `canceled_revenue / gross_revenue`
- **Net Revenue**: `gross_revenue - canceled_revenue`
- **High-Impact Drivers**: Top 10 Countries and Top 10 SKUs ranked by total canceled revenue.
- **AOV**: Average Order Value (`gross_revenue / total_orders`)
- **UPO**: Units per Order (`total_units / total_orders`)
- **ASP**: Average Selling Price (`gross_revenue / total_units`)

## Data Quality & Analytical Assumptions
- **Denominator Calibration**: The source dataset uses journal-style offsetting records rather than simple dynamic state tables. Counting total invoice entries blindly dilutes cancellation metrics. Therefore, the denominator for cancel rates is strictly filtered to positive sales orders, restoring true business cancellation pressure.
- **Time Window Harmonization**: The raw dataset spans December 2009 to December 2011 (25 months), which causes "December" to appear three times compared to twice for other months. Given strong Q4 seasonality in the wholesale gift industry, including three Decembers introduces significant "seasonal weighting bias" and "left-truncation bias." All dashboard models standardize the analytical scope to a full 24-month cycle: **January 1, 2010 to December 31, 2011**.
- **Customer Segmentation Scope**: Time-series revenue and macro KPI trends retain all records (including null `CustomerID`s) to avoid selection bias. Customer-level RFM and retention segmentations strictly filter for non-null `CustomerID` records.
- **Unified Baseline Threshold**: The baseline cancel rate threshold is standardized at **1.98%** across all scatter plots, quadrant models, and high-risk flags. This threshold represents the overall mean cancellation rate after filtering out zero-cancellation noise (perfect-fulfillment SKUs), providing a consistent and robust benchmark for actionable risk management.

## KPI Overview (2010-01 to 2011-12)
- **Cancel Rate**: 18.74%
- **Canceled Revenue Share**: 3.65%
- **Top 10 Countries by Canceled Revenue (DESC)**: United Kingdom, EIRE, France, Spain, Germany, Denmark, Netherlands, Japan, Channel Islands, USA
- **Top 10 SKUs by Canceled Revenue (DESC)**: 23843, 23166, 22423, 85123A, 21108, 71477, 79323W, 23113, 48185, 84078A

---

## Deep Dive Analysis

### 1. Scale & Trend (Macro & SKU Level)
- **Revenue Trend**: Across both general inventory and product-only subsets, net revenue remained stable (£0.5M–£0.8M/month) during Q1–Q2. Sales began surging in August, peaking at ~£1.4M in November before dropping sharply to ~£0.6M in December.
- **Purchasing Behavior Breakdown (Aug–Dec)**:
  - **2010**: AOV and ASP trended upward while UPO declined. Large bulk orders in December elevated the monthly average despite a shrinking buyer volume.
  - **2011**: AOV, ASP, and UPO surged simultaneously in Q4. A single massive enterprise order (>£100,000) occurred in December 2011.
  - **Business Insight**: Following the November retail stocking boom, small buyers step back in December. The market is dominated by late enterprise re-orders, triggering survivorship bias where average order value spikes while overall transaction volume drops.
- **Quality Trend Anomaly**: Canceled revenue share remained lower than the cancellation rate for 23 consecutive months, but inverted sharply in December 2011 (canceled revenue share exceeded cancel rate by >10%).
  - **Anomaly Finding**: Invoice `C581484` (SKU `23843`) was a single cancellation exceeding £168.47K in December 2011, skewing total portfolio loss metrics.

### 2. Dimension Breakdown (Country, SKU & Price Band)
- **Country Level**: The United Kingdom accounts for the vast majority of canceled revenue, outstripping the second-ranked market (EIRE) by roughly £10K every month due to domestic market volume concentration.
- **SKU Scatter Quadrant Analysis**:
  - SKUs are divided into 4 quadrants using order volume **P90 (538 orders)** and the unified **1.98% cancel rate** threshold.
  - High-risk focus quadrant (*Fix Now*): High volume (>538) & High cancellation (>1.98%).
  - Key focus products exceeding £3,000 in canceled revenue: `21843`, `22138`, `22423`, `71477`, `85123A`.
- **Price Band Risk Distribution**:
  - The **£1–4.99** price band represents the highest systemic risk, exceeding P90 order volume (31,758 orders) and averaging a 3.92% canceled revenue share.
  - This price band accounts for **72.6%** of total business canceled revenue, indicating heavy reliance on low-priced traffic drivers that suffer from supply chain friction.

### 3. Product Cancellation Diagnostics
Cancellation causes are classified based on the relationship between price band brackets and cancellation rate triggers:

- **Low Price Band (£1–19.99)** with **Cancel Rate > 10%** $\rightarrow$ **Stockout / Logistics Delay**
- **Mid-to-High Price Band (£20+)** with **Cancel Rate > 5%** $\rightarrow$ **Product Quality Issues**
- **All Other Conditions** $\rightarrow$ **Buyer Remorse / Changed Mind**

```tableau
// Tableau Calculated Field: Primary Cancel Reason (Simulated)
IF [Price Band] IN ('1-4.99', '5-9.99', '10-19.99') AND [Cancel Rate] > 0.10 THEN 
    'Stockout/Logistics Delay'
ELSEIF [Price Band] IN ('20-49.99', '50-99.99', '100+') AND [Cancel Rate] > 0.05 THEN 
    'Product Quality Issues'
ELSE 
    'Buyer Remorse/Changed Mind'
END //
```
- **Diagnostic Findings:**
  - During **Peak Season (Q4)**, cancellations are dominated by Stockout / Logistics Delay.
  - During **Regular Seasons**, cancellations are driven by Buyer Remorse / Changed Mind.

### 4. Customer Segmentation Analysis (RFM & Retention)
- **New vs. Returning Buyers**: Returning customers generate significantly higher gross revenue, but also exhibit higher cancellation rates. Optimization efforts are focused on high-value returning buyers.
- **RFM Segmentation Matrix**: Customers are mapped using **P90 Average Canceled Revenue (£196.18)** and **P75 Canceled Revenue Share (9.15%)**:
- Quadrant 1 (At Risk / High Loss): High canceled revenue & high cancellation rate.
- Quadrant 2 (New/Promising): High cancellation rate, lower absolute monetary impact.
- Quadrant 3 (Lost): Low revenue impact.
- Quadrant 4 (Champions): High revenue, low cancellation rate.

---

## Root Cause Diagnosis

### 1. Macro Revenue & Seasonality Shift
- **Aug–Oct Growth (Lead-Time Driven)**: Wholesale buyers must stock up 2–3 months ahead of holiday sales. Sea freight lead times and warehouse customs clearance require orders to lock in early Q3.
- **Nov Peak (Black Friday & Final Stocking)**: Driven by Black Friday retail surges and last-minute merchant replenishment for bestsellers.
- **Dec Sharp Drop (Wholesale Cycle Closing)**: B2B gift wholesale orders cut off in early December to ensure delivery before Christmas. Small retailers pause purchases, while year-end enterprise contracts dominate, causing AOV to surge via survivorship bias. 

### 2. Geographic & Traffic Concentration
- The United Kingdom dominates sales volume due to local market presence, fast fulfillment capabilities, and lower pre-sales communication friction. Higher baseline transaction volume naturally concentrates total cancellation amounts in the UK market.

### 3. Supply Chain & Inventory Mechanics (5 Key High-Risk SKUs)
- **SKU 21843 (Flash-Sale Overselling)**: Canceled revenue spiked to £1.34K during the Nov 2011 promo peak despite flat historical performance. Root cause: sudden traffic bursts triggering inventory overselling and instant fulfillment interception.

- **SKU 71477 (Cyclical Capacity Collapse)**: Massive spikes in Oct 2010 (£3.20K) and July 2011 (£1.99K)—both immediately prior to major sales events. Root cause: supplier raw material procurement flaws and rigid seasonal production capacity bottlenecks.

- **SKU 22328 (Bulk Order Stock Depletion)**: In April 2011, global loss (£1.60K) converged almost entirely with losses from the At Risk cohort (£1.59K). Root cause: large B2B enterprise orders draining localized stock without order-splitting buffers, wiping out core VIP purchases.

- **SKU 22138 (Multi-Channel Sync Friction & Lead-Lag Exhaustion)**: Maintains an unhealthy baseline cancellation rate year-round, with a September 2010 global spike (34.21%) triggering a catastrophic 100% cancellation rate for At Risk VIP buyers in October 2010. Root cause: ERP-WMS inventory desynchronization and unmonitored safety stock depletion.

- **SKU 22617 (Phantom Stock Discrepancy)**: Recurrent 100% cancellation spikes among VIP returning customers in Aug 2010, Feb 2011, and March 2011. Root cause: "Phantom inventory" lingering in the frontend e-commerce system due to API synchronization latency with physical warehouse bins.

---

## 🛠️ High-Risk SKUs Supply Chain Action Plan (Standard Operating Procedures)

Based on the dual-track diagnostic analysis comparing **Global Portfolio** and **At Risk (VIP Returning)** customer cohorts, standard operating procedures have been established for the 5 key high-risk SKUs.

---

### 🚨 SKU 21843: Promotional Peak Overselling & ATP Circuit Breakers
* **Root Cause Pattern**: Flash-sale inventory depletion. Daily performance is extremely stable, but canceled revenue surged to £1.34K during the Black Friday peak (Dec 2011), driven by sudden traffic bursts exceeding real-time warehouse fulfillment capacity.
* **Immediate Remediation (0–30 Days)**:
  * **ATP (Available-to-Promise) Buffer Locking**: Implement a hard 10% safety buffer on online storefront inventory during major Q4 promotion windows (Nov–Dec) to prevent backend overselling.
* **Long-Term Strategy**:
  * **Dynamic Order Throttling**: Establish automated API rate-limiting between e-commerce sales channels and the WMS to queue order processing during traffic spikes.

---

### 🚨 SKU 71477: Seasonal Supplier Capacity Bottleneck & Pre-Sale Locking
* **Root Cause Pattern**: Recurrent pre-promotional capacity collapse. Cancellation spikes occurred consistently in October 2010 (£3.20K) and July 2011 (£1.99K)—right before major seasonal shopping events—pointing to severe vendor lead-time failures.
* **Immediate Remediation (0–30 Days)**:
  * **Vendor Whitelisting & Lead-Time Advance**: Advance procurement purchase orders (POs) for SKU 71477 by at least 60 days prior to Q3/Q4 promotional events.
* **Long-Term Strategy**:
  * **Supplier SLA Enforcement**: Incorporate strict delivery window SLA penalties into vendor contracts, requiring suppliers to reserve dedicated raw material capacity months in advance.

---

### 🚨 SKU 22328: B2B Bulk-Order Allocation & Inventory Cushioning
* **Root Cause Pattern**: Single-point infrastructure shock. In April 2011, global canceled revenue (£1.60K) converged almost entirely with the At Risk cohort loss (£1.59K), driven by enterprise buyers placing large orders against insufficient localized stock.
* **Immediate Remediation (0–30 Days)**:
  * **Dynamic Safety Stock Cushioning**: Recalculate safety stock for SKU 22328 using a higher service level factor ($Z = 2.33$, 99% fill rate) to buffer against historical April volatility.
  * **ERP Order-Splitting Alerts**: Configure ERP rules where any single order exceeding 15% of available regional warehouse stock triggers an automated review rather than an immediate systemic rejection.
* **Long-Term Strategy**:
  * **VIP Inventory Reservation Channel**: Configure WMS allocation algorithms to reserve a 15% baseline inventory layer exclusively for returning VIP tiers, shielding core revenue from stock depletion by guest users.

---

### 🚨 SKU 22138: Lead-Lag Depletion Mitigation & Early-Warning Triggers
* **Root Cause Pattern**: Systemic supply chain exhaustion with a distinct lead-lag correlation. Global cancellation spikes in September 2010 (34.21%) acted as a leading indicator, resulting in a 100% cancellation rate for VIP customers in October 2010 once safety stocks were completely depleted.
* **Immediate Remediation (0–30 Days)**:
  * **Early Warning System (EWS)**: Set a threshold: if the **Global Cancel Rate** for SKU 22138 breaches **15%** in a rolling 14-day window, trigger mandatory procurement intervention.
  * **Proactive VIP Backorder Automation**: Automatically route affected VIP accounts to prioritized backorder queues with guaranteed delivery dates and complimentary shipping.
* **Long-Term Strategy**:
  * **Vendor Managed Inventory (VMI)**: Transition SKU 22138 to a VMI framework with primary suppliers, enforcing strict SLA lead times (<7 business days) to prevent seasonal inventory drawdowns.

---

### 🚨 SKU 22617: Long-Tail Data Synchronization & Phantom Stock Eradication
* **Root Cause Pattern**: Structural inventory desynchronization. Recurrent 100% cancellation spikes within the At Risk cohort indicate low absolute volume coupled with persistent "phantom stock" discrepancies between the digital storefront and physical warehouse bins.
* **Immediate Remediation (0–30 Days)**:
  * **Targeted Cycle Counting**: Issue an immediate physical cycle count directive for SKU 22617 to align physical bin counts with the ERP master database.
  * **Frontend Hard-Fails Integration**: Implement a storefront rule: when physical inventory falls below 5 units, the frontend automatically switches to "Out of Stock," disabling checkout rather than risking backend cancellation.
* **Long-Term Strategy**:
  * **API Middleware Optimization**: Upgrade the integration interval between WMS and the e-commerce middleware layer, reducing inventory sync latency from batch processing to near real-time queues.
