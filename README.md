## Reducing Returns to Improve Net Revenue: Returns/Cancellations Diagnostics & Action Plan (E-commerce)

## Business Goal
- Reduce return/cancellation rate
- Increase net revenue (gross revenue − return/cancellation impact)

## Source Dataset
**[Online Retail II](https://archive.ics.uci.edu/dataset/502/online%2Bretail%2Bii?utm_source=chatgpt.com)**--This dataset originating from UCI Machine Learning Respository includes online retail transactions from 2009-2011.

## Metrics & KPI
- **Return/Cancellation**--The 'invoice' number beginning with upper letter 'C' or lower one 'c' refers to cancellation/return.
- **Cancel Rate**--canceled_orders divided by all_orders.
- **Canceled Revenue Share**--canceled_revenue / gross_revenue`
- **Net Revenue**--gross revenue minus canceled revenue.
- **High-impact driver**--Top 10 Countries and SKUs by canceled revenue.

## Data Quality & Assumption
- The raw dataset is at transaction-line level (multiple rows per invoice). For SKU-level diagnostics, we aggregated lines to invoice–SKU granularity (InvoiceNo + StockCode) to avoid double counting and ensure consistent driver attribution.
- For time-series KPI trends (orders, cancel rate, canceled revenue share), we keep all transactions including missing CustomerID to avoid selection bias.
- For customer-level segmentation (RFM, repeat-cancel patterns), we restrict to records with non-null CustomerID.
- **Limitation** Here, "cancellation/return" is used to approximately represent "post-sale return pressure", which is not equivalent to the entire process of actual returns, but is sufficient for identifying driving factors and optimization opportunities.
