/* Maksimum sipariş sayısına sahip ilk 3 müşteriyi bulun. */
select top 3 Cust_ID, count(Order_Quantity) order_count
from e_commerce_data
group by Cust_ID
order by count(Order_Quantity) desc;

/*Siparişinin kargoya verilmesi maksimum süreyi alan müşteriyi bulun.*/
select Top 1 Cust_ID, datediff(day,Order_Date,Ship_Date) day_diff
from e_commerce_data
order by datediff(day,Order_Date,Ship_Date) desc;

/*Ocak ayındaki toplam tekil müşteri sayısını ve bunlardan kaç tanesinin 2011 yılının her bir ayında tekrar geri geldiğini sayın.*/
WITH T1 AS (
    SELECT
        Cust_ID
    FROM
        e_commerce_data
    WHERE
        Month(Order_Date) = 1
        AND year(Order_Date) = 2011
    GROUP BY
        Cust_ID
),
T2 AS (
    SELECT
        Cust_ID,
        Month(Order_Date) AS order_month,
        ROW_NUMBER() OVER (PARTITION BY Cust_ID ORDER BY Order_Date ASC) AS return_sequence
    FROM
        e_commerce_data
    WHERE
        year(Order_Date) = 2011
)
SELECT
    T2.order_month,
    COUNT(T1.Cust_ID) AS total_unique_customers,
    COUNT(T2.Cust_ID) AS returned_customers
FROM
    T1
LEFT JOIN
    T2 ON T1.Cust_ID = T2.Cust_ID AND T2.return_sequence > 1
GROUP BY
    T2.order_month;
/*Bu kod, Ocak ayında eşsiz müşteri sayısını ve bu müşterilerin 2011'in her bir ayında tekrar geri döndüğü durumu hesaplar. 
T1 CTE'sinde Ocak 2011'de sipariş veren müşterilerin kimliklerini alır, T2 CTE'sinde her müşterinin sipariş tarihlerini ve hangi sırayla geri döndüklerini belirler. 
Sonra T1 ve T2 CTE'leri birleştirilir ve her ay için eşsiz müşteri sayısı ve geri dönen müşteri sayısı hesaplanır.*/

/* 4. Her kullanıcı için ilk satın alma ile üçüncü satın alma arasında geçen süreyi Müşteri Kimliğine göre artan sırada döndürecek bir sorgu yazın.*/
WITH CustomerFirstPurchase AS (
    SELECT
        Cust_ID,
        MIN(Order_Date) AS first_purchase_date
    FROM
        e_commerce_data
    GROUP BY
        Cust_ID
),
CustomerThirdPurchase AS (
    SELECT
        Cust_ID,
        Order_Date,
        ROW_NUMBER() OVER (PARTITION BY Cust_ID ORDER BY Order_Date ASC) AS purchase_sequence
    FROM
        e_commerce_data
)
SELECT
    cfp.Cust_ID,
    DATEDIFF(day, cfp.first_purchase_date, ctp.Order_Date) AS days_between_first_and_third_purchase
FROM
    CustomerFirstPurchase cfp
JOIN
    CustomerThirdPurchase ctp ON cfp.Cust_ID = ctp.Cust_ID
WHERE
    ctp.purchase_sequence = 3
ORDER BY
    cfp.Cust_ID;
/*Bu sorgu, CustomerFirstPurchase adlı bir CTE oluşturur ve her müşterinin ilk satın alma tarihini bulur. 
Ardından, CustomerThirdPurchase adlı başka bir CTE oluşturur ve her müşterinin üçüncü satın alma tarihini ve bu satın alma sırasını bulur. 
Son olarak, bu iki CTE'yi birleştirir ve her müşteri için ilk ve üçüncü satın alma arasındaki gün sayısını hesaplar. 
Bu sorgu, müşteri kimliğine göre sonuçları artan sırayla döndürecektir.*/


