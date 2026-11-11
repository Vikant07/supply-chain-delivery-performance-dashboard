# Supply Chain Delivery Performance Dashboard

An end-to-end data analytics portfolio project using the **Olist
Brazilian E-Commerce Public Dataset**. The project investigates delivery
reliability, regional fulfilment variation, freight economics, seller
concentration, and the relationship between delivery outcomes and
customer review scores.

> **Evidence note:** Headline metrics below were recalculated from the
> supplied nine cleaned CSV tables and cross-checked against the
> supplied SQLite SQL analysis. The Power BI dashboard was reviewed from
> screenshots; its PBIX/DAX model was not supplied for independent
> measure-level validation. The Python notebook was reviewed but not
> executed end-to-end because its original raw-data path was not
> included.

------------------------------------------------------------------------

## 1. Business Problem

What factors are associated with late delivery, freight cost variation,
and customer review scores in an e-commerce fulfilment operation?

The analysis is intended to help operations and marketplace stakeholders
identify where delivery performance varies, which regions warrant
investigation, how freight differs across products and sellers, and
whether customer feedback differs by delivery outcome.

This is a **descriptive analytics** project. Observed associations
should not be interpreted as proven causes.

## 2. Business Objectives

-   Measure delivery duration and late-delivery rate for eligible
    delivered orders.
-   Compare review scores between late and on-time/early deliveries.
-   Compare delivery performance across customer states, considering
    both rate and order volume.
-   Analyse freight value by product category and seller geography.
-   Demonstrate data-quality checks, cleaning, feature engineering, SQL
    analysis, and Power BI reporting.
-   Preserve the nine cleaned source tables at their natural grains for
    analysis and modelling.

## 3. Dataset

**Source:** Olist Brazilian E-Commerce Public Dataset (Kaggle).

The project uses nine cleaned relational tables:

  -----------------------------------------------------------------------
  Table                               Analytical purpose
  ----------------------------------- -----------------------------------
  `customers_clean.csv`               Customer identifier and customer
                                      location

  `geolocation_clean.csv`             ZIP-prefix geographic lookup

  `order_items_clean.csv`             Item, product, seller, price,
                                      freight, shipping-limit details

  `payments_clean.csv`                Payment type, sequence,
                                      instalments, payment value

  `reviews_clean.csv`                 Review score, text, and timestamps

  `orders_clean.csv`                  Order status and purchase/delivery
                                      timestamps

  `products_clean.csv`                Product category and product
                                      attributes

  `sellers_clean.csv`                 Seller identifier and seller
                                      location

  `category_translation_clean.csv`    Portuguese-to-English category
                                      mapping
  -----------------------------------------------------------------------

The dataset contains **99,441 unique orders**. Its historical purchase
period runs from September 2016 to October 2018.

Please follow the original Kaggle dataset licence and attribution
requirements when redistributing source-derived data. Do not upload raw
data if its licence or sharing terms do not permit redistribution.

## 4. Verified Headline Results

The following figures were recalculated from the supplied cleaned CSVs:

  ------------------------------------------------------------------------
  KPI                                         Result Definition / grain
  --------------------- ---------------------------- ---------------------
  Unique orders                               99,441 Distinct order
                                                     records

  Delivered orders                            96,478 Orders with delivered
                                                     status

  Eligible delivered                          96,470 Delivered orders with
  orders                                             valid delivery and
                                                     estimate dates

  Late delivered orders                        7,826 Eligible orders
                                                     delivered after
                                                     estimated date

  Late delivery rate                       **8.11%** Late eligible orders
                                                     / eligible delivered
                                                     orders

  On-time / early                             88,644 Eligible orders
  orders                                             delivered on or
                                                     before estimate

  On-time / early rate                    **91.89%** On-time/early
                                                     eligible orders /
                                                     eligible delivered
                                                     orders

  Average delivery time                   12.56 days Purchase timestamp to
                                                     actual customer
                                                     delivery

  Average delay                          -11.18 days Actual delivery
  vs. estimate                                       timestamp minus
                                                     estimated delivery
                                                     timestamp

  Average review score:                     4.29 / 5 Order-level average
  on-time/early                                      review score

  Average review score:                     2.57 / 5 Order-level average
  late                                               review score

  Total freight                        2.252 million Sum of freight values
                                                     across order items

  Average freight per                          19.99 Average item-level
  item                                               freight value

  Freight / item sales                        16.57% Total freight / total
                                                     item value
  ------------------------------------------------------------------------

