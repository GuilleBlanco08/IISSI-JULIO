-- Necesitamos conocer los pagos que se realicen sobre los pedidos. Para ello se propone la creación de 
-- una nueva tabla llamada Pagos. Cada pedido podrá tener asociado varios pagos y cada pago solo 
-- corresponde con un pedido en concreto. 
-- Para cada pago necesitamos conocer la fecha de pago, la cantidad pagada (que no puede ser 
-- negativa) y si el pago ha sido revisado o no (por defecto no estará revisado).

CREATE TABLE Pagos(
	idPago INT NOT NULL AUTO_INCREMENT,
	idPedido INT NOT NULL,
	fechaPago DATE NOT NULL,
	cantidad DECIMAL(10,2) NOT NULL CHECK(cantidad >= 0),
	revisado BOOL NOT NULL DEFAULT FALSE,
	PRIMARY KEY(idPago),
	FOREIGN KEY(idPedido) REFERENCES pedidos(id)
		ON DELETE CASCADE 
		ON UPDATE CASCADE
);


-- 2.1. Devuelva el nombre del empleado, la fecha de realización del pedido y el nombre del cliente 
-- de todos los pedidos realizados este mes.

SELECT ue.nombre AS empleado, pedidos.fechaRealizacion, uc.nombre AS cliente
FROM pedidos 
JOIN empleados ON empleados.id = pedidos.empleadoId
JOIN usuarios ue ON ue.id = empleados.usuarioId
JOIN clientes ON clientes.id = pedidos.clienteId
JOIN usuarios uc ON uc.id = clientes.usuarioId
WHERE YEAR(pedidos.fechaRealizacion) = 2024 AND 
MONTH(pedidos.fechaRealizacion) = 9
ORDER BY pedidos.fechaRealizacion;

-- 2.2. Devuelva el nombre, las unidades totales pedidas y el importe total gastado de aquellos clientes 
-- que han realizado más de 5 pedidos en el último año

SELECT u.nombre AS cliente, SUM(lp.unidades) AS unidades_totales, SUM(lp.unidades * lp.precio) AS importe
FROM pedidos p
JOIN clientes c ON c.id = p.clienteId
JOIN usuarios u ON u.id = c.usuarioId
JOIN lineaspedido lp ON lp.pedidoId = p.id
WHERE p.fechaRealizacion BETWEEN DATE_SUB(CURDATE(), INTERVAL 1 YEAR) AND CURDATE()
GROUP BY u.nombre
having COUNT(distinct p.id) > 5; -- Contar distintos pedidos


-- Cree un procedimiento que permita crear un nuevo producto con posibilidad de que sea para regalo. 
-- Si el producto está destinado a regalo se creará un pedido con ese producto y costes 0€ para el 
-- cliente más antiguo. (1,5 puntos) 

-- Asegure que el precio del producto para regalo no debe superar los 50 euros y lance excepción si se 
-- da el caso con el siguiente mensaje: 

DELIMITER //

CREATE PROCEDURE crear_producto_regalo(
  IN p_tipoProductoId  INT,
  IN p_nombre          VARCHAR(100),
  IN p_descripcion     TEXT,
  IN p_precio          DECIMAL(10,2),
  IN p_paraRegalo      BOOL
)
BEGIN
  DECLARE v_idProducto       INT;
  DECLARE v_clienteMasAntiguo INT;
  
  DECLARE exit handler FOR SQLEXCEPTION 
	BEGIN 
		ROLLBACK;
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Error al actualizar el producto';
	END;

  START TRANSACTION;

  -- 1) Si es regalo, validar precio ≤ 50€
  IF p_paraRegalo AND p_precio > 50 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'No se permite crear un producto para regalo de más de 50€';
  END IF;

  -- 2) Crear el producto
  INSERT INTO Productos(tipoProductoId, nombre, descripcion, precio, puedeVenderseAMenores)
    VALUES (p_tipoProductoId, p_nombre, p_descripcion, p_precio, TRUE);
    
  SET v_idProducto = LAST_INSERT_ID();

  -- 3) Si es regalo, crear pedido de coste 0 para el cliente más antiguo
  IF p_paraRegalo THEN
    -- 3.1) Encontrar el cliente de mayor edad (fechaNacimiento mínima)
    SELECT id INTO v_clienteMasAntiguo
    FROM Clientes
    ORDER BY fechaNacimiento
    LIMIT 1;

    -- 3.2) Insertar pedido
    INSERT INTO Pedidos(clienteId, empleadoId, fechaRealizacion, fechaEnvio, direccionEnvio, comentarios)
    	VALUES (v_clienteMasAntiguo, NULL, CURDATE(), NULL, '', 'Pedido de regalo');

    -- 3.3) Añadir línea de pedido con precio 0 y 1 unidad
    INSERT INTO LineasPedido(pedidoId, productoId, unidades, precio)
      VALUES (LAST_INSERT_ID(), v_idProducto, 1, 0.00);
  END IF;

  COMMIT;
END;
//

DELIMITER ;

-- Cree un trigger llamado t_limitar_importe_pedidos_de_menores que impida que, a partir de ahora, 
-- los pedidos realizados por menores superen los 500€. 

DELIMITER //

CREATE TRIGGER t_limitar_importe_pedidos_de_menores
BEFORE INSERT ON LineasPedido
FOR EACH ROW
BEGIN

  DECLARE v_fechaNac   DATE;
  DECLARE v_edad       INT;
  DECLARE v_importeAct DECIMAL(10,2);

  -- 1) Obtenemos la fecha de nacimiento del cliente del pedido
  SELECT c.fechaNacimiento INTO v_fechaNac
  FROM Pedidos p
  JOIN Clientes c ON p.clienteId = c.id
  WHERE p.id = NEW.pedidoId;

  -- 2) Calculamos la edad en años
  SET v_edad = TIMESTAMPDIFF(YEAR, v_fechaNac, CURDATE());

  -- 3) Si es menor de 18, comprobamos el importe acumulado
  IF v_edad < 18 THEN
  
    SELECT COALESCE(SUM(lp.unidades * lp.precio), 0) INTO v_importeAct
    FROM LineasPedido lp
    WHERE lp.pedidoId = NEW.pedidoId;

    -- 4) Si la suma de lo ya pedido + esta línea supera 500€, lo impedimos
    IF v_importeAct + (NEW.unidades * NEW.precio) > 500 THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No se permite que un pedido de un menor supere los 500€';
    END IF;
  END IF;
END //
DELIMITER ;
