-- ============================================================
-- 航空订票系统 七种复杂查询
-- 数据库: AirlineReservation_ZYX03
-- 说明: 每种查询包含查询语义说明、SQL代码。执行后截取结果即可。
-- ============================================================

USE AirlineReservation_ZYX03;

-- ============================================================
-- 查询1: 聚集函数查询 (COUNT / SUM / AVG / MAX / MIN)
-- 查询语义: 统计每个航空公司已售出机票的销售情况，包括售票数量、
--           售票总额、平均票价、最高票价和最低票价
-- ============================================================
SELECT
    f.airline                                 AS 航空公司,
    COUNT(t.ticket_id)                        AS 售票数量,
    COALESCE(SUM(t.final_price), 0)           AS 售票总额,
    COALESCE(ROUND(AVG(t.final_price), 2), 0) AS 平均票价,
    COALESCE(MAX(t.final_price), 0)           AS 最高票价,
    COALESCE(MIN(t.final_price), 0)           AS 最低票价
FROM Flight_ZYX03 f
LEFT JOIN Ticket_ZYX03 t
    ON f.flight_id = t.flight_id
    AND t.payment_status = '已支付'
GROUP BY f.airline
ORDER BY 售票总额 DESC;

-- ============================================================
-- 查询2: 分组查询 (GROUP BY + HAVING)
-- 查询语义: 统计每位已支付旅客的购票次数和累计消费金额，
--           只显示购票次数≥2的高频旅客
-- ============================================================
SELECT
    p.passenger_id            AS 旅客编号,
    p.name                    AS 旅客姓名,
    v.vip_level               AS VIP等级,
    COUNT(t.ticket_id)        AS 购票次数,
    SUM(t.final_price)        AS 累计消费金额
FROM Passenger_ZYX03 p
JOIN VipRule_ZYX03 v
    ON p.total_purchase_amount >= v.min_amount
    AND p.total_purchase_amount < v.max_amount + 0.01
JOIN Ticket_ZYX03 t
    ON p.passenger_id = t.passenger_id
    AND t.payment_status = '已支付'
GROUP BY p.passenger_id, p.name, v.vip_level
HAVING COUNT(t.ticket_id) >= 2
ORDER BY 累计消费金额 DESC;

-- ============================================================
-- 查询3: 自身连接查询 (SELF JOIN)
-- 查询语义: 查询同一天从同一城市出发的多个航班对，
--           用于发现航班时刻冲突或互补关系
-- ============================================================
SELECT
    f1.departure_city        AS 出发城市,
    f1.flight_date           AS 航班日期,
    f1.flight_number         AS 航班A,
    f1.airline               AS 航空公司A,
    f2.flight_number         AS 航班B,
    f2.airline               AS 航空公司B
FROM Flight_ZYX03 f1
JOIN Flight_ZYX03 f2
    ON f1.departure_city = f2.departure_city
    AND f1.flight_date   = f2.flight_date
    AND f1.flight_id     < f2.flight_id         -- 避免重复配对
ORDER BY f1.flight_date;

-- ============================================================
-- 查询4: 带有 ALL 谓词的查询
-- 查询语义: 查询基础票价高于所有"广州"出发航班基础票价的航班
--           (即票价高于任一广州始发航班的票价上限)
-- ============================================================
SELECT
    flight_number            AS 航班号,
    departure_city           AS 出发城市,
    arrival_city             AS 到达城市,
    base_price               AS 基础票价,
    airline                  AS 航空公司
FROM Flight_ZYX03
WHERE base_price > ALL (
    SELECT base_price
    FROM Flight_ZYX03
    WHERE departure_city = '广州'
)
ORDER BY base_price DESC;

-- ============================================================
-- 查询5: 用 NOT EXISTS 实现全称量词的查询
-- 查询语义: 查询购买了所有"中国国际航空"航班的旅客
--           全称量词: ∀x ∈ 中国国际航空航班, 旅客购买了x
--           SQL等价: NOT ∃x ∈ 中国国际航空航班, 旅客未购买x
--           中国国际航空共有2个航班(CA1234 07-15 + CA1234 07-16)，张伟均已购买
-- ============================================================
SELECT
    p.passenger_id           AS 旅客编号,
    p.name                   AS 旅客姓名,
    p.total_purchase_amount  AS 累计消费金额
FROM Passenger_ZYX03 p
WHERE NOT EXISTS (
    SELECT 1
    FROM Flight_ZYX03 f
    WHERE f.airline = '中国国际航空'
    AND NOT EXISTS (
        SELECT 1
        FROM Ticket_ZYX03 t
        WHERE t.passenger_id = p.passenger_id
        AND t.flight_id = f.flight_id
        AND t.payment_status = '已支付'
    )
);

-- ============================================================
-- 查询6: 用 NOT EXISTS 实现逻辑蕴涵的查询
-- 查询语义: 查询满足以下逻辑蕴涵条件的旅客——
--           "如果旅客购买了MU5678(航班号)的机票，
--            则该旅客一定也购买过CA1234(航班号)的机票"
--           逻辑蕴涵 P→Q ≡ ¬(P ∧ ¬Q) ≡ 不存在"买了MU5678却没买CA1234"的情况
-- ============================================================
SELECT
    p.passenger_id           AS 旅客编号,
    p.name                   AS 旅客姓名,
    p.total_purchase_amount  AS 累计消费金额
FROM Passenger_ZYX03 p
WHERE NOT EXISTS (
    SELECT 1
    FROM Ticket_ZYX03 t1
    WHERE t1.passenger_id = p.passenger_id
    AND t1.payment_status = '已支付'
    AND t1.flight_id IN (
        SELECT flight_id FROM Flight_ZYX03 WHERE flight_number = 'MU5678'
    )
    AND NOT EXISTS (
        SELECT 1
        FROM Ticket_ZYX03 t2
        WHERE t2.passenger_id = p.passenger_id
        AND t2.payment_status = '已支付'
        AND t2.flight_id IN (
            SELECT flight_id FROM Flight_ZYX03 WHERE flight_number = 'CA1234'
        )
    )
)
ORDER BY p.passenger_id;

-- ============================================================
-- 查询7: 基于派生表(子查询在FROM子句)的查询
-- 查询语义: 基于旅客购票统计派生表，关联旅客信息，
--           展示每位旅客的VIP等级、购票次数和累计消费金额
-- ============================================================
SELECT
    p.name                         AS 旅客姓名,
    v.vip_level                    AS VIP等级,
    v.vip_discount                 AS VIP折扣率,
    COALESCE(ts.ticket_count, 0)   AS 购票次数,
    COALESCE(ts.total_spent, 0)    AS 本次统计消费,
    p.total_purchase_amount        AS 历史累计总额
FROM Passenger_ZYX03 p
JOIN VipRule_ZYX03 v
    ON p.total_purchase_amount >= v.min_amount
    AND p.total_purchase_amount < v.max_amount + 0.01
LEFT JOIN (
    SELECT
        passenger_id,
        COUNT(*)                   AS ticket_count,
        SUM(final_price)           AS total_spent
    FROM Ticket_ZYX03
    WHERE payment_status = '已支付'
    GROUP BY passenger_id
) AS ts
    ON p.passenger_id = ts.passenger_id
ORDER BY p.total_purchase_amount DESC;