/*5. Hem ürün 11'i hem de ürün 14'ü satın alan müşterileri ve bu ürünlerin müşterinin satın aldığı toplam ürün sayısına oranını döndüren bir sorgu yazın. */
WITH CustomerProductCounts AS (
    SELECT
        Cust_ID,
        COUNT(*) AS total_products
    FROM
        e_commerce_data
    GROUP BY
        Cust_ID
),
Product11Customers AS (
    SELECT DISTINCT
        Cust_ID
    FROM
        e_commerce_data
    WHERE
        Prod_ID = 'Prod_11'
),
Product14Customers AS (
    SELECT DISTINCT
        Cust_ID
    FROM
        e_commerce_data
    WHERE
        Prod_ID = 'Prod_14'
)
SELECT
    COUNT(DISTINCT pc11.Cust_ID) AS product_11_customers,
    COUNT(DISTINCT pc14.Cust_ID) AS product_14_customers,
    cp.total_products,
    ROUND((COUNT(DISTINCT pc11.Cust_ID) + COUNT(DISTINCT pc14.Cust_ID)) * 100.0 / MAX(cp.total_products), 2) AS product_ratio_percentage
FROM
    Product11Customers pc11
JOIN
    Product14Customers pc14 ON pc11.Cust_ID = pc14.Cust_ID
JOIN
    CustomerProductCounts cp ON pc11.Cust_ID = cp.Cust_ID
GROUP BY
    cp.total_products;
	/*
	
Tablodaki her müşterinin toplam satın aldığı ürün sayısını belirlemek için bir CTE (Common Table Expression) oluşturdum ve bu CTE'yi "CustomerProductCounts" adı altında adlandırdım. 
Ardından, ürün 11'i satın alan müşterileri bulmak için bir başka CTE oluşturdum ve bu CTE'yi "Product11Customers" olarak adlandırdım. 
Benzer şekilde, ürün 14'ü satın alan müşterileri bulmak için başka bir CTE oluşturdum ve bu CTE'yi "Product14Customers" olarak adlandırdım.
Daha sonra, her iki ürünü de satın alan müşteri sayılarını ve toplam satın alınan ürün sayısını hesaplamak için bu üç CTE'yi birleştirdim. 
Ancak, bu birleştirmeyi yaparken, total_products sütununu GROUP BY ifadesine eklemeyi unuttum. 
Bu nedenle, SQL sorgusu, total_products sütununu gruplama işlemi olmadan seçmeye çalıştığı için bir hata verdi.
Son olarak, sorguyu düzeltmek için GROUP BY ifadesine total_products sütununu ekledim. 
Bu, SQL'e, total_products sütununu gruplaması ve sorgunun her bir grup için doğru sonuçları hesaplaması gerektiğini belirtir.
*/

/*
Müşteri Segmentasyonu
Müşterileri ziyaret sıklıklarına göre kategorize edin. Aşağıdaki adımlar size yol gösterecektir. İsterseniz siz de kendi yönteminizle takip edebilirsiniz.
1. Müşterilerin ziyaret günlüklerini aylık olarak tutan bir "görünüm" oluşturun. (Her günlük için üç alan tutulur: Cust_id, Yıl, Ay)
*/
CREATE VIEW MonthlyVisitLog AS
SELECT DISTINCT
    Cust_ID,
    YEAR(Order_Date) AS Year,
    MONTH(Order_Date) AS Month
FROM
    dbo.e_commerce_data

/* 2. Kullanıcıların aylık ziyaret sayısını tutan bir "görünüm" oluşturun. (Başlangıç işinden itibaren tüm ayları ayrı ayrı gösterin) */
CREATE VIEW MonthlyVisitCounts AS
SELECT
    Cust_ID,
    YEAR(Order_Date) AS Year,
    MONTH(Order_Date) AS Month,
    COUNT(*) AS VisitCount
FROM
    dbo.e_commerce_data
GROUP BY
    Cust_ID,
    YEAR(Order_Date),
    MONTH(Order_Date);

/* 3. Müşterilerin her ziyareti için, ziyaretin bir önceki veya bir sonraki ayını ayrı bir sütun olarak oluşturun. */

CREATE VIEW MonthlyVisitWithAdjacentMonths AS
SELECT 
    m.Cust_ID,
    m.Year,
    m.Month,
    m.VisitCount,
    COALESCE(mv.PreviousMonthVisits, 0) AS PreviousMonthVisits,
    COALESCE(mv2.NextMonthVisits, 0) AS NextMonthVisits
FROM 
    (
        SELECT
            Cust_ID,
            YEAR(Order_Date) AS Year,
            MONTH(Order_Date) AS Month,
            COUNT(*) AS VisitCount
        FROM
            dbo.e_commerce_data
        GROUP BY
            Cust_ID,
            YEAR(Order_Date),
            MONTH(Order_Date)
    ) m
