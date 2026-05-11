-- =============================================================================
-- script_golikov_a_08.sql — исправленная версия (февраль 2026)
-- =============================================================================

-- =============================================================================
-- 1. Очистка (без изменений)
-- =============================================================================
DROP TABLE IF EXISTS Shipments_golikov_a_08 CASCADE;
DROP TABLE IF EXISTS Cargo        CASCADE;
DROP TABLE IF EXISTS Employee     CASCADE;
DROP TABLE IF EXISTS Point        CASCADE;
DROP TABLE IF EXISTS Client       CASCADE;

DROP VIEW  IF EXISTS v_cargo_status;
DROP VIEW  IF EXISTS v_reports_income;
DROP VIEW  IF EXISTS v_warehouse_load;

DROP FUNCTION IF EXISTS trig_check_slot();
DROP FUNCTION IF EXISTS trig_update_date_on_status_change();
DROP FUNCTION IF EXISTS get_shipments_by_point(VARCHAR);
DROP FUNCTION IF EXISTS calculate_total_price(DECIMAL, VARCHAR, VARCHAR, BOOLEAN, BOOLEAN);

DROP PROCEDURE IF EXISTS proc_insert_client(VARCHAR, VARCHAR, VARCHAR, VARCHAR);
DROP PROCEDURE IF EXISTS proc_update_client(VARCHAR, VARCHAR, VARCHAR, VARCHAR);
DROP PROCEDURE IF EXISTS proc_delete_client(VARCHAR);

DROP PROCEDURE IF EXISTS proc_insert_point(VARCHAR, VARCHAR, VARCHAR);
DROP PROCEDURE IF EXISTS proc_update_point(VARCHAR, VARCHAR, VARCHAR);
DROP PROCEDURE IF EXISTS proc_delete_point(VARCHAR);

DROP PROCEDURE IF EXISTS proc_insert_employee(VARCHAR, VARCHAR, VARCHAR, VARCHAR);
DROP PROCEDURE IF EXISTS proc_update_employee(VARCHAR, VARCHAR, VARCHAR, VARCHAR);
DROP PROCEDURE IF EXISTS proc_delete_employee(VARCHAR);

DROP PROCEDURE IF EXISTS proc_insert_cargo(VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, DECIMAL, DECIMAL, DECIMAL, BOOLEAN, BOOLEAN);
DROP PROCEDURE IF EXISTS proc_update_cargo(VARCHAR, VARCHAR, VARCHAR, DECIMAL, DECIMAL, DECIMAL, BOOLEAN, BOOLEAN);
DROP PROCEDURE IF EXISTS proc_delete_cargo(VARCHAR);

DROP PROCEDURE IF EXISTS proc_insert_shipment(VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, DATE);
DROP PROCEDURE IF EXISTS proc_update_shipment(VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, DATE);

DROP PROCEDURE IF EXISTS proc_archive_shipment(VARCHAR);
DROP PROCEDURE IF EXISTS proc_delete_shipment(VARCHAR, VARCHAR);

-- =============================================================================
-- 2. Таблицы (без изменений)
-- =============================================================================

CREATE TABLE Client (
    client_phone    VARCHAR(20) PRIMARY KEY,
    address         VARCHAR(200),
    fio             VARCHAR(200) NOT NULL UNIQUE,
    password        VARCHAR(100),
    CONSTRAINT valid_phone CHECK (client_phone ~ '^\+?[1-9]\d{1,14}$')
);

CREATE TABLE Point (
    point_name      VARCHAR(100) PRIMARY KEY,
    point_phone     VARCHAR(20),
    point_address   VARCHAR(200)
);

CREATE TABLE Employee (
    employee_fio    VARCHAR(100) PRIMARY KEY,
    position        VARCHAR(50) NOT NULL,
    phone           VARCHAR(20) CHECK (phone ~ '^\+?[1-9]\d{1,14}$'),
    password        VARCHAR(100)
);

