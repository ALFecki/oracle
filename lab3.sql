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

CREATE TABLE dev.group (
    id NUMBER NOT NULL,
    gr_name VARCHAR2(20) NOT NULL,
    university_id NUMBER NOT NULL,
    CONSTRAINT gr_id_pk PRIMARY KEY (id),
    CONSTRAINT university_id_fk FOREIGN KEY (university_id) REFERENCES dev.university (id)
);

-- ALTER TABLE dev.group ADD gr_motto VARCHAR2(200) NOT NULL;

-- CREATE INDEX gr_motto_idx ON dev.group (gr_motto);

CREATE TABLE dev.student (
    st_id NUMBER NOT NULL,
    st_name VARCHAR2(20) NOT NULL,
    gr_id NUMBER NOT NULL,
    CONSTRAINT st_id_pk PRIMARY KEY (st_id),
    CONSTRAINT gr_id_fk FOREIGN KEY (gr_id) REFERENCES dev.group (id)
);

CREATE TABLE dev.person (
    h_id NUMBER NOT NULL,
    acc_id NUMBER UNIQUE NOT NULL,
    CONSTRAINT h_id_pk PRIMARY KEY (h_id)
);

CREATE TABLE dev.account (
    acc_id NUMBER NOT NULL,
    h_id NUMBER UNIQUE NOT NULL,
    CONSTRAINT acc_id_pk PRIMARY KEY (acc_id),
    CONSTRAINT h_id_fk FOREIGN KEY (h_id) REFERENCES dev.human (h_id)
);

ALTER TABLE dev.human ADD CONSTRAINT acc_id_fk FOREIGN KEY (acc_id) REFERENCES dev.account (acc_id);

CREATE TABLE dev.aa (
    id NUMBER PRIMARY KEY,
    b_id NUMBER NOT NULL
);

CREATE TABLE dev.bb (
    id NUMBER PRIMARY KEY,
    c_id NUMBER NOT NULL
);

CREATE TABLE dev.cc (
    id NUMBER PRIMARY KEY,
    a_id NUMBER NOT NULL
);

ALTER TABLE dev.aa ADD CONSTRAINT fk_a_b FOREIGN KEY (b_id) REFERENCES dev.bb (id);

ALTER TABLE dev.bb ADD CONSTRAINT fk_b_c FOREIGN KEY (c_id) REFERENCES dev.cc (id);

ALTER TABLE dev.cc ADD CONSTRAINT fk_c_a FOREIGN KEY (a_id) REFERENCES dev.aa (id);

-- PROD SCHEME

CREATE TABLE prod.uni (
    uni_id NUMBER NOT NULL,
    uni_name VARCHAR2(20) NOT NULL,
    CONSTRAINT uni_id_pk PRIMARY KEY (uni_id)
);

CREATE TABLE prod.groups (
    gr_id NUMBER NOT NULL,
    gr_name VARCHAR2(20) NOT NULL,
    uni_id NUMBER NOT NULL,
    st_count NUMBER NOT NULL,
    CONSTRAINT gr_id_pk PRIMARY KEY (gr_id),
    CONSTRAINT uni_id_fk FOREIGN KEY (uni_id) REFERENCES prod.uni (uni_id)
);

CREATE TABLE prod.students (
    st_id NUMBER NOT NULL,
    st_name VARCHAR2(20) NOT NULL,
    st_surname VARCHAR2(20) NOT NULL,
    gr_id NUMBER NOT NULL,
    CONSTRAINT st_id_pk PRIMARY KEY (st_id),
    CONSTRAINT gr_id_fk FOREIGN KEY (gr_id) REFERENCES prod.groups (gr_id)
);

ALTER TABLE prod.students ADD CONSTRAINT st_name_length_check CHECK (length(st_name) >= 10);

CREATE INDEX st_name_idx ON prod.students (st_name);
