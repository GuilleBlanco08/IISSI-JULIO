-- Necesitamos conocer la opinión de nuestros clientes sobre nuestros productos. Para ello se propone 
-- la creación de una nueva tabla llamada Valoraciones. Cada valoración versará sobre un producto y 
-- será realizada por un solo cliente. Cada producto podrá ser valorado por muchos clientes. Cada 
-- cliente podrá realizar muchas valoraciones. Un cliente no puede valorar más de una vez un mismo 
-- producto. 
-- Para cada valoración necesitamos conocer la puntuación de 1 a 5 (sólo se permiten enteros) y la 
-- fecha en que se realiza la valoración.

CREATE TABLE Valoraciones(
	idValoracion INT NOT NULL AUTO_INCREMENT,
	idProducto INT NOT NULL,
	idCliente INT NOT NULL,
	puntuacion INT CHECK (puntuacion >= 0 AND puntuacion <= 5),
	fechaRealizacion DATE NOT NULL,
	UNIQUE(idProducto, idCliente),
	PRIMARY KEY(idValoracion),
	FOREIGN KEY(idProducto) REFERENCES productos(id)
		ON DELETE CASCADE 
		ON UPDATE CASCADE,
	FOREIGN KEY(idCliente) REFERENCES clientes(id)
		ON DELETE CASCADE 
		ON UPDATE CASCADE
);


-- 2.1. Devuelva el nombre del producto, el precio unitario y las unidades compradas para las 5 líneas 
-- de pedido con más unidades.

SELECT lp.id, p.nombre AS nombreProducto, lp.precio AS precioUnitario, lp.unidades AS unidadesCompradas
FROM lineaspedido lp
JOIN productos p ON p.id = lp.productoId
ORDER BY lp.unidades DESC
LIMIT 5;

-- 2.3. Devuelva el nombre del empleado, la fecha de realización del pedido, el precio total del pedido y 
-- las unidades totales del pedido para todos los pedidos que de más 7 días de antigüedad desde que 
-- se realizaron. Si un pedido no tiene asignado empleado, también debe aparecer en el listado 
-- devuelto. 

SELECT usuarios.nombre AS empleado, pedidos.fechaRealizacion AS fecha, SUM(lineaspedido.unidades * lineaspedido.precio) AS total, SUM(lineaspedido.unidades) AS unidades
FROM usuarios
JOIN empleados ON usuarios.id = empleados.usuarioId
right JOIN pedidos ON pedidos.empleadoId = empleados.id -- Si un pedido no tiene asignado empleado, también aparece en el listado
JOIN lineaspedido ON lineaspedido.pedidoId = pedidos.Id
GROUP BY pedidos.id
having TIMESTAMPDIFF(DAY, pedidos.fechaRealizacion, CURDATE()) > 7;

-- O así --
SELECT usuarios.nombre AS empleado, pedidos.fechaRealizacion AS fecha, SUM(lineaspedido.unidades * lineaspedido.precio) AS importe, sum(lineaspedido.unidades) AS unidades
FROM lineaspedido
JOIN pedidos ON pedidos.id = lineaspedido.pedidoId
left JOIN empleados ON empleados.id = pedidos.empleadoId
left JOIN usuarios ON usuarios.id = empleados.usuarioId
GROUP BY pedidos.id
having TIMESTAMPDIFF(DAY, pedidos.fechaRealizacion, CURDATE()) > 7

-- Otra opción -- 
SELECT usuarios.nombre, pedidos.fechaRealizacion, SUM(lineaspedido.unidades * lineaspedido.precio) AS precioTotal, sum(lineaspedido.unidades) AS unidades
FROM usuarios 																																			-- No olvidemos sumar las unidades --
JOIN empleados ON empleados.usuarioId=usuarios.id
RIGHT JOIN pedidos ON pedidos.empleadoId=empleados.id
JOIN lineaspedido ON lineaspedido.pedidoId=pedidos.id
GROUP BY pedidos.id -- Agrupar por pedido y no por empleado
HAVING (DATEDIFF(CURDATE(),pedidos.fechaRealizacion) > 7);

-- Cree un procedimiento que permita bonificar un pedido que se ha retrasado debido a la mala gestión 
-- del empleado a cargo. Recibirá un identificador de pedido, asignará a otro empleado como gestor y 
-- reducirá un 20% el precio unitario de cada línea de pedido asociada a ese pedido. (1,5 puntos) 

-- Asegure que el pedido estaba asociado a un empleado y en caso contrario lance excepción con el 
-- siguiente mensaje: 

DELIMITER //

CREATE PROCEDURE bonificar_pedido_retrasado(
  IN p_pedidoId INT
)
BEGIN
  -- 1) Primero declaramos todas las variables
  DECLARE empleadoPedido INT;
  DECLARE nuevoEmpleado   INT;

  -- 2) A continuación declaramos los handlers
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SIGNAL SQLSTATE '45000'
   	SET MESSAGE_TEXT = 'Error al bonificar el pedido';
  END;

  -- 3) Ahora ya van el resto de sentencias
  START TRANSACTION;

  -- Bloquear y leer el gestor actual
  SELECT empleadoId INTO empleadoPedido
  FROM Pedidos
  WHERE id = p_pedidoId;

  IF empleadoPedido IS NULL THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'El pedido no tiene gestor';
  END IF;

  -- Elegir otro empleado cualquiera
  SELECT id INTO nuevoEmpleado
  FROM Empleados
  WHERE id != empleadoPedido
  LIMIT 1;

  -- Actualizar el pedido con el nuevo gestor
  UPDATE Pedidos SET empleadoId = nuevoEmpleado
  WHERE id = p_pedidoId;

  -- Rebajar un 20% todas las líneas de ese pedido
  UPDATE lineaspedido SET precio = precio * 0.80
  WHERE pedidoId = p_pedidoId;

  COMMIT;
END;
//

DELIMITER ;

-- Cree un trigger llamado p_limitar_unidades_mensuales_de_productos_fisicos que, a partir de este 
-- momento, impida la venta de más de 1000 unidades al mes de cualquier producto físico.

DELIMITER //
-- incluya su solución a continuación
CREATE or replace TRIGGER t_limitar_unidades_mensuales_de_productos_fisicos
BEFORE INSERT ON lineaspedido
FOR EACH ROW
BEGIN 
	
	DECLARE unidades_vendidas_mes INT;
	DECLARE tipo_producto INT;
	DECLARE fecha DATE;
	
	SELECT tipoProductoId INTO tipo_producto
	FROM productos
	WHERE id=NEW.productoId;
	
	if (tipo_producto = 1) then 
		
		SELECT pedidos.fechaRealizacion INTO fecha
		FROM pedidos 
		WHERE pedidos.id=NEW.pedidoId;
		
		SELECT SUM(lp.unidades) INTO unidades_vendidas_mes
		FROM lineaspedido lp
		WHERE lp.productoId = NEW.productoId 
		AND MONTH(CURDATE()) = MONTH(fecha) AND YEAR(CURDATE()) = YEAR(fecha);
		
		if((NEW.unidades + unidades_vendidas_mes) > 1000) then
			SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'No se puede comprar mas de 1000 unidades en el mismo mes';
		END if;
	END if;
END //
-- fin de su solución
DELIMITER ;

INSERT INTO pedidos(fechaRealizacion, fechaEnvio, direccionEntrega, comentarios, clienteId, empleadoId) VALUES
(CURDATE(), CURDATE(), 'fdafa', 'dafdfa', 1, 1);

INSERT INTO lineaspedido(pedidoId, productoId, unidades, precio) VALUES
(16, 1, 990 , 699.99);