-- TABLES
CREATE TABLE uni (
    uni_id NUMBER GENERATED BY DEFAULT ON NULL AS IDENTITY,
    uni_name VARCHAR2(20) NOT NULL,
    creation_date timestamp,
    CONSTRAINT uni_id_pk PRIMARY KEY (uni_id)
);

CREATE TABLE groups (
    gr_id NUMBER GENERATED BY DEFAULT ON NULL AS IDENTITY,
    gr_name VARCHAR2(20) NOT NULL,
    uni_id NUMBER NOT NULL,
    creation_date timestamp,
    CONSTRAINT gr_id_pk PRIMARY KEY (gr_id)
);

CREATE TABLE students (
    st_id NUMBER GENERATED BY DEFAULT ON NULL AS IDENTITY,
    st_name VARCHAR2(20) NOT NULL,
    gr_id NUMBER NOT NULL,
    enter_date timestamp,
    CONSTRAINT st_id_pk PRIMARY KEY (st_id)
);

-- LOGS
CREATE TABLE uni_logs (
    action_id NUMBER GENERATED BY DEFAULT ON NULL AS IDENTITY,
    uni_id NUMBER NOT NULL,
    uni_name VARCHAR2(20) NOT NULL,
    creation_date timestamp,
    change_date timestamp,
    change_type VARCHAR2(6),
    CONSTRAINT uni_logs_id_pk PRIMARY KEY (action_id)
);

CREATE TABLE groups_logs (
    action_id NUMBER GENERATED BY DEFAULT ON NULL AS IDENTITY,
    gr_id NUMBER NOT NULL,
    gr_name VARCHAR2(20) NOT NULL,
    uni_id NUMBER NOT NULL,
    creation_date timestamp,
    change_date timestamp,
    change_type VARCHAR2(6),
    CONSTRAINT gr_logs_id_pk PRIMARY KEY (action_id)
);

CREATE TABLE students_logs (
    action_id NUMBER GENERATED BY DEFAULT ON NULL AS IDENTITY,
    st_id NUMBER NOT NULL,
    st_name VARCHAR2(20) NOT NULL,
    gr_id NUMBER NOT NULL,
    enter_date timestamp,
    change_date timestamp,
    change_type VARCHAR2(6),
    CONSTRAINT stud_logs_id_pk PRIMARY KEY (action_id)
);

CREATE TABLE reports_logs (
    id NUMBER GENERATED ALWAYS AS IDENTITY,
    report_date timestamp,
    CONSTRAINT pk_reports_logs PRIMARY KEY (id)
);

-- TRIGGERS LOGS
CREATE
OR REPLACE TRIGGER tr_uni
AFTER
INSERT
    OR
UPDATE
    OR DELETE ON uni FOR EACH ROW BEGIN IF inserting THEN
INSERT INTO
    uni_logs (
        uni_id,
        uni_name,
        creation_date,
        change_date,
        change_type
    )
VALUES
    (
        :new.uni_id,
        :new.uni_name,
        :new.creation_date,
        systimestamp,
        'INSERT'
    );

ELSIF deleting THEN
INSERT INTO
    uni_logs (
        uni_id,
        uni_name,
        creation_date,
        change_date,
        change_type
    )
VALUES
    (
        :old.uni_id,
        :old.uni_name,
        :old.creation_date,
        systimestamp,
        'DELETE'
    );

ELSIF updating THEN
INSERT INTO
    uni_logs (
        uni_id,
        uni_name,
        creation_date,
        change_date,
        change_type
    )
VALUES
    (
        :new.uni_id,
        :new.uni_name,
        :new.creation_date,
        systimestamp,
        'UPDATE'
    );

END IF;

END;

CREATE
OR REPLACE TRIGGER tr_groups
AFTER
INSERT
    OR
UPDATE
    OR DELETE ON groups FOR EACH ROW BEGIN IF inserting THEN
