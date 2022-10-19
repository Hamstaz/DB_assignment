DROP TABLE IF EXISTS customer CASCADE;
DROP TABLE IF EXISTS bank_details CASCADE;
DROP TABLE IF EXISTS transaction CASCADE;
DROP TABLE IF EXISTS product CASCADE;
DROP TABLE IF EXISTS warehouse_item CASCADE;
DROP TABLE IF EXISTS store CASCADE;

CREATE TABLE bank_details (
	bank_id SERIAL PRIMARY KEY,
	bank_name VARCHAR(50) NOT NULL,
	bank_address VARCHAR(50) NOT NULL,
	bank_city VARCHAR(50) NOT NULL,
	bank_code VARCHAR(15) NOT NULL
);

CREATE TABLE customer (
	customer_id SERIAL PRIMARY KEY,
	customer_sname VARCHAR(20) NOT NULL,
	customer_name VARCHAR(20) NOT NULL,
	customer_address VARCHAR(50),
	customer_city VARCHAR(50),
	customer_phone VARCHAR(20) NOT NULL,
	customer_date_of_birth DATE,
	bank_id INTEGER REFERENCES bank_details(bank_id) NOT NULL,
	bank_account VARCHAR(30) NOT NULL
);

CREATE TABLE product (
	product_id SERIAL PRIMARY KEY,
	product_type VARCHAR(30) NOT NULL,
	product_name VARCHAR(100) NOT NULL,
	product_description VARCHAR(200),
	product_cost DECIMAL NOT NULL
);

CREATE TABLE transaction (
	transaction_id SERIAL PRIMARY KEY,
	customer_id INTEGER REFERENCES customer(customer_id) NOT NULL,
	product_id INTEGER REFERENCES product(product_id) NOT NULL,
	transaction_date DATE NOT NULL,
	delivery_date DATE NOT NULL,
	delivery_slot VARCHAR(9) NOT NULL	
);

CREATE TABLE store (
	store_id SERIAL PRIMARY KEY,
	store_address VARCHAR(50),
	store_city VARCHAR(50),
	store_phone VARCHAR(20)
);

CREATE TABLE  warehouse_item (
	store_id INTEGER REFERENCES store(store_id) NOT NULL,
	product_id INTEGER REFERENCES product(product_id) NOT NULL,
	stock_quantity SMALLINT NOT NULL,
	PRIMARY KEY(store_id, product_id)
);

INSERT INTO bank_details (bank_name, bank_address, bank_city, bank_code) 
VALUES 
('Lloyds Banking Group', '25 Gresham Street', 'London', '779181'),
('HSBC', '8 Canada Square', 'London', '448308'),
('Barclays', '1 Churchill Place', 'London', '203253')
 ; 
 
INSERT INTO customer (customer_sname, customer_name, customer_address, customer_city, customer_phone, customer_date_of_birth, bank_id, bank_account) 
VALUES 
('Farrell', 'John', '5 Ryhope Road', 'Newcastle', '0191 7659447', '1992-04-08', '1', 'GB45LOYD60161331926819'),
('Carling', 'Julie', '34 Jackson Drive', 'London', '0189 8886552', '1982-02-03', '3', 'GB54HBUK60161331926819'),
('Stones', 'Peter', '12 Bristol Road', 'London', '0154 2274197', '1978-01-09', '2', 'GB13BUKB60161331926819')
;

INSERT INTO product (product_type, product_name, product_description, product_cost)
VALUES
('Instrument', 'YAMAHA P-45', 'Digital piano', 499.99),
('Instrument', 'The Epiphone Les Paul Special VE', 'Electric guitar', 120.00),
('Sheet Music', 'Piano: David Bowie', 'Wise Publications Really Easy Piano: David Bowie', 15.50),
('DVD', 'HOW TO... Setup your drumkit!', 'DVD Drum Setup Workshop', 20.00),
('Instrument', 'Fame First Step Floor Tom 18"x16"', 'Drum set beginner, mixed wood, single drum, aluminum lugs', 48.00),
('DVD', 'Roadrock International Lick Library', 'Learn to play five hard rocking Whitesnake tracks, note-for-note with Danny Gill!Songlist', 23.40)
;

INSERT INTO transaction (customer_id, product_id, transaction_date, delivery_date, delivery_slot)
VALUES
('1', '2', '2022-10-16', '2022-10-18', 'morning'),
('3', '1', '2022-10-12', '2022-10-20', 'afternoon'),
('1', '2', '2022-10-16', '2022-10-18', 'morning'),
('2', '6', '2022-10-15', '2022-10-17', 'evening'),
('2', '5', '2022-10-14', '2022-12-30', 'evening')
;

