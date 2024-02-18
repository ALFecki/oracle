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