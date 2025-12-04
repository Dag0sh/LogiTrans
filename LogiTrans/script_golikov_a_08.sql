-- Чистка всех объектов для создания новых
DROP TABLE IF EXISTS Shipments_golikov_a_08 CASCADE;
DROP TABLE IF EXISTS Cargo CASCADE;
DROP TABLE IF EXISTS Employee CASCADE;
DROP TABLE IF EXISTS Point CASCADE;
DROP TABLE IF EXISTS Client CASCADE;

DROP VIEW IF EXISTS v_cargo_status;
DROP VIEW IF EXISTS v_reports_income;
DROP VIEW IF EXISTS v_warehouse_load;

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
DROP PROCEDURE IF EXISTS proc_delete_shipment(VARCHAR, VARCHAR);

DROP PROCEDURE IF EXISTS proc_archive_shipment(VARCHAR);

-- Таблицы по рз
CREATE TABLE Client (
    client_phone VARCHAR(100) PRIMARY KEY,
    address VARCHAR(200),
    fio VARCHAR(200) NOT NULL UNIQUE,
    password VARCHAR(50),
    CHECK (client_phone ~ '^\+?[1-9]\d{1,14}$')  -- Формат телефона
);

CREATE TABLE Point (
    point_name VARCHAR(100) PRIMARY KEY,
    point_phone VARCHAR(20),
    point_address VARCHAR(200)
);

CREATE TABLE Employee (
    employee_fio VARCHAR(100) PRIMARY KEY,
    position VARCHAR(50) NOT NULL,
    phone VARCHAR(20) CHECK (phone ~ '^\+?[1-9]\d{1,14}$'),
    password VARCHAR(50)
);

CREATE TABLE Cargo (
    cargo_track VARCHAR(50) PRIMARY KEY,
    cargo_type VARCHAR(50) NOT NULL CHECK (cargo_type IN ('мелкий', 'средний', 'крупный', 'документный')),
    delivery_type VARCHAR(50) NOT NULL CHECK (delivery_type IN ('стандартная', 'срочная', 'экспресс')),
    sender_phone VARCHAR(100) REFERENCES Client(client_phone),
    receiver_phone VARCHAR(100) REFERENCES Client(client_phone),
    total_price DECIMAL(10,2) CHECK (total_price > 0),
    cargo_mass DECIMAL(10,2) CHECK (cargo_mass > 0 OR cargo_type = 'документный'),
    cargo_value DECIMAL(10,2) CHECK (cargo_value >= 0),
    packaging BOOLEAN NOT NULL,
    insurance BOOLEAN NOT NULL
);

CREATE TABLE Shipments_golikov_a_08 (
    cargo_track VARCHAR(50) NOT NULL REFERENCES Cargo(cargo_track),
    point_name VARCHAR(100) NOT NULL REFERENCES Point(point_name),
    slot_number VARCHAR(50) NOT NULL,
    status VARCHAR(50) NOT NULL,
    employee_fio VARCHAR(100) REFERENCES Employee(employee_fio),
    date DATE NOT NULL,
    PRIMARY KEY (cargo_track, point_name)
);


CREATE OR REPLACE FUNCTION trig_check_slot() RETURNS trigger AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM Shipments_golikov_a_08 WHERE point_name = NEW.point_name AND slot_number = NEW.slot_number AND status != 'доставлено') THEN
        RAISE EXCEPTION 'Слот % на пункте % уже занят', NEW.slot_number, NEW.point_name;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_slot_before_insert
BEFORE INSERT OR UPDATE ON Shipments_golikov_a_08
FOR EACH ROW EXECUTE FUNCTION trig_check_slot();

CREATE OR REPLACE FUNCTION trig_update_date_on_status_change() RETURNS trigger AS $$
BEGIN
    IF NEW.status <> OLD.status THEN
        NEW.date = CURRENT_DATE;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_date_on_status_change
BEFORE UPDATE ON Shipments_golikov_a_08
FOR EACH ROW EXECUTE FUNCTION trig_update_date_on_status_change();

-- Функции
CREATE OR REPLACE FUNCTION get_shipments_by_point(p_point VARCHAR) RETURNS SETOF Shipments_golikov_a_08 AS $$
SELECT * FROM Shipments_golikov_a_08 WHERE point_name = p_point ORDER BY date DESC;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION calculate_total_price(p_mass DECIMAL, p_type VARCHAR, p_delivery VARCHAR, p_pack BOOLEAN, p_ins BOOLEAN) RETURNS DECIMAL AS $$
DECLARE
    base DECIMAL;
    delivery_factor DECIMAL = 1;
    pack_cost DECIMAL = 100;
    ins_cost DECIMAL = 200;
