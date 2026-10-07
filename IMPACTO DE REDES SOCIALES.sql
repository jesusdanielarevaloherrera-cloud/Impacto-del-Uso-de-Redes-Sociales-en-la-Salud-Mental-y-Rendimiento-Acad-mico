-- ============================================================
-- TABLA ÚNICA: social_media_impact
-- BD Target: PostgreSQL 14+
-- ============================================================

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

-- Índices estratégicos para optimizar filtros y tableros
CREATE INDEX idx_platform ON social_media_impact(primary_platform);
CREATE INDEX idx_academic_level ON social_media_impact(academic_level);
CREATE INDEX idx_overall_impact ON social_media_impact(overall_impact);

-- Pregunta 1: ¿Cual es el perfil de volumen y promedio de tiempo diario en 
-- redes sociales por plataforma principal y genero?

SELECT 
    primary_platform,
    gender,
    COUNT(student_id) AS total_students,
    ROUND(AVG(daily_usage_hours), 2) AS avg_daily_usage_hours,
    ROUND(AVG(weekend_extra_hours), 2) AS avg_weekend_extra_hours
FROM social_media_impact
GROUP BY primary_platform, gender
ORDER BY avg_daily_usage_hours DESC;

--Pregunta 2: ¿Cómo afecta el uso nocturno (late_night_usage) a las horas y calidad del sueño?

SELECT 
    late_night_usage,
    COUNT(student_id) AS total_students,
    ROUND(AVG(sleep_duration_hours), 2) AS avg_sleep_hours,
    ROUND(AVG(sleep_quality_score), 2) AS avg_sleep_quality_score,
    ROUND(AVG(perceived_stress_score), 2) AS avg_stress_score
FROM social_media_impact
GROUP BY late_night_usage;

--Pregunta 3: ¿Existe relación entre la frecuencia de comparación social
--y el índice de salud mental o el estrés percibido?

SELECT 
    social_comparison_frequency,
    COUNT(student_id) AS total_students,
    ROUND(AVG(perceived_stress_score), 2) AS avg_stress_score,
    ROUND(AVG(mental_health_index), 2) AS avg_mental_health_index,
    ROUND(STDDEV(mental_health_index), 2) AS std_mental_health
FROM social_media_impact
GROUP BY social_comparison_frequency
ORDER BY avg_stress_score DESC;


--Pregunta 4: ¿Cuáles son las métricas de rendimiento 
--académico (GPA) según los niveles de consumo diario?

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

--Pregunta 5: ¿Qué porcentaje de estudiantes percibe un impacto 'Negative' según su nivel académico?

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


--Pregunta 6: ¿Cuál es la plataforma con la mayor tasa de uso nocturno y peor nivel de salud mental?
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

--Pregunta 7: Ranking de estudiantes en riesgo severo 
--(Alto Estrés, Baja Salud Mental y Bajo GPA) usando funciones de ventana (DENSE_RANK).


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

-- Pregunta 8: ¿Varían las métricas de consumo y estrés según el tipo de dispositivo de acceso?

SELECT 
    device_type,
    COUNT(student_id) AS student_count,
    ROUND(AVG(daily_usage_hours), 2) AS avg_daily_hours,
    ROUND(AVG(sleep_duration_hours), 2) AS avg_sleep_duration,
    ROUND(AVG(perceived_stress_score), 2) AS avg_stress_score
FROM social_media_impact
GROUP BY device_type
ORDER BY avg_daily_hours DESC;

--Pregunta 9: Comparativa de salud mental, sueño y GPA agrupada por segmentos de edad.

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


--Pregunta 10: ¿Qué combinación de factores 
--(Plataforma + Uso Nocturno + Comparación Frecuente) presenta los peores índices de salud mental?


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


