LEFT JOIN (
    SELECT 
        Cust_ID,
        Year,
        Month,
        VisitCount AS PreviousMonthVisits
    FROM 
        (
            SELECT
                Cust_ID,
                YEAR(Order_Date) AS Year,
                MONTH(Order_Date) AS Month,
                COUNT(*) AS VisitCount
            FROM
                dbo.e_commerce_data
            GROUP BY
                Cust_ID,
                YEAR(Order_Date),
                MONTH(Order_Date)
        ) MonthlyVisitCounts
    WHERE 
        (Year = (SELECT DISTINCT Year FROM (SELECT YEAR(Order_Date) AS Year, MONTH(Order_Date) AS Month FROM dbo.e_commerce_data) AS SubQuery WHERE Month = 1) AND Month = 12)
    OR
        (Year = Year AND Month = Month - 1)
) mv ON m.Cust_ID = mv.Cust_ID AND m.Year = mv.Year AND m.Month = mv.Month
LEFT JOIN (
    SELECT 
        Cust_ID,
        Year,
        Month,
        VisitCount AS NextMonthVisits
    FROM 
        (
            SELECT
                Cust_ID,
                YEAR(Order_Date) AS Year,
                MONTH(Order_Date) AS Month,
                COUNT(*) AS VisitCount
            FROM
                dbo.e_commerce_data
            GROUP BY
                Cust_ID,
                YEAR(Order_Date),
                MONTH(Order_Date)
        ) MonthlyVisitCounts
    WHERE 
        (Year = (SELECT DISTINCT Year FROM (SELECT YEAR(Order_Date) AS Year, MONTH(Order_Date) AS Month FROM dbo.e_commerce_data) AS SubQuery WHERE Month = 12) AND Month = 1)
    OR
        (Year = Year AND Month = Month + 1)
) mv2 ON m.Cust_ID = mv2.Cust_ID AND m.Year = mv2.Year AND m.Month = mv2.Month;

/*
Bu sorgu, 'MonthlyVisitWithAdjacentMonths' adında bir görünüm oluşturur. 
Bu görünüm, e-ticaret sistemindeki müşterilerin aylık ziyaret sayılarıyla birlikte önceki ve sonraki ayların ziyaret sayıları hakkında bilgi sağlamak amacıyla tasarlanmıştır.
Sorgunun yaptığı işlemleri şu şekilde özetleyebilirim:
İlk olarak, alt sorgu (m) Order_Date'e dayalı olarak dbo.e_commerce_data tablosundan verileri gruplayarak her müşteri (Cust_ID), yıl (Year) ve ay (Month) için ziyaret sayılarını (VisitCount) hesaplar.
Ardından iki sol birleştirme işlemi gerçekleştirilir:
a. İlk sol birleştirme (mv), önceki ayın ziyaret sayılarını (PreviousMonthVisits) hesaplar. 
Bu, yıl ve ay bazında gruplanmış ziyaret sayılarını hesaplayan bir alt sorgu aracılığıyla yapılır. 
Sol birleştirme, mevcut ay verileri için eşleşme olmasa bile her kaydın (MonthlyVisitCounts) dahil edilmesini sağlar.
b. İkinci sol birleştirme (mv2), bir sonraki ayın ziyaret sayılarını (NextMonthVisits) hesaplar. 
Önceki sol birleştirmeyle benzer şekilde, yıl ve ay bazında gruplanmış ziyaret sayılarını hesaplayan bir alt sorgu aracılığıyla yapılır.
COALESCE fonksiyonu, NULL değerlerle başa çıkmak için kullanılır. Önceki veya sonraki aylarda ziyaret yoksa, 0 döndürülür.
Bu görünüm, MonthlyVisitWithAdjacentMonths, her müşterinin her aydaki ziyaret sayılarını ve geçerli olduğunda önceki ve sonraki ayların ziyaret sayılarını içeren kapsamlı bir veri seti sağlar.*/

/* 4. Her bir müşterinin iki ardışık ziyareti arasındaki aylık zaman aralığını hesaplayın. */

CREATE VIEW MonthlyVisitInterval AS
SELECT 
    Cust_ID,
    Year,
    Month,
    DATEDIFF(MONTH, LAG(Order_Date) OVER(PARTITION BY Cust_ID ORDER BY Year, Month), Order_Date) AS MonthlyInterval
