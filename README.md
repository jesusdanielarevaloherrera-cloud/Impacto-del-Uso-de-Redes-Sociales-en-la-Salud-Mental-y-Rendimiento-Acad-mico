# 📊 Análisis SQL: Impacto del Uso de Redes Sociales en la Salud Mental y Rendimiento Académico

## 📌 Resumen Ejecutivo
El presente proyecto analiza un conjunto de datos desnormalizado con **4,500 registros** de estudiantes para evaluar el impacto del consumo de redes sociales en variables críticas como la **calidad del sueño**, el **estrés percibido**, la **salud mental** y el **rendimiento académico (GPA)**.

El repositorio contiene el diseño de base de datos relacional para **PostgreSQL**, así como **10 consultas SQL analíticas avanzadas** orientadas a responder preguntas de negocio e identificar patrones de riesgo.

---

## 🔍 Hallazgos Principales del Análisis

1. **Efecto Crítico del Uso Nocturno (`late_night_usage`)**:
   - Los estudiantes que consumen redes sociales a altas horas de la noche presentan un incremento directo en los niveles de estrés percibido y una reducción en sus horas y calidad del descanso.
   - El rendimiento académico (GPA) muestra una tendencia decreciente en los grupos con consumo nocturno habitual.

2. **Plataformas de Mayor Concentración**:
   - Plataformas con alto contenido visual e interactivo capturan la mayor proporción de horas diarias de pantalla, convirtiéndose en los canales prioritarios para estrategias de bienestar digital.

3. **Comparación Social**:
   - Existe una relación inversa entre la alta frecuencia de comparación social y el índice general de salud mental.

---

## 🛠️ Arquitectura de Datos (PostgreSQL)

Se diseñó la tabla desnormalizada `social_media_impact` optimizada mediante índices para acelerar la ejecución de consultas analíticas.

### Estructura DDL (`sql/01_schema_creation.sql`)

```sql
CREATE TABLE social_media_impact (
    student_id VARCHAR(20) PRIMARY KEY,
    age INT CHECK (age BETWEEN 10 AND 100),
    gender VARCHAR(30) NOT NULL,
    academic_level VARCHAR(50) NOT NULL,
    primary_platform VARCHAR(50) NOT NULL,
    daily_usage_hours NUMERIC(4,2) CHECK (daily_usage_hours >= 0),
    weekend_extra_hours NUMERIC(4,2) CHECK (weekend_extra_hours >= 0),
    device_type VARCHAR(50) NOT NULL,
    sleep_duration_hours NUMERIC(4,2) CHECK (sleep_duration_hours >= 0),
    sleep_quality_score INT CHECK (sleep_quality_score BETWEEN 1 AND 5),
    late_night_usage BOOLEAN NOT NULL,
    social_comparison_frequency VARCHAR(50) NOT NULL,
    perceived_stress_score NUMERIC(5,2) CHECK (perceived_stress_score BETWEEN 0 AND 100),
    mental_health_index INT CHECK (mental_health_index BETWEEN 0 AND 100),
    academic_performance_gpa NUMERIC(3,2) CHECK (academic_performance_gpa BETWEEN 0.00 AND 5.00),
    overall_impact VARCHAR(20) CHECK (overall_impact IN ('Beneficial', 'Neutral', 'Negative'))
);

-- Índices de rendimiento
CREATE INDEX idx_platform ON social_media_impact(primary_platform);
CREATE INDEX idx_academic_level ON social_media_impact(academic_level);
CREATE INDEX idx_overall_impact ON social_media_impact(overall_impact);
```

---

## 💡 Preguntas de Negocio y Consultas SQL (`sql/02_analytical_queries.sql`)

### 1. Perfil de Uso por Plataforma y Género
Evalúa el volumen de estudiantes y el promedio de tiempo diario y de fin de semana según la red social preferida y el género.
```sql
SELECT 
    primary_platform,
    gender,
    COUNT(student_id) AS total_students,
    ROUND(AVG(daily_usage_hours), 2) AS avg_daily_usage_hours,
    ROUND(AVG(weekend_extra_hours), 2) AS avg_weekend_extra_hours
FROM social_media_impact
GROUP BY primary_platform, gender
ORDER BY avg_daily_usage_hours DESC;
```