BEGIN
    IF p_type = 'документный' THEN
        base = 300; -- Фиксированная для документов
    ELSIF p_type = 'мелкий' THEN
        base = p_mass * 50;
    ELSIF p_type = 'средний' THEN
        base = p_mass * 40;
    ELSIF p_type = 'крупный' THEN
        base = p_mass * 30;
    ELSE
        RAISE EXCEPTION 'Неверный тип груза: %', p_type;
    END IF;

    IF p_delivery = 'стандартная' THEN
        delivery_factor = 1;
    ELSIF p_delivery = 'срочная' THEN
        delivery_factor = 1.5;
    ELSIF p_delivery = 'экспресс' THEN
        delivery_factor = 2;
    ELSE
        RAISE EXCEPTION 'Неверный тип доставки: %', p_delivery;
    END IF;

    base = base * delivery_factor;

    IF p_pack THEN base = base + pack_cost; END IF;
    IF p_ins THEN base = base + ins_cost; END IF;

    RETURN base;
END;
$$ LANGUAGE plpgsql;

-- Процедуры
CREATE OR REPLACE PROCEDURE proc_insert_client(p_phone VARCHAR, p_address VARCHAR, p_fio VARCHAR, p_password VARCHAR) AS $$
BEGIN
    INSERT INTO Client (client_phone, address, fio, password) VALUES (p_phone, p_address, p_fio, p_password);
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Ошибка вставки клиента: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE proc_update_client(p_phone VARCHAR, p_new_address VARCHAR, p_new_fio VARCHAR, p_new_password VARCHAR) AS $$
BEGIN
    UPDATE Client SET address = p_new_address, fio = p_new_fio, password = p_new_password WHERE client_phone = p_phone;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Клиент с телефоном % не найден', p_phone;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE proc_delete_client(p_phone VARCHAR) AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM Cargo WHERE sender_phone = p_phone OR receiver_phone = p_phone) THEN
        RAISE EXCEPTION 'Нельзя удалить клиента, есть связанные грузы';
    END IF;
    DELETE FROM Client WHERE client_phone = p_phone;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Клиент с телефоном % не найден', p_phone;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE proc_insert_point(p_name VARCHAR, p_phone VARCHAR, p_address VARCHAR) AS $$
BEGIN
    INSERT INTO Point (point_name, point_phone, point_address) VALUES (p_name, p_phone, p_address);
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Ошибка вставки пункта: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE proc_update_point(p_name VARCHAR, p_new_phone VARCHAR, p_new_address VARCHAR) AS $$
BEGIN
    UPDATE Point SET point_phone = p_new_phone, point_address = p_new_address WHERE point_name = p_name;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Пункт % не найден', p_name;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE proc_delete_point(p_name VARCHAR) AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM Shipments_golikov_a_08 WHERE point_name = p_name) THEN
        RAISE EXCEPTION 'Нельзя удалить пункт, есть связанные отгрузки';
    END IF;
    DELETE FROM Point WHERE point_name = p_name;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Пункт % не найден', p_name;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE proc_insert_employee(p_fio VARCHAR, p_position VARCHAR, p_phone VARCHAR, p_password VARCHAR) AS $$
BEGIN
    INSERT INTO Employee (employee_fio, position, phone, password) VALUES (p_fio, p_position, p_phone, p_password);
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Ошибка вставки сотрудника: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE proc_update_employee(p_fio VARCHAR, p_new_position VARCHAR, p_new_phone VARCHAR, p_new_password VARCHAR) AS $$
BEGIN
    UPDATE Employee SET position = p_new_position, phone = p_new_phone, password = p_new_password WHERE employee_fio = p_fio;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Сотрудник % не найден', p_fio;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE proc_delete_employee(p_fio VARCHAR) AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM Shipments_golikov_a_08 WHERE employee_fio = p_fio) THEN
        RAISE EXCEPTION 'Нельзя удалить сотрудника, есть связанные отгрузки';
    END IF;
    DELETE FROM Employee WHERE employee_fio = p_fio;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Сотрудник % не найден', p_fio;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE proc_insert_cargo(p_track VARCHAR, p_type VARCHAR, p_delivery VARCHAR, p_sender VARCHAR, p_receiver VARCHAR, p_price DECIMAL, p_mass DECIMAL, p_value DECIMAL, p_pack BOOLEAN, p_ins BOOLEAN) AS $$