**Interpretation:** Late-delivered orders have a materially lower
average review score than on-time/early orders in this dataset. This is
an association, not proof that lateness alone caused the lower scores.

### Regional examples

  Customer state     Eligible delivered orders   Late rate
  ---------------- --------------------------- -----------
  RJ                                    12,350      13.47%
  SP                                    40,494       5.89%
  BA                                     3,256      14.04%

Regional rates should be interpreted alongside their supporting order
counts. Further investigation is needed before attributing regional
differences to carriers, distance, seller dispatch, or local
infrastructure.

### Seller concentration

São Paulo accounts for approximately **71.32% of order items by seller
state**. This describes seller-side item concentration; it does not by
itself establish that seller location causes delivery delays.

## 5. Tools & Technologies

-   **Python:** data preparation and exploratory analysis
-   **pandas / NumPy:** data manipulation and numerical operations
-   **Jupyter Notebook:** documented analytical workflow
-   **SQL / SQLite:** data-quality checks, analytical views, and
    business queries
-   **Power BI:** interactive dashboard and KPI reporting
-   **Git / GitHub:** version control and project publishing

## 6. Repository Structure

Recommended GitHub repository layout:

``` text
olist-ecommerce-fulfilment-analysis/
│
├── README.md
├── LICENSE
├── .gitignore
│
├── data/
│   └── cleaned/
│       ├── customers_clean.csv
│       ├── geolocation_clean.csv
│       ├── order_items_clean.csv
│       ├── payments_clean.csv
│       ├── reviews_clean.csv
│       ├── orders_clean.csv
│       ├── products_clean.csv
│       ├── sellers_clean.csv
│       └── category_translation_clean.csv
│
├── notebooks/
│   └── Olist_Ecommerce_Complete_Analysis_Easy_to_Intermediate.ipynb
│
├── sql/
│   └── Olist_Ecommerce_SQL_Analysis_Beginner_Intermediate.sql
│
├── dashboard/
│   ├── power_bi_dashboard_screenshots/
│   └── Olist_Dashboard.pbix
│
├── reports/
│   ├── Olist_Fulfilment_Delivery_Analysis_Report.pdf
│   └── Olist_Fulfilment_Delivery_Analysis_Report.docx
│
└── presentation/
    └── Olist_Fulfilment_Delivery_Executive_Presentation.pptx
```

Only include the `.pbix` file if you actually have it. The screenshots
can be included as evidence, but they are not a substitute for the
editable Power BI model.

## 7. Methodology

1.  Define the business problem and analytical questions.
2.  Load and profile the source tables.
3.  Inspect row counts, data types, missing values, duplicates, keys,
    and relationships.
4.  Convert date columns to datetime and standardise relevant fields.
5.  Engineer `delivery_days`, `delay_days`, and late-delivery
    classification.
6.  Preserve item-level and order-level grains for the correct analyses.
7.  Aggregate payments, reviews, and order items before joining them to
    order-level analysis, preventing one-to-many joins from multiplying
    order records.
8.  Create SQL views and business-focused queries.
9.  Analyse delivery outcomes, customer reviews, customer states,
    product categories, freight, and seller geography.
10. Present the results in Power BI and document limitations and
    recommended investigations.

## 8. KPI Definitions

-   **Eligible delivered order:** delivered order with valid purchase,
    actual delivery, and estimated delivery timestamps.
