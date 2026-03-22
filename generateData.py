import pandas as pd
import numpy as np
from datetime import datetime, timedelta

# Параметри Варіанта №4 (Готель)
START_DATE = datetime(2025, 1, 1)
HOURS = 8760
PV_CAPACITY = 120  # кВт
TOTAL_AVG_LOAD = 70  # кВт

def generate_full_system_data():
    readings, ems_log, weather = [], [], []
    
    for h in range(HOURS):
        ts = START_DATE + timedelta(hours=h)
        hour, month = ts.hour, ts.month
        
        # 1. Погода (Київ)
        # Моделювання температури та сонячної інсоляції
        temp = 10 + 15 * np.sin(2 * np.pi * (ts.timetuple().tm_yday - 150) / 365) + np.random.normal(0, 2)
        irrad = max(0, 800 * np.sin(np.pi * (hour - 6) / 14)) * np.random.uniform(0.5, 1.0) if 6 <= hour <= 20 else 0
        weather.append([ts, round(temp, 2), round(irrad, 2)])
        
        # 2. Споживання (Три рівні ієрархії)
        daily_mod = 1 + 0.4 * np.sin(2 * np.pi * (hour - 6) / 24)
        seasonal_mod = 1.3 if month in [1, 2, 12, 6, 7, 8] else 1.0
        total_kwh = TOTAL_AVG_LOAD * daily_mod * seasonal_mod * np.random.uniform(0.9, 1.1)
        
        # Рівень 1: Головний ввід
        readings.append([1, ts, round(total_kwh, 3)]) 
        
        # Рівень 2: Розподіл по вузлах
        readings.append([2, ts, round(total_kwh * 0.3, 3)]) # Харчоблок
        readings.append([3, ts, round(total_kwh * 0.5, 3)]) # Номери
        readings.append([4, ts, round(total_kwh * 0.2, 3)]) # Технічний блок
        
        # Рівень 3: Деталізація обладнання
        readings.append([5, ts, round(total_kwh * 0.3 * 0.6, 3)])
        readings.append([6, ts, round(total_kwh * 0.3 * 0.4, 3)])
        for m_id in range(7, 13):
            readings.append([m_id, ts, round(total_kwh * 0.05, 3)])

        # 3. СЕС та Батарея
        pv_gen = (irrad / 1000) * PV_CAPACITY * 0.8
        soc = 50 + 20 * np.sin(2 * np.pi * hour / 24)
        ems_log.append([ts, round(pv_gen, 3), round(soc, 1)])

    # Збереження результатів у CSV
    pd.DataFrame(readings, columns=['meter_id', 'ts', 'value']).to_csv('readings.csv', index=False)
    pd.DataFrame(weather, columns=['ts', 'temp', 'irrad']).to_csv('weather.csv', index=False)
    pd.DataFrame(ems_log, columns=['ts', 'pv_gen', 'soc']).to_csv('ems.csv', index=False)

if __name__ == "__main__":
    generate_full_system_data()
    print("Files generated successfully: readings.csv, weather.csv, ems.csv")