BEGIN
    INSERT INTO Cargo (cargo_track, cargo_type, delivery_type, sender_phone, receiver_phone, total_price, cargo_mass, cargo_value, packaging, insurance)
    VALUES (p_track, p_type, p_delivery, p_sender, p_receiver, p_price, p_mass, p_value, p_pack, p_ins);
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Ошибка вставки груза: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE proc_update_cargo(p_track VARCHAR, p_new_type VARCHAR, p_new_delivery VARCHAR, p_new_mass DECIMAL, p_new_value DECIMAL, p_new_price DECIMAL, p_new_pack BOOLEAN, p_new_ins BOOLEAN) AS $$
BEGIN
    UPDATE Cargo SET cargo_type = p_new_type, delivery_type = p_new_delivery, cargo_mass = p_new_mass, cargo_value = p_new_value, total_price = p_new_price, packaging = p_new_pack, insurance = p_new_ins WHERE cargo_track = p_track;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Груз % не найден', p_track;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE proc_delete_cargo(p_track VARCHAR) AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM Shipments_golikov_a_08 WHERE cargo_track = p_track) THEN
        RAISE EXCEPTION 'Нельзя удалить груз, есть связанные отгрузки';
    END IF;
    DELETE FROM Cargo WHERE cargo_track = p_track;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Груз % не найден', p_track;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE proc_insert_shipment(p_cargo_track VARCHAR, p_point_name VARCHAR, p_slot VARCHAR, p_status VARCHAR, p_employee_fio VARCHAR, p_date DATE) AS $$
BEGIN
    INSERT INTO Shipments_golikov_a_08 (cargo_track, point_name, slot_number, status, employee_fio, date) VALUES (p_cargo_track, p_point_name, p_slot, p_status, p_employee_fio, p_date);
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Ошибка вставки отгрузки: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE proc_update_shipment(p_cargo_track VARCHAR, p_point_name VARCHAR, p_new_slot VARCHAR, p_new_status VARCHAR, p_new_employee_fio VARCHAR, p_new_date DATE) AS $$
BEGIN
    UPDATE Shipments_golikov_a_08 SET slot_number = p_new_slot, status = p_new_status, employee_fio = p_new_employee_fio, date = p_new_date WHERE cargo_track = p_cargo_track AND point_name = p_point_name;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Отгрузка для груза % в пункте % не найдена', p_cargo_track, p_point_name;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE proc_delete_shipment(p_cargo_track VARCHAR, p_point_name VARCHAR) AS $$
BEGIN
    DELETE FROM Shipments_golikov_a_08 WHERE cargo_track = p_cargo_track AND point_name = p_point_name;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Отгрузка для груза % в пункте % не найдена', p_cargo_track, p_point_name;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE proc_archive_shipment(p_cargo_track VARCHAR) AS $$
BEGIN
    -- Создаём таблицу архива если не существует
    IF NOT EXISTS (SELECT FROM pg_tables WHERE tablename = 'archiveshipments') THEN
        CREATE TABLE ArchiveShipments AS TABLE Shipments_golikov_a_08 WITH NO DATA;
    END IF;
    INSERT INTO ArchiveShipments SELECT * FROM Shipments_golikov_a_08 WHERE cargo_track = p_cargo_track;
    DELETE FROM Shipments_golikov_a_08 WHERE cargo_track = p_cargo_track;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Груз % не найден для архивации', p_cargo_track;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Представления
CREATE VIEW v_cargo_status AS
SELECT s.cargo_track, p.point_name, s.status, s.date
FROM Shipments_golikov_a_08 s
JOIN Point p ON s.point_name = p.point_name
ORDER BY s.date DESC;

CREATE VIEW v_reports_income AS
SELECT DATE_TRUNC('month', s.date) AS period, SUM(c.total_price) AS income, COUNT(c.cargo_track) AS count, AVG(c.total_price) AS avg_price, c.cargo_type
FROM Shipments_golikov_a_08 s
JOIN Cargo c ON s.cargo_track = c.cargo_track
WHERE s.status = 'доставлено'
GROUP BY period, c.cargo_type;

CREATE VIEW v_warehouse_load AS
SELECT
    p.point_name,
    COALESCE(COUNT(s.slot_number), 0) AS occupied_slots
FROM Point p
LEFT JOIN Shipments_golikov_a_08 s ON p.point_name = s.point_name AND s.status != 'доставлено'
GROUP BY p.point_name
ORDER BY occupied_slots DESC;


GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO "Руководитель";
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO "Руководитель";
GRANT ALL PRIVILEGES ON ALL PROCEDURES IN SCHEMA public TO "Руководитель";

GRANT SELECT, INSERT, UPDATE, DELETE ON Cargo, Shipments_golikov_a_08, Client, Point TO "Администратор";
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO "Администратор";
GRANT EXECUTE ON ALL PROCEDURES IN SCHEMA public TO "Администратор";

GRANT SELECT, INSERT ON Cargo TO "Оператор";
GRANT SELECT, INSERT ON Shipments_golikov_a_08 TO "Оператор";
GRANT EXECUTE ON FUNCTION calculate_total_price(DECIMAL, VARCHAR, VARCHAR, BOOLEAN, BOOLEAN) TO "Оператор";  -- Исправление: указали аргументы
GRANT EXECUTE ON PROCEDURE proc_insert_cargo(VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, DECIMAL, DECIMAL, DECIMAL, BOOLEAN, BOOLEAN) TO "Оператор";  -- Исправление: указали аргументы
GRANT EXECUTE ON PROCEDURE proc_insert_shipment(VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, DATE) TO "Оператор";

