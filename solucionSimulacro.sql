-- Ejercicio 1
-- Tener disponible información sobre las valoraciones que cada usuario haya podido realizar para cada juego, 
-- teniendo en cuenta que un usuario puede valorar muchos juegos, y un juego puede ser valorado por muchos usuarios. 
-- Es necesario guardar información de la fecha de la valoración, la puntuación que ha otorgado cada usuario a cada juego, 
-- su opinión en forma de texto, el número de “likes” que ha recibido esa valoración por parte de otros usuarios 
-- y el veredicto final sobre el juego. 
-- Todos los atributos son obligatorios salvo el número de “likes”, que por defecto será 0.

CREATE TABLE valoraciones(
	idValoracion INT NOT NULL AUTO_INCREMENT,
	idUser INT NOT NULL,
	idJuego INT NOT NULL,
	fecha DATE NOT NULL,
	puntuacion DECIMAL(2,1) NOT NULL,
	opinion TEXT NOT NULL,
	likes INT DEFAULT 0,
	veredicto VARCHAR(64) NOT NULL,
	PRIMARY KEY(idValoracion),
	FOREIGN KEY(idUser) REFERENCES jugadores(jugadorId),
	FOREIGN KEY(idJuego) REFERENCES videojuegos(videojuegoId),
	CONSTRAINT RN01 CHECK(puntuacion >= 0 AND puntuacion <=5 ),
	CONSTRAINT RN02 CHECK(veredicto IN ('Imprescindible', 'Recomendado', 'Comprar en rebajas', 'No merece la pena')),
	CONSTRAINT RN03 UNIQUE(idUser,idJuego)
);

-- Ejercicio 2

-- Codifique un procedimiento almacenado que inserte una nueva valoración de un usuario concreto para un 
-- juego dado en la tabla creada en el ejercicio anterior, que será llamado tantas veces como progresos se deseen añadir

DELIMITER //
CREATE OR REPLACE PROCEDURE pInsertar(id_u INT, id_j INT, f DATE, p DECIMAL(2,1), o TEXT, v VARCHAR(64))
BEGIN 
	INSERT INTO valoraciones(idUser, idJuego, fecha, puntuacion, opinion, veredicto) VALUES
	(id_u,id_j, f, p, o, v);
END //
DELIMITER ;

CALL pInsertar(1,2,CURDATE(),5,'El mejor que he probado', 'Imprescindible');
CALL pInsertar(2,4,CURDATE(),3,'No está mal', 'Comprar en rebajas');
CALL pInsertar(3,3,CURDATE(),4,'Muy bueno', 'Recomendado');
CALL pInsertar(4,5,CURDATE(),1,'Malísimo', 'No merece la pena');
CALL pInsertar(5,8,'1990-08-07',4.5,'Buenísimo', 'Imprescindible');

CALL pInsertar(1,6,CURDATE(),10,'Buenísimo', 'Imprescindible');
CALL pInsertar(2,3,CURDATE(),4.5,'Buenísimo', 'Ni fu ni fa');
CALL pInsertar(3,3,CURDATE(),4.5,'Buenísimo', 'Imprescindible');

-- Ejercicio 3

SELECT * 
FROM jugadores NATURAL JOIN videojuegos NATURAL JOIN valoraciones
ORDER BY videojuegoId;

-- Ejercicio 4

-- Codifique un trigger para impedir que la fecha de una valoración sea anterior 
-- a la fecha de lanzamiento del juego, y posterior a la fecha actual

DELIMITER //
CREATE OR REPLACE TRIGGER tFechaAnt
BEFORE INSERT ON valoraciones
FOR EACH ROW
BEGIN
	DECLARE fechaJuego DATE;
	SET fechaJuego = (SELECT fechaLanzamiento FROM videojuegos WHERE VideojuegoId=NEW.idJuego);
	
	if (NEW.fecha < fechaJuego OR NEW.fecha > CURDATE()) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'La fecha de valoración no es válida.';
	END IF;
END //
DELIMITER ;

CALL pInsertar(1,1,'2025-01-1',5,'Me encantó','Imprescindible');

-- Ejercicio 5
-- Codifique una función que devuelva el número de valoraciones de un usuario dado.

DELIMITER //
CREATE OR REPLACE function fNumVal(id INT) 
RETURNS INT
BEGIN
	DECLARE num INT;
	
	SET num = (SELECT COUNT(idUser) FROM valoraciones WHERE idUser=id);
	
	RETURN num;

END //
DELIMITER ;

SELECT fNumVal(1);

-- Ejercicio 6

SELECT v.nombre, AVG(va.puntuacion) AS media
FROM videojuegos v
LEFT JOIN valoraciones va ON va.idJuego=v.videojuegoId
GROUP BY v.nombre
ORDER BY media DESC;

-- Ejercicio 7

DELIMITER //
CREATE OR REPLACE TRIGGER tInsertBeta
BEFORE INSERT ON valoraciones
FOR EACH ROW
BEGIN
	DECLARE fase VARCHAR(64);
	SET fase = (SELECT estado FROM videojuegos WHERE videojuegoId=NEW.idJuego);
	
	if (fase = 'Beta') then
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'No puedes valorar un juego en fase beta';
	END if;
END //
DELIMITER ;

CALL pInsertar(1,6,CURDATE(),5,'Me encantó','Imprescindible');

-- Ejercicio 8

DELIMITER //
CREATE OR REPLACE PROCEDURE pAddUsuarioValoracion(ji INT, nick VARCHAR (60),
																  id_j INT, f DATE, p DECIMAL(2,1), o TEXT, v VARCHAR(64))
BEGIN 
	
	START TRANSACTION;
	
	INSERT INTO jugadores(jugadorId, nickname) VALUES
	(ji, nick);
	
	INSERT INTO valoraciones(idUser, idJuego, fecha, opinion, puntuacion, veredicto) VALUES
	(ji,id_j, f, p,o, v);
	
	COMMIT;
	
END //
DELIMITER ;

CALL pAddUsuarioValoracion(6, 'guilleton04', 4, CURDATE(), 4.7, 'Me encantó', 'Imprescindible');
CALL pAddUsuarioValoracion(9, 'pepa', 30, CURDATE(), 4.1, 'Me encantó', 'Imprescindible');