### 2. Impacto Biológico del Uso Nocturno
Mide la diferencia en horas de sueño, calidad de descanso y estrés entre quienes consumen redes por la noche y quienes no.
```sql
SELECT 
    late_night_usage,
    COUNT(student_id) AS total_students,
    ROUND(AVG(sleep_duration_hours), 2) AS avg_sleep_hours,
    ROUND(AVG(sleep_quality_score), 2) AS avg_sleep_quality_score,
    ROUND(AVG(perceived_stress_score), 2) AS avg_stress_score
FROM social_media_impact
GROUP BY late_night_usage;
```

### 3. Estrés e Índice de Salud Mental por Frecuencia de Comparación Social
Mide la correlación entre la frecuencia con la que los estudiantes se comparan en redes y sus indicadores psicológicos.
```sql
SELECT 
    social_comparison_frequency,
    COUNT(student_id) AS total_students,
    ROUND(AVG(perceived_stress_score), 2) AS avg_stress_score,
    ROUND(AVG(mental_health_index), 2) AS avg_mental_health_index,
    ROUND(STDDEV(mental_health_index), 2) AS std_mental_health
FROM social_media_impact
GROUP BY social_comparison_frequency
ORDER BY avg_stress_score DESC;
```

### 4. Categorización del Rendimiento Académico (GPA) según Horas Diarias de Pantalla
Segmenta el tiempo en pantalla en niveles (Bajo, Moderado, Excesivo) para medir su distribución en el GPA.
```sql
WITH usage_categories AS (
    SELECT 
        student_id,
        academic_performance_gpa,
        CASE 
            WHEN daily_usage_hours < 3 THEN '1. Bajo (< 3h)'
            WHEN daily_usage_hours BETWEEN 3 AND 6 THEN '2. Moderado (3-6h)'
            ELSE '3. Excesivo (> 6h)'
        END AS usage_tier
    FROM social_media_impact
)
SELECT 
    usage_tier,
    COUNT(student_id) AS student_count,
    ROUND(AVG(academic_performance_gpa), 2) AS avg_gpa,
    ROUND(MIN(academic_performance_gpa), 2) AS min_gpa,
    ROUND(MAX(academic_performance_gpa), 2) AS max_gpa
FROM usage_categories
GROUP BY usage_tier
ORDER BY usage_tier;
```

### 5. Porcentaje de Percepción 'Negative' por Nivel Académico
Calcula el porcentaje de estudiantes por nivel educativo que reportan un impacto negativo global en sus vidas.
```sql
SELECT 
    academic_level,
    COUNT(student_id) AS total_students,
    COUNT(CASE WHEN overall_impact = 'Negative' THEN 1 END) AS negative_impact_count,
    ROUND(
        (COUNT(CASE WHEN overall_impact = 'Negative' THEN 1 END) * 100.0) / COUNT(student_id), 2
    ) AS pct_negative_impact
FROM social_media_impact
GROUP BY academic_level
ORDER BY pct_negative_impact DESC;
```

### 6. Tasa de Uso Nocturno y Salud Mental por Plataforma
Identifica qué plataformas concentran la mayor proporción de usuarios nocturnos y su impacto en la salud mental.
```sql
SELECT 
    primary_platform,
    COUNT(student_id) AS total_users,
    ROUND(AVG(CASE WHEN late_night_usage = TRUE THEN 1.0 ELSE 0.0 END) * 100, 2) AS late_night_user_pct,
    ROUND(AVG(mental_health_index), 2) AS avg_mental_health,
    ROUND(AVG(perceived_stress_score), 2) AS avg_stress
FROM social_media_impact
GROUP BY primary_platform
HAVING COUNT(student_id) > 50
ORDER BY late_night_user_pct DESC;
```

