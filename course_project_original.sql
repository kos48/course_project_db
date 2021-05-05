-- DROP DATABASE IF EXISTS autoservice;
-- CREATE DATABASE autoservice;


/* База данных интернет сервиса для автомобилистов, для вывода информации о проведении технического обслуживания при определенном пробеге.
 * При введении марки, модели и пробега авто, должна предоставить данные о необходимых работах, 
 * заявленных заводом изготовителем(Техническое обслуживание),  
 */ 

USE autoservice;

/* создадим таблицу марок авто. */

CREATE TABLE auto_brand (
	id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
	brand VARCHAR(20) NOT NULL
	)ENGINE=InnoDB;
	
-- заполним таблицу
INSERT INTO auto_brand (brand)
VALUES ('Mercedes-Benz'),
		('Toyota'),
		('Mazda'),
		('Mitsubishi'),
		('Subaru'),
		('Audi'),
		('Wolksvagen'),
		('Kia'),
		('Hyundai'),
		('Skoda');

SELECT * FROM auto_brand;

/* создадим таблицу моделей
 * вообще должно быть на каждую модель своя таблица, но для простоты делаю одну*/

CREATE TABLE auto_model (
	id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
	model VARCHAR(30) NOT NULL,
	brand_id BIGINT UNSIGNED NOT NULL,
	UNIQUE INDEX model_unique_idx (model),
	CONSTRAINT fk_auto_model FOREIGN KEY (brand_id) REFERENCES auto_brand(id)
	);

-- заполним таблицу моделей
INSERT INTO auto_model(model, brand_id)
VALUES ('a-class', 1),
		('b-class', 1),
		('carolla', 2),
		('land-cruiser', 2),
		('3', 3),
		('6', 3),
		('lancer', 4),
		('impresa', 5),
		('A4', 6),
		('polo', 7),
		('ceed', 8),
		('solaris', 9),
		('octavia', 10);
	
SELECT * FROM auto_model
ORDER BY id ;

-- представление марка, модель, id 
 CREATE or replace VIEW view_brand_model_id
 AS 
 	SELECT ab.brand, am.model,ab.id AS id_brand, am.id AS id_model 
	FROM auto_model AS am 
		JOIN auto_brand AS ab ON am.brand_id = ab.id ;
  	
SELECT * FROM view_brand_model_id ;

-- DROP VIEW view_brand_model ;

-- триггер на добавление в спец табл авто всех зарегистрированных пользователей
-- создаем спец табл
create table auto_statistic(
	id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_auto_brand_id  BIGINT UNSIGNED NOT NULL,
    user_auto_model_id  BIGINT UNSIGNED NOT NULL,
    user_name VARCHAR(145) NOT NULL
    );
  -- создадим триггер  
-- DROP TRIGGER IF EXISTS auto_statistic_users;
delimiter //
CREATE TRIGGER auto_statistic_users AFTER INSERT ON users
FOR EACH ROW
BEGIN
	INSERT INTO  auto_statistic(user_auto_brand_id, user_auto_model_id, user_name)
	VALUES (NEW.user_auto_brand, NEW.user_auto_model, NEW.name);
END //
delimiter ;
 
 /* таблица для регистрации пользователя. Делаю простую */

CREATE TABLE users (
	id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
	name VARCHAR(145) NOT NULL, 
    user_auto_brand BIGINT UNSIGNED NOT NULL,
    user_auto_model BIGINT UNSIGNED NOT NULL,
    mileage BIGINT UNSIGNED NOT NULL COMMENT 'пробег автомобиля',
    CONSTRAINT fk_user_auto_brand FOREIGN KEY (user_auto_brand) REFERENCES auto_brand(id),
    CONSTRAINT fk_user_auto_model FOREIGN KEY (user_auto_model) REFERENCES auto_model(id)
	);

-- DROP TABLE users ;
-- заполним таблицу users
INSERT INTO users (name, user_auto_brand, user_auto_model, mileage)
VALUES ('Ivan', 10, 13, 90000),
		('Sergey', 2, 3 , 15000),
		('Mihail', 10, 13, 14500),
		('John', 10, 13, 73000),
		('Nikolay', 5, 8, 23500 ),
		('Anton', 9, 12, 43000),
		('Vladimir', 8, 11, 57300);
	
SELECT * FROM auto_statistic; -- смотрим сработал ли триггер