CREATE TABLE Cargo (
    cargo_track     VARCHAR(50) PRIMARY KEY,
    cargo_type      VARCHAR(50) NOT NULL 
        CHECK (cargo_type IN ('мелкий', 'средний', 'крупный', 'документный')),
    delivery_type   VARCHAR(50) NOT NULL 
        CHECK (delivery_type IN ('стандартная', 'срочная', 'экспресс')),
    sender_phone    VARCHAR(20) REFERENCES Client(client_phone),
    receiver_phone  VARCHAR(20) REFERENCES Client(client_phone),
    total_price     DECIMAL(12,2) CHECK (total_price >= 0),
    cargo_mass      DECIMAL(10,2) CHECK (cargo_mass > 0 OR cargo_type = 'документный'),
    cargo_value     DECIMAL(12,2) CHECK (cargo_value >= 0),
    packaging       BOOLEAN NOT NULL DEFAULT FALSE,
    insurance       BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE Shipments_golikov_a_08 (
    cargo_track     VARCHAR(50) NOT NULL REFERENCES Cargo(cargo_track) ON DELETE CASCADE,
    point_name      VARCHAR(100) NOT NULL REFERENCES Point(point_name),
    slot            VARCHAR(50) NOT NULL,
    status          VARCHAR(50) NOT NULL DEFAULT 'занято'
        CHECK (status IN ('занято', 'в пути', 'доставлено', 'проблема')),
    employee_fio    VARCHAR(100) REFERENCES Employee(employee_fio),
    update_date     DATE NOT NULL DEFAULT CURRENT_DATE,
    PRIMARY KEY (cargo_track, point_name)
);

-- =============================================================================
-- 3. Триггеры и функции
-- =============================================================================

CREATE OR REPLACE FUNCTION trig_check_slot() RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM Shipments_golikov_a_08 
        WHERE point_name = NEW.point_name 
          AND slot = NEW.slot 
          AND cargo_track != NEW.cargo_track
          AND status = 'занято'
    ) THEN
        RAISE EXCEPTION 'Слот % уже занят на пункте %', NEW.slot, NEW.point_name;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_slot
BEFORE INSERT OR UPDATE ON Shipments_golikov_a_08
FOR EACH ROW EXECUTE FUNCTION trig_check_slot();

CREATE OR REPLACE FUNCTION trig_update_date_on_status_change() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status IS DISTINCT FROM OLD.status THEN
        NEW.update_date = CURRENT_DATE;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_date_status
BEFORE UPDATE ON Shipments_golikov_a_08
FOR EACH ROW EXECUTE FUNCTION trig_update_date_on_status_change();

-- =============================================================================
-- 4. Важная функция расчёта цены (была пропущена)
-- =============================================================================

CREATE OR REPLACE FUNCTION calculate_total_price(
    mass_kg         DECIMAL,
    cargo_type      VARCHAR,
    delivery_type   VARCHAR,
    packaging       BOOLEAN,
    insurance       BOOLEAN
) RETURNS DECIMAL AS $$
DECLARE
    base_price      DECIMAL := 0;
    mass_factor     DECIMAL := COALESCE(mass_kg, 0);
    type_coeff      DECIMAL := 1.0;
    delivery_coeff  DECIMAL := 1.0;
    extra           DECIMAL := 0;
BEGIN
    -- Базовая цена по типу груза
    base_price := CASE cargo_type
        WHEN 'документный' THEN 300
        WHEN 'мелкий'      THEN 450
        WHEN 'средний'     THEN 800
        WHEN 'крупный'     THEN 1500
        ELSE 500
    END;

    -- Коэффициент по типу доставки
    delivery_coeff := CASE delivery_type
        WHEN 'стандартная' THEN 1.0
        WHEN 'срочная'     THEN 1.6
        WHEN 'экспресс'    THEN 2.4
        ELSE 1.0
    END;

    -- Дополнительно за массу (после 1 кг)
    IF mass_factor > 1 THEN
        extra := extra + (mass_factor - 1) * 120;
    END IF;

    -- Упаковка и страховка
    IF packaging THEN extra := extra + 150; END IF;
    IF insurance  THEN extra := extra + GREATEST(base_price * 0.05, 200); END IF;

    RETURN ROUND((base_price + extra) * delivery_coeff * type_coeff, 2);
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- 5. Представления
-- =============================================================================

CREATE VIEW v_cargo_status AS
SELECT 
    c.cargo_track,
    sh.point_name,
    sh.slot,
    sh.status,
    sh.employee_fio,
    sh.update_date
FROM Cargo c
JOIN Shipments_golikov_a_08 sh ON c.cargo_track = sh.cargo_track
ORDER BY c.cargo_track, sh.update_date;

