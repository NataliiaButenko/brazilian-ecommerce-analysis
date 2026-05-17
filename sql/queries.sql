-- Brazilian E-Commerce Analysis
-- BigQuery SQL Queries

-- ============================================================
-- Which product categories generate the most revenue?
-- ============================================================
SELECT
    t.product_category_name_english AS category,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    COUNT(DISTINCT oi.order_id) AS orders_count,
    ROUND(SUM(oi.price) * 100.0 / SUM(SUM(oi.price)) OVER (), 2) AS revenue_share_pct
FROM `olist-ecommerce-496511.olist_raw.olist_order_items` oi
JOIN `olist-ecommerce-496511.olist_raw.olist_orders` o USING (order_id)
JOIN `olist-ecommerce-496511.olist_raw.olist_products` p USING (product_id)
JOIN `olist-ecommerce-496511.olist_raw.product_category_name_translation` t 
    USING (product_category_name)
WHERE o.order_status = 'delivered'
GROUP BY category
ORDER BY total_revenue DESC
LIMIT 10;

-- ============================================================
-- How have revenue and order volume changed over time?
-- ============================================================
WITH payments_agg AS (
    SELECT
        order_id,
        SUM(payment_value) AS total_payment
    FROM `olist-ecommerce-496511.olist_raw.olist_order_payments`
    GROUP BY order_id
)

SELECT
    FORMAT_DATE('%Y-%m', DATE(o.order_purchase_timestamp)) AS year_month,
    ROUND(SUM(p.total_payment), 2) AS total_revenue,
    COUNT(DISTINCT o.order_id) AS orders_count
FROM `olist-ecommerce-496511.olist_raw.olist_orders` o
JOIN payments_agg p USING (order_id)
WHERE o.order_status = 'delivered'
    AND FORMAT_DATE('%Y-%m', DATE(o.order_purchase_timestamp))
        NOT IN ('2016-10', '2016-12')
GROUP BY year_month
ORDER BY year_month;

-- ============================================================
-- Which states have the longest average delivery times?
-- ============================================================
SELECT
    c.customer_state,
    ROUND(AVG(
        DATE_DIFF(o.order_delivered_customer_date, o.order_purchase_timestamp, DAY)
    ), 1) AS avg_delivery_days,
    ROUND(AVG(r.review_score), 2) AS avg_review_score,
    COUNT(DISTINCT o.order_id) AS orders_count
FROM `olist-ecommerce-496511.olist_raw.olist_orders` o
JOIN `olist-ecommerce-496511.olist_raw.olist_customers` c USING (customer_id)
JOIN `olist-ecommerce-496511.olist_raw.olist_order_reviews` r USING (order_id)
WHERE o.order_status = 'delivered'
    AND o.order_delivered_customer_date IS NOT NULL
GROUP BY customer_state
ORDER BY avg_delivery_days DESC;

-- ============================================================
-- Which states contribute the most to revenue and customer activity?
-- ============================================================
WITH payments_agg AS (
    SELECT
        order_id,
        SUM(payment_value) AS total_payment
    FROM `olist-ecommerce-496511.olist_raw.olist_order_payments`
    GROUP BY order_id
)

SELECT
    c.customer_state,
    ROUND(SUM(p.total_payment), 2) AS total_revenue,
    COUNT(DISTINCT o.order_id) AS orders_count,
    COUNT(DISTINCT c.customer_unique_id) AS unique_customers,
    ROUND(
        SUM(p.total_payment) * 100.0
        / SUM(SUM(p.total_payment)) OVER (),
        2
    ) AS revenue_share_pct
FROM `olist-ecommerce-496511.olist_raw.olist_orders` o
JOIN `olist-ecommerce-496511.olist_raw.olist_customers` c
    USING (customer_id)
JOIN payments_agg p USING (order_id)
WHERE o.order_status = 'delivered'
GROUP BY customer_state
ORDER BY total_revenue DESC;

-- ============================================================
-- Which payment methods are most popular?
-- ============================================================
SELECT
    payment_type,
    COUNT(*) AS transactions,
    ROUND(AVG(payment_value), 2) AS avg_order_value,
    ROUND(SUM(payment_value), 2) AS total_value,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS transactions_pct
FROM `olist-ecommerce-496511.olist_raw.olist_order_payments`
WHERE payment_type != 'not_defined'
GROUP BY payment_type
ORDER BY transactions DESC;

-- ============================================================
-- Which product categories receive the lowest review scores?
-- ============================================================
SELECT
    t.product_category_name_english AS category,
    ROUND(AVG(r.review_score), 2) AS avg_review_score,
    COUNT(r.review_score) AS total_reviews,
    ROUND(AVG(
        DATE_DIFF(o.order_delivered_customer_date, o.order_purchase_timestamp, DAY)
    ), 1) AS avg_delivery_days,
    ROUND(COUNTIF(
        DATE(o.order_delivered_customer_date) > DATE(o.order_estimated_delivery_date)
    ) * 100.0 / COUNT(*), 1) AS late_rate_pct
FROM `olist-ecommerce-496511.olist_raw.olist_order_reviews` r
JOIN `olist-ecommerce-496511.olist_raw.olist_orders` o USING (order_id)
JOIN `olist-ecommerce-496511.olist_raw.olist_order_items` oi USING (order_id)
JOIN `olist-ecommerce-496511.olist_raw.olist_products` p USING (product_id)
JOIN `olist-ecommerce-496511.olist_raw.product_category_name_translation` t
    USING (product_category_name)
WHERE o.order_status = 'delivered'
GROUP BY category
HAVING total_reviews >= 100
ORDER BY avg_review_score ASC
LIMIT 10;
