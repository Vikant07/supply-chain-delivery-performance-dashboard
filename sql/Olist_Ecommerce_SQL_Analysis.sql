-- ============================================================================
-- PROJECT: E-commerce Fulfilment & Delivery Performance Analysis
-- FILE:    Olist_Ecommerce_SQL_Analysis_Beginner_Intermediate.sql
-- DATABASE: SQLite
-- LEVEL:   Beginner to Intermediate
-- PURPOSE:
--   1. Check the nine separately imported cleaned tables.
--   2. Create order-level and order-item-level analysis views.
--   3. Run business-focused SQL analysis for delivery, reviews, freight,
--      customer geography, product categories and seller geography.
--
-- IMPORTANT SETUP:
--   First import the nine cleaned CSV files into SQLite as tables using these
--   exact table names (without .csv):
--     customers_clean
--     geolocation_clean
--     order_items_clean
--     payments_clean
--     reviews_clean
--     orders_clean
--     products_clean
--     sellers_clean
--     category_translation_clean
--
--   The script assumes the columns exported by the Python notebook.
--   It does NOT create or replace the nine source tables.
--   It creates SQL views for analysis; source tables remain separate.
--
-- GRAIN / DOUBLE-COUNTING CONTROL:
--   - v_order_level_analysis: one row per order.
--   - v_order_item_analysis: one row per order item.
--   - Payments, reviews and order items are summarised before joining to the
--     order-level view. This prevents one-to-many joins from multiplying rows.
--   - Category and seller performance are analysed at order-item grain.
--
-- METRIC DEFINITIONS:
--   - Eligible delivered order: delivered order with delivery_days and
--     delay_days available.
--   - Late order: delay_days > 0 (actual delivery after estimated date).
--   - On-time / early: delay_days <= 0.
--   - If delay_days is NULL, the order is not classified as late or on-time.
-- ============================================================================


-- ============================================================================
-- SECTION 1: BASIC TABLE CHECKS
-- Purpose: confirm that the nine tables were imported and have data.
-- ============================================================================

SELECT 'customers_clean' AS table_name, COUNT(*) AS row_count FROM customers_clean
UNION ALL
SELECT 'geolocation_clean', COUNT(*) FROM geolocation_clean
UNION ALL
SELECT 'order_items_clean', COUNT(*) FROM order_items_clean
UNION ALL
SELECT 'payments_clean', COUNT(*) FROM payments_clean
UNION ALL
SELECT 'reviews_clean', COUNT(*) FROM reviews_clean
UNION ALL
SELECT 'orders_clean', COUNT(*) FROM orders_clean
UNION ALL
SELECT 'products_clean', COUNT(*) FROM products_clean
UNION ALL
SELECT 'sellers_clean', COUNT(*) FROM sellers_clean
UNION ALL
SELECT 'category_translation_clean', COUNT(*) FROM category_translation_clean;


-- ============================================================================
-- SECTION 2: DATA QUALITY / KEY CHECKS
-- Purpose: check candidate primary keys and common relationship keys.
-- Expected result for unique keys: zero duplicate rows.
-- ============================================================================

-- 2.1 One row per customer_id in customers_clean
SELECT customer_id, COUNT(*) AS repeated_rows
FROM customers_clean
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- 2.2 One row per order_id in orders_clean
SELECT order_id, COUNT(*) AS repeated_rows
FROM orders_clean
GROUP BY order_id
HAVING COUNT(*) > 1;

-- 2.3 One row per product_id in products_clean
SELECT product_id, COUNT(*) AS repeated_rows
FROM products_clean
GROUP BY product_id
HAVING COUNT(*) > 1;

-- 2.4 One row per seller_id in sellers_clean
SELECT seller_id, COUNT(*) AS repeated_rows
FROM sellers_clean
GROUP BY seller_id
HAVING COUNT(*) > 1;

