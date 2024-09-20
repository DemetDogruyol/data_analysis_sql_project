--Case 1 : Sipariş Analizi
--Question 1 : Aylık olarak order dağılımını inceleyiniz. Tarih verisi için order_approved_at kullanılmalıdır.

SELECT
COALESCE(TO_CHAR(order_approved_at, 'YYYY-MM'), 'Bilinmeyen Tarih') AS year_month,
COUNT(*) AS order_count
FROM
orders
GROUP BY
year_month
ORDER BY
year_month;

--Question 2 : Aylık olarak order status kırılımında order sayılarını inceleyiniz. Sorgu sonucunda çıkan outputu excel ile görselleştiriniz. Dramatik bir düşüşün ya da yükselişin olduğu aylar var mı? Veriyi inceleyerek yorumlayınız.

SELECT
COALESCE(TO_CHAR(order_approved_at, 'YYYY-MM'), 'Bilinmeyen Tarih') AS year_month,
order_status,
COUNT(*) AS order_count
FROM
orders
GROUP BY
year_month, order_status
ORDER BY
year_month, order_status; 

/*
•	Gönderilen ve teslim edilen ürünlere baktığımız da 2017 yılında Kasım ayında daha fazla ürün gönderilip teslim edildiğini görüyoruz. Buradan 2017 yılının Kasım ayında satışın daha fazla olduğu çıkarımına varabiliriz. Bunun sebebi 15 Kasım’ın Bağımsızlık İlan edilme tarihi olabilir.
•	Aynı tarihte ‘unavailable’ durumunda da bir artış görmekteyiz. Bunun sebebi stok tükenmiş veya ürün belli bir sınır üzerinde sipariş verilmiş olabilir. 
•	Grafiklerden çıkardığım izlenimde ‘unavailable’ durumunun genelde diğerlerinden daha fazla olduğudur. Stok durumuna göre veya başka bir sebepten kaynaklı ürünler için sipariş uygunluğu verilmemiş.

*/

--Question 3 : Ürün kategorisi kırılımında sipariş sayılarını inceleyiniz. Özel günlerde öne çıkan kategoriler nelerdir? Örneğin yılbaşı, sevgililer günü…

SELECT
COALESCE(p.product_category_name, 'Unknown') AS product_category_name,
COUNT(oi.order_id) AS order_count
FROM
order_items oi
LEFT JOIN
products p ON oi.product_id = p.product_id
GROUP BY
product_category_name
ORDER BY
order_count DESC;

/*

•	Bu sorgu sonucunda en çok sipariş verilen kategorinin 'cama_mesa_banho' olduğunu görüyoruz.
•	Araştırmalarım sonucunda 2. ve 3. ayda karnaval kutlamaları yapılmaktaymış. 2-3 ayların toplam siparişlerine baktığım zaman ise 2017 yılında "moveis_decoracao" kategorisinde daha çok sipariş alınmış.
•	Ayrıca diğer özel günlere baktığım zamanda da "moveis_decoracao" kategorisinde daha çok sipariş verildiğini görebiliriz.
•	2018 yılında ise "informatica_acessorios" kategorisinde daha çok sipariş alınmış.
*/

--Question 4 : Haftanın günleri(pazartesi, perşembe, ….) ve ay günleri (ayın 1’i,2’si gibi) bazında order sayılarını inceleyiniz. Yazdığınız sorgunun outputu ile excel’de bir görsel oluşturup yorumlayınız.

WITH date_info AS (
SELECT
TO_CHAR(order_approved_at, 'DY') AS day_of_week,
EXTRACT(DAY FROM order_approved_at) AS day_of_month,
COUNT(order_id) AS order_count
FROM
orders
WHERE
order_approved_at IS NOT NULL
GROUP BY
day_of_week, day_of_month
)
SELECT
day_of_week,
day_of_month,
COALESCE(order_count, 0) AS order_count
FROM
date_info
ORDER BY
CASE
WHEN day_of_week = 'MON' THEN 1
WHEN day_of_week = 'TUE' THEN 2
WHEN day_of_week = 'WED' THEN 3
WHEN day_of_week = 'THU' THEN 4
WHEN day_of_week = 'FRI' THEN 5
WHEN day_of_week = 'SAT' THEN 6
WHEN day_of_week = 'SUN' THEN 7
END,
day_of_month;