INSERT INTO store (store_address, store_city, store_phone)
VALUES
('16 Rugby Drive', 'Newcastle', '0145 7776757'),
('25 Ryhope Road', 'London', '0283 4442478')
;

INSERT INTO warehouse_item (store_id, product_id, stock_quantity)
VALUES
('1', '1', '2'),
('1', '2', '4'),
('1', '3', '5'),
('1', '4', '0'),
('1', '5', '3'),
('1', '6', '8'),
('2', '1', '3'),
('2', '2', '0'),
('2', '3', '6'),
('2', '4', '7'),
('2', '5', '5'),
('2', '6', '3')
;

-- Function to search if a bank information exists in the database
CREATE OR REPLACE FUNCTION find_bank_id(search_bank_id bank_details.bank_id%TYPE)
	RETURNS bank_details.bank_id%TYPE 
LANGUAGE plpgsql
AS $$
  BEGIN
  SELECT bank_id INTO STRICT search_bank_id FROM bank_details
  WHERE bank_id = search_bank_id;
  RETURN search_bank_id;
 EXCEPTION
 	WHEN NO_DATA_FOUND THEN
 		RAISE NOTICE 'The bank information could not be found. Please add bank detials before registering a new customer.';
END;$$;

-- Procedure for registering a new customer
DROP PROCEDURE IF EXISTS new_customer;
CREATE OR REPLACE PROCEDURE new_customer (
	new_name customer.customer_sname%TYPE, 
	new_surname customer.customer_name%TYPE,
	new_address customer.customer_address%TYPE,
	new_city customer.customer_city%TYPE,
	new_phone customer.customer_phone%TYPE,
	new_date_of_birth customer.customer_date_of_birth%TYPE,
	new_bank_id customer.bank_id%TYPE,
	new_bank_account customer.bank_account%TYPE
)
LANGUAGE 'plpgsql'
AS $$
BEGIN 
new_bank_id = find_bank_id(new_bank_id);

IF EXISTS (SELECT customer_phone FROM customer 
              WHERE  new_phone = customer_phone
           ) THEN
      RAISE NOTICE 'Customer with the phone number % already registered.', new_phone;
   ELSE
  	INSERT INTO customer 
	(
	customer_name, 
	customer_sname,
	customer_address,
	customer_city,
	customer_phone,
	customer_date_of_birth,
	bank_id,
	bank_account
	)
	VALUES
	(new_name, new_surname, new_address, new_city, new_phone, new_date_of_birth, new_bank_id, new_bank_account);
	RAISE NOTICE '% % has been registered as a new customer', new_name, new_surname;
END IF;
END; $$;

-- Trigger for checking if a customer date of birth is invalid
CREATE OR REPLACE FUNCTION date_of_birth_error() RETURNS TRIGGER
LANGUAGE 'plpgsql'
AS
$BODY$
BEGIN
 RAISE EXCEPTION 'Date of birth should be > 1900-01-01';
END;
$BODY$;

DROP TRIGGER IF EXISTS check_date_of_birth ON customer;

CREATE TRIGGER check_date_of_birth
BEFORE INSERT ON customer
FOR EACH ROW
WHEN (new.customer_date_of_birth < '1900-01-01')
EXECUTE PROCEDURE date_of_birth_error();

-- Trigger if a product cost is invalid
CREATE OR REPLACE FUNCTION product_cost_error() RETURNS TRIGGER
LANGUAGE 'plpgsql'
AS
$BODY$
BEGIN
 RAISE EXCEPTION 'Product cost can not be < 0';
END;
$BODY$;

DROP TRIGGER IF EXISTS check_product_cost ON product;

CREATE TRIGGER check_product_cost
BEFORE INSERT ON product
FOR EACH ROW
WHEN (new.product_cost < 0)
EXECUTE PROCEDURE product_cost_error();

-- Trigger if a delivery date is invalid
CREATE OR REPLACE FUNCTION delivery_date_error() RETURNS TRIGGER
LANGUAGE 'plpgsql'
AS
$BODY$
BEGIN
 RAISE EXCEPTION 'The delivery date must be after purchase date!';
END;
$BODY$;

DROP TRIGGER IF EXISTS check_delivery_date ON transaction;

CREATE TRIGGER check_delivery_date
BEFORE INSERT ON transaction
FOR EACH ROW
WHEN (new.delivery_date < new.transaction_date)
EXECUTE PROCEDURE delivery_date_error();

-- Trigger if a stock quantity is invalid
CREATE OR REPLACE FUNCTION stock_quantity_error() RETURNS TRIGGER
LANGUAGE 'plpgsql'
AS
$BODY$
BEGIN
 RAISE EXCEPTION 'Stock quantity can not be less than 0.';
END;
$BODY$;

DROP TRIGGER IF EXISTS check_stock_quantity ON warehouse_item;

CREATE TRIGGER check_stock_quantity
BEFORE INSERT ON warehouse_item
FOR EACH ROW
WHEN (new.stock_quantity < 0)
EXECUTE PROCEDURE stock_quantity_error();

-- Function to check if a customer is already registered
CREATE OR REPLACE FUNCTION if_customer_exists(find_customer customer.customer_id%TYPE)
	RETURNS customer.customer_id%TYPE 
LANGUAGE plpgsql
AS $$
  BEGIN
  SELECT customer_id 
  INTO STRICT find_customer 
  FROM customer
  WHERE customer_id = find_customer;
  RETURN find_customer;
  EXCEPTION
  	WHEN NO_DATA_FOUND THEN
		RAISE NOTICE 'The customer is not registered';
END;$$;

-- Function to check if a product exists
CREATE OR REPLACE FUNCTION if_product_exists(find_product_id product.product_id%TYPE)
   RETURNS product.product_id%TYPE
   LANGUAGE plpgsql
  AS
$$
BEGIN
 SELECT product_id
 INTO STRICT find_product_id
 FROM product
 WHERE product_id = find_product_id;
  RETURN find_product_id;
EXCEPTION
 	WHEN NO_DATA_FOUND THEN
 		RAISE NOTICE 'The product is not found';
END;
$$;

-- Function to check if a product is in stock
CREATE OR REPLACE FUNCTION check_if_in_stock(my_store_id store.store_id%TYPE, my_product_id product.product_id%TYPE)
returns BOOLEAN
language plpgsql
  as $$
BEGIN
my_product_id = if_product_exists(my_product_id);
IF (SELECT stock_quantity FROM warehouse_item
 WHERE store_id = my_store_id
	AND product_id = my_product_id) > 0 THEN
RETURN True;
ELSE
	RAISE NOTICE 'Product is not in stock';
	RETURN False;
END IF;
END
$$;

-- Function to check if a delivery slot is available
CREATE OR REPLACE FUNCTION delivery_slot_availability(my_date transaction.delivery_date%TYPE, my_slot transaction.delivery_slot%TYPE)
RETURNS BOOLEAN
LANGUAGE plpgsql
	AS $$
	DECLARE 
	result INTEGER; 
	BEGIN
		IF my_date < CURRENT_DATE THEN
			RAISE EXCEPTION 'The delivery date can not be in the past';
		END IF;
		IF my_slot <> 'morning' AND my_slot <> 'afternoon' AND my_slot <> 'evening' THEN
			RAISE EXCEPTION 'The delivery slot must be morning, afternoon or evening!';
		END IF;
		SELECT COUNT(delivery_date) INTO result FROM transaction
			WHERE my_date = transaction.delivery_date AND my_slot = transaction.delivery_slot;
		IF result = 0 THEN
			RETURN 1;
		ELSE
			RAISE NOTICE 'Delivery slot is not available!';
			RETURN 0;
		END IF;	
END; $$;

-- Procedure for purchasing a product
DROP PROCEDURE IF EXISTS new_purchase;
CREATE OR REPLACE PROCEDURE new_purchase (
	my_store store.store_id%TYPE,
	my_customer customer.customer_id%TYPE, 
	my_product product.product_id%TYPE,
	my_date transaction.delivery_date%TYPE,
	my_slot transaction.delivery_slot%TYPE
	)
LANGUAGE plpgsql    
AS $$
DECLARE
product_in_stock BOOLEAN;
delivery_check BOOLEAN;

BEGIN
	--checking if a customer exists and a product is in stock
	my_customer = if_customer_exists(my_customer);
	product_in_stock = check_if_in_stock(my_store, my_product);
	IF product_in_stock = False THEN
		RETURN;
	ELSEIF product_in_stock = True THEN
		--checking if delivery is available:
		delivery_check = delivery_slot_availability(my_date, my_slot);
			IF delivery_check = True THEN
				-- Updating transaction table with a new purchase information 
				INSERT INTO transaction (customer_id, product_id, transaction_date, delivery_date, delivery_slot )
					VALUES (
					my_customer,
					my_product,
					CURRENT_DATE,
					my_date,
					my_slot
					);
				-- Updating warehouse_item table and subtracting stock quantity
				UPDATE warehouse_item SET stock_quantity=stock_quantity - 1 
				WHERE store_id=my_store AND product_id=my_product;
					RAISE NOTICE 'The customer % % has bought the product %. The delivery is scheduled for %, %', 
					customer.customer_name FROM customer WHERE customer_id = my_customer,
					customer.customer_sname FROM customer WHERE customer_id = my_customer,
					product.product_name FROM product WHERE product_id = my_product,
					my_date, my_slot;
		END IF;
	END IF;
COMMIT;
END; $$;