-- 2.5 One row per order-item combination
SELECT order_id, order_item_id, COUNT(*) AS repeated_rows
FROM order_items_clean
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1;

-- 2.6 One row per payment sequence within an order
SELECT order_id, payment_sequential, COUNT(*) AS repeated_rows
FROM payments_clean
GROUP BY order_id, payment_sequential
HAVING COUNT(*) > 1;

-- 2.7 Check order records without a matching customer
SELECT COUNT(*) AS orders_without_customer
FROM orders_clean AS o
LEFT JOIN customers_clean AS c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- 2.8 Check order items without a matching order
SELECT COUNT(*) AS items_without_order
FROM order_items_clean AS oi
LEFT JOIN orders_clean AS o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

-- 2.9 Check order items without matching product or seller records
SELECT
    SUM(CASE WHEN p.product_id IS NULL THEN 1 ELSE 0 END) AS items_without_product,
    SUM(CASE WHEN s.seller_id IS NULL THEN 1 ELSE 0 END) AS items_without_seller
FROM order_items_clean AS oi
LEFT JOIN products_clean AS p
    ON oi.product_id = p.product_id
LEFT JOIN sellers_clean AS s
    ON oi.seller_id = s.seller_id;


-- ============================================================================
-- SECTION 3: CHECK ORDER STATUS AND MISSING DELIVERY INFORMATION
-- Purpose: understand missing dates before using delivery KPIs.
-- Do not delete non-delivered orders just because delivery dates are missing.
-- ============================================================================

-- 3.1 How many orders are in each status?
SELECT
    order_status,
    COUNT(*) AS order_count
FROM orders_clean
GROUP BY order_status
ORDER BY order_count DESC;

-- 3.2 Missing date counts by order status
SELECT
    order_status,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN order_purchase_timestamp IS NULL THEN 1 ELSE 0 END) AS missing_purchase_date,
    SUM(CASE WHEN order_delivered_carrier_date IS NULL THEN 1 ELSE 0 END) AS missing_carrier_date,
    SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END) AS missing_actual_delivery_date,
    SUM(CASE WHEN order_estimated_delivery_date IS NULL THEN 1 ELSE 0 END) AS missing_estimated_delivery_date
FROM orders_clean
GROUP BY order_status
ORDER BY order_status;


-- ============================================================================
-- SECTION 4: CREATE ANALYSIS VIEWS
-- Views are saved SQL queries. They do not duplicate or replace source tables.
-- ============================================================================

-- 4.1 Order-level view: exactly one row per order.
-- Payment, review and order-item details are summarised to order level first.
DROP VIEW IF EXISTS v_order_level_analysis;

CREATE VIEW v_order_level_analysis AS
WITH
item_summary AS (
    SELECT
        oi.order_id,
        COUNT(*) AS order_item_count,
        COUNT(DISTINCT oi.product_id) AS product_count,
        COUNT(DISTINCT oi.seller_id) AS seller_count,
        SUM(oi.price) AS total_item_value,
        SUM(oi.freight_value) AS total_freight_value,
        AVG(oi.freight_value) AS avg_freight_per_item,
        AVG(p.product_weight_g) AS avg_product_weight_g,
        AVG(p.product_length_cm) AS avg_product_length_cm,
        AVG(p.product_height_cm) AS avg_product_height_cm,
        AVG(p.product_width_cm) AS avg_product_width_cm
    FROM order_items_clean AS oi
    LEFT JOIN products_clean AS p
        ON oi.product_id = p.product_id
    GROUP BY oi.order_id
),
payment_summary AS (
    SELECT
        order_id,
        SUM(payment_value) AS total_payment_value,
        COUNT(*) AS payment_record_count
    FROM payments_clean
    GROUP BY order_id
),
review_summary AS (
    SELECT
        order_id,
        AVG(review_score) AS avg_review_score,
        COUNT(review_score) AS review_count
    FROM reviews_clean
    GROUP BY order_id
)
SELECT
    o.order_id,
    o.customer_id,
    c.customer_unique_id,
    c.customer_state,
    c.customer_city,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    o.delivery_days,
    o.delay_days,
    CASE
        WHEN o.delay_days > 0 THEN 1
        WHEN o.delay_days IS NOT NULL THEN 0
        ELSE NULL
    END AS is_late_delivery,
    i.order_item_count,
    i.product_count,
    i.seller_count,
    i.total_item_value,
    i.total_freight_value,
    i.avg_freight_per_item,
    i.avg_product_weight_g,
    i.avg_product_length_cm,
    i.avg_product_height_cm,
    i.avg_product_width_cm,
    pay.total_payment_value,
    pay.payment_record_count,
    r.avg_review_score,
    r.review_count