CREATE VIEW v_warehouse_load AS
SELECT 
    point_name,
    COUNT(*) FILTER (WHERE status = 'занято') AS occupied_slots,
    COUNT(*) AS total_shipments
FROM Shipments_golikov_a_08
GROUP BY point_name;

CREATE VIEW v_reports_income AS
SELECT 
    DATE_TRUNC('month', update_date) AS period,
    SUM(c.total_price) AS income,
    COUNT(DISTINCT c.cargo_track) AS shipments_count,
    AVG(c.total_price) AS avg_price,
    c.cargo_type
FROM Cargo c
JOIN Shipments_golikov_a_08 sh ON c.cargo_track = sh.cargo_track
WHERE sh.status = 'доставлено'
GROUP BY period, c.cargo_type
ORDER BY period DESC, cargo_type;

-- =============================================================================
-- 6. Процедуры (без изменений)
-- =============================================================================

-- Клиенты
CREATE OR REPLACE PROCEDURE proc_insert_client(p_phone VARCHAR, p_address VARCHAR, p_fio VARCHAR, p_password VARCHAR)
LANGUAGE SQL AS $$ INSERT INTO Client VALUES (p_phone, p_address, p_fio, p_password); $$;

CREATE OR REPLACE PROCEDURE proc_update_client(p_phone VARCHAR, p_new_address VARCHAR, p_new_fio VARCHAR, p_new_password VARCHAR)
LANGUAGE SQL AS $$
    UPDATE Client SET
        address  = COALESCE(p_new_address, address),
        fio      = COALESCE(p_new_fio,     fio),
        password = COALESCE(p_new_password, password)
    WHERE client_phone = p_phone;
$$;

CREATE OR REPLACE PROCEDURE proc_delete_client(p_phone VARCHAR)
LANGUAGE SQL AS $$ DELETE FROM Client WHERE client_phone = p_phone; $$;

-- Пункты, сотрудники, грузы, отгрузки — аналогично (оставляем как было)

CREATE OR REPLACE PROCEDURE proc_insert_point(p_name VARCHAR, p_phone VARCHAR, p_address VARCHAR)
LANGUAGE SQL AS $$ INSERT INTO Point VALUES (p_name, p_phone, p_address); $$;

CREATE OR REPLACE PROCEDURE proc_update_point(p_name VARCHAR, p_new_phone VARCHAR, p_new_address VARCHAR)
LANGUAGE SQL AS $$
    UPDATE Point SET
        point_phone   = COALESCE(p_new_phone,   point_phone),
        point_address = COALESCE(p_new_address, point_address)
    WHERE point_name = p_name;
$$;

CREATE OR REPLACE PROCEDURE proc_delete_point(p_name VARCHAR)
LANGUAGE SQL AS $$ DELETE FROM Point WHERE point_name = p_name; $$;

CREATE OR REPLACE PROCEDURE proc_insert_employee(p_fio VARCHAR, p_position VARCHAR, p_phone VARCHAR, p_password VARCHAR)
LANGUAGE SQL AS $$ INSERT INTO Employee VALUES (p_fio, p_position, p_phone, p_password); $$;

CREATE OR REPLACE PROCEDURE proc_update_employee(p_fio VARCHAR, p_new_position VARCHAR, p_new_phone VARCHAR, p_new_password VARCHAR)
LANGUAGE SQL AS $$
    UPDATE Employee SET
        position = COALESCE(p_new_position, position),
        phone    = COALESCE(p_new_phone,    phone),
        password = COALESCE(p_new_password, password)
    WHERE employee_fio = p_fio;
$$;

CREATE OR REPLACE PROCEDURE proc_delete_employee(p_fio VARCHAR)
LANGUAGE SQL AS $$ DELETE FROM Employee WHERE employee_fio = p_fio; $$;

CREATE OR REPLACE PROCEDURE proc_insert_cargo(
    p_track VARCHAR, p_type VARCHAR, p_delivery VARCHAR,
    p_sender VARCHAR, p_receiver VARCHAR, p_price DECIMAL,
    p_mass DECIMAL, p_value DECIMAL, p_pack BOOLEAN, p_ins BOOLEAN
)
LANGUAGE SQL AS $$
    INSERT INTO Cargo (cargo_track, cargo_type, delivery_type, sender_phone, receiver_phone,
                       total_price, cargo_mass, cargo_value, packaging, insurance)
    VALUES (p_track, p_type, p_delivery, p_sender, p_receiver,
            p_price, p_mass, p_value, p_pack, p_ins);
