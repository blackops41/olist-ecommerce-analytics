/* ============================================================

   02_EXPLORATORY_DATA_ANALYSIS

   ============================================================ */


-- 01. TOTAL ORDERS & TOTAL REVENUE

SELECT 
    -- 1. Toplam Sipariş Sayısı (Tüm siparişler dahil)
    COUNT(DISTINCT o.order_id) AS total_orders,

    -- 2. Toplam Ciro (Sadece onaylı ve iptal edilmemiş olanlar)
    SUM(
        CASE 
            WHEN o.order_approved_at IS NOT NULL AND o.order_status <> 'canceled' 
            THEN op.payment_value 
            ELSE 0 
        END
    ) AS total_revenue_payments

FROM dbo.orders AS o
LEFT JOIN dbo.order_payments AS op 
    ON o.order_id = op.order_id;

GO



-- 02. ORDER STATUS DISTRIBUTION

SELECT

    order_status,

    COUNT(DISTINCT order_id) AS orders

FROM dbo.orders

GROUP BY order_status

ORDER BY orders DESC;

GO



-- 03. NON-DELIVERED ORDER DISTRIBUTION

SELECT

    order_status,

    COUNT(DISTINCT order_id) AS orders

FROM dbo.orders

WHERE order_status <> 'delivered'

GROUP BY order_status

ORDER BY orders DESC;

GO



-- 04. DAILY ORDER VOLUME

SELECT

    CAST(order_purchase_timestamp AS date) AS order_date,

    COUNT(*) AS orders

FROM dbo.orders

GROUP BY CAST(order_purchase_timestamp AS date)

ORDER BY order_date ASC, orders DESC;

GO



-- 05. MONTHLY ORDER TREND

SELECT

    DATEFROMPARTS(YEAR(order_purchase_timestamp), MONTH(order_purchase_timestamp), 1) AS month_start,

    COUNT(*) AS orders

FROM dbo.orders

GROUP BY DATEFROMPARTS(YEAR(order_purchase_timestamp), MONTH(order_purchase_timestamp), 1)

ORDER BY month_start;

GO



-- 06. QUARTERLY ORDER TREND

SELECT

    DATEFROMPARTS(YEAR(order_purchase_timestamp), ((DATEPART(QUARTER, order_purchase_timestamp) - 1) * 3) + 1, 1) AS quarter_start,

    COUNT(*) AS orders

FROM dbo.orders

GROUP BY DATEFROMPARTS(YEAR(order_purchase_timestamp), ((DATEPART(QUARTER, order_purchase_timestamp) - 1) * 3) + 1, 1)

ORDER BY quarter_start;

GO



-- 07. WEEKLY ORDER TREND

SELECT

    DATEADD(WEEK, DATEDIFF(WEEK, 0, order_purchase_timestamp), 0) AS week_start,

    COUNT(*) AS orders

FROM dbo.orders

GROUP BY DATEADD(WEEK, DATEDIFF(WEEK, 0, order_purchase_timestamp), 0)

ORDER BY week_start;

GO



-- 08. MONTH SEASONALITY

SELECT

    DATEPART(MONTH, order_purchase_timestamp) AS month_no,

    DATENAME(MONTH, order_purchase_timestamp) AS month_name,

    COUNT(*) AS orders

FROM dbo.orders

GROUP BY

    DATEPART(MONTH, order_purchase_timestamp),

    DATENAME(MONTH, order_purchase_timestamp)

ORDER BY month_no;

GO



-- 09. TOP 10 CUSTOMER STATES BY ORDER VOLUME

SELECT TOP (10)

    c.customer_state,

    COUNT(o.order_id) AS orders

FROM dbo.orders AS o

INNER JOIN dbo.customers_clean AS c -- HAM TABLO YERİNE CLEAN KULLANILDI

    ON o.customer_id = c.customer_id

GROUP BY c.customer_state

ORDER BY orders DESC;

GO



-- 10. TOP 10 CUSTOMER CITIES BY ORDER VOLUME

SELECT TOP (10)

    c.customer_city,

    COUNT(o.order_id) AS orders

FROM dbo.orders AS o

INNER JOIN dbo.customers_clean AS c -- HAM TABLO YERİNE CLEAN KULLANILDI

    ON o.customer_id = c.customer_id

GROUP BY c.customer_city

ORDER BY orders DESC;

GO



-- ============================================================

-- 11. ORDER VALUE BY PRIMARY PAYMENT TYPE

-- Assigns each order to its dominant payment method

-- (highest payment amount; ties resolved by payment sequence)

-- and calculates order-level revenue metrics.

-- ============================================================