FROM orders_clean AS o
LEFT JOIN customers_clean AS c
    ON o.customer_id = c.customer_id
LEFT JOIN item_summary AS i
    ON o.order_id = i.order_id
LEFT JOIN payment_summary AS pay
    ON o.order_id = pay.order_id
LEFT JOIN review_summary AS r
    ON o.order_id = r.order_id;


-- 4.2 Order-item view: one row per order item.
-- Use this view for product category and seller-state analysis.
DROP VIEW IF EXISTS v_order_item_analysis;

CREATE VIEW v_order_item_analysis AS
SELECT
    oi.order_id,
    oi.order_item_id,
    oi.product_id,
    oi.seller_id,
    o.customer_id,
    c.customer_state,
    c.customer_city,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    o.delivery_days,
    o.delay_days,
    CASE
        WHEN o.delay_days > 0 THEN 1
        WHEN o.delay_days IS NOT NULL THEN 0
        ELSE NULL
    END AS is_late_delivery,
    oi.shipping_limit_date,
    oi.price AS item_price,
    oi.freight_value,
    p.product_category_name,
    COALESCE(t.product_category_name_english, p.product_category_name, 'Unknown / not translated')
        AS product_category_english,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm,
    s.seller_state,
    s.seller_city
FROM order_items_clean AS oi
LEFT JOIN orders_clean AS o
    ON oi.order_id = o.order_id
LEFT JOIN customers_clean AS c
    ON o.customer_id = c.customer_id
LEFT JOIN products_clean AS p
    ON oi.product_id = p.product_id
LEFT JOIN category_translation_clean AS t
    ON p.product_category_name = t.product_category_name
LEFT JOIN sellers_clean AS s
    ON oi.seller_id = s.seller_id;


-- ============================================================================
-- SECTION 5: OVERALL DELIVERY KPI SUMMARY
-- Denominator: delivered orders with delivery_days and delay_days available.
-- ============================================================================

SELECT
    COUNT(*) AS eligible_delivered_orders,
    SUM(CASE WHEN is_late_delivery = 1 THEN 1 ELSE 0 END) AS late_orders,
    SUM(CASE WHEN is_late_delivery = 0 THEN 1 ELSE 0 END) AS on_time_or_early_orders,
    ROUND(
        100.0 * SUM(CASE WHEN is_late_delivery = 1 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0),
        2
    ) AS late_delivery_rate_percent,
    ROUND(AVG(delivery_days), 2) AS average_delivery_days,
    ROUND(AVG(delay_days), 2) AS average_delay_days,
    ROUND(AVG(avg_review_score), 2) AS average_review_score,
    ROUND(AVG(total_freight_value), 2) AS average_total_freight_per_order
FROM v_order_level_analysis
WHERE order_status = 'delivered'
  AND delivery_days IS NOT NULL
  AND delay_days IS NOT NULL;


-- ============================================================================
-- SECTION 6: REVIEW SCORE — LATE VS ON-TIME / EARLY ORDERS
-- Only orders with a recorded review score are included in the average.
-- ============================================================================

