
/* ============================================================

   01_DATA_PROFILING_AND_CLEANING

   ============================================================ */

-- 01. TABLE SNAPSHOT CHECKS

SELECT TOP (1) * FROM dbo.customers;

SELECT TOP (1) * FROM dbo.geolocation;

SELECT TOP (1) * FROM dbo.order_itemst;

SELECT TOP (1) * FROM dbo.order_payments;

SELECT TOP (1) * FROM dbo.order_reviews;

SELECT TOP (1) * FROM dbo.orders;

SELECT TOP (1) * FROM dbo.products;

SELECT TOP (1) * FROM dbo.sellers;

SELECT TOP (1) * FROM dbo.product_category_name_translation;

GO

-- 02. CUSTOMERS NULL CHECK

SELECT

    COUNT(*) AS total_rows,

    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_customer_id,

    SUM(CASE WHEN customer_unique_id IS NULL THEN 1 ELSE 0 END) AS null_customer_unique_id,

    SUM(CASE WHEN customer_zip_code_prefix IS NULL THEN 1 ELSE 0 END) AS null_customer_zip_code_prefix,

    SUM(CASE WHEN customer_city IS NULL THEN 1 ELSE 0 END) AS null_customer_city,

    SUM(CASE WHEN customer_state IS NULL THEN 1 ELSE 0 END) AS null_customer_state

FROM dbo.customers;

GO

-- 03. CUSTOMERS DUPLICATE CHECK

SELECT

    customer_id,

    COUNT(*) AS duplicate_count

FROM dbo.customers

GROUP BY customer_id

HAVING COUNT(*) > 1

ORDER BY duplicate_count DESC;

GO



SELECT

    customer_unique_id,

    COUNT(*) AS duplicate_count

FROM dbo.customers

GROUP BY customer_unique_id

HAVING COUNT(*) > 1

ORDER BY duplicate_count DESC;

GO



-- 04. CUSTOMERS CITY FORMAT CHECK

SELECT

    customer_city,

    customer_state

FROM dbo.customers

WHERE PATINDEX('%[^a-z ]%', LOWER(customer_city)) > 0;

GO



-- 05. CUSTOMERS CLEAN STAGING TABLE

IF OBJECT_ID('dbo.customers_clean', 'U') IS NOT NULL

    DROP TABLE dbo.customers_clean;

GO