SELECT * FROM users;

 -- запрос пользователь, марка, модель, пробег
SELECT u.name, ab.brand, am.model, mileage_determination(u.id), u.mileage
	FROM 
		auto_brand AS ab 
		JOIN users AS u ON u.user_auto_brand = ab.id
		JOIN auto_model am ON u.user_auto_model = am.id; 
	
/* т к мне нужен пробег авто кратный 15000, создадим функцию */
	
-- функция преобразования пробега. Т,е пробег пользователя преобразуем в кратное 15000 
drop  function if exists mileage_determination;

delimiter //
create function mileage_determination(user_id BIGINT)
RETURNS BIGINT READS SQL DATA
BEGIN
    DECLARE x BIGINT;
    set x = (SELECT mileage FROM users WHERE id = user_id );
		if x < 20000 then return 15000;
        elseif (x > 20000 and x < 35000) then return 30000;
        elseif (x > 35000 and x < 50000) then return 45000;
        elseif (x > 50000 and x < 65000) then return 60000;
        elseif (x > 65000 and x < 80000) then return 75000;
        elseif (x > 80000 and x < 95000) then return 90000;
        end if;
end//

delimiter ;
select mileage_determination(4);

 -- запрос пользователь, марка, модель, пробег(через функцию), реальный пробег
SELECT u.name, ab.brand, am.model, mileage_determination(u.id), u.mileage
	FROM 
		auto_brand AS ab 
		JOIN users AS u ON u.user_auto_brand = ab.id
		JOIN auto_model am ON u.user_auto_model = am.id; 
	
-- создадим табл всех работ
CREATE TABLE all_work (
	id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
	name_work  VARCHAR(145) NOT NULL COMMENT 'наименование работ'
	);

INSERT INTO all_work (name_work)
	VALUES ('замена масла'), ('замена масленного фильтра'), ('замена салонного фильтра'), ('замена топливного фильтра'),
			('замена свечей зажигания'), ('замена тормозной жидкости'), ('замена тормозных колодок');
		
SELECT * FROM all_work;

/* таблица зап.частей */
CREATE TABLE spare_parts_catalogs (
	id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
	name VARCHAR(145) NOT NULL,
	work_id  BIGINT UNSIGNED NOT NULL,
	CONSTRAINT fk_spare_parts_catalogs_work_id FOREIGN KEY (work_id) REFERENCES all_work(id)
	);

-- заполним каталог
INSERT INTO spare_parts_catalogs (name, work_id)
	VALUES ('фильтр двигателя', 2), ('фильр салона', 3), ('масло двигателя', 1), ('колодки тормозные', 7), ('топливный фильтр', 4), 
	('свеча зажигания', 5), ('тормозная жидкость', 6);

SELECT * FROM spare_parts_catalogs;

	
-- делаем представления на каждое ТО 
 CREATE or replace VIEW view_working_15000
 AS 
 	SELECT aw.name_work, spc.name  
	FROM all_work aw 
	JOIN spare_parts_catalogs spc ON spc.work_id = aw.id 
		WHERE aw.id IN (1, 2, 3);


 CREATE or replace VIEW view_working_30000
 AS 
 	SELECT aw.name_work, spc.name  
	FROM all_work aw 
	JOIN spare_parts_catalogs spc ON spc.work_id = aw.id 
		WHERE aw.id IN (1, 2, 3) ;

 CREATE or replace VIEW view_working_45000
 AS 
 	SELECT aw.name_work, spc.name  
	FROM all_work aw 
	JOIN spare_parts_catalogs spc ON spc.work_id = aw.id 
		WHERE aw.id IN (1, 2, 3, 5);

 CREATE or replace VIEW view_working_60000
 AS 
 	SELECT aw.name_work, spc.name  
	FROM all_work aw 
	JOIN spare_parts_catalogs spc ON spc.work_id = aw.id 
		WHERE aw.id IN (1, 2, 3, 7);

 CREATE or replace VIEW view_working_75000
 AS 
 	SELECT aw.name_work, spc.name  
	FROM all_work aw 
	JOIN spare_parts_catalogs spc ON spc.work_id = aw.id 
		WHERE aw.id IN (1, 2, 3, 5, 6);

 CREATE or replace VIEW view_working_90000
 AS 
 	SELECT aw.name_work, spc.name  
	FROM all_work aw 
	JOIN spare_parts_catalogs spc ON spc.work_id = aw.id 
		WHERE aw.id IN (1, 2, 3, 4);

 SELECT * FROM view_working_75000;

