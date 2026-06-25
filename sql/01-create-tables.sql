-- ============================================================
-- 航空订票系统 数据库设计
-- 数据库名称: AirlineReservation_ZYX03
-- DBMS: MySQL
-- ============================================================

-- 1. 创建数据库
DROP DATABASE IF EXISTS AirlineReservation_ZYX03;
CREATE DATABASE AirlineReservation_ZYX03
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE AirlineReservation_ZYX03;

-- ============================================================
-- 2. 创建数据表
-- ============================================================

-- 2.1 航班表
CREATE TABLE Flight_ZYX03 (
    flight_id        INT             NOT NULL AUTO_INCREMENT  COMMENT '航班编号(主码)',
    flight_number    VARCHAR(20)     NOT NULL                 COMMENT '航班号,如CA1234',
    flight_date      DATE            NOT NULL                 COMMENT '航班日期',
    departure_city   VARCHAR(50)     NOT NULL                 COMMENT '出发城市',
    arrival_city     VARCHAR(50)     NOT NULL                 COMMENT '到达城市',
    departure_time   TIME            NOT NULL                 COMMENT '计划出发时间',
    arrival_time     TIME            NOT NULL                 COMMENT '计划到达时间',
    total_seats      INT             NOT NULL                 COMMENT '总座位数',
    available_seats  INT             NOT NULL                 COMMENT '可用座位数',
    base_price       DECIMAL(10,2)   NOT NULL                 COMMENT '经济舱基础票价(元)',
    airline          VARCHAR(50)     NOT NULL                 COMMENT '航空公司名称',
    status           VARCHAR(20)     NOT NULL DEFAULT '计划'  COMMENT '航班状态(计划/取消/完成)',
    PRIMARY KEY (flight_id),
    UNIQUE KEY uk_flight_no_date (flight_number, flight_date),
    CHECK (available_seats >= 0 AND available_seats <= total_seats),
    CHECK (base_price > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='航班表';

-- 2.2 折扣表
CREATE TABLE Discount_ZYX03 (
    discount_id     INT             NOT NULL AUTO_INCREMENT  COMMENT '折扣编号(主码)',
    flight_id       INT             NOT NULL                 COMMENT '航班编号(外码)',
    discount_rate   DECIMAL(3,2)    NOT NULL                 COMMENT '折扣率(0.01~1.00)',
    start_date      DATE            NOT NULL                 COMMENT '折扣生效起始日期',
    end_date        DATE            NOT NULL                 COMMENT '折扣截止日期',
    description     VARCHAR(200)    DEFAULT NULL             COMMENT '折扣描述',
    season_type     VARCHAR(20)     NOT NULL                 COMMENT '季节类型(旺季/淡季/平季)',
    PRIMARY KEY (discount_id),
    FOREIGN KEY (flight_id) REFERENCES Flight_ZYX03(flight_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CHECK (discount_rate > 0 AND discount_rate <= 1.00),
    CHECK (end_date >= start_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='折扣表';

-- 2.3 旅客表
CREATE TABLE Passenger_ZYX03 (
    passenger_id           INT             NOT NULL AUTO_INCREMENT  COMMENT '旅客编号(主码)',
    name                   VARCHAR(50)     NOT NULL                 COMMENT '旅客姓名',
    id_type                VARCHAR(20)     NOT NULL                 COMMENT '证件类型(身份证/护照/军官证)',
    id_number              VARCHAR(50)     NOT NULL                 COMMENT '证件号码',
    phone                  VARCHAR(20)     NOT NULL                 COMMENT '联系电话',
    email                  VARCHAR(100)    DEFAULT NULL             COMMENT '电子邮箱',
    total_purchase_amount  DECIMAL(12,2)   NOT NULL DEFAULT 0.00    COMMENT '历史购票总金额',
    register_date          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '注册时间',
    PRIMARY KEY (passenger_id),
    UNIQUE KEY uk_id_number (id_number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='旅客表';

-- 2.4 VIP规则表 (来自3NF规范化分解)
CREATE TABLE VipRule_ZYX03 (
    vip_level       VARCHAR(20)     NOT NULL                 COMMENT 'VIP等级(主码)',
    min_amount      DECIMAL(12,2)   NOT NULL                 COMMENT '最低累计金额(含)',
    max_amount      DECIMAL(12,2)   NOT NULL                 COMMENT '最高累计金额(不含边界处理)',
    vip_discount    DECIMAL(3,2)    NOT NULL                 COMMENT 'VIP折扣率',
    PRIMARY KEY (vip_level),
    CHECK (vip_discount > 0 AND vip_discount <= 1.00),
    CHECK (min_amount >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='VIP规则表';

-- 2.5 购票记录表
CREATE TABLE Ticket_ZYX03 (
    ticket_id       INT             NOT NULL AUTO_INCREMENT  COMMENT '机票编号(主码)',
    passenger_id    INT             NOT NULL                 COMMENT '旅客编号(外码)',
    flight_id       INT             NOT NULL                 COMMENT '航班编号(外码)',
    purchase_date   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '购票时间',
    seat_class      VARCHAR(20)     NOT NULL                 COMMENT '舱位等级(经济舱/商务舱/头等舱)',
    original_price  DECIMAL(10,2)   NOT NULL                 COMMENT '原价',
    discount_amount DECIMAL(10,2)   NOT NULL DEFAULT 0.00    COMMENT '折扣金额',
    final_price     DECIMAL(10,2)   NOT NULL                 COMMENT '最终支付价',
    payment_status  VARCHAR(20)     NOT NULL DEFAULT '已支付' COMMENT '支付状态(已支付/待支付/已退款)',
    seat_number     VARCHAR(10)     DEFAULT NULL             COMMENT '座位号',
    PRIMARY KEY (ticket_id),
    FOREIGN KEY (passenger_id) REFERENCES Passenger_ZYX03(passenger_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (flight_id) REFERENCES Flight_ZYX03(flight_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CHECK (final_price >= 0),
    CHECK (discount_amount >= 0),
    CHECK (original_price >= final_price)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='购票记录表';