FROM 
    (
        SELECT 
            Cust_ID,
            YEAR(Order_Date) AS Year,
            MONTH(Order_Date) AS Month,
            ROW_NUMBER() OVER(PARTITION BY Cust_ID ORDER BY YEAR(Order_Date), MONTH(Order_Date)) AS VisitNumber,
            Order_Date
        FROM 
            dbo.e_commerce_data
    ) AS Visits
WHERE 
    VisitNumber > 1;
/*her müşteri için ziyaretlerin ardışık olduğu durumları belirler ve ardışık ziyaretler arasındaki aylık zaman aralığını hesaplar. 
Sonuç olarak, her bir müşterinin, ardışık ziyaretler arasındaki ay farkını içeren bir veri seti elde edersiniz.*/
/* 5. Ortalama zaman aralıklarını kullanarak müşterileri kategorize edin. Sizin için en uygun etiketleme modelini seçin. 
Örneğin:
o Müşteri ilk satın alımını yaptıktan sonraki aylarda başka bir satın alım yapmadıysa kayıp olarak etiketlenir.
o Müşteri her ay bir satın alma işlemi gerçekleştirmişse düzenli olarak etiketlenir
*/
/*Ortalama zaman aralıklarını kullanarak müşterileri kategorize etmek için birkaç farklı etiketleme modeli düşünebiliriz. İşte bazı olası modeller:
Ziyaret Frekansına Göre Kategorizasyon: Müşterileri, ortalama ziyaret frekanslarına dayalı olarak düzenli, aralıklı ve seyrek ziyaret eden müşteriler olarak üç kategoriye ayırabiliriz.
Sadakat Seviyesine Göre Kategorizasyon: Ortalama ziyaret aralıklarına göre müşterileri sadakat seviyelerine göre kategorize edebiliriz. 
Daha sık ziyaret eden müşteriler sadık müşteriler olarak kabul edilirken, daha seyrek ziyaret edenler daha az sadık müşteriler olarak kabul edilebilir.
Yeniden Aktivasyon Potansiyeline Göre Kategorizasyon: Müşterileri, son ziyaretlerinden bu yana geçen ortalama zaman aralıklarına göre, aktif, uyuyan ve kayıp müşteriler olmak üzere üç kategoriye ayırabiliriz. 
Bu, yeniden pazarlama stratejilerini belirlemede yardımcı olabilir.
Sezonluk Davranışa Göre Kategorizasyon: Müşterileri, belirli sezonlarda veya zaman dilimlerindeki ortalama ziyaret aralıklarına göre kategorize edebiliriz. 
Örneğin, yaz aylarında daha sık ziyaret edenlerle kış aylarında daha az ziyaret edenleri ayırt edebiliriz. 
Örneğin, müşteri sadakatini artırmak istiyorsanız, sadakat seviyesine göre kategorizasyon modeli daha uygun olabilir. 
Müşterilerinizi daha sık ziyaret etmeleri için teşvik etmek istiyorsanız, ziyaret frekansına göre kategorizasyon modeli daha uygun olabilir.*/
/*
Sadakat seviyesine göre kategorizasyon yapmak için müşterileri sık, orta ve seyrek ziyaret eden müşteriler olmak üzere üç gruba ayırabiliriz. 
Bu gruplar, müşterilerin ortalama ziyaret aralıklarına göre belirlenecektir. İşte bu kategorizasyon modelini uygulamak için adımlar:
Ortalama Ziyaret Aralıklarının Hesaplanması: Her müşteri için ortalama ziyaret aralığı hesaplanır.
Kategorizasyonun Gerçekleştirilmesi: Ortalama ziyaret aralıklarına göre müşteriler sık, orta veya seyrek ziyaret eden müşteriler olarak kategorize edilir.
Sonuçların Değerlendirilmesi ve Etiketlemenin Uygulanması: Her müşteriye uygun kategori etiketi atanır. */
SELECT
    Cust_ID,
    CASE
        WHEN AvgVisitInterval <= 30 THEN 'Sık Ziyaret Eden'
        WHEN AvgVisitInterval <= 60 THEN 'Orta Ziyaret Eden'
        ELSE 'Seyrek Ziyaret Eden'
    END AS LoyaltyLevel
FROM
    (
        SELECT
            Cust_ID,
            AVG(MonthlyInterval) AS AvgVisitInterval
        FROM
            MonthlyVisitInterval
        GROUP BY
            Cust_ID
    ) AS AvgIntervals;
/*Bu sorgu, her müşteri için ortalama ziyaret aralığını hesaplar ve ardından bu ortalama aralığa göre müşterileri "Sık Ziyaret Eden", "Orta Ziyaret Eden" ve "Seyrek Ziyaret Eden" olmak üzere üç gruba ayırır.
Bu gruplamayı müşterilere uygun kategori etiketlerini atamak için kullanabilirsiniz.*/
SELECT
    Cust_ID,
    CASE
        WHEN AVG(MonthlyInterval) <= 2 THEN 'Yaz Aylarında Sık Ziyaret Eden'
        WHEN AVG(MonthlyInterval) <= 4 THEN 'Kış Aylarında Orta Ziyaret Eden'
        ELSE 'Diğer Zamanlarda Seyrek Ziyaret Eden'
    END AS SeasonalBehavior
FROM
    MonthlyVisitInterval
GROUP BY
    Cust_ID;
/*Bu sorgu, müşterileri yaz aylarında sık ziyaret edenlerle kış aylarında orta ziyaret edenler olarak kategorize eder. Müşterileri uygun kategori etiketleriyle gruplar.*/

/*Ay Bazında Elde Tutma Oranı
İşletmenin başlangıcından bu yana ay bazında müşteri tutma oranını bulun.
Elde Tutma Oranının hesaplanmasında birçok farklı varyasyon vardır. Ancak biz bu projede ay bazında elde tutma oranını hesaplamaya çalışacağız.
Yani, bir önceki aydaki müşterilerin kaçının bir sonraki ay elde tutulabileceği ile ilgileneceğiz.
"Görünümler" oluşturarak adım adım ilerleyin. Müşteri Segmentasyonu bölümünün sonunda elde ettiğiniz görünümü kaynak olarak kullanabilirsiniz.*/
/*1. Ay bazında elde tutulan müşteri sayısını bulun. (Zaman aralıklarını kullanabilirsiniz)*/
/*Ay bazında elde tutulan müşteri sayısını bulmak için, her aydaki müşterileri bir önceki aydaki müşterilerle karşılaştırmamız gerekir. 
Aylık Müşteri Sayıları için Bir Görünüm Oluşturun: Her ay için benzersiz müşteri sayısını içeren bir görünüm oluşturacağız.
Bu görünüm bize her ay için benzersiz müşteri sayısını verecektir.*/

CREATE VIEW MonthlyCustomerCounts AS
SELECT
    Year,
    Month,
    COUNT(DISTINCT Cust_ID) AS CustomerCount
FROM
    MonthlyVisitLog
GROUP BY
    Year,
    Month;
/*Elde Tutulan Müşteri Sayısını Bulun: Daha sonra, ardışık aylar arasındaki müşteri sayılarını karşılaştırmak ve elde tutulan müşteri sayısını bulmak için bu görünümü kendisiyle birleştireceğiz.
Bu görünüm bize her ay için bir önceki aydan kalan müşteri sayısını verecektir.*/
CREATE VIEW MonthlyRetention AS
SELECT
    current_month.Year AS Year,
    current_month.Month AS Month,
    current_month.CustomerCount AS CurrentMonthCustomerCount,
    COALESCE(previous_month.CustomerCount, 0) AS PreviousMonthCustomerCount,
    COALESCE(current_month.CustomerCount - previous_month.CustomerCount, 0) AS RetainedCustomers
FROM
    MonthlyCustomerCounts current_month
LEFT JOIN
    MonthlyCustomerCounts previous_month ON current_month.Year = previous_month.Year AND current_month.Month = previous_month.Month + 1;

/*2. Ay bazında elde tutma oranını hesaplayın.
Ay Bazında Elde Tutma Oranı = 1.0 * Mevcut Ayda Elde Tutulan Müşteri Sayısı / Önceki Aydaki Toplam Müşteri Sayısı */
/*Ay bazında elde tutma oranını hesaplamak için, önceki adımda oluşturulan MonthlyRetention görünümündeki bilgileri kullanacağız. 
Mevcut aydaki elde tutulan müşteri sayısını bir önceki aydaki toplam müşteri sayısına böleceğiz.*/
CREATE VIEW MonthlyRetentionRate AS
SELECT
    Year,
    Month,
    1.0 * RetainedCustomers / PreviousMonthCustomerCount AS RetentionRate
FROM
    MonthlyRetention;
/*mevcut aydaki elde tutulan müşteri sayısını bir önceki aydaki toplam müşteri sayısına bölerek bize ay bazında elde tutma oranını verecektir.*/