GRANT SELECT, UPDATE ON Shipments_golikov_a_08 TO "Работник склада";
GRANT EXECUTE ON PROCEDURE proc_update_shipment(VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, DATE) TO "Работник склада";
GRANT EXECUTE ON PROCEDURE proc_archive_shipment(VARCHAR) TO "Работник склада";

GRANT SELECT ON v_reports_income, v_cargo_status, v_warehouse_load TO "Менеджер";

-- Тестовые данные (расширенные для аналитики: больше для views)
DO $$
BEGIN
    -- Clients (3 для тестов)
    IF NOT EXISTS (SELECT 1 FROM Client WHERE client_phone = '+79161234567') THEN
        CALL proc_insert_client('+79161234567', 'Москва, ул. Ленина 10', 'Петров П.П.', 'clientpass1');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM Client WHERE client_phone = '+79169876543') THEN
        CALL proc_insert_client('+79169876543', 'СПб, пр. Невский 5', 'Сидорова А.А.', 'clientpass2');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM Client WHERE client_phone = '+79160000000') THEN
        CALL proc_insert_client('+79160000000', 'Казань, ул. Баумана 1', 'Иванов И.И.', 'clientpass3');
    END IF;

    -- Points (3 для тестов загруженности)
    IF NOT EXISTS (SELECT 1 FROM Point WHERE point_name = 'Москва Центр') THEN
        CALL proc_insert_point('Москва Центр', '+74951234567', 'Москва, Красная площадь 1');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM Point WHERE point_name = 'СПб Север') THEN
        CALL proc_insert_point('СПб Север', '+78129876543', 'СПб, ул. Большая 2');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM Point WHERE point_name = 'Казань Восток') THEN
        CALL proc_insert_point('Казань Восток', '+78430000000', 'Казань, ул. Кремлёвская 3');
    END IF;

    -- Employees (5 для ролей)
    IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_fio = 'Иванов И.И.') THEN
        CALL proc_insert_employee('Иванов И.И.', 'Руководитель', '+79161111111', 'pass1');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_fio = 'Петров П.П.') THEN
        CALL proc_insert_employee('Петров П.П.', 'Администратор', '+79162222222', 'pass2');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_fio = 'Сидоров С.С.') THEN
        CALL proc_insert_employee('Сидоров С.С.', 'Оператор', '+79163333333', 'pass3');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_fio = 'Кузнецова К.К.') THEN
        CALL proc_insert_employee('Кузнецова К.К.', 'Работник склада', '+79164444444', 'pass4');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_fio = 'Смирнов С.С.') THEN
        CALL proc_insert_employee('Смирнов С.С.', 'Менеджер', '+79165555555', 'pass5');
    END IF;

    -- Cargos (3 для тестов отчётов)
    IF NOT EXISTS (SELECT 1 FROM Cargo WHERE cargo_track = 'TRACK001') THEN
        CALL proc_insert_cargo('TRACK001', 'мелкий', 'стандартная', '+79161234567', '+79169876543', 500.00, 2.5, 1000.00, TRUE, FALSE);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM Cargo WHERE cargo_track = 'TRACK002') THEN
        CALL proc_insert_cargo('TRACK002', 'документный', 'экспресс', '+79169876543', '+79161234567', 600.00, NULL, NULL, FALSE, TRUE);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM Cargo WHERE cargo_track = 'TRACK003') THEN
        CALL proc_insert_cargo('TRACK003', 'крупный', 'срочная', '+79160000000', '+79161234567', 1000.00, 50.0, 5000.00, TRUE, TRUE);
    END IF;

    -- Shipments (3 для тестов статусов и загруженности)
    IF NOT EXISTS (SELECT 1 FROM Shipments_golikov_a_08 WHERE cargo_track = 'TRACK001' AND point_name = 'Москва Центр') THEN
        CALL proc_insert_shipment('TRACK001', 'Москва Центр', 'SLOT001', 'занято', 'Сидоров С.С.', '2025-12-01');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM Shipments_golikov_a_08 WHERE cargo_track = 'TRACK002' AND point_name = 'СПб Север') THEN
        CALL proc_insert_shipment('TRACK002', 'СПб Север', 'SLOT002', 'доставлено', 'Петров П.П.', '2025-12-02');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM Shipments_golikov_a_08 WHERE cargo_track = 'TRACK003' AND point_name = 'Казань Восток') THEN
        CALL proc_insert_shipment('TRACK003', 'Казань Восток', 'SLOT003', 'занято', 'Кузнецова К.К.', '2025-12-03');
    END IF;
END
$$;
