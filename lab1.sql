-- 1
CREATE TABLE MyTable (
  id NUMBER,
  val NUMBER
);

-- 2
BEGIN
  FOR i IN 1..10 LOOP
    INSERT INTO MyTable (id, val)
    VALUES (i, ROUND(DBMS_RANDOM.VALUE(1, 10000), 0));
  END LOOP;
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Записи успешно добавлены в таблицу MyTable.');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Произошла ошибка: ' || SQLERRM);
    ROLLBACK;
END;
/


-- 3
CREATE OR REPLACE FUNCTION CheckEvenOddCount
  RETURN VARCHAR2
IS
  evenCount NUMBER := 0;
  oddCount NUMBER := 0;
BEGIN
  SELECT COUNT(*) INTO evenCount
  FROM MyTable
  WHERE MOD(val, 2) = 0;
  
  SELECT COUNT(*) INTO oddCount
  FROM MyTable
  WHERE MOD(val, 2) = 1;
  
  IF evenCount > oddCount THEN
    RETURN 'TRUE';
  ELSIF evenCount < oddCount THEN
    RETURN 'FALSE';
  ELSE
    RETURN 'EQUAL';
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    RETURN 'ERROR';
END;
/


DECLARE
  result VARCHAR2(10);
BEGIN
  result := CheckEvenOddCount();
  DBMS_OUTPUT.PUT_LINE('Результат: ' || result);
END;
/

-- 4
CREATE OR REPLACE FUNCTION GenerateInsertStatementErrorHandling(p_id NUMBER, p_val NUMBER)
  RETURN VARCHAR2
IS
  l_count NUMBER;
  v_insert_statement VARCHAR2(4000);
BEGIN
  SELECT COUNT(*) INTO l_count
  FROM MyTable
  WHERE id = p_id;
  
  IF l_count > 0 THEN
    DBMS_OUTPUT.PUT_LINE('Ошибка: Запись с ID ' || p_id || ' уже существует.');
    RETURN NULL;
  END IF;

  v_insert_statement := 'INSERT INTO MyTable (id, val) VALUES (' || p_id || ', ' || p_val || ');';
  DBMS_OUTPUT.PUT_LINE(v_insert_statement);
  
  RETURN v_insert_statement;

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Произошла ошибка: ' || SQLERRM);
    RETURN NULL;
END;


CREATE OR REPLACE FUNCTION GenerateInsertStatement(p_id NUMBER)
  RETURN VARCHAR2
IS
  v_val NUMBER;
  v_insert_statement VARCHAR2(4000);
BEGIN

  SELECT val INTO v_val
  FROM MyTable
  WHERE id = p_id;
  
  v_insert_statement := 'INSERT INTO MyTable (id, val) VALUES (' || p_id || ', ' || v_val || ');';
  
  DBMS_OUTPUT.PUT_LINE(v_insert_statement);
  
  RETURN v_insert_statement;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('Запись с ID ' || p_id || ' не найдена.');
    RETURN NULL;
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Произошла ошибка: ' || SQLERRM);
    RETURN NULL;
END;
/

DECLARE
  insert_statement VARCHAR2(4000);
BEGIN
  insert_statement := GenerateInsertStatement(123);
END;
/

-- 5
CREATE OR REPLACE PROCEDURE InsertRecord(p_id NUMBER, p_val NUMBER)
IS
  l_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO l_count
  FROM MyTable
  WHERE id = p_id;
  
  IF l_count > 0 THEN
    DBMS_OUTPUT.PUT_LINE('Ошибка: Запись с ID ' || p_id || ' уже существует.');
    RETURN;
  END IF;

  INSERT INTO MyTable (id, val)
  VALUES (p_id, p_val);
  
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Запись с ID ' || p_id || ' успешно добавлена.');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Произошла ошибка: ' || SQLERRM);
    ROLLBACK;
END;
/

CREATE OR REPLACE PROCEDURE UpdateRecord(p_id NUMBER, p_new_val NUMBER)
IS
BEGIN
  UPDATE MyTable
  SET val = p_new_val
  WHERE id = p_id;
  
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Запись с ID ' || p_id || ' успешно обновлена.');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Произошла ошибка: ' || SQLERRM);
    ROLLBACK;
END;
/

CREATE OR REPLACE PROCEDURE DeleteRecord(p_id NUMBER)
IS
  l_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO l_count
  FROM MyTable
  WHERE id = p_id;
  
  IF l_count = 0 THEN
    DBMS_OUTPUT.PUT_LINE('Ошибка: Запись с ID ' || p_id || ' не существует.');
    RETURN;
  END IF;

  DELETE FROM MyTable
  WHERE id = p_id;
  
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Запись с ID ' || p_id || ' успешно удалена.');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Произошла ошибка: ' || SQLERRM);
    ROLLBACK;
END;
/

BEGIN
  InsertRecord(123, 456);
END;
/

BEGIN
  UpdateRecord(123, 789);
END;
/

BEGIN
  DeleteRecord(123);
END;
/


-- 6
CREATE OR REPLACE FUNCTION CalculateAnnualCompensation(p_monthly_salary NUMBER, p_annual_bonus_percentage VARCHAR)
  RETURN NUMBER
IS
  p_annual_bonus_percentage_number NUMBER;
  v_annual_bonus_percentage_decimal NUMBER;
  v_annual_compensation NUMBER;
BEGIN
  IF NOT REGEXP_LIKE(p_annual_bonus_percentage, '^-*[[:digit:]]+$') THEN
    RAISE_APPLICATION_ERROR(-20001, 'Процент годовых премиальных должен быть числом.');
  END IF;
  IF NOT REGEXP_LIKE(p_monthly_salary, '^-*[[:digit:]]+$') THEN
      RAISE_APPLICATION_ERROR(-20001, 'Зарплата должна быть числом.');
  END IF;
  p_annual_bonus_percentage_number := CAST(p_annual_bonus_percentage AS NUMBER);

  IF p_annual_bonus_percentage < 0 THEN
    RAISE_APPLICATION_ERROR(-20001, 'Процент годовых премиальных не может быть отрицательным.');
  END IF;
  IF p_monthly_salary < 0 THEN 
    RAISE_APPLICATION_ERROR(-20001, 'Зарплата не может быть отрицательной.');
  END IF;
  
  v_annual_bonus_percentage_decimal := p_annual_bonus_percentage / 100;
  v_annual_compensation := (1 + v_annual_bonus_percentage_decimal) * 12 * p_monthly_salary;
  
  RETURN v_annual_compensation;
EXCEPTION
  WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20002, 'Произошла ошибка: ' || SQLERRM);
END;
/


DECLARE
  monthly_salary NUMBER := 5000;
  annual_bonus_percentage NUMBER := 10;
  annual_compensation NUMBER;
BEGIN
  annual_compensation := CalculateAnnualCompensation(monthly_salary, annual_bonus_percentage);
  DBMS_OUTPUT.PUT_LINE('Общее вознаграждение за год: ' || annual_compensation);
END;
/