-   **Late order:** eligible delivered order where actual delivery is
    later than the estimated delivery timestamp (`delay_days > 0`).
-   **On-time / early order:** eligible delivered order where
    `delay_days <= 0`.
-   **Late delivery rate:** late eligible delivered orders divided by
    all eligible delivered orders.
-   **Delivery days:** actual customer delivery timestamp minus purchase
    timestamp, expressed in days.
-   **Delay days:** actual customer delivery timestamp minus estimated
    delivery timestamp, expressed in days. Negative values mean early
    delivery.
-   **Average review score:** mean recorded review score for the
    selected order population. Review coverage should be reported
    alongside it.
-   **Freight value:** freight amount from order-item records. State
    clearly whether the analysis is item-level or order-level.

## 9. SQL Design & Grain Control

The SQL script creates two analytical views:

-   `v_order_level_analysis`: one row per order. Item, payment, and
    review details are aggregated before joining.
-   `v_order_item_analysis`: one row per order item. Used for category
    and seller-state analyses.

This grain separation is important. Joining raw order items, payments,
and reviews directly can multiply rows and inflate counts or sums.

To run the SQL script, first import the nine cleaned CSV files into
SQLite using the exact table names referenced in the SQL file (without
`.csv`):

`customers_clean`, `geolocation_clean`, `order_items_clean`,
`payments_clean`, `reviews_clean`, `orders_clean`, `products_clean`,
`sellers_clean`, `category_translation_clean`.

Then execute the SQL file in a SQLite-compatible tool such as DB Browser
for SQLite or the SQLite command-line client.

## 10. Key Business Recommendations

1.  **Monitor delivery reliability:** track eligible delivered orders,
    late orders, late rate, average delivery days, delay days, and
    review score by delivery status.
2.  **Investigate regional outliers:** review regional carrier
    performance, seller-to-customer routes, estimated-date accuracy, and
    local logistics constraints.
3.  **Review high-freight categories:** assess product dimensions and
    weight, packaging, carrier pricing, freight recovery, and product
    margin impact.
4.  **Analyse seller geography:** compare seller-state concentration
    with destination region, delivery performance, freight, and review
    scores.
5.  **Use reviews as a service-quality signal:** monitor review scores
    by delivery status, delay band, customer state, product category,
    and seller state.
6.  **Consider a future late-risk model:** only after establishing a
    reliable time-based training design and validating that input
    features are available before dispatch/delivery outcomes occur.

These are investigation and monitoring recommendations. No monetary
savings, ROI, or causal improvement is claimed.

## 11. Limitations

-   Historical public marketplace data; results should not be assumed to
    represent every e-commerce business or current operations.
-   Carrier-level and warehouse-processing event data are not available
    in the supplied project tables.
-   Stock availability and detailed operational exception data are not
    included.
-   Delivery-rate denominators exclude delivered orders without valid
    actual/estimated delivery timestamps.
-   Review scores are available only for reviewed orders; review
    coverage matters.
-   Descriptive associations do not establish causality.
-   Currency convention was not independently confirmed; freight values
    are shown in dataset currency units without assigning a currency
    symbol.
-   The Power BI PBIX/DAX model was not supplied for independent
    measure-level validation.
-   The notebook was reviewed, but its full original raw-data workflow
    was not independently rerun from raw source files.

## 12. Files in This Repository

Add the following project artifacts to their corresponding folders:

-   Cleaned CSV tables
-   Jupyter notebook
-   SQL analysis script
-   Power BI screenshots and, if available, PBIX file
-   Final project report (PDF and editable DOCX)
-   Executive presentation (PPTX)

## 13. Author

**Vikant Kumar**\
Data Analytics Portfolio Project\
Skills demonstrated: Python, pandas, SQL, SQLite, Power BI, data
quality, KPI design, exploratory analysis, and business storytelling.

 

 
