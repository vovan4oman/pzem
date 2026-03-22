-- 1. Споживання за різні періоди (день, тиждень, місяць)
SELECT date_trunc('day', ts) AS period, SUM(consumption_kwh) AS total_kwh FROM meter_readings WHERE meter_id = 1 GROUP BY 1 ORDER BY 1;
SELECT date_trunc('week', ts) AS period, SUM(consumption_kwh) AS total_kwh FROM meter_readings WHERE meter_id = 1 GROUP BY 1 ORDER BY 1;
SELECT date_trunc('month', ts) AS period, SUM(consumption_kwh) AS total_kwh FROM meter_readings WHERE meter_id = 1 GROUP BY 1 ORDER BY 1;

-- 2. Споживання в розрізі тарифних зон (День/Ніч)
SELECT 
    CASE WHEN EXTRACT(HOUR FROM ts) >= 7 AND EXTRACT(HOUR FROM ts) < 23 THEN 'День (6.9 грн)' ELSE 'Ніч (5.6 грн)' END AS tariff_zone,
    SUM(consumption_kwh) AS total_kwh,
    SUM(consumption_kwh * CASE WHEN EXTRACT(HOUR FROM ts) >= 7 AND EXTRACT(HOUR FROM ts) < 23 THEN 6.9 ELSE 5.6 END) AS total_cost_uah
FROM meter_readings WHERE meter_id = 1 GROUP BY 1;

-- 3. Питомі показники (кВт·год/м2)
SELECT SUM(consumption_kwh) / 2500 AS kwh_per_m2 FROM meter_readings WHERE meter_id = 1 AND ts >= '2025-01-01' AND ts < '2026-01-01';

-- 4. Порівняння з базовою лінією (Baseline 70 кВт*год/год)
SELECT ts, consumption_kwh AS actual, 70 AS baseline, (consumption_kwh - 70) AS deviation FROM meter_readings WHERE meter_id = 1 LIMIT 100;

-- 5. Виявлення аномалій (відхилення >20% від середнього)
WITH stats AS (SELECT AVG(consumption_kwh) AS avg_cons FROM meter_readings WHERE meter_id = 1)
SELECT r.ts, r.consumption_kwh, s.avg_cons, ((r.consumption_kwh - s.avg_cons) / s.avg_cons) * 100 AS percent_deviation
FROM meter_readings r, stats s WHERE meter_id = 1 AND ABS(r.consumption_kwh - s.avg_cons) > (s.avg_cons * 0.2) ORDER BY r.ts;