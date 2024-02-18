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