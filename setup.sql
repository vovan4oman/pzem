-- Створення структури таблиць
CREATE TABLE objects (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    area_m2 NUMERIC(10, 2) DEFAULT 2500,
    contract_power_kw NUMERIC(10, 2) DEFAULT 300
);

CREATE TABLE meters (
    id SERIAL PRIMARY KEY,
    object_id INTEGER NOT NULL REFERENCES objects(id) ON DELETE CASCADE,
    label VARCHAR(100) NOT NULL,
    meter_level INTEGER NOT NULL CHECK (meter_level IN (1, 2, 3)),
    parent_meter_id INTEGER REFERENCES meters(id) ON DELETE SET NULL
);

CREATE TABLE energy_assets (
    id SERIAL PRIMARY KEY,
    object_id INTEGER NOT NULL REFERENCES objects(id),
    asset_type VARCHAR(20) CHECK (asset_type IN ('PV_PANEL', 'BATTERY')),
    capacity_kwh NUMERIC(10, 2),
    max_power_kw NUMERIC(10, 2)
); 

CREATE TABLE meter_readings (
    id BIGSERIAL PRIMARY KEY,
    meter_id INTEGER NOT NULL REFERENCES meters(id) ON DELETE CASCADE,
    ts TIMESTAMP NOT NULL,
    consumption_kwh NUMERIC(10, 3) NOT NULL,
    UNIQUE(meter_id, ts)
);

CREATE TABLE weather_data (
    ts TIMESTAMP PRIMARY KEY,
    temperature_c NUMERIC(5, 2) NOT NULL,
    irradiation_wm2 NUMERIC(10, 2) NOT NULL
);

CREATE TABLE ems_log (
    ts TIMESTAMP PRIMARY KEY REFERENCES weather_data(ts),
    pv_generation_kwh NUMERIC(10, 3),
    battery_soc_pct NUMERIC(5, 2) CHECK (battery_soc_pct BETWEEN 20 AND 90),
    grid_export_kwh NUMERIC(10, 3)
);

CREATE TABLE tariffs (
    id SERIAL PRIMARY KEY,
    zone_name VARCHAR(20) NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    price_per_kwh NUMERIC(10, 2) NOT NULL
);

-- Створення View для рівнів обліку
CREATE VIEW view_level_1_main AS SELECT r.ts, m.label, r.consumption_kwh FROM meter_readings r JOIN meters m ON r.meter_id = m.id WHERE m.meter_level = 1;
CREATE VIEW view_level_2_substations AS SELECT r.ts, m.label, r.consumption_kwh FROM meter_readings r JOIN meters m ON r.meter_id = m.id WHERE m.meter_level = 2;
CREATE VIEW view_level_3_endpoints AS SELECT r.ts, m.label, r.consumption_kwh FROM meter_readings r JOIN meters m ON r.meter_id = m.id WHERE m.meter_level = 3;

-- Реєстрація об'єктів та лічильників
INSERT INTO objects (name, area_m2, contract_power_kw) VALUES ('Готель №4', 2500, 300);
INSERT INTO meters (id, object_id, label, meter_level) VALUES (1, 1, 'Головний ввід', 1);
INSERT INTO meters (id, object_id, label, meter_level, parent_meter_id) VALUES (2, 1, 'Харчоблок', 2, 1), (3, 1, 'Житловий корпус', 2, 1), (4, 1, 'Технічні системи', 2, 1);
INSERT INTO meters (id, object_id, label, meter_level, parent_meter_id) VALUES (5, 1, 'Плити (Кухня)', 3, 2), (6, 1, 'Холодильники (Кухня)', 3, 2), (7, 1, 'Освітлення 1-5 поверх', 3, 3), (8, 1, 'Освітлення 6-10 поверх', 3, 3), (9, 1, 'Кондиціонування Блок А', 3, 3), (10, 1, 'Ліфти', 3, 4), (11, 1, 'Пральня', 3, 4), (12, 1, 'Конференц-зал', 3, 4);

-- Імпорт даних (замініть path на актуальний шлях до CSV)
COPY meter_readings(meter_id, ts, consumption_kwh) FROM 'path/readings.csv' WITH (FORMAT CSV, HEADER); 
COPY weather_data(ts, temperature_c, irradiation_wm2) FROM 'path/weather.csv' WITH (FORMAT CSV, HEADER);
COPY ems_log(ts, pv_generation_kwh, battery_soc_pct) FROM 'path/ems.csv' WITH (FORMAT CSV, HEADER);