SELECT
    CASE
        WHEN is_late_delivery = 1 THEN 'Late'
        ELSE 'On time or early'
    END AS delivery_status,
    COUNT(*) AS eligible_orders,
    COUNT(avg_review_score) AS orders_with_review,
    ROUND(AVG(avg_review_score), 2) AS average_review_score,
    ROUND(AVG(delivery_days), 2) AS average_delivery_days,
    ROUND(AVG(delay_days), 2) AS average_delay_days
FROM v_order_level_analysis
WHERE order_status = 'delivered'
  AND delay_days IS NOT NULL
GROUP BY is_late_delivery
ORDER BY is_late_delivery;


-- ============================================================================
-- SECTION 7: CUSTOMER STATE DELIVERY PERFORMANCE
-- Show order volume with rate so small samples are not over-interpreted.
-- ============================================================================

SELECT
    customer_state,
    COUNT(*) AS eligible_orders,
    SUM(CASE WHEN is_late_delivery = 1 THEN 1 ELSE 0 END) AS late_orders,
    ROUND(
        100.0 * SUM(CASE WHEN is_late_delivery = 1 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0),
        2
    ) AS late_delivery_rate_percent,
    ROUND(AVG(delivery_days), 2) AS average_delivery_days,
    ROUND(AVG(avg_review_score), 2) AS average_review_score,
    ROUND(AVG(total_freight_value), 2) AS average_total_freight_per_order
FROM v_order_level_analysis
WHERE order_status = 'delivered'
  AND delay_days IS NOT NULL
  AND customer_state IS NOT NULL
GROUP BY customer_state
ORDER BY eligible_orders DESC;


-- 7.1 States with higher late-delivery rates (minimum 100 eligible orders)
SELECT
    customer_state,
    COUNT(*) AS eligible_orders,
    SUM(CASE WHEN is_late_delivery = 1 THEN 1 ELSE 0 END) AS late_orders,
    ROUND(
        100.0 * SUM(CASE WHEN is_late_delivery = 1 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0),
        2
    ) AS late_delivery_rate_percent,
    ROUND(AVG(avg_review_score), 2) AS average_review_score
FROM v_order_level_analysis
WHERE order_status = 'delivered'
  AND delay_days IS NOT NULL
  AND customer_state IS NOT NULL
GROUP BY customer_state
HAVING COUNT(*) >= 100
ORDER BY late_delivery_rate_percent DESC;


-- ============================================================================
-- SECTION 8: PRODUCT CATEGORY PERFORMANCE (ORDER-ITEM GRAIN)
-- Important: rates below are item-based rates, not unique-order rates.
-- ============================================================================

SELECT
    product_category_english,
    COUNT(*) AS delivered_order_items,
    COUNT(DISTINCT order_id) AS delivered_orders,
    SUM(CASE WHEN is_late_delivery = 1 THEN 1 ELSE 0 END) AS late_order_items,
    ROUND(
        100.0 * SUM(CASE WHEN is_late_delivery = 1 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0),
        2
    ) AS late_item_rate_percent,
    ROUND(AVG(freight_value), 2) AS average_freight_per_item,
    ROUND(AVG(item_price), 2) AS average_item_price
FROM v_order_item_analysis
WHERE order_status = 'delivered'
  AND is_late_delivery IS NOT NULL
GROUP BY product_category_english
ORDER BY delivered_orders DESC
LIMIT 20;


-- 8.1 Categories with higher average freight (minimum 100 delivered items)
SELECT
    product_category_english,
    COUNT(*) AS delivered_order_items,
    COUNT(DISTINCT order_id) AS delivered_orders,
    ROUND(AVG(freight_value), 2) AS average_freight_per_item,
    ROUND(AVG(product_weight_g), 2) AS average_product_weight_g,
    ROUND(AVG(item_price), 2) AS average_item_price
FROM v_order_item_analysis
WHERE order_status = 'delivered'
GROUP BY product_category_english
HAVING COUNT(*) >= 100
ORDER BY average_freight_per_item DESC
LIMIT 20;