$$;

CREATE OR REPLACE PROCEDURE proc_update_cargo(
    p_track VARCHAR, p_type VARCHAR, p_delivery VARCHAR,
    p_price DECIMAL, p_mass DECIMAL, p_value DECIMAL,
    p_pack BOOLEAN, p_ins BOOLEAN
)
LANGUAGE SQL AS $$
    UPDATE Cargo SET
        cargo_type    = COALESCE(p_type,     cargo_type),
        delivery_type = COALESCE(p_delivery, delivery_type),
        total_price   = COALESCE(p_price,    total_price),
        cargo_mass    = COALESCE(p_mass,     cargo_mass),
        cargo_value   = COALESCE(p_value,    cargo_value),
        packaging     = COALESCE(p_pack,     packaging),
        insurance     = COALESCE(p_ins,      insurance)
    WHERE cargo_track = p_track;
$$;

CREATE OR REPLACE PROCEDURE proc_delete_cargo(p_track VARCHAR)
LANGUAGE SQL AS $$ DELETE FROM Cargo WHERE cargo_track = p_track; $$;

CREATE OR REPLACE PROCEDURE proc_insert_shipment(
    p_track VARCHAR, p_point VARCHAR, p_slot VARCHAR,
    p_status VARCHAR, p_employee_fio VARCHAR, p_date DATE
)
LANGUAGE SQL AS $$
    INSERT INTO Shipments_golikov_a_08
        (cargo_track, point_name, slot, status, employee_fio, update_date)
    VALUES (p_track, p_point, p_slot, p_status, p_employee_fio, p_date);
$$;

CREATE OR REPLACE PROCEDURE proc_update_shipment(
    p_track VARCHAR, p_point VARCHAR, p_new_slot VARCHAR,
    p_new_status VARCHAR, p_new_employee VARCHAR, p_new_date DATE
)
LANGUAGE SQL AS $$
    UPDATE Shipments_golikov_a_08 SET
        slot         = COALESCE(p_new_slot,     slot),
        status       = COALESCE(p_new_status,   status),
        employee_fio = COALESCE(p_new_employee, employee_fio),
        update_date  = COALESCE(p_new_date,     update_date)
    WHERE cargo_track = p_track AND point_name = p_point;
$$;

CREATE OR REPLACE PROCEDURE proc_archive_shipment(p_track VARCHAR)
LANGUAGE SQL AS $$
    DELETE FROM Shipments_golikov_a_08
    WHERE cargo_track = p_track AND status = 'доставлено';
$$;

CREATE OR REPLACE PROCEDURE proc_delete_shipment(p_track VARCHAR, p_point VARCHAR)
LANGUAGE SQL AS $$
    DELETE FROM Shipments_golikov_a_08
    WHERE cargo_track = p_track AND point_name = p_point;
$$;

-- =============================================================================
-- Функция для получения отгрузок по пункту (используется приложением)
-- =============================================================================

CREATE OR REPLACE FUNCTION get_shipments_by_point(p_point VARCHAR)
RETURNS TABLE (
    cargo_track  VARCHAR,
    point_name   VARCHAR,
    slot         VARCHAR,
    status       VARCHAR,
    employee_fio VARCHAR,
    update_date  DATE
) AS $$
    SELECT cargo_track, point_name, slot, status, employee_fio, update_date
    FROM Shipments_golikov_a_08
    WHERE point_name = p_point
    ORDER BY update_date DESC;
$$ LANGUAGE SQL;

-- =============================================================================
-- 7. Роли и права (GRANT на calculate_total_price теперь сработает)
-- =============================================================================

DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'Руководитель') THEN
        CREATE ROLE "Руководитель" LOGIN PASSWORD 'leader2026';
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'Администратор') THEN
        CREATE ROLE "Администратор" LOGIN PASSWORD 'admin2026';
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'Оператор') THEN
        CREATE ROLE "Оператор" LOGIN PASSWORD 'oper2026';
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'Работник склада') THEN
        CREATE ROLE "Работник склада" LOGIN PASSWORD 'wh2026';
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'Менеджер') THEN
        CREATE ROLE "Менеджер" LOGIN PASSWORD 'mgr2026';
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'Клиент') THEN
        CREATE ROLE "Клиент" LOGIN PASSWORD 'client2026';
    END IF;