WITH PrimaryPaymentType AS (
    SELECT
        p.order_id,

        p.payment_type,

        p.payment_value,

        -- Total payment amount for the order

        SUM(p.payment_value) OVER (

            PARTITION BY p.order_id

        ) AS order_total_value,

        -- Select the primary payment method for each order

        ROW_NUMBER() OVER (

            PARTITION BY p.order_id

            ORDER BY
                p.payment_value DESC,

                p.payment_sequential ASC

        ) AS rn
    FROM dbo.order_payments AS p

    INNER JOIN dbo.orders AS o

        ON p.order_id = o.order_id

    WHERE o.order_status <> 'canceled'

      AND o.order_approved_at IS NOT NULL
)
SELECT
    payment_type,

    COUNT(*) AS total_orders,


    CAST(
        SUM(order_total_value)

        AS decimal(15,2)

    ) AS total_revenue,



    CAST(
        AVG(order_total_value)

        AS decimal(15,2)

    ) AS avg_order_value

FROM PrimaryPaymentType

WHERE rn = 1

GROUP BY payment_type
ORDER BY total_revenue DESC;
GO



-- 12. TOP PRODUCT CATEGORIES BY ITEM REVENUE

SELECT TOP (10)
    COALESCE(t.product_category_name_english, 'unknown_category') AS category,
    COUNT(*) AS total_items,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    CAST(SUM(oi.price) AS decimal(15,2)) AS gross_item_revenue
FROM dbo.order_itemst AS oi
INNER JOIN dbo.products AS pr
    ON oi.product_id = pr.product_id
LEFT JOIN dbo.product_category_name_translation AS t
    ON LOWER(pr.product_category_name) = LOWER(t.product_category_name)
INNER JOIN dbo.orders AS o
    ON oi.order_id = o.order_id
WHERE o.order_status <> 'canceled'
  AND o.order_approved_at IS NOT NULL
  AND COALESCE(t.product_category_name_english, 'unknown_category') <> 'unknown_category'
GROUP BY COALESCE(t.product_category_name_english, 'unknown_category')
ORDER BY gross_item_revenue DESC;

GO

-- 12B Monthly Revenue Trend:

SELECT 
    FORMAT(o.order_purchase_timestamp, 'yyyy-MM') AS order_month,
    CAST(SUM(p.payment_value) AS decimal(15,2)) AS total_revenue
FROM dbo.orders o
INNER JOIN dbo.order_payments p ON o.order_id = p.order_id
WHERE o.order_status <> 'canceled'
GROUP BY FORMAT(o.order_purchase_timestamp, 'yyyy-MM')
ORDER BY order_month;
GO

-- 13. REVIEW SCORE DISTRIBUTION

SELECT

    review_score,

    COUNT(*) AS review_count

FROM dbo.order_reviews

GROUP BY review_score

ORDER BY review_score DESC;

GO



-- 14. DELIVERY DELAY DISTRIBUTION

SELECT

    CASE

        WHEN DATEDIFF(DAY, order_estimated_delivery_date, order_delivered_customer_date) <= -3 THEN 'Early (3+ days)'

        WHEN DATEDIFF(DAY, order_estimated_delivery_date, order_delivered_customer_date) BETWEEN -2 AND 0 THEN 'On Time'

        WHEN DATEDIFF(DAY, order_estimated_delivery_date, order_delivered_customer_date) BETWEEN 1 AND 3 THEN 'Mild Delay'

        WHEN DATEDIFF(DAY, order_estimated_delivery_date, order_delivered_customer_date) BETWEEN 4 AND 7 THEN 'Moderate Delay'

        ELSE 'Severe Delay'

    END AS delivery_bucket,

    COUNT(*) AS orders

FROM dbo.orders

WHERE order_status = 'delivered'

  AND order_delivered_customer_date IS NOT NULL

  AND order_estimated_delivery_date IS NOT NULL

GROUP BY

    CASE

        WHEN DATEDIFF(DAY, order_estimated_delivery_date, order_delivered_customer_date) <= -3 THEN 'Early (3+ days)'

        WHEN DATEDIFF(DAY, order_estimated_delivery_date, order_delivered_customer_date) BETWEEN -2 AND 0 THEN 'On Time'

        WHEN DATEDIFF(DAY, order_estimated_delivery_date, order_delivered_customer_date) BETWEEN 1 AND 3 THEN 'Mild Delay'

        WHEN DATEDIFF(DAY, order_estimated_delivery_date, order_delivered_customer_date) BETWEEN 4 AND 7 THEN 'Moderate Delay'

        ELSE 'Severe Delay'

    END

ORDER BY orders DESC;

GO



-- 15. REPEAT CUSTOMER SHARE

WITH customer_orders AS (

    SELECT

        c.customer_unique_id,

        COUNT(DISTINCT o.order_id) AS order_cnt

    FROM dbo.orders AS o

    INNER JOIN dbo.customers_clean AS c

        ON o.customer_id = c.customer_id

    WHERE o.order_status <> 'canceled'

    GROUP BY c.customer_unique_id

)

SELECT

    COUNT(CASE WHEN order_cnt > 1 THEN 1 END) AS repeat_customers,

    COUNT(*) AS total_customers,

    ROUND(100.0 * COUNT(CASE WHEN order_cnt > 1 THEN 1 END) / NULLIF(COUNT(*), 0), 2) AS repeat_customer_rate_pct

FROM customer_orders;

GO
