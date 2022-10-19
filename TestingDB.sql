-- Testing a new customer registration procedure: 
-- unknown bank_id, error message is expected:
CALL new_customer ('Riddell', 'Hugh','25 Arlington Crescent', 'London', '0151 1375232', '1995-03-05', '5', 'GB45LOYD60153234927833');
-- invalid date of birth, error message is expected
CALL new_customer ('Riddell', 'Hugh','25 Arlington Crescent', 'London', '0151 1375232', '1111-03-05', '1', 'GB45LOYD60153234927833');
-- correct registraion 
CALL new_customer ('Riddell', 'Hugh','25 Arlington Crescent', 'London', '0151 1375232', '1995-03-05', '1', 'GB45LOYD60153234927833');
-- verifying new customer was registered
SELECT * FROM customer;
-- existing customer, error message is expected
CALL new_customer ('Riddell', 'Hugh','25 Arlington Crescent', 'London', '0151 1375232', '1995-03-05', '1', 'GB45LOYD60153234927833');


-- Testing the trigger if a product cost is invalid (error message is expected)
INSERT INTO product (product_type, product_name, product_description, product_cost)
VALUES('Instrument', 'YAMAHA P-55', 'Digital piano', -10);

-- Testing the trigger if a quantity of stock is invalid (error message is expected)
INSERT INTO warehouse_item (store_id, product_id, stock_quantity)
VALUES ('1', '1', '-1');

-- Testing the function to check if a customer is registered (with invalid customer_id, error message is expected)
SELECT if_customer_exists(7);

-- Testing the function to check if a product exists (with invalid product_id, error message is expected)
SELECT if_product_exists(9);

-- Testing the trigger if delivery date is invalid (with delivery date in the past, error message is expected)
INSERT INTO transaction (customer_id, product_id, transaction_date, delivery_date, delivery_slot)
VALUES ('1', '2', '2022-10-20', '2022-10-15', 'morning');

-- Testing the function to check if a product is in stock (with stock quantity is 0, error message is expected)
SELECT check_if_in_stock(1, 4);

-- Testing the function to check if a delivery slot is available (delivery slot is not available, error message is expected)
SELECT delivery_slot_availability('2022-10-20', 'afternoon');

-- Testing purchasing a product procedure:
-- unknown customer, error message is expected
CALL new_purchase(1, 7, 3, '2022-12-30', 'morning');
-- unknown product, error message is expected
CALL new_purchase (1, 2, 30, '2022-12-30', 'morning');
-- product not in stock, error message is expected
CALL new_purchase (1, 2, 4, '2022-12-30', 'morning');
-- delivery date in the past, error message is expected
CALL new_purchase (1, 2, 5, '2022-09-30', 'morning');
-- delivery slot is not available, error message is expected
CALL new_purchase (1, 2, 5, '2022-12-30', 'evening');

--Checking transaction and warehouse_item tables before running a successfull purchase:
SELECT * FROM transaction;
SELECT * FROM warehouse_item;
--Making a purchase:
CALL new_purchase (1, 2, 5, '2022-12-31', 'afternoon');
--Checking transaction table is updated:
SELECT * FROM transaction;
--Checking that the quantity of a product in stock has decreased:
SELECT * FROM warehouse_item;


