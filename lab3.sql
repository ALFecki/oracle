-- CREATE USERS

CREATE USER dev IDENTIFIED BY "root";
CREATE USER prod IDENTIFIED BY "root";
CREATE USER lab3 IDENTIFIED BY "root";
GRANT sysdba TO lab3 container=all;


-- CREATE TABLES

-- DEV SCHEME

CREATE TABLE dev.university (
    id NUMBER NOT NULL,
    university_name VARCHAR2(20) NOT NULL,
    CONSTRAINT university_id_pk PRIMARY KEY (id)
);

CREATE TABLE dev.groups (
    id NUMBER NOT NULL,
    gr_name VARCHAR2(20) NOT NULL,
    university_id NUMBER NOT NULL,
    slogan VARCHAR2(200) NOT NULL
    CONSTRAINT gr_id_pk PRIMARY KEY (id),
    CONSTRAINT university_id_fk FOREIGN KEY (university_id) REFERENCES dev.university (id)
);

CREATE INDEX gr_motto_idx ON dev.groups (slogan);

CREATE TABLE dev.student (
    id NUMBER NOT NULL,
    st_name VARCHAR2(20) NOT NULL,
    gr_id NUMBER NOT NULL,
    CONSTRAINT st_id_pk PRIMARY KEY (id),
    CONSTRAINT gr_id_fk FOREIGN KEY (gr_id) REFERENCES dev.groups (id)
);

CREATE TABLE dev.person (
    id NUMBER NOT NULL,
    acc_id NUMBER UNIQUE NOT NULL,
    CONSTRAINT p_id_pk PRIMARY KEY (id)
);

CREATE TABLE dev.acc (
    id NUMBER NOT NULL,
    p_id NUMBER UNIQUE NOT NULL,
    CONSTRAINT acc_id_pk PRIMARY KEY (id),
    CONSTRAINT p_id_fk FOREIGN KEY (p_id) REFERENCES dev.person (id)
);

ALTER TABLE dev.person ADD CONSTRAINT acc_id_fk FOREIGN KEY (acc_id) REFERENCES dev.acc (id);

CREATE TABLE dev.test1 (
    id NUMBER PRIMARY KEY,
    t2_id NUMBER NOT NULL
);

CREATE TABLE dev.test2 (
    id NUMBER PRIMARY KEY,
    t3_id NUMBER NOT NULL
);

CREATE TABLE dev.test3 (
    id NUMBER PRIMARY KEY,
    t1_id NUMBER NOT NULL
);

ALTER TABLE dev.test1 ADD CONSTRAINT fk_t1_t2 FOREIGN KEY (t2_id) REFERENCES dev.test2 (id);

ALTER TABLE dev.test2 ADD CONSTRAINT fk_t2_t3 FOREIGN KEY (t3_id) REFERENCES dev.test3 (id);

ALTER TABLE dev.test3 ADD CONSTRAINT fk_t3_t1 FOREIGN KEY (t1_id) REFERENCES dev.test1 (id);

-- PROD SCHEME

    CREATE TABLE prod.university (
        id NUMBER NOT NULL,
        university_name VARCHAR2(20) NOT NULL,
        CONSTRAINT university_id_pk PRIMARY KEY (id)
    );

    CREATE TABLE prod.groups (
        id NUMBER NOT NULL,
        gr_name VARCHAR2(20) NOT NULL,
        university_id NUMBER NOT NULL,
        st_count NUMBER NOT NULL,
        CONSTRAINT gr_id_pk PRIMARY KEY (id),
        CONSTRAINT university_id_fk FOREIGN KEY (university_id) REFERENCES prod.university_id (id)
    );

    CREATE TABLE prod.students (
        id NUMBER NOT NULL,
        st_name VARCHAR2(20) NOT NULL,
        st_surname VARCHAR2(20) NOT NULL,
        gr_id NUMBER NOT NULL,
        CONSTRAINT st_id_pk PRIMARY KEY (id),
        CONSTRAINT gr_id_fk FOREIGN KEY (gr_id) REFERENCES prod.groups (id)
    );

    ALTER TABLE prod.students ADD CONSTRAINT st_name_length_check CHECK (length(st_name) >= 10);

CREATE INDEX st_name_idx ON prod.students (st_name);
