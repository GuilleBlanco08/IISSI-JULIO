-- 1. Último día (últimas 24 horas)
WHERE fecha >= DATE_SUB(CURDATE(), INTERVAL 1 DAY);

-- 2. Última semana (últimos 7 días)
WHERE fecha >= DATE_SUB(CURDATE(), INTERVAL 1 WEEK);

-- 3. Último mes (últimos 1 mes)
WHERE fecha >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH);

-- 4. Último trimestre (últimos 3 meses)
WHERE fecha >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH);

-- 4b. Último trimestre calendario (trimestre anterior completo)

WHERE YEAR(fecha)  = YEAR(DATE_SUB(CURDATE(), INTERVAL 1 QUARTER))
  AND QUARTER(fecha) = QUARTER(DATE_SUB(CURDATE(), INTERVAL 1 QUARTER));

-- 5. Último año (último 1 año)
WHERE fecha >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR);

-- 6. Año en curso (año actual)
WHERE YEAR(fecha) = YEAR(CURDATE());

-- 7. Año anterior (año calendario anterior)
WHERE YEAR(fecha) = YEAR(CURDATE()) - 1;

-- 8a. Hace 2 años (año calendario hace 2 años)
WHERE YEAR(fecha) = YEAR(CURDATE()) - 2;

-- 8b. Rango dinámico de N años hacia atrás (ej. 2 años atrás)
WHERE fecha >= DATE_SUB(CURDATE(), INTERVAL 2 YEAR);

-- 9. Trimestre en curso
WHERE YEAR(fecha)   = YEAR(CURDATE())
  AND QUARTER(fecha) = QUARTER(CURDATE());

-- 10. Rango arbitrario entre dos parámetros
-- Parámetros: @fechaInicio, @fechaFin
WHERE fecha BETWEEN @fechaInicio AND @fechaFin;

-- 11. Mes concreto de un año concreto (ej. julio 2025)
WHERE MONTH(fecha) = 7
  AND YEAR(fecha)  = 2025;
