-- 1. Consulta que calcula la media de unidades por pedido de un cliente específico (clienteId = 1)
SELECT COALESCE(SUM(lp.unidades), 0) / COUNT(p.id) 
FROM Pedidos p
JOIN LineasPedido lp ON p.id = lp.pedidoId
WHERE p.clienteId = 1;

-- IMPORTANTE
-- 2. Clientes que han comprado los 3 productos más vendidos en al menos 3 meses distintos del año 2024
SELECT u.nombre AS cliente, COUNT(DISTINCT MONTH(p.fechaRealizacion)) AS mes
FROM usuarios u
JOIN clientes c ON c.usuarioId = u.id
JOIN pedidos p ON p.clienteId = c.id
JOIN lineaspedido lp ON lp.pedidoId = p.id
JOIN (
  SELECT pr.id AS productoId, pr.nombre AS producto, SUM(lp.unidades) AS unidades
  FROM productos pr
  JOIN lineaspedido lp ON lp.productoId = pr.id
  JOIN pedidos p ON p.id = lp.pedidoId
  WHERE p.fechaRealizacion >= DATE_SUB(CURDATE(), INTERVAL 5 YEAR)
  GROUP BY pr.nombre
  ORDER BY unidades DESC
  LIMIT 3
) AS producto ON producto.productoId = lp.productoId
WHERE YEAR(p.fechaRealizacion) = 2024
GROUP BY cliente
HAVING COUNT(DISTINCT MONTH(p.fechaRealizacion)) >= 3;

-- 4. Top 5 pedidos con menor importe total respecto a la media de importes

SELECT p.id AS pedido, SUM(lp.unidades * lp.precio) AS importe
FROM pedidos p
JOIN lineaspedido lp ON lp.pedidoId = p.id
GROUP BY p.id
HAVING importe < (
  SELECT COALESCE(SUM(lp.precio * lp.unidades), 0) / COUNT(p.id) 
	FROM Pedidos p
	JOIN LineasPedido lp ON p.id = lp.pedidoId
	)
ORDER BY importe DESC
LIMIT 5;

-- 5. Productos que nunca han sido vendidos
SELECT Productos.nombre 
FROM Productos 
LEFT JOIN LineasPedido ON Productos.id = LineasPedido.productoId 
WHERE LineasPedido.productoId IS NULL;

-- 6. Clientes que han comprado más productos prohibidos para menores que permitidos
SELECT c.id AS cliente_id, u.nombre, u.email
FROM Clientes c
JOIN Usuarios u ON c.usuarioId = u.id
JOIN Pedidos p ON c.id = p.clienteId
JOIN LineasPedido lp ON p.id = lp.pedidoId
JOIN Productos pr ON lp.productoId = pr.id
GROUP BY c.id
HAVING (
  SELECT SUM(lp1.unidades)
  FROM LineasPedido lp1
  JOIN Productos pr1 ON lp1.productoId = pr1.id
  JOIN Pedidos p1 ON lp1.pedidoId = p1.id
  WHERE p1.clienteId = c.id AND pr1.puedeVenderseAMenores = FALSE) 
  > 
  (SELECT SUM(lp2.unidades)
  FROM LineasPedido lp2
  JOIN Productos pr2 ON lp2.productoId = pr2.id
  JOIN Pedidos p2 ON lp2.pedidoId = p2.id
  WHERE p2.clienteId = c.id AND pr2.puedeVenderseAMenores = TRUE
);

-- 7. Productos que no han sido comprados por menores de edad
SELECT pr.id AS producto_id, pr.nombre
FROM Productos pr
WHERE pr.id NOT IN (
  SELECT lp.productoId
  FROM LineasPedido lp
  JOIN Pedidos p ON lp.pedidoId = p.id
  JOIN Clientes c ON p.clienteId = c.id
  WHERE TIMESTAMPDIFF(YEAR, c.fechaNacimiento, CURDATE()) < 18
);

-- 8. Total gastado por cada cliente
SELECT u.nombre AS cliente, SUM(lp.unidades * lp.precio) AS total_gastado
FROM usuarios u
JOIN clientes c ON c.usuarioId = u.id
JOIN pedidos p ON p.clienteId = c.id
JOIN lineaspedido lp ON lp.pedidoId = p.id
GROUP BY u.nombre, c.id;

-- 9. Número de pedidos gestionados por cada empleado
SELECT u.nombre AS empleado, COUNT(DISTINCT p.id) AS numPedidos
FROM usuarios u
JOIN empleados e ON e.usuarioId = u.id
JOIN pedidos p ON p.empleadoId = e.id
JOIN lineaspedido lp ON lp.pedidoId = p.id
GROUP BY u.nombre;

-- 10. Productos del tipo 1 cuyo precio medio es superior a 20€
SELECT pr.nombre, AVG(lp.precio) AS precio
FROM lineaspedido lp
JOIN productos pr ON pr.id = lp.productoId
WHERE pr.tipoProductoId = 1
GROUP BY pr.nombre
HAVING AVG(lp.precio) > 20;