INSERT INTO
    groups_logs (
        gr_id,
        gr_name,
        uni_id,
        creation_date,
        change_date,
        change_type
    )
VALUES
    (
        :new.gr_id,
        :new.gr_name,
        :new.uni_id,
        :new.creation_date,
        systimestamp,
        'INSERT'
    );

ELSIF deleting THEN
INSERT INTO
    groups_logs (
        gr_id,
        gr_name,
        uni_id,
        creation_date,
        change_date,
        change_type
    )
VALUES
    (
        :old.gr_id,
        :old.gr_name,
        :old.uni_id,
        :old.creation_date,
        systimestamp,
        'DELETE'
    );

ELSIF updating THEN
INSERT INTO
    groups_logs (
        gr_id,
        gr_name,
        uni_id,
        creation_date,
        change_date,
        change_type
    )
VALUES
    (
        :new.gr_id,
        :new.gr_name,
        :new.uni_id,
        :new.creation_date,
        systimestamp,
        'UPDATE'
    );

END IF;

END;

CREATE
OR REPLACE TRIGGER tr_students
AFTER
INSERT
    OR
UPDATE
    OR DELETE ON students FOR EACH ROW BEGIN IF inserting THEN
INSERT INTO
    students_logs (
        st_id,
        st_name,
        gr_id,
        enter_date,
        change_date,
        change_type
    )
VALUES
    (
        :new.st_id,
        :new.st_name,
        :new.gr_id,
        :new.enter_date,
        systimestamp,
        'INSERT'
    );

ELSIF deleting THEN
INSERT INTO
    students_logs (
        st_id,
        st_name,
        gr_id,
        enter_date,
        change_date,
        change_type
    )
VALUES
    (
        :old.st_id,
        :old.st_name,
        :old.gr_id,
        :old.enter_date,
        systimestamp,
        'DELETE'
    );

ELSIF updating THEN
INSERT INTO
    students_logs (
        st_id,
        st_name,
        gr_id,
        enter_date,
        change_date,
        change_type
    )
VALUES
    (
        :new.st_id,
        :new.st_name,
        :new.gr_id,
        :new.enter_date,
        systimestamp,
        'UPDATE'
    );

END IF;

END;

-- TIMESTAMP PACKAGE
CREATE
OR REPLACE PACKAGE cur_state_timestamp_pkg IS cur_state_time timestamp;

PROCEDURE set_time(p_value IN TIMESTAMP);

END cur_state_timestamp_pkg;

CREATE
OR REPLACE PACKAGE BODY cur_state_timestamp_pkg IS PROCEDURE set_time(p_value IN TIMESTAMP) IS BEGIN cur_state_time := p_value;

END set_time;

END cur_state_timestamp_pkg;

-- MAIN PACKAGE
CREATE
OR REPLACE PACKAGE func_package IS PROCEDURE roll_back(date_time TIMESTAMP);

PROCEDURE roll_back(date_time NUMBER);

PROCEDURE report(t_begin IN TIMESTAMP);

PROCEDURE report;

END func_package;

create
OR REPLACE PACKAGE BODY func_package IS PROCEDURE roll_back(date_time TIMESTAMP) IS BEGIN rollback_by_date(date_time);

END roll_back;

PROCEDURE roll_back(date_time NUMBER) IS BEGIN DECLARE current_time timestamp := systimestamp;

BEGIN current_time := current_time - numtodsinterval(date_time / 1000, 'SECOND');

rollback_by_date(current_time);

END;

END roll_back;

PROCEDURE report(t_begin IN TIMESTAMP) IS v_cur timestamp := systimestamp;

BEGIN create_report(t_begin, v_cur);

INSERT INTO
    reports_logs(report_date)
VALUES
    (v_cur);

END report;

PROCEDURE report IS v_begin timestamp := to_timestamp('1/1/1 1:1:1', 'YYYY/MM/DD HH:MI:SS');

v_cur timestamp := systimestamp;

v_count NUMBER;