/*
•	Grafiği incelediğim zaman Brezilyalılar Salı günü daha çok sipariş veriyorlar. Ay bazında baktığım zaman da ayın 24 ve 25’inde siparişin arttığını görebiliyoruz. Bunun sebebinin 25 Aralık’ta Noel kutlamaları için verilen siparişler olduğunu düşünüyorum.
*/

--Case 2 : Müşteri Analizi
--Question 1 : Hangi şehirlerdeki müşteriler daha çok alışveriş yapıyor? Müşterinin şehrini en çok sipariş verdiği şehir olarak belirleyip analizi ona göre yapınız. 

--En çok sipariş verilen şehirler

SELECT
customer_city,
COUNT(DISTINCT o.order_id) AS order_count
FROM
public.orders o
JOIN
public.customers c ON o.customer_id = c.customer_id
GROUP BY
customer_city
ORDER BY
order_count DESC;

---- Müşterinin şehrini en çok sipariş verdiği şehir 

WITH CustomerCityOrderCounts AS (
SELECT
c.customer_unique_id,
c.customer_city,
COUNT(o.order_id) AS order_count
FROM
public.orders o
JOIN
public.customers c ON o.customer_id = c.customer_id
GROUP BY
c.customer_unique_id, c.customer_city
)

SELECT
cco.customer_unique_id,
(ARRAY_AGG(cco.customer_city ORDER BY cco.order_count DESC))[1] AS most_order_city,
MAX(cco.order_count) AS max_order_count
FROM
CustomerCityOrderCounts cco
GROUP BY
cco.customer_unique_id
ORDER BY
max_order_count DESC;


--Case 3: Satıcı Analizi
--Question 1 : Siparişleri en hızlı şekilde müşterilere ulaştıran satıcılar kimlerdir? Top 5 getiriniz. Bu satıcıların order sayıları ile ürünlerindeki yorumlar ve puanlamaları inceleyiniz ve yorumlayınız.

SELECT
oi.seller_id,
s.seller_city,
AVG(EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_approved_at)) / 86400) AS avg_delivery_days,
COUNT(DISTINCT o.order_id) AS total_orders
FROM
order_items oi
JOIN
orders o ON oi.order_id = o.order_id
JOIN
sellers s ON oi.seller_id = s.seller_id
WHERE
o.order_status = 'delivered'
GROUP BY
oi.seller_id, s.seller_city
HAVING
COUNT(DISTINCT o.order_id) > 20
ORDER BY
avg_delivery_days
LIMIT 5;

/*
•	Limitsiz olarak diğer satıcılarında ortalama teslimat sürelerini de incelediğim de ortalama olarak 20 ve üzeri ürün satanlar yedi gün içerisinde teslim ederken burada ki satıcılar beş gün içerisinde teslim ediyor. 
•	Yine aynı şekilde 50 ve üzeri siparişler de diğer satıcılar neredeyse dokuz gün içerisinde teslim ederken burada ki satıcılar daha kısa sürede teslim ediyorlar sattıkları ürün sayısına göre.
•	Elimizde yeterince bilgi olmadığı için tam çıkarım yapmak doğru olmasa da araştırmalarım sonucunda bu satıcıların şehirlerinin São Paulo eyaletine bağlı olduğunu gördüm. Metropol olan bu eyalette kargo sisteminin daha çok geliştiğini ve birçok farklı kargo gönderim şirketinin olmasından kaynaklandığını düşünüyorum. 
*/

--Question 2 : Hangi satıcılar daha fazla kategoriye ait ürün satışı yapmaktadır? 
--Fazla kategoriye sahip satıcıların order sayıları da fazla mı? 

SELECT
s.seller_id,
s.seller_city,
p.product_category_name,
COUNT(oi.order_item_id) AS total_sales
FROM
order_items oi
JOIN
products p ON oi.product_id = p.product_id
JOIN
sellers s ON oi.seller_id = s.seller_id
--WHERE
--s.seller_id = '1f50f920176fa81dab994f9023523100'
GROUP BY
s.seller_id, s.seller_city, p.product_category_name
ORDER BY
total_sales DESC;

--Yorum satırına aldığım WHERE şartı ile bir kaç satıcıyı kontrol ettiğim de fazla kategoriye sahip satıcıların order sayıları da fazla.

--Case 4 : Payment Analizi
--Question 1 : Ödeme yaparken taksit sayısı fazla olan kullanıcılar en çok hangi bölgede yaşamaktadır? Bu çıktıyı yorumlayınız.

SELECT
c.customer_state,
c.customer_city,
AVG(op.payment_installments) AS avg_installments
FROM
order_payments op
JOIN
orders o ON op.order_id = o.order_id
JOIN
customers c ON o.customer_id = c.customer_id
GROUP BY
c.customer_state, c.customer_city
ORDER BY
avg_installments DESC
LIMIT 100;

--Question 2 : Ödeme tipine göre başarılı order sayısı ve toplam başarılı ödeme tutarını hesaplayınız. En çok kullanılan ödeme tipinden en az olana göre sıralayınız.

SELECT
op.payment_type,
COUNT(DISTINCT o.order_id) AS successful_order_count,
SUM(op.payment_value) AS total_successful_payment_amount
FROM
order_payments op
JOIN
orders o ON op.order_id = o.order_id
WHERE
o.order_status = 'delivered'
AND op.payment_type IS NOT NULL
GROUP BY
op.payment_type
ORDER BY
total_successful_payment_amount DESC;

--Question 3 : Tek çekimde ve taksitle ödenen siparişlerin kategori bazlı analizini yapınız. En çok hangi kategorilerde taksitle ödeme kullanılmaktadır?

SELECT
COALESCE(pc.product_category_name, 'unknown') AS product_category_name,
op.payment_type,
COUNT(DISTINCT oi.order_id) AS order_count,
SUM(oi.price) AS total_order_amount
FROM
order_items oi
JOIN
order_payments op ON oi.order_id = op.order_id
JOIN
products p ON oi.product_id = p.product_id
LEFT JOIN
product_category_name_translation pc ON p.product_category_name = pc.product_category_name
WHERE
op.payment_type IN ('credit_card', 'boleto') --boleto tek çekim kabul edilmiştir.
GROUP BY
COALESCE(pc.product_category_name, 'unknown'), op.payment_type
ORDER BY
product_category_name, order_count DESC;

/*
•	En çok taksit kullanılan kategori "cama_mesa_banho" kategorisidir. 
•	"beleza_saude"
•	"esporte_lazer"
*/

--Case 5 : RFM Analizi
--Recency hesaplarken bugünün tarihi değil en son sipariş tarihini baz alınız. 

--Recency 

SELECT
CustomerID,
MAX(InvoiceDate) AS LastPurchaseDate,
CURRENT_TIMESTAMP AS CurrentDate,
CURRENT_TIMESTAMP - MAX(InvoiceDate) AS Recency
FROM
rfm_data
GROUP BY
CustomerID;

--Frequency

SELECT
CustomerID,
COUNT(DISTINCT InvoiceNo) AS Frequency
FROM
rfm_data
GROUP BY
CustomerID
ORDER BY
Frequency DESC;

--Monetary

SELECT
CustomerID,
SUM(Quantity * UnitPrice) AS MonetaryValue
FROM
rfm_data
GROUP BY
CustomerID
ORDER BY
MonetaryValue DESC;

--Veri seti bu linkten alınmıştır, veriyi tanımak için linke girip inceleyebilirsiniz.   E-Commerce Data