-- 11. Clientes que han comprado alguno de los 3 productos más vendidos
-- INCLUSO SI UN PRODUCTO NO HA SIDO COMPRADO POR NADIE, IGUAL APARECERÁ EN EL RESULTADO
SELECT u.nombre AS cliente, product.producto, product.unidades
FROM clientes c
LEFT JOIN usuarios u ON c.usuarioId = u.id
LEFT JOIN pedidos p ON p.clienteId = c.id
LEFT JOIN lineaspedido lp ON lp.pedidoId = p.id
LEFT JOIN (
  SELECT pr.id AS id, pr.nombre AS producto, SUM(lp.unidades) AS unidades
  FROM productos pr
  JOIN lineaspedido lp ON lp.productoId = pr.id
  GROUP BY producto
  ORDER BY unidades DESC
  LIMIT 3
) AS product ON product.id = lp.productoId
GROUP BY u.nombre;

-- 12. Pedidos realizados en los últimos 10 meses, incluyendo cliente y empleado
SELECT p.id AS pedido_id, p.fechaRealizacion, uc.nombre AS cliente, ue.nombre AS empleado
FROM Pedidos p
JOIN Clientes c ON c.id = p.clienteId
JOIN Usuarios uc ON uc.id = c.usuarioId
LEFT JOIN Empleados e ON e.id = p.empleadoId
LEFT JOIN Usuarios ue ON ue.id = e.usuarioId
WHERE p.fechaRealizacion >= CURDATE() - INTERVAL 10 MONTH;

-- 13. Clientes que han hecho pedidos en al menos 3 meses distintos durante el último año
SELECT u.nombre AS clientes
FROM usuarios u
JOIN clientes c ON c.usuarioId = u.id
JOIN pedidos p ON p.clienteId = c.id
WHERE p.fechaRealizacion >= CURDATE() - INTERVAL 1 YEAR
GROUP BY u.nombre
HAVING COUNT(DISTINCT MONTH(p.fechaRealizacion)) >= 3;

-- 14. Productos prohibidos vendidos a menores de edad
SELECT DISTINCT pr.nombre
FROM Productos pr
JOIN LineasPedido lp ON lp.productoId = pr.id
JOIN Pedidos p ON p.id = lp.pedidoId
JOIN Clientes c ON c.id = p.clienteId
WHERE pr.puedeVenderseAMenores = FALSE
AND TIMESTAMPDIFF(YEAR, c.fechaNacimiento, p.fechaRealizacion) < 18;

-- 15. Clientes que tienen entre 14 y 15 años
SELECT u.nombre AS cliente, c.fechaNacimiento
FROM usuarios u 
JOIN clientes c ON c.usuarioId = u.id
WHERE TIMESTAMPDIFF(YEAR, c.fechaNacimiento, CURDATE()) BETWEEN 14 AND 15;

-- 16. Importe mensual de pedidos del año actual
SELECT MONTH(p.fechaRealizacion) AS mes, SUM(lp.unidades * lp.precio) AS total_mensual
FROM pedidos p
JOIN lineaspedido lp ON lp.pedidoId = p.id
WHERE YEAR(p.fechaRealizacion) = YEAR(CURDATE())
GROUP BY mes
ORDER BY mes;

-- 17. Número de pedidos por empleado por mes
SELECT u.nombre AS empleado, MONTH(p.fechaRealizacion) AS mes, COUNT(*) AS pedidos
FROM Pedidos p
JOIN Empleados e ON e.id = p.empleadoId
JOIN Usuarios u ON u.id = e.usuarioId
GROUP BY e.id, mes
ORDER BY u.nombre, pedidos DESC;

-- 18. Pedidos que contienen al menos 3 líneas de pedido distintas
SELECT p.id, COUNT(lp.id) AS lineaspedidoDistintas
FROM pedidos p
JOIN lineaspedido lp ON lp.pedidoId = p.id
GROUP BY p.id
HAVING COUNT(lp.id) >= 3;



-- 2.1. Calcule el importe medio de los pedidos realizados en el último trimestre (importe total de cada
-- pedido = suma de unidades × precio unitario de sus líneas). (1,5 puntos)
 
SELECT AVG(sub.importe) 
FROM (
	SELECT pedidos.id, SUM(lineaspedido.unidades * lineaspedido.precio) AS importe
	FROM pedidos
	JOIN lineaspedido ON lineaspedido.pedidoId = pedidos.id
	-- Ésta mejor para 3 meses 
	WHERE pedidos.fechaRealizacion >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH)
	-- WHERE TIMESTAMPDIFF(MONTH, pedidos.fechaRealizacion, CURDATE()) <= 3
	GROUP BY pedidos.id) AS sub; 

-- 2.2. Devuelva el nombre del empleado, el número de pedidos gestionados en los últimos 12 meses y
-- el importe total gestionado por cada uno, incluyendo también aquellos empleados que no hayan
-- gestionado pedidos (con valores cero). Ordene el resultado de mayor a menor importe gestionado.

SELECT usuarios.nombre AS empleado, COUNT(DISTINCT pedidos.id) AS pedidos, coalesce(SUM(lineaspedido.unidades * lineaspedido.precio),0) AS importe
FROM usuarios
jOIN empleados ON empleados.usuarioId = usuarios.id
left JOIN pedidos ON pedidos.empleadoId = empleados.id -- Todos los pedidos incluso los que no tienen empleado asignado
AND pedidos.fechaRealizacion >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
JOIN lineaspedido ON lineaspedido.pedidoId = pedidos.id -- Si un pedido no tiene líneas lo devuelve igual
GROUP BY usuarios.nombre
ORDER BY importe DESC;

-- Calcule los ingresos totales por categoría de producto generados en el último mes.
-- Devuelva dos columnas: nombre de categoría e ingresos (suma de unidades×precio unitario
-- de todas las líneas de pedido de productos de esa categoría). Ordene el resultado de mayor
-- a menor ingresos. 
 
SELECT tiposproducto.nombre AS categoria, SUM(lineaspedido.precio * lineaspedido.unidades) AS ingresos
FROM lineaspedido
JOIN productos ON productos.id = lineaspedido.productoId
JOIN pedidos ON pedidos.id = lineaspedido.pedidoId
JOIN tiposproducto ON tiposproducto.id = productos.tipoProductoId
WHERE pedidos.fechaRealizacion >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH)
GROUP BY tiposproducto.nombre
ORDER BY ingresos DESC;

-- Obtenga los tres clientes que más hayan gastado en el último año. Devuelva:- Nombre y correo electrónico del cliente.
-- Número de pedidos realizados.- Importe total gastado.
-- Solo considere clientes con al menos un pedido. Ordene de mayor a menor importe.

SELECT usuarios.nombre AS nombre, usuarios.email AS correo, COUNT(DISTINCT pedidos.id) AS pedido, coalesce(SUM(lineaspedido.unidades * lineaspedido.precio),0) AS importe
FROM usuarios
JOIN clientes ON clientes.usuarioId = usuarios.id
JOIN pedidos ON pedidos.clienteId = clientes.id
JOIN lineaspedido ON lineaspedido.pedidoId = pedidos.id
WHERE pedidos.fechaRealizacion > DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
GROUP BY clientes.id, usuarios.nombre
ORDER BY importe DESC
LIMIT 3;


-- Obtenga los cinco productos más vendidos en el último semestre.
       -- Devuelva dos columnas:
        -- nombre_producto
        -- unidades_vendidas (suma de todas las unidades de LineasPedido).
       -- Ordene de mayor a menor.

SELECT productos.nombre AS producto, SUM(lineaspedido.unidades) AS unidades
FROM lineaspedido
JOIN productos ON productos.id = lineaspedido.productoId
JOIN pedidos ON pedidos.id = lineaspedido.pedidoId
WHERE pedidos.fechaRealizacion >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
GROUP BY productos.nombre
ORDER BY unidades DESC
LIMIT 5;

-- 2.2. MUY IMPORTANTE COMO HACE EL LEFT JOIN CON EL AND

SELECT tiposproducto.nombre AS categoria, COUNT(DISTINCT pedidos.id) AS pedidos, COALESCE(SUM(lineaspedido.precio * lineaspedido.unidades),0) AS importe
FROM lineaspedido
left JOIN productos ON productos.id = lineaspedido.productoId
left JOIN pedidos ON pedidos.id = lineaspedido.pedidoId
	and pedidos.fechaRealizacion >= DATE_SUB(CURDATE(), INTERVAL 9 MONTH)
left JOIN tiposproducto ON tiposproducto.id = productos.tipoProductoId
GROUP BY tiposproducto.nombre
ORDER BY importe DESC;


-- 2.1 Calcule las ventas totales mensuales (suma de unidades × precio) para cada mes
      -- del año en curso. Devuelva: mes (número) e ventas_totales. Ordene por mes asc.

SELECT MONTH(pedidos.fechaRealizacion) AS mes, SUM(lineaspedido.unidades * lineaspedido.precio) AS ventas
FROM lineaspedido
JOIN pedidos ON pedidos.id = lineaspedido.pedidoId
WHERE YEAR(pedidos.fechaRealizacion) = 2024
GROUP BY mes
ORDER BY mes ASC;

-- 2.2. Obtenga el importe medio de los pedidos realizados en el último trimestre por cliente,
        -- incluyendo aquellos clientes sin pedidos (importe = 0). Devuelva:
        -- nombre_cliente
        -- importe_medio_pedido
        -- Ordene por importe_medio_pedido desc.

SELECT u.nombre AS cliente, AVG(ped.importe) AS importeMedio
FROM usuarios u
JOIN clientes c ON c.usuarioId = u.id
LEFT JOIN ( SELECT p.clienteId AS clienteId, coalesce(SUM(lp.unidades * lp.precio),0) AS importe
				FROM pedidos p
				JOIN lineaspedido lp ON lp.pedidoId = p.id
				WHERE p.fechaRealizacion >= DATE_SUB(CURDATE(), INTERVAL 10 MONTH)
				GROUP BY p.id
		) ped ON c.id = ped.clienteId
GROUP BY u.nombre , c.id
ORDER BY importeMedio DESC;














