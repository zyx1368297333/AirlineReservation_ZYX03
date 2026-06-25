-- ============================================================
-- 航空订票系统 视图定义
-- 数据库: AirlineReservation_ZYX03
-- ============================================================

USE AirlineReservation_ZYX03;

-- 视图1: 旅客VIP信息视图
-- 通过连接Passenger和VipRule，动态获取旅客当前的VIP等级和折扣率
CREATE OR REPLACE VIEW v_passenger_vip_ZYX03 AS
SELECT
    p.passenger_id,
    p.name,
    p.id_type,
    p.id_number,
    p.phone,
    p.email,
    p.total_purchase_amount,
    v.vip_level,
    v.vip_discount,
    p.register_date
FROM Passenger_ZYX03 p
JOIN VipRule_ZYX03 v
    ON p.total_purchase_amount >= v.min_amount
    AND p.total_purchase_amount < v.max_amount + 0.01;

-- 视图2: 航班上座率视图
-- 展示每个航班的售票进度和上座率
CREATE OR REPLACE VIEW v_flight_occupancy_ZYX03 AS
SELECT
    f.flight_id,
    f.flight_number,
    f.flight_date,
    f.departure_city,
    f.arrival_city,
    f.airline,
    f.total_seats,
    f.available_seats,
    (f.total_seats - f.available_seats) AS sold_seats,
    ROUND((f.total_seats - f.available_seats) * 100.0 / f.total_seats, 2) AS occupancy_rate
FROM Flight_ZYX03 f;

-- 视图3: 购票明细视图
-- 完整展示购票记录，包含旅客姓名、航班信息和VIP折扣
CREATE OR REPLACE VIEW v_ticket_detail_ZYX03 AS
SELECT
    t.ticket_id,
    p.name                     AS passenger_name,
    f.flight_number,
    f.flight_date,
    f.departure_city,
    f.arrival_city,
    f.airline,
    t.seat_class,
    t.original_price,
    t.discount_amount,
    t.final_price,
    t.payment_status,
    t.purchase_date,
    t.seat_number,
    v.vip_level,
    v.vip_discount
FROM Ticket_ZYX03 t
JOIN Passenger_ZYX03 p ON t.passenger_id = p.passenger_id
JOIN Flight_ZYX03 f    ON t.flight_id = f.flight_id
JOIN v_passenger_vip_ZYX03 v ON p.passenger_id = v.passenger_id;

-- 视图4: 当前有效折扣视图
-- 筛选 start_date <= 今天 <= end_date 的折扣记录
CREATE OR REPLACE VIEW v_active_discount_ZYX03 AS
SELECT
    d.discount_id,
    f.flight_number,
    f.flight_date,
    f.departure_city,
    f.arrival_city,
    f.base_price,
    d.discount_rate,
    d.season_type,
    d.description,
    d.start_date,
    d.end_date
FROM Discount_ZYX03 d
JOIN Flight_ZYX03 f ON d.flight_id = f.flight_id
WHERE CURDATE() BETWEEN d.start_date AND d.end_date;