-- процедура вывода листа работ и запчастей
-- drop procedure IF EXISTS show_works;

DELIMITER //
create procedure show_works(user_id BIGINT)
begin
	set @x = (select mileage_determination(user_id));
    if (@x = 15000) then SELECT * FROM view_working_15000;
    elseif (@x = 30000) then SELECT * FROM view_working_30000;
    elseif (@x = 45000) then SELECT * FROM view_working_45000;
    elseif (@x = 60000) then SELECT * FROM view_working_60000;
    elseif (@x = 75000) then SELECT * FROM view_working_75000;
    elseif (@x = 90000) then SELECT * FROM view_working_90000;
    end if;
end//

DELIMITER ;
call show_works(5);
select * from users;

-- табл с ценой на работы

CREATE TABLE price_works (
	brand_id BIGINT UNSIGNED NOT NULL COMMENT 'марка',
	model_id BIGINT UNSIGNED NOT NULL COMMENT 'модель',
	work_id BIGINT UNSIGNED NOT NULL COMMENT 'какая работа',
	price decimal(15,2) NOT NULL COMMENT 'цена',
	CONSTRAINT fk_number_of_spare_parts_brand_id FOREIGN KEY (brand_id) REFERENCES auto_brand(id),
	CONSTRAINT fk_number_of_spare_parts_model_id FOREIGN KEY (model_id) REFERENCES auto_model(id),
	CONSTRAINT fk_number_of_spare_parts_work_id FOREIGN KEY (work_id) REFERENCES all_work(id)
	);
DROP TABLE price_works;
SELECT * 
	FROM all_work aw 
	JOIN spare_parts_catalogs spc ON spc.work_id = aw.id;
-- заполним 
INSERT INTO price_works (brand_id, model_id, work_id, price)
	VALUES (1, 1, 1, 1000),(1, 1, 2, 1000), (1, 1, 3, 700), (1, 1, 4, 2500), (1, 1, 5, 1500), (1, 1, 6, 850), (1, 1, 7, 750), -- mers A
			(1, 2, 1, 1500), (1, 2, 2, 1200),  (1, 2, 3, 800), (1, 2, 4, 3000), (1, 2, 5, 1600), (1, 2, 6, 1000), (1, 2, 7, 750), -- mers B
			(2, 3, 1, 800), (2, 3, 2, 800), (2, 3, 3, 600), (2, 3, 4, 2000), (2, 3, 5, 1000), (2, 3, 6, 700), (2, 3, 7, 750), -- toy c
			(2, 4, 1, 1500), (2, 4, 2, 1600), (2, 4, 3, 1000), (2, 4, 4, 4500), (2, 4, 5, 3000), (2, 4, 6, 1300), (2, 4, 7, 750), -- to La Cru
			(3, 5, 1, 1000), (3, 5, 2, 800), (3, 5, 3, 500), (3, 5, 4, 2000), (3, 5, 5, 1000), (3, 5, 6, 800), (3, 5, 7, 750), -- Maz 3
			(3, 6, 1, 1600), (3, 6, 2, 1300), (3, 6, 3, 500), (3, 6, 4, 3000), (3, 6, 5, 1500), (3, 6, 6, 1200), (3, 6, 7, 750), -- Maz 6
			(4, 7, 1, 700), (4, 7, 2, 700), (4, 7, 3, 450), (4, 7, 4, 2000), (4, 7, 5, 1000), (4, 7, 6, 700), (4, 7, 7, 750), -- Mit Lan
			(5, 8, 1, 800), (5, 8, 2, 800), (5, 8, 3, 500), (5, 8, 4, 2000), (5, 8, 5, 1200), (5, 8, 6, 850), (5, 8, 7, 750), -- Su imp
			(6, 9, 1, 1200), (6, 9, 2, 1100), (6, 9, 3, 700), (6, 9, 4, 2200), (6, 9, 5, 2000), (6, 9, 6, 1500), (6, 9, 7, 750), -- A4
			(7, 10, 1, 450), (7, 10, 2, 500), (7, 10, 3, 400), (7, 10, 4, 1500), (7, 10, 5, 1000), (7, 10, 6, 700), (7, 10, 7, 750),-- W polo 
			(8, 11, 1, 700), (8, 11, 2, 700), (8, 11, 3, 500), (8, 11, 4, 1800), (8, 11, 5, 1200), (8, 11, 6, 800), (8, 11, 7, 750), -- Ki see
			(9, 12, 1, 400), (9, 12, 2, 500), (9, 12, 3, 450), (9, 12, 4, 1300), (9, 12, 5, 900), (9, 12, 6, 650), (9, 12, 7, 750), -- Hy sol
			(10, 13, 1, 700), (10, 13, 2, 800), (10, 13, 3, 600), (10, 13, 4, 1900), (10, 13, 5, 1500), (10, 13, 6, 1000), (10, 13, 7, 750); -- Sk oct;
			
-- процедура вывода работ, зап частей и цены на работу согласно пробегу авто пользователя
drop procedure IF EXISTS show_price;
DELIMITER //

create procedure show_price(user_id BIGINT)
begin
	set @x = (select mileage_determination(user_id));
    if (@x = 15000) then SELECT aw.name_work, spc.name, pw.price  
							FROM all_work aw 
								JOIN users u2 
								JOIN spare_parts_catalogs spc ON spc.work_id = aw.id
								JOIN price_works AS pw ON (pw.work_id = aw.id AND pw.model_id = u2.user_auto_model)
								JOIN auto_model am ON am.id = u2.user_auto_model
								JOIN auto_brand ab ON ab.id = u2.user_auto_brand 
									WHERE aw.id IN (1, 2, 3) AND u2.id = user_id;
        
    elseif (@x = 30000) then SELECT aw.name_work, spc.name, pw.price  
							FROM all_work aw 
								JOIN users u2 
								JOIN spare_parts_catalogs spc ON spc.work_id = aw.id
								JOIN price_works AS pw ON (pw.work_id = aw.id AND pw.model_id = u2.user_auto_model)
								JOIN auto_model am ON am.id = u2.user_auto_model
								JOIN auto_brand ab ON ab.id = u2.user_auto_brand 
									WHERE aw.id IN (1, 2, 3) AND u2.id = user_id;
                                    
    elseif (@x = 45000) then SELECT aw.name_work, spc.name, pw.price  
							FROM all_work aw 
								JOIN users u2 
								JOIN spare_parts_catalogs spc ON spc.work_id = aw.id
								JOIN price_works AS pw ON (pw.work_id = aw.id AND pw.model_id = u2.user_auto_model)
								JOIN auto_model am ON am.id = u2.user_auto_model
								JOIN auto_brand ab ON ab.id = u2.user_auto_brand 
									WHERE aw.id IN (1, 2, 3, 5) AND u2.id = user_id;
                                    
    elseif (@x = 60000) then SELECT aw.name_work, spc.name, pw.price  
							FROM all_work aw 
								JOIN users u2 
								JOIN spare_parts_catalogs spc ON spc.work_id = aw.id
								JOIN price_works AS pw ON (pw.work_id = aw.id AND pw.model_id = u2.user_auto_model)
								JOIN auto_model am ON am.id = u2.user_auto_model
								JOIN auto_brand ab ON ab.id = u2.user_auto_brand 
									WHERE aw.id IN (1, 2, 3, 7) AND u2.id = user_id;
                                    
    elseif (@x = 75000) then SELECT aw.name_work, spc.name, pw.price  
							FROM all_work aw 
								JOIN users u2 
								JOIN spare_parts_catalogs spc ON spc.work_id = aw.id
								JOIN price_works AS pw ON (pw.work_id = aw.id AND pw.model_id = u2.user_auto_model)
								JOIN auto_model am ON am.id = u2.user_auto_model
								JOIN auto_brand ab ON ab.id = u2.user_auto_brand 
									WHERE aw.id IN (1, 2, 3, 5, 6) AND u2.id = user_id;
                                    
    elseif (@x = 90000) then SELECT aw.name_work, spc.name, pw.price  
							FROM all_work aw 
								JOIN users u2 
								JOIN spare_parts_catalogs spc ON spc.work_id = aw.id
								JOIN price_works AS pw ON (pw.work_id = aw.id AND pw.model_id = u2.user_auto_model)
								JOIN auto_model am ON am.id = u2.user_auto_model
								JOIN auto_brand ab ON ab.id = u2.user_auto_brand 
									WHERE aw.id IN (1, 2, 3, 4) AND u2.id = user_id;
    end if;
end//

call show_price(4);
	


-- представления


