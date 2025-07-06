-- Necesitamos conocer la garantía de nuestros productos. Para ello se propone la creación de una 
-- nueva tabla llamada Garantias. Cada producto tendrá como máximo una garantía (no todos los 
-- productos tienen garantía), y cada garantía estará relacionada con un producto. 
-- Para cada garantía necesitamos conocer la fecha de inicio de la garantía, la fecha de fin de la garantía, 
-- si tiene garantía extendida o no. 
-- Asegure que la fecha de fin de la garantía es posterior a la fecha de inicio. 

CREATE TABLE Garantias(
	idGarantia INT NOT NULL AUTO_INCREMENT,
	idProducto INT NOT NULL UNIQUE, -- Un producto sólo puede tener una fila en Garantias -- 
	fechaInicio DATE NOT NULL,
	fechaFin DATE NOT NULL,
	extendida BOOL NOT NULL,
	PRIMARY KEY(idGarantia),
	FOREIGN KEY(idProducto) REFERENCES productos(id)
		ON DELETE CASCADE
		ON UPDATE CASCADE, 
	CONSTRAINT RN01 CHECK (fechaFin > fechaInicio)
);

-- 2.1. Devuelva el nombre del producto, nombre del tipo de producto, y precio unitario al que se 
-- vendieron los productos digitales

SELECT productos.nombre, tiposproducto.nombre, lineaspedido.precio -- lp.precio es el precio de cada unidad 
FROM productos 
JOIN tiposproducto ON tiposproducto.id = productos.tipoProductoId
JOIN lineaspedido ON lineaspedido.productoId = productos.id
WHERE tiposproducto.nombre = 'Digitales';

-- Si quisiéramos el precio del pedido completo tendríamos que multiplicar el precio por el número de unidades --

-- 2.2. Consulta que devuelva el nombre del empleado, el número de pedidos de más de 500 euros 
-- gestionados en este año y el importe total de cada uno de ellos, ordenados de mayor a menor 
-- importe gestionado. Los empleados que no hayan gestionado ningún pedido, también deben 
-- aparecer. 

SELECT usuarios.nombre AS empleado,COUNT(ped.pedidoId) AS numPedidos,COALESCE(SUM(ped.totalPedido),0) AS importeTotal 
FROM empleados 
JOIN usuarios ON usuarios.id=empleados.usuarioId 
LEFT JOIN ( -- lEFT JOIN PARA DEVOLVER TODOS LOS PEDIDOS AUNQUE NO HAYA EMPLEADO ASOCIADO A ALGUNO -- 
  SELECT p.id AS pedidoId,p.empleadoId,SUM(lp.precio*lp.unidades) AS totalPedido 
  FROM pedidos p 
  JOIN lineaspedido lp ON lp.pedidoId=p.id 
  WHERE YEAR(p.fechaRealizacion)= 2024
  GROUP BY p.id,p.empleadoId 
  HAVING totalPedido > 500
) AS ped ON ped.empleadoId=empleados.id 

GROUP BY usuarios.nombre 
ORDER BY importeTotal DESC;

-- Cree un procedimiento que permita actualizar el precio de un producto dado y que modifique los 
-- precios de las líneas de pedido asociadas al producto dado solo en aquellos pedidos que aún no 
-- hayan sido enviados. (1,5 puntos) 

-- Asegure que el nuevo precio no sea un 50% menor que el precio actual y lance excepción si se da el 
-- caso con el siguiente mensaje: (1 punto)

DELIMITER //

CREATE PROCEDURE actualizar_precio_producto(
    IN p_productoId INT,
    IN p_nuevoPrecio DECIMAL(10, 2)
)
-- incluya su solución a continuación
BEGIN	
	
	DECLARE v_precioActual DECIMAL(10, 2);
	
	DECLARE exit handler FOR SQLEXCEPTION 
	BEGIN 
		ROLLBACK;
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Error al actualizar el producto';
	END;
	
	START TRANSACTION;
	
	SET v_precioActual = (SELECT sum(productos.precio * 0.5) FROM productos WHERE productos.id = p_productoId);
	
	if (p_nuevoPrecio < v_precioActual) then
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'No se permite rebajar el precio más del 50%';
	END IF;
	
	UPDATE productos SET productos.precio=p_nuevoPrecio WHERE productos.id = p_productoId;
	
	UPDATE lineaspedido 
	JOIN pedidos ON pedidos.id=lineaspedido.pedidoId
	SET lineaspedido.precio = p_nuevoPrecio 
	WHERE lineaspedido.productoId = p_productoId
	AND pedidos.fechaEnvio IS NULL;
	
	COMMIT;
	
END //
-- fin de su solución
DELIMITER ;

CALL actualizar_precio_producto(8, 20.00);

-- Cree un trigger llamado t_asegurar_mismo_tipo_producto_en_pedidos que impida que, a partir de 
-- ahora, un mismo pedido incluya productos físicos y digitales. 

DELIMITER //
-- incluya su solución a continuación
CREATE TRIGGER t_asegurar_mismo_tipo_producto_en_pedidos
BEFORE INSERT ON lineaspedido
FOR EACH ROW
BEGIN 

	DECLARE tipoNuevo INT;
	DECLARE tipoExistente INT;
	
	SET tipoNuevo = (SELECT tiposproducto.id FROM productos
							JOIN tiposproducto ON tiposproducto.id = productos.tipoProductoId
							WHERE productos.id = NEW.productoId);
										
	SET tipoExistente = (SELECT tiposproducto.id FROM lineaspedido
								JOIN productos ON lineaspedido.productoId = productos.id
								JOIN tiposproducto ON tiposproducto.id = productos.tipoProductoId
								WHERE lineaspedido.pedidoId = NEW.pedidoId
								LIMIT 1);
								
	if (tipoExistente IS NOT NULL AND tipoExistente != tipoNuevo) then 
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'No se permite mezclar productos físicos y digitales en un mismo pedido.';
	END if;
	
END //
-- fin de su solución
DELIMITER ;







