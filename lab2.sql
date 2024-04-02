-- 1

CREATE TABLE groups(
    id NUMBER PRIMARY KEY,
    name VARCHAR2(100) NOT NULL,
    c_val NUMBER, -- количество студентов
);

CREATE TABLE students(
    id NUMBER,
    name VARCHAR2(100) NOT NULL,
    group_id NUMBER,
    FOREIGN KEY(group_id) REFERENCES groups (id)
);


INSERT INTO GROUPS (ID, NAME, C_VAL) VALUES (1, 'Group A', 10);
INSERT INTO GROUPS (ID, NAME, C_VAL) VALUES (2, 'Group B', 15);
INSERT INTO GROUPS (ID, NAME, C_VAL) VALUES (3, 'Group C', 12);

INSERT INTO STUDENTS (ID, NAME, GROUP_ID) VALUES (1, 'John Smith', 1);
INSERT INTO STUDENTS (ID, NAME, GROUP_ID) VALUES (2, 'Jane Doe', 1);
INSERT INTO STUDENTS (ID, NAME, GROUP_ID) VALUES (3, 'Michael Johnson', 2);
INSERT INTO STUDENTS (ID, NAME, GROUP_ID) VALUES (4, 'Emily Williams', 3);

-- 2
CREATE OR REPLACE TRIGGER unique_id_students
FOR INSERT OR UPDATE ON students
COMPOUND TRIGGER

TYPE t_students_id IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
v_students_id t_students_id;

BEFORE STATEMENT IS
BEGIN
    v_students_id.DELETE;
END BEFORE STATEMENT;

BEFORE EACH ROW IS
BEGIN
    IF INSERTING OR UPDATING THEN
        v_students_id(v_students_id.COUNT + 1) := :NEW.ID;
    END IF;
END BEFORE EACH ROW;

AFTER STATEMENT IS
    v_id_count NUMBER;
BEGIN
    FOR i IN 1 .. v_students_id.COUNT 
    LOOP
        SELECT COUNT(*)
        INTO v_id_count
        FROM students
        WHERE id = v_students_id(i);
        
        DBMS_OUTPUT.PUT_LINE('Count row ' || v_id_count);
        IF v_id_count <> 1 THEN
            RAISE_APPLICATION_ERROR(-20001, 'This student id exists: ' || v_students_id(i));
        END IF;
    END LOOP;
END AFTER STATEMENT;
END unique_id_students;
/


CREATE OR REPLACE SEQUENCE students_id_seq
START WITH 1
INCREMENT BY 1;


CREATE OR REPLACE TRIGGER check_unique_id_groups
BEFORE INSERT ON groups
FOR EACH ROW
DECLARE
    id_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO id_count
    FROM groups
    WHERE ID = :NEW.ID;

    IF id_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'ID already exists in groups');
    END IF;
END;


CREATE OR REPLACE TRIGGER check_group_name
FOR INSERT OR UPDATE ON groups
COMPOUND TRIGGER

TYPE t_group_names IS TABLE OF VARCHAR2(100) INDEX BY PLS_INTEGER;
v_group_names t_group_names;

BEFORE STATEMENT IS
BEGIN
    v_group_names.DELETE;
END BEFORE STATEMENT;

BEFORE EACH ROW IS
BEGIN
    IF INSERTING OR UPDATING THEN
        v_group_names(v_group_names.COUNT + 1) := :NEW.name;
    END IF;
END BEFORE EACH ROW;

AFTER STATEMENT IS
    v_name_count NUMBER;
BEGIN
    FOR i IN 1 .. v_group_names.COUNT 
    LOOP
        SELECT COUNT(*)
        INTO v_name_count
        FROM groups
        WHERE name = v_group_names(i);
        
        DBMS_OUTPUT.PUT_LINE('Count row ' || v_name_count);
        IF v_name_count <> 1 THEN
            RAISE_APPLICATION_ERROR(-20001, 'This group name exists: ' || v_group_names(i));
        END IF;
    END LOOP;
END AFTER STATEMENT;
END check_group_name;
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
    group_id NUMBER,
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
        INSERT INTO students_log (log_id, action, student_id, student_name, group_id, action_date)
            VALUES (students_log_seq.NEXTVAL, v_action, :NEW.id, :NEW.name, :NEW.group_id, SYSTIMESTAMP);
    ELSIF UPDATING THEN
        v_action := 'UPDATE';
        INSERT INTO students_log (log_id, action, student_id, student_name, group_id, action_date)
            VALUES (students_log_seq.NEXTVAL, v_action, :NEW.id, :NEW.name, :NEW.group_id,  SYSTIMESTAMP);
    ELSIF DELETING THEN
        v_action := 'DELETE';
        INSERT INTO students_log (log_id, action, student_id, student_name, group_id, action_date)
            VALUES (students_log_seq.NEXTVAL, v_action, :OLD.id, :OLD.name, :OLD.group_id, SYSTIMESTAMP);
    END IF;
END;
/

-- 5
CREATE OR REPLACE PROCEDURE restore_students(
    restore_time TIMESTAMP DEFAULT NULL,
    time_offset INTERVAL DAY TO SECOND DEFAULT NULL
) 
AS
    restore_timestamp TIMESTAMP;
BEGIN
    IF restore_time IS NULL AND time_offset IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001, 'Procedure need correct parameters.');
    END IF;

    IF restore_time IS NOT NULL THEN
        restore_timestamp := restore_time;
    ELSE
        restore_timestamp := SYSTIMESTAMP - time_offset;
    END IF;
    DELETE students;
    FOR log_record IN (SELECT * FROM students_log WHERE action_date <= restore_timestamp) 
    LOOP
        IF log_record.action = 'INSERT' THEN
            IF log_record.student_id IS NOT NULL THEN
                DELETE FROM students WHERE id = log_record.student_id; 
            END IF;
            INSERT INTO students (id, name, group_id)
            VALUES (log_record.student_id, log_record.student_name, log_record.group_id);
        ELSIF log_record.action = 'UPDATE' THEN
            UPDATE students
            SET name = log_record.student_name, group_id = log_record.group_id
            WHERE id = log_record.student_id;
        ELSIF log_record.action = 'DELETE' THEN
            DELETE FROM students WHERE id = log_record.student_id;
        END IF;
    END LOOP;
END;
/

BEGIN
    restore_students(TIMESTAMP '2024-02-28 12:50:00');
END;
/

-- 6
CREATE OR REPLACE TRIGGER students_update_groups
AFTER INSERT OR UPDATE OR DELETE ON students
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        UPDATE groups
        SET c_val = c_val + 1
        WHERE id = :NEW.group_id;
    ELSIF UPDATING THEN
        IF :NEW.group_id <> :OLD.group_id THEN
            UPDATE groups
            SET c_val = c_val + 1
            WHERE id = :NEW.group_id;
            UPDATE groups   
            SET c_val = c_val - 1
            WHERE id = :OLD.group_id;
        END IF;
    ELSIF DELETING THEN
        UPDATE groups
        SET c_val = c_val - 1
        WHERE id = :OLD.group_id;
    END IF;
END;
/