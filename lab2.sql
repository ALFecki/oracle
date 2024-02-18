-- 1

CREATE TABLE groups(
    id NUMBER NOT NULL,
    name VARCHAR2(100) NOT NULL,
    c_val NUMBER, -- количество студентов
    CONSTRAINT group_pk PRIMARY KEY (id)

);

CREATE TABLE students(
    id NUMBER,
    name VARCHAR2(100) NOT NULL,
    group_id NUMBER,
    CONSTRAINT student_pk PRIMARY KEY (id),
    CONSTRAINT group_fk FOREIGN KEY(group_id) REFERENCES groups (id)
);


-- 2
CREATE OR REPLACE TRIGGER students_id_unique
BEFORE INSERT OR UPDATE ON students
FOR EACH ROW
DECLARE
    duplicate_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO duplicate_count
    FROM students
    WHERE id = :NEW.id;

    IF duplicate_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Duplicate ID value');
    END IF;
END;
/


CREATE OR REPLACE TRIGGER students_id_autoincrement
BEFORE INSERT ON students
FOR EACH ROW
DECLARE
    last_id NUMBER;
BEGIN
    SELECT MAX(id) INTO last_id
    FROM students;

    IF last_id IS NULL THEN
        :NEW.id := 1;
    ELSE
        :NEW.id := last_id + 1;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER groups_name_unique
BEFORE INSERT OR UPDATE ON groups
FOR EACH ROW
DECLARE
    duplicate_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO duplicate_count
    FROM groups
    WHERE name = :NEW.name;

    IF duplicate_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Duplicate NAME value');
    END IF;
END;
/

-- 3
CREATE OR REPLACE TRIGGER students_cascade_delete
BEFORE DELETE ON groups
FOR EACH ROW
BEGIN
    DELETE FROM students
    WHERE group_id = :OLD.id;
END;
/

-- 4
CREATE TABLE students_log (
    log_id NUMBER PRIMARY KEY,
    action VARCHAR2(10),
    student_id NUMBER,
    student_name VARCHAR2(100),
    action_date TIMESTAMP
);

CREATE SEQUENCE students_log_seq START WITH 1 INCREMENT BY 1;

CREATE OR REPLACE TRIGGER students_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON students
FOR EACH ROW
DECLARE
    v_action VARCHAR2(10);
BEGIN
    IF INSERTING THEN
        v_action := 'INSERT';
    ELSIF UPDATING THEN
        v_action := 'UPDATE';
    ELSIF DELETING THEN
        v_action := 'DELETE';
    END IF;

    INSERT INTO students_log (log_id, action, student_id, student_name, action_date)
    VALUES (students_log_seq.NEXTVAL, v_action, :OLD.id, :OLD.name, SYSTIMESTAMP);
END;
/

-- 5
CREATE OR REPLACE PROCEDURE restore_students_data(
    p_timestamp TIMESTAMP,
    p_offset INTERVAL DAY TO SECOND DEFAULT INTERVAL '0' DAY TO SECOND
)
AS
BEGIN
    CREATE TABLE students_restored AS SELECT * FROM students WHERE 1 = 0;

    INSERT INTO students_restored (id, name, group_id)
    SELECT id, name, group_id
    FROM students AS OF TIMESTAMP (p_timestamp + p_offset);

    DELETE FROM students;

    INSERT INTO students (id, name, group_id)
    SELECT id, name, group_id
    FROM students_restored;

    DROP TABLE students_restored;
END;
/