SELECT

    customer_id,

    customer_unique_id,

    customer_zip_code_prefix,

    LTRIM(RTRIM(
        REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(

            TRANSLATE(LOWER(customer_city),

                      'áéíóúâêôãõàç',

                      'aeiouaeoaoac'),

        '''', ' '), '.', ' '), ',', ' '), '-', ' '), '/', ' '), '  ', ' ')

    )) AS customer_city,

    customer_state

INTO dbo.customers_clean

FROM dbo.customers;

GO



-- 06. GEOLOCATION NULL CHECK

SELECT

    COUNT(*) AS total_rows,

    SUM(CASE WHEN geolocation_zip_code_prefix IS NULL THEN 1 ELSE 0 END) AS null_geolocation_zip_code_prefix,

    SUM(CASE WHEN geolocation_lat IS NULL THEN 1 ELSE 0 END) AS null_geolocation_lat,

    SUM(CASE WHEN geolocation_lng IS NULL THEN 1 ELSE 0 END) AS null_geolocation_lng,

    SUM(CASE WHEN geolocation_city IS NULL THEN 1 ELSE 0 END) AS null_geolocation_city,

    SUM(CASE WHEN geolocation_state IS NULL THEN 1 ELSE 0 END) AS null_geolocation_state

FROM dbo.geolocation;

GO



-- 07. GEOLOCATION DUPLICATE CHECK

SELECT

    geolocation_zip_code_prefix,

    geolocation_lat,

    geolocation_lng,

    geolocation_city,

    geolocation_state,

    COUNT(*) AS duplicate_count

FROM dbo.geolocation

GROUP BY

    geolocation_zip_code_prefix,

    geolocation_lat,

    geolocation_lng,

    geolocation_city,

    geolocation_state

HAVING COUNT(*) > 1

ORDER BY duplicate_count DESC;

GO



-- 08. GEOLOCATION DISTINCT STAGING VIEW

WITH geolocation_clean AS (

    SELECT DISTINCT

        geolocation_zip_code_prefix,

        geolocation_lat,

        geolocation_lng,

        geolocation_city,

        geolocation_state

    FROM dbo.geolocation

)

SELECT *

FROM geolocation_clean

ORDER BY geolocation_zip_code_prefix;

GO



-- 09. ORDER ITEM NULL CHECK

SELECT

    COUNT(*) AS total_rows,

    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS null_order_id,

    SUM(CASE WHEN order_item_id IS NULL THEN 1 ELSE 0 END) AS null_order_item_id,

    SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS null_product_id,

    SUM(CASE WHEN seller_id IS NULL THEN 1 ELSE 0 END) AS null_seller_id,

    SUM(CASE WHEN shipping_limit_date IS NULL THEN 1 ELSE 0 END) AS null_shipping_limit_date,

    SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END) AS null_price,

    SUM(CASE WHEN freight_value IS NULL THEN 1 ELSE 0 END) AS null_freight_value

FROM dbo.order_itemst;

GO



-- 10. ORDER ITEM DUPLICATE CHECK

SELECT

    order_id,

    order_item_id,

    COUNT(*) AS duplicate_count

FROM dbo.order_itemst

GROUP BY order_id, order_item_id

HAVING COUNT(*) > 1

ORDER BY duplicate_count DESC;

GO



-- 11. ORDER PAYMENTS NULL CHECK

SELECT

    COUNT(*) AS total_rows,

    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS null_order_id,

    SUM(CASE WHEN payment_sequential IS NULL THEN 1 ELSE 0 END) AS null_payment_sequential,

    SUM(CASE WHEN payment_type IS NULL THEN 1 ELSE 0 END) AS null_payment_type,

    SUM(CASE WHEN payment_installments IS NULL THEN 1 ELSE 0 END) AS null_payment_installments,

    SUM(CASE WHEN payment_value IS NULL THEN 1 ELSE 0 END) AS null_payment_value

FROM dbo.order_payments;

GO



-- 12. ORDER PAYMENTS DUPLICATE CHECK

SELECT

    order_id,

    payment_sequential,

    COUNT(*) AS duplicate_count

FROM dbo.order_payments

GROUP BY order_id, payment_sequential

HAVING COUNT(*) > 1

ORDER BY duplicate_count DESC;

GO



-- 13. ORDER REVIEWS NULL CHECK

SELECT

    COUNT(*) AS total_rows,

    SUM(CASE WHEN review_id IS NULL THEN 1 ELSE 0 END) AS null_review_id,

    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS null_order_id,

    SUM(CASE WHEN review_score IS NULL THEN 1 ELSE 0 END) AS null_review_score,

    SUM(CASE WHEN review_comment_title IS NULL THEN 1 ELSE 0 END) AS null_review_comment_title,

    SUM(CASE WHEN review_comment_message IS NULL THEN 1 ELSE 0 END) AS null_review_comment_message,

    SUM(CASE WHEN review_creation_date IS NULL THEN 1 ELSE 0 END) AS null_review_creation_date,

    SUM(CASE WHEN review_answer_timestamp IS NULL THEN 1 ELSE 0 END) AS null_review_answer_timestamp

FROM dbo.order_reviews;

GO



-- 14. ORDER REVIEWS DUPLICATE CHECK

SELECT

    review_id,

    COUNT(*) AS duplicate_count

FROM dbo.order_reviews

GROUP BY review_id

HAVING COUNT(*) > 1

ORDER BY duplicate_count DESC;

GO



SELECT

    order_id,

    COUNT(*) AS duplicate_count

FROM dbo.order_reviews

GROUP BY order_id

HAVING COUNT(*) > 1

ORDER BY duplicate_count DESC;

GO



-- 15. ORDERS NULL CHECK

SELECT

    COUNT(*) AS total_rows,

    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS null_order_id,

    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_customer_id,

    SUM(CASE WHEN order_status IS NULL THEN 1 ELSE 0 END) AS null_order_status,

    SUM(CASE WHEN order_purchase_timestamp IS NULL THEN 1 ELSE 0 END) AS null_order_purchase_timestamp,

    SUM(CASE WHEN order_approved_at IS NULL THEN 1 ELSE 0 END) AS null_order_approved_at,

    SUM(CASE WHEN order_delivered_carrier_date IS NULL THEN 1 ELSE 0 END) AS null_order_delivered_carrier_date,

    SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END) AS null_order_delivered_customer_date,

    SUM(CASE WHEN order_estimated_delivery_date IS NULL THEN 1 ELSE 0 END) AS null_order_estimated_delivery_date

FROM dbo.orders;

GO

-- 16. ORDERS DUPLICATE CHECK

SELECT

    order_id,

    COUNT(*) AS duplicate_count

FROM dbo.orders

GROUP BY order_id

HAVING COUNT(*) > 1

ORDER BY duplicate_count DESC;

GO

-- 17. PRODUCTS NULL CHECK

SELECT

    COUNT(*) AS total_rows,

    SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS null_product_id,

    SUM(CASE WHEN product_category_name IS NULL THEN 1 ELSE 0 END) AS null_product_category_name,

    SUM(CASE WHEN product_name_lenght IS NULL THEN 1 ELSE 0 END) AS null_product_name_lenght,

    SUM(CASE WHEN product_description_lenght IS NULL THEN 1 ELSE 0 END) AS null_product_description_lenght,

    SUM(CASE WHEN product_photos_qty IS NULL THEN 1 ELSE 0 END) AS null_product_photos_qty,

    SUM(CASE WHEN product_weight_g IS NULL THEN 1 ELSE 0 END) AS null_product_weight_g,

    SUM(CASE WHEN product_length_cm IS NULL THEN 1 ELSE 0 END) AS null_product_length_cm,

    SUM(CASE WHEN product_height_cm IS NULL THEN 1 ELSE 0 END) AS null_product_height_cm,

    SUM(CASE WHEN product_width_cm IS NULL THEN 1 ELSE 0 END) AS null_product_width_cm

FROM dbo.products;

GO

-- 18. PRODUCTS DUPLICATE CHECK

SELECT

    product_id,

    COUNT(*) AS duplicate_count

FROM dbo.products

GROUP BY product_id

HAVING COUNT(*) > 1

ORDER BY duplicate_count DESC;

GO

-- 19. PRODUCT CATEGORY TRANSLATION NULL CHECK

SELECT 'product_category_name' AS column_name, COUNT(*) AS number_of_nulls

FROM dbo.product_category_name_translation

WHERE product_category_name IS NULL

UNION ALL

SELECT 'product_category_name_english', COUNT(*)

FROM dbo.product_category_name_translation

WHERE product_category_name_english IS NULL;

GO

-- 20. PRODUCT CATEGORY TRANSLATION DUPLICATE CHECK

SELECT

    product_category_name,

    product_category_name_english,

    COUNT(*) AS duplicate_count

FROM dbo.product_category_name_translation

GROUP BY

    product_category_name,

    product_category_name_english

HAVING COUNT(*) > 1

ORDER BY duplicate_count DESC;

GO

-- 21. SELLERS NULL CHECK

SELECT

    COUNT(*) AS total_rows,

    SUM(CASE WHEN seller_id IS NULL THEN 1 ELSE 0 END) AS null_seller_id,

    SUM(CASE WHEN seller_zip_code_prefix IS NULL THEN 1 ELSE 0 END) AS null_seller_zip_code_prefix,

    SUM(CASE WHEN seller_city IS NULL THEN 1 ELSE 0 END) AS null_seller_city,

    SUM(CASE WHEN seller_state IS NULL THEN 1 ELSE 0 END) AS null_seller_state

FROM dbo.sellers;

GO

-- 22. SELLERS DUPLICATE CHECK

SELECT

    seller_id,

    COUNT(*) AS duplicate_count

FROM dbo.sellers

GROUP BY seller_id

HAVING COUNT(*) > 1

ORDER BY duplicate_count DESC;

GO