BEGIN
SELECT
    COUNT(*) INTO v_count
FROM
    reports_logs;

IF (v_count > 0) THEN
SELECT
    report_date INTO v_begin
FROM
    reports_logs
WHERE
    id = (
        SELECT
            MAX(id)
        FROM
            reports_logs
    );

END IF;

create_report(v_begin, v_cur);

INSERT INTO
    reports_logs(report_date)
VALUES
    (v_cur);

END report;

END func_package;

-- PROCEDURES FOR MAIN PACKAGE
CREATE
OR REPLACE PROCEDURE rollback_by_date (date_time IN TIMESTAMP) AS v_cur timestamp := systimestamp;

BEGIN
DELETE FROM
    students;

DELETE FROM
    groups;

DELETE FROM
    uni;

FOR log_ IN (
    SELECT
        *
    FROM
        uni_logs
    WHERE
        change_date <= date_time
    ORDER BY
        action_id
) LOOP IF log_.change_type = 'INSERT' THEN
INSERT INTO
    uni
VALUES
    (
        log_.uni_id,
        log_.uni_name,
        log_.creation_date
    );

ELSIF log_.change_type = 'DELETE' THEN
DELETE FROM
    uni
WHERE
    uni_id = log_.uni_id;

ELSIF log_.change_type = 'UPDATE' THEN
UPDATE
    uni
SET
    uni_id = log_.uni_id,
    uni_name = log_.uni_name,
    creation_date = log_.creation_date
WHERE
    uni_id = log_.uni_id;

END IF;

END LOOP;

FOR log_ IN (
    SELECT
        *
    FROM
        groups_logs
    WHERE
        change_date <= date_time
    ORDER BY
        action_id
) LOOP IF log_.change_type = 'INSERT' THEN
INSERT INTO
    groups
VALUES
    (
        log_.gr_id,
        log_.gr_name,
        log_.uni_id,
        log_.creation_date
    );

ELSIF log_.change_type = 'DELETE' THEN
DELETE FROM
    groups
WHERE
    gr_id = log_.gr_id;

ELSIF log_.change_type = 'UPDATE' THEN
UPDATE
    groups
SET
    gr_id = log_.gr_id,
    gr_name = log_.gr_name,
    uni_id = log_.uni_id,
    creation_date = log_.creation_date
WHERE
    gr_id = log_.gr_id;

END IF;

END LOOP;

FOR log_ IN (
    SELECT
        *
    FROM
        students_logs
    WHERE
        change_date <= date_time
    ORDER BY
        action_id
) LOOP IF log_.change_type = 'INSERT' THEN
INSERT INTO
    students
VALUES
    (
        log_.st_id,
        log_.st_name,
        log_.gr_id,
        log_.enter_date
    );

ELSIF log_.change_type = 'DELETE' THEN
DELETE FROM
    students
WHERE
    st_id = log_.st_id;

ELSIF log_.change_type = 'UPDATE' THEN
UPDATE
    students
SET
    st_id = log_.st_id,
    st_name = log_.st_name,
    gr_id = log_.gr_id,
    enter_date = log_.enter_date
WHERE
    st_id = log_.st_id;

END IF;

END LOOP;

DELETE FROM
    uni_logs
WHERE
    change_date >= v_cur;

DELETE FROM
    groups_logs
WHERE
    change_date >= v_cur;

DELETE FROM
    students_logs
WHERE
    change_date >= v_cur;

cur_state_timestamp_pkg.set_time(date_time);

END;

CREATE
OR REPLACE PROCEDURE create_report(t_begin IN TIMESTAMP, t_end IN TIMESTAMP) AS v_result VARCHAR2(4000);

i_count NUMBER;

u_count NUMBER;

d_count NUMBER;

v_t_end TIMESTAMP := LEAST(t_end, cur_state_timestamp_pkg.cur_state_time);