END $$;

GRANT ALL ON ALL TABLES IN SCHEMA public             TO "Руководитель";
GRANT ALL ON ALL SEQUENCES IN SCHEMA public          TO "Руководитель";
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public          TO "Руководитель";
GRANT ALL ON ALL PROCEDURES IN SCHEMA public         TO "Руководитель";

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO "Администратор";
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public          TO "Администратор";
GRANT ALL ON ALL PROCEDURES IN SCHEMA public         TO "Администратор";

GRANT SELECT, INSERT, UPDATE ON Cargo, Shipments_golikov_a_08 TO "Оператор";
GRANT EXECUTE ON FUNCTION calculate_total_price,
                           get_shipments_by_point    TO "Оператор";
GRANT EXECUTE ON PROCEDURE proc_insert_cargo, proc_update_cargo,
                              proc_insert_shipment,
                              proc_delete_shipment   TO "Оператор";

GRANT SELECT, UPDATE ON Shipments_golikov_a_08       TO "Работник склада";
GRANT EXECUTE ON PROCEDURE proc_update_shipment,
                              proc_archive_shipment,
                              proc_delete_shipment     TO "Работник склада";
GRANT EXECUTE ON FUNCTION get_shipments_by_point     TO "Работник склада";

GRANT SELECT ON v_reports_income, v_warehouse_load   TO "Менеджер";

GRANT SELECT ON v_cargo_status                       TO "Клиент";

-- =============================================================================
-- 8. Тестовые данные — теперь с CALL
-- =============================================================================

DO $$
BEGIN
    CALL proc_insert_client('+79161234567', 'Москва, ул. Ленина 10',    'Иванов Иван Иванович',   'client1');
    CALL proc_insert_client('+79169876543', 'Санкт-Петербург, Невский 25','Петрова Анна Сергеевна','client2');
    CALL proc_insert_client('+79160000000', 'Казань, ул. Баумана 1',     'Сидоров Сидор Сидорович','client3');

    CALL proc_insert_point('Москва Центр',   '+74951234567', 'Москва, Красная пл. 1');
    CALL proc_insert_point('СПб Север',      '+78129876543', 'Санкт-Петербург, пл. Ленина 2');
    CALL proc_insert_point('Казань Восток',  '+78430000000', 'Казань, ул. Кремлёвская 3');

    CALL proc_insert_employee('Иванов И.И.',     'Руководитель',     '+79161111111', 'leader2026');
    CALL proc_insert_employee('Петрова А.С.',    'Администратор',    '+79162222222', 'admin2026');
    CALL proc_insert_employee('Сидоров С.С.',    'Оператор',          '+79163333333', 'oper2026');
    CALL proc_insert_employee('Кузнецова К.К.',  'Работник склада',   '+79164444444', 'wh2026');
    CALL proc_insert_employee('Смирнов М.В.',    'Менеджер',          '+79165555555', 'mgr2026');

    -- Грузы — считаем цену через функцию
    CALL proc_insert_cargo('TRK000001', 'мелкий',      'стандартная', '+79161234567', '+79169876543',
                           calculate_total_price(1.8,  'мелкий',      'стандартная', true,  false),
                           1.8,  800.00, true, false);

    CALL proc_insert_cargo('TRK000002', 'документный', 'экспресс',    '+79169876543', '+79161234567',
                           calculate_total_price(0.1,  'документный', 'экспресс',    false, true),
                           NULL, NULL,   false, true);

    CALL proc_insert_cargo('TRK000003', 'крупный',     'срочная',     '+79160000000', '+79161234567',
                           calculate_total_price(42.5, 'крупный',     'срочная',     true,  true),
                           42.5, 18000.00, true, true);

    CALL proc_insert_shipment('TRK000001', 'Москва Центр',  'A-12', 'занято',   'Сидоров С.С.', CURRENT_DATE - 2);
    CALL proc_insert_shipment('TRK000002', 'СПб Север',     'B-05', 'доставлено','Петрова А.С.', CURRENT_DATE - 1);
    CALL proc_insert_shipment('TRK000003', 'Казань Восток', 'C-08', 'занято',   'Кузнецова К.К.', CURRENT_DATE);
END $$;

-- =============================================================================
-- Конец — должно выполниться без ошибок
-- =============================================================================