### 7. Ranking de Estudiantes en Riesgo Severo (`DENSE_RANK`)
Utiliza funciones de ventana para extraer los 10 estudiantes con mayor combinación de estrés, menor salud mental y menor desempeño académico.
```sql
WITH student_risk_score AS (
    SELECT 
        student_id,
        age,
        perceived_stress_score,
        mental_health_index,
        academic_performance_gpa,
        daily_usage_hours,
        DENSE_RANK() OVER (
            ORDER BY perceived_stress_score DESC, mental_health_index ASC, academic_performance_gpa ASC
        ) AS risk_rank
    FROM social_media_impact
)
SELECT *
FROM student_risk_score
WHERE risk_rank <= 10;
```

### 8. Impacto Según Dispositivo Principal de Acceso
Analiza diferencias en el consumo de horas, horas de sueño y estrés según el dispositivo utilizado.
```sql
SELECT 
    device_type,
    COUNT(student_id) AS student_count,
    ROUND(AVG(daily_usage_hours), 2) AS avg_daily_hours,
    ROUND(AVG(sleep_duration_hours), 2) AS avg_sleep_duration,
    ROUND(AVG(perceived_stress_score), 2) AS avg_stress_score
FROM social_media_impact
GROUP BY device_type
ORDER BY avg_daily_hours DESC;
```

### 9. Comparativa Agrupada por Rangos de Edad
Agrupa a los usuarios en tres etapas (Adolescentes, Jóvenes Adultos y Adultos) para evaluar tendencias por rango etario.
```sql
SELECT 
    CASE 
        WHEN age < 18 THEN '15-17 años (Adolescentes)'
        WHEN age BETWEEN 18 AND 21 THEN '18-21 años (Jóvenes Adultos)'
        ELSE '22+ años (Adultos/Postgrado)'
    END AS age_group,
    COUNT(student_id) AS total_students,
    ROUND(AVG(daily_usage_hours), 2) AS avg_daily_hours,
    ROUND(AVG(sleep_quality_score), 2) AS avg_sleep_quality,
    ROUND(AVG(academic_performance_gpa), 2) AS avg_gpa,
    ROUND(AVG(mental_health_index), 2) AS avg_mental_health
FROM social_media_impact
GROUP BY 
    CASE 
        WHEN age < 18 THEN '15-17 años (Adolescentes)'
        WHEN age BETWEEN 18 AND 21 THEN '18-21 años (Jóvenes Adultos)'
        ELSE '22+ años (Adultos/Postgrado)'
    END
ORDER BY age_group;
```

### 10. Vista Multivariable de Máximo Riesgo (KPI Dashboard View)
Cruza plataforma, hábito nocturno y frecuencia de comparación social para detectar la combinación de factores de peor salud mental.
```sql
SELECT 
    primary_platform,
    late_night_usage,
    social_comparison_frequency,
    COUNT(student_id) AS student_sample,
    ROUND(AVG(mental_health_index), 2) AS avg_mental_health_index,
    ROUND(AVG(perceived_stress_score), 2) AS avg_perceived_stress,
    ROUND(AVG(academic_performance_gpa), 2) AS avg_gpa
FROM social_media_impact
GROUP BY primary_platform, late_night_usage, social_comparison_frequency
HAVING COUNT(student_id) >= 20
ORDER BY avg_mental_health_index ASC
LIMIT 10;
```

---

## 📈 Recomendaciones Basadas en Datos

1. **Higiene Digital Nocturna**: Diseñar campañas enfocadas en restringir las pantallas antes de dormir, dado que el uso nocturno es el principal catalizador del incremento de estrés y degradación del sueño.
2. **Priorización de Plataformas**: Enfocar recursos institucionales en las redes sociales con mayor volumen de usuarios y mayores tasas de hábitos nocturnos.
3. **Monitoreo Preventivo**: Establecer rangos de alerta cuando el consumo diario supere las 6 horas o la frecuencia de comparación sea recurrente.

---
*Proyecto de análisis de datos desarrollado en PostgreSQL.*