BEGIN v_result := '<table>
                      <tr>
                        <th>Table</th>
                        <th>INSERT</th>
                        <th>UPDATE</th>
                        <th>DELETE</th>
                      </tr>
                      ';

SELECT
    COUNT(*) INTO u_count
FROM
    uni_logs
WHERE
    change_date BETWEEN t_begin
    AND v_t_end
    AND change_type = 'UPDATE';

SELECT
    COUNT(*) INTO i_count
FROM
    uni_logs
WHERE
    change_date BETWEEN t_begin
    AND v_t_end
    AND change_type = 'INSERT';

SELECT
    COUNT(*) INTO d_count
FROM
    uni_logs
WHERE
    change_date BETWEEN t_begin
    AND v_t_end
    AND change_type = 'DELETE';

v_result := v_result || '<tr>
                               <td>uni</td>
                               <td>' || i_count || '</td>
                               <td>' || u_count || '</td>
                               <td>' || d_count || '</td>
                             </tr>
                              ';

SELECT
    COUNT(*) INTO u_count
FROM
    groups_logs
WHERE
    change_date BETWEEN t_begin
    AND v_t_end
    AND change_type = 'UPDATE';

SELECT
    COUNT(*) INTO i_count
FROM
    groups_logs
WHERE
    change_date BETWEEN t_begin
    AND v_t_end
    AND change_type = 'INSERT';

SELECT
    COUNT(*) INTO d_count
FROM
    groups_logs
WHERE
    change_date BETWEEN t_begin
    AND v_t_end
    AND change_type = 'DELETE';

v_result := v_result || '<tr>
                               <td>groups</td>
                               <td>' || i_count || '</td>
                               <td>' || u_count || '</td>
                               <td>' || d_count || '</td>
                             </tr>
                              ';

SELECT
    COUNT(*) INTO u_count
FROM
    students_logs
WHERE
    change_date BETWEEN t_begin
    AND v_t_end
    AND change_type = 'UPDATE';

SELECT
    COUNT(*) INTO i_count
FROM
    students_logs
WHERE
    change_date BETWEEN t_begin
    AND v_t_end
    AND change_type = 'INSERT';

SELECT
    COUNT(*) INTO d_count
FROM
    students_logs
WHERE
    change_date BETWEEN t_begin
    AND v_t_end
    AND change_type = 'DELETE';

v_result := v_result || '<tr>
                               <td>students</td>
                               <td>' || i_count || '</td>
                               <td>' || u_count || '</td>
                               <td>' || d_count || '</td>
                             </tr>
                              ';

v_result := v_result || '</table>';

dbms_output.put_line(v_result);

END;

-- TESTS
DELETE FROM
    uni;

DELETE FROM
    groups;

DELETE FROM
    students;

DELETE FROM
    uni_logs;

DELETE FROM
    groups_logs;

DELETE FROM
    students_logs;

DELETE from
    reports_logs;

INSERT INTO
    uni (uni_name, creation_date)
VALUES
(
        'u1',
        '11-MAR-24 06.41.24.789000000 PM'
    );

INSERT INTO
    uni (uni_name, creation_date)
VALUES
(
        'u2',
        '16-MAR-24 06.41.24.789000000 PM'
    );

INSERT INTO
    uni (uni_name, creation_date)
VALUES
(
        'u3',
        '18-MAR-24 08.45.45.789000000 PM'
    );

UPDATE
    uni
SET
    creation_date = systimestamp
WHERE
    uni_name = 'u1';

DELETE FROM
    uni
WHERE
    uni_name = 'u3';

SELECT
    *
FROM
    uni_logs
ORDER BY
    change_date;

SELECT
    *
FROM
    uni
ORDER BY
    uni_id;

CALL func_package.roll_back(to_timestamp('22-MAR-24 09.07.46.960000000 PM'));

CALL func_package.roll_back(1200000);

CALL func_package.report();

CALL func_package.report(to_timestamp('22-MAR-24 09.07.46.926000000 PM'))