-- ============================================================================
-- SECTION 9: SELLER STATE CONCENTRATION AND DELIVERY EXPOSURE
-- Grain: order item. One order can contain items from different sellers.
-- ============================================================================

SELECT
    seller_state,
    COUNT(*) AS order_items,
    COUNT(DISTINCT order_id) AS orders,
    COUNT(DISTINCT seller_id) AS sellers,
    SUM(CASE WHEN is_late_delivery = 1 THEN 1 ELSE 0 END) AS late_order_items,
    ROUND(
        100.0 * SUM(CASE WHEN is_late_delivery = 1 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0),
        2
    ) AS late_item_rate_percent,
    ROUND(SUM(freight_value), 2) AS total_freight_value
FROM v_order_item_analysis
WHERE order_status = 'delivered'
  AND is_late_delivery IS NOT NULL
  AND seller_state IS NOT NULL
GROUP BY seller_state
ORDER BY order_items DESC;


-- ============================================================================
-- SECTION 10: DELAY BANDS AND CUSTOMER REVIEWS
-- Delay bands make it easier to compare early and late deliveries.
-- ============================================================================

SELECT
    CASE
        WHEN delay_days <= -7 THEN '7+ days early'
        WHEN delay_days BETWEEN -6 AND -1 THEN '1-6 days early'
        WHEN delay_days = 0 THEN 'Delivered on estimated date'
        WHEN delay_days BETWEEN 1 AND 3 THEN '1-3 days late'
        WHEN delay_days BETWEEN 4 AND 7 THEN '4-7 days late'
        WHEN delay_days > 7 THEN 'More than 7 days late'
        ELSE 'Unknown'
    END AS delay_band,
    COUNT(*) AS eligible_orders,
    COUNT(avg_review_score) AS orders_with_review,
    ROUND(AVG(avg_review_score), 2) AS average_review_score,
    ROUND(AVG(delay_days), 2) AS average_delay_days,
    ROUND(AVG(delivery_days), 2) AS average_delivery_days
FROM v_order_level_analysis
WHERE order_status = 'delivered'
  AND delay_days IS NOT NULL
GROUP BY delay_band
ORDER BY
    CASE delay_band
        WHEN '7+ days early' THEN 1
        WHEN '1-6 days early' THEN 2
        WHEN 'Delivered on estimated date' THEN 3
        WHEN '1-3 days late' THEN 4
        WHEN '4-7 days late' THEN 5
        WHEN 'More than 7 days late' THEN 6
        ELSE 7
    END;


-- ============================================================================
-- SECTION 11: FREIGHT VALUE AT ORDER LEVEL
-- Compare total freight per order by customer state.
-- ============================================================================

SELECT
    customer_state,
    COUNT(*) AS delivered_orders,
    ROUND(AVG(total_freight_value), 2) AS average_freight_per_order,
    ROUND(AVG(total_item_value), 2) AS average_item_value,
    ROUND(AVG(total_freight_value / NULLIF(total_item_value, 0)), 4) AS average_freight_to_item_value_ratio
FROM v_order_level_analysis
WHERE order_status = 'delivered'
  AND total_freight_value IS NOT NULL
  AND customer_state IS NOT NULL
GROUP BY customer_state
ORDER BY average_freight_per_order DESC;


-- ============================================================================
-- SECTION 12: SIMPLE DATE COVERAGE CHECK
-- The dataset has purchase/delivery timestamps, so we can inspect monthly order
-- volume. This is descriptive volume, not a forecast.
-- ============================================================================

SELECT
    substr(order_purchase_timestamp, 1, 7) AS purchase_month,
    COUNT(*) AS total_orders
FROM orders_clean
WHERE order_purchase_timestamp IS NOT NULL
GROUP BY substr(order_purchase_timestamp, 1, 7)
ORDER BY purchase_month;


-- ============================================================================
-- END OF SCRIPT
-- ============================================================================
