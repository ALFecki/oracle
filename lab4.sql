alter session set container=freepdb1;


CREATE OR REPLACE NONEDITIONABLE PROCEDURE parse_json_proc(
    json_str CLOB
) IS
    v_drop_param        VARCHAR2(2000);
    v_query_type        VARCHAR2(100);
    v_cond_type         VARCHAR2(8000);
    v_operator          VARCHAR2(8000);
    v_set_type          VARCHAR2(2000);
    v_columns           VARCHAR2(8000);
    v_tables            VARCHAR2(8000);
    v_join_conditions   VARCHAR2(8000);
    v_filter_conditions VARCHAR2(8000);
    v_set_clause        VARCHAR2(8000);
    v_values            VARCHAR2(8000);
    v_pks               VARCHAR2(8000);
    v_fks               VARCHAR2(8000);
    v_sql               VARCHAR2(8000);
    f_q_type            VARCHAR2(8000);
    f_cond              VARCHAR2(8000);
    f_operator          VARCHAR2(8000);
    
    v_cursor            SYS_REFCURSOR;
    
    v_json_data         json_object_t;
    v_temp_obj          json_object_t;
    v_json_array        json_array_t;
    v_fk_json_arr       json_array_t;
    
    v_values_type       VARCHAR2(8000);
    v_included_values   VARCHAR2(8000);



    FUNCTION process_select_condition(
        v_nest_json_data json_object_t
    ) RETURN VARCHAR2 IS
        v_type_check         VARCHAR2(100);
        v_col                VARCHAR2(8000);
        v_tab                VARCHAR2(4000);
        v_filter_cond        VARCHAR2(4000);
        v_inclusion_operator VARCHAR2(4000);
        v_search_column      VARCHAR2(4000); 
        v_res_sql            VARCHAR2(4000);
        
        v_n_temp_obj         json_object_t;
        v_n_json_array       json_array_t;
        
        f_n_q_type           VARCHAR2(8000);
        f_n_cond             VARCHAR2(8000);
        f_n_operator         VARCHAR2(8000);
            
        -- Данные ВЗ, переведенные в CLOB-формат (формат для больших текстовых объёктов)
        v_clob               CLOB := v_nest_json_data.to_clob();
    BEGIN
    
        -- Получение ВЗ
        v_type_check := v_nest_json_data.get_string('query_type');
        
        -- Обработка SELECT-запроса 
        IF v_type_check = 'SELECT' THEN
        
            -- Получаем таблицы из JSON
            v_n_json_array := v_nest_json_data.get_array('tables');
            FOR j IN 0..v_n_json_array.get_size() - 1 LOOP
                IF v_tab IS NULL THEN
                    v_tab := v_n_json_array.get_string(j);
                ELSE
                    v_tab := v_columns || ', ' || v_n_json_array.get_string(j);
                END IF;
            END LOOP;
            
            
            -- Получаем колонки SELECT-запроса
            v_col := v_nest_json_data.get_string('column');
            -- Если имена колонок не были представлены в JSON явно,
            -- то получаем их через JSON_TABLE
            IF v_col IS NULL THEN
                SELECT LISTAGG (column_name, ', ') INTO v_col
                FROM JSON_TABLE (v_clob,
                    '$.columns[*]' COLUMNS (column_name VARCHAR2 (1000) PATH '$')) j;
            END IF;
            
            
            -- Получаем оператор "объединения"
            v_inclusion_operator := v_nest_json_data.get_string('operator');
            
            -- Получаем колонку, по которой будем вести поиск
            v_search_column := v_nest_json_data.get_string('search_col');
            
            -- Получаем массив условий фильтрации
            v_n_json_array := v_nest_json_data.get_array('filter_conditions');
            
            -- Создаём общее условие фильтрации
            FOR j IN 0..v_n_json_array.get_size() - 1 LOOP
                v_n_temp_obj := TREAT(v_n_json_array.get(j) AS json_object_t);
                f_n_q_type := v_n_temp_obj.get_string('condition_type');
                f_n_operator := v_n_temp_obj.get_string('operator');
                
                -- Обычое условие фильтрации
                IF f_n_q_type = 'plain' OR f_n_q_type IS NULL THEN
                    f_n_cond := v_n_temp_obj.get_string('condition');
                    IF v_filter_cond IS NULL THEN
                        v_filter_cond := f_n_cond;
                    ELSE
                        dbms_output.put_line('1' || f_n_operator || '1');
                        v_filter_cond := v_filter_cond || ' ' || f_n_operator || ' ' || f_n_cond;
                    END IF;
                    
                -- Сложное условие фильтрации, которое обрабатываем через рекурсию
                ELSIF f_n_q_type = 'included' THEN
                    f_n_cond := process_select_condition(TREAT(v_n_temp_obj.get('condition') AS json_object_t));
                    IF v_filter_cond IS NULL THEN
                        v_filter_cond := f_n_cond;
                    ELSE
                        v_filter_cond := v_filter_cond || ' ' || f_n_operator || ' (' || f_n_cond || ')';
                    END IF;
                END IF;
            END LOOP;
            
            -- Создание результирующего SQL-запроса
            v_res_sql := 'SELECT ' || v_col || ' FROM ' || v_tab;
            v_res_sql := v_res_sql || ' WHERE ' || v_filter_cond;
            v_res_sql := v_search_column || ' ' || v_inclusion_operator || ' (' || v_res_sql || ')';
            --dbms_output.put_line('v res sql: ' || v_res_sql);
        END IF;

        RETURN v_res_sql;
    END;
    
BEGIN

    -- Парсим сам JSON
    v_json_data  := json_object_t.parse(json_str);
    
    -- Получаем тип запроса из JSON
    v_query_type := v_json_data.get_string('query_type'); 
    
    -- Обработка JSON с выборкой из таблицы
    IF v_query_type = 'SELECT' THEN
    
        dbms_output.put_line('select block');
    
    
        -- Получение колонок из JSON
        v_json_array := v_json_data.get_array('columns');
        FOR i IN 0..v_json_array.get_size() - 1 LOOP
            IF v_columns IS NULL THEN
                v_columns := v_json_array.get_string(i);
            ELSE
                v_columns := v_columns || ', ' || v_json_array.get_string(i);
            END IF;
        END LOOP;
        
        
        -- Получение таблиц из JSON
        v_json_array := v_json_data.get_array('tables');
        FOR i IN 0..v_json_array.get_size() - 1 LOOP
            IF v_tables IS NULL THEN
                v_tables := v_json_array.get_string(i);
            ELSE
                v_tables := v_tables || ', ' || v_json_array.get_string(i);
            END IF;
        END LOOP;
        
        
        -- Получение условий для JOIN из JSON
        v_json_array := v_json_data.get_array('join_block');
        v_join_conditions := v_json_array.get_string(0) || ' JOIN ' || v_json_array.get_string(1) || ' ON ' || v_json_array.get_string(2);
        
        --FOR i IN 0..v_json_array.get_size() - 1 LOOP
        --    IF v_join_conditions IS NULL THEN
        --        v_join_conditions := v_json_array.get_string(i);
        --    ELSE
        --        v_join_conditions := v_join_conditions || ' AND ' || v_json_array.get_string(i);
        --    END IF;
        --END LOOP;
        
        
        -- Получение условий фильтрации из JSON
        v_json_array := v_json_data.get_array('filter_conditions');
        FOR i IN 0..v_json_array.get_size() - 1 LOOP
            v_temp_obj := TREAT(v_json_array.get(i) AS json_object_t);
            f_q_type := v_temp_obj.get_string('condition_type');
            f_operator := v_temp_obj.get_string('operator');
            
            
            -- Обычные условия
            IF f_q_type = 'plain' OR f_q_type = '' THEN
                f_cond := v_temp_obj.get_string('condition');
                IF v_filter_conditions IS NULL OR i = v_json_array.get_size() - 1 THEN
                    v_filter_conditions := f_cond;
                ELSE
                    v_filter_conditions := v_filter_conditions || ' ' || f_operator || ' ' || f_cond;
                END IF;
                
            -- Сложные условия (обрабатываем рекурсивно)
            ELSIF f_q_type = 'included' THEN
                dbms_output.put_line('included cond!');
                f_cond := process_select_condition(TREAT(v_temp_obj.get('condition') AS json_object_t));
                IF v_filter_conditions IS NULL THEN
                    v_filter_conditions := f_cond;
                ELSE
                    v_filter_conditions := v_filter_conditions || ' ' || f_operator || ' (' || f_cond || ')';
                END IF;
            END IF;
        END LOOP;
        
        dbms_output.put_line('building sql...');
        
        -- Создание результирующего SELECT-запроса
        v_sql := 'SELECT ' || v_columns || ' FROM ' || v_tables;
        
        -- Добаление условий JOIN
        IF v_join_conditions IS NOT NULL THEN
            v_sql := v_sql || ' ' || v_join_conditions || ' WHERE ';
        END IF;
        
        -- Добавление условий фильтрации
        IF v_filter_conditions IS NOT NULL THEN
            IF v_join_conditions IS NULL THEN
                v_sql := v_sql || ' WHERE ' || v_filter_conditions;
            ELSE
                v_sql := v_sql || '' || v_filter_conditions;
            END IF;
        END IF;
        
        dbms_output.put_line('Output query: ' || v_sql);
        
        
        
        -- Создание курсора для полученного запроса
        OPEN v_cursor FOR v_sql;
        
        
    -- Обработка JSON с вставкой в таблицу
    ELSIF v_query_type = 'INSERT' THEN
    
        -- Получаем имя таблицы и пишем его в v_tables
        SELECT json_value(json_str, '$.table') INTO v_tables
        FROM dual;
        
        -- Получаем колонки и пишем их в строку через запятую 
        -- и присваиваем в v_columns
        SELECT LISTAGG (column_name, ', ') INTO v_columns
        FROM JSON_TABLE (json_str,
            '$.columns[*]' COLUMNS (column_name VARCHAR2 (1000) PATH '$')) j;
            
        -- Получаем тип значений (явные или неявные(заданные через запрос))
        v_values_type := v_json_data.get_string('values_type');
        
        -- Обработка явных значений
        IF v_values_type IS NULL THEN
        
            -- Получаем значения и пишем их в строку через запятую
            -- и присваиваем в v_columns
            SELECT LISTAGG (val, ', ') INTO v_values
            FROM JSON_TABLE (json_str,
                '$.values[*]' COLUMNS (val VARCHAR2 (4000) PATH '$')) j;
                
            -- Формируем окончательный запрос
            v_sql := 'INSERT INTO ' || v_tables || ' (' || v_columns || ') VALUES (' || v_values || ')';
            
        -- Обработка вложенных значений через рекурсию
        ELSIF v_values_type = 'included' THEN
            v_included_values := process_select_condition(TREAT(v_json_data.get('values') AS json_object_t));
            v_sql := 'INSERT INTO ' || v_tables || ' (' || v_columns || ')' || v_included_values;
        END IF;
        
        
    -- Обработка JSON с удалением из таблицы
    ELSIF v_query_type = 'DELETE' THEN
    
        --  Получаем значения в v_tables
        SELECT json_value(json_str, '$.table') INTO v_tables
        FROM dual;
        
        -- Получаем условия фильтрации
        v_cond_type := v_json_data.get_string('filter_type');
        
        -- Обработка явного условия
        IF (v_cond_type IS NULL) THEN
            SELECT LISTAGG (condition, ' AND ') INTO v_filter_conditions
            FROM JSON_TABLE (json_str,
                '$.filter_conditions[*]' COLUMNS (condition VARCHAR2 (4000) PATH '$')) j;
            v_sql := 'DELETE FROM ' || v_tables || ' WHERE ' || v_filter_conditions;
        
        -- Обработка сложного условия через рекурсию
        ELSE
            v_filter_conditions := process_select_condition(TREAT(v_json_data.get('filter_conditions') AS json_object_t));
            dbms_output.put_line(v_included_values);
            v_operator := v_json_data.get_string('operator');
            v_sql := 'DELETE FROM ' || v_tables || ' WHERE ' || v_operator || v_filter_conditions;
        END IF;
        
        
    -- Обработка JSON с обновлением таблицы
    ELSIF v_query_type = 'UPDATE' THEN
    
        -- Извлечение имени таблицы из JSON и запись в v_tables
        SELECT json_value(json_str, '$.table') INTO v_tables
        FROM dual;
        
        -- Обработка массива сеттеров
        v_json_array := v_json_data.get_array('set');
        FOR i IN 0..v_json_array.get_size() - 1 LOOP
        
            -- Извлечение объекта из массива
            v_temp_obj := TREAT(v_json_array.get(i) AS json_object_t);
            
            -- Получение типа сеттера
            v_set_type := v_temp_obj.get_string('set_type');
            
            -- Если тип не указан, формирование SET-клаузы с явными значениями
            IF v_set_type IS NULL THEN
                IF i != v_json_array.get_size() - 1 THEN
                    v_set_clause := v_set_clause || v_temp_obj.get_string('field') || ' = ' || v_temp_obj.get_string('value') || ', ';
                ELSE
                    v_set_clause := v_set_clause || v_temp_obj.get_string('field') || ' = ' || v_temp_obj.get_string('value');
                END IF;
                
            -- Если указан тип сеттера, обработка вложенного запроса    
            ELSE
                
                v_filter_conditions := process_select_condition(TREAT(v_temp_obj.get('value') AS json_object_t));
                IF i != v_json_array.get_size() - 1 THEN
                    v_set_clause := v_set_clause || v_temp_obj.get_string('field') || ' = ' || v_filter_conditions || ', ';
                ELSE
                    v_set_clause := v_set_clause || v_temp_obj.get_string('field') || ' = ' || v_filter_conditions;
                END IF;
            END IF;
        END LOOP;
    
        -- Получение типа фильтра и обработка соответствующего блока
        v_cond_type := v_json_data.get_string('filter_type');
        
        -- Если тип фильтра не указан, формирование условия из JSON
        IF (v_cond_type IS NULL) THEN
            
            SELECT LISTAGG (condition, ' AND ') INTO v_filter_conditions
            FROM JSON_TABLE (json_str,
                '$.filter_conditions[*]' COLUMNS (condition VARCHAR2 (4000) PATH '$')) j;
                
            -- Формирование SQL-запроса для UPDATE
            v_sql := 'UPDATE ' || v_tables || ' SET ' || v_set_clause || ' WHERE ' || v_filter_conditions;
            
        -- Если указан тип фильтра, обработка вложенного запроса
        ELSE
            
            v_filter_conditions := process_select_condition(TREAT(v_json_data.get('filter_conditions') AS json_object_t));
            dbms_output.put_line(v_included_values);
            
            -- Получение оператора для комбинирования условий фильтрации
            v_operator := v_json_data.get_string('operator');
            
            -- Формирование SQL-запроса для UPDATE
            v_sql := 'UPDATE ' || v_tables || ' SET ' || v_set_clause || ' WHERE ' || v_operator || v_filter_conditions;
            
        END IF;
    
        -- Формирование списка условий фильтрации для вложенного запроса
        SELECT LISTAGG (condition, ' AND ') WITHIN GROUP (ORDER BY condition) INTO v_filter_conditions
        FROM JSON_TABLE (json_str,
            '$.filter_conditions[*]' COLUMNS (condition VARCHAR2 (4000) PATH '$')) j;

            
            
    -- Обработка JSON для создания таблицы
    ELSIF v_query_type = 'CREATE TABLE' THEN
    
        DBMS_OUTPUT.PUT_LINE('HELLO FUNC!');
    
        -- Получение имени таблицы из JSON и запись в v_tables
        SELECT json_value(json_str, '$.table') INTO v_tables
        FROM dual;
        
        -- Получение списка колонок и их типов из JSON
        SELECT LISTAGG(column_name || ' ' || data_type, ', ') INTO v_columns
        FROM JSON_TABLE (json_str,
            '$.columns[*]' COLUMNS ( column_name VARCHAR2(100) PATH '$.name',
            data_type VARCHAR2(100) PATH '$.type') ) j;
        
        -- Получение списка первичных ключей из JSON
        SELECT LISTAGG ('constraint pk_' || v_tables || '_' || col_name || ' primary key (' || col_name || ')', ', ') INTO v_pks
        FROM JSON_TABLE (json_str,
            '$.primary_keys[*]' COLUMNS (col_name VARCHAR2 (4000) PATH '$')) j;
        
        -- Получение списка внешних ключей из JSON
        SELECT LISTAGG ('constraint fk_' || v_tables || '_' || col_name || ' FOREIGN  key (' || col_name || ') references ' || table_name || '(' || ref_field || ')', ', ') INTO v_fks
        FROM JSON_TABLE (json_str,
            '$.foreign_keys [*]' COLUMNS (col_name VARCHAR2 (4000) PATH '$.field',
            table_name VARCHAR2 (4000) PATH '$.table',
            ref_field VARCHAR2 (4000) PATH '$.ref_field')) j;
        
        -- Формирование SQL-запроса для создания таблицы с учетом ключей
        v_sql := 'CREATE TABLE ' || v_tables || ' (' || v_columns || ', ' || v_pks || ', ' || v_fks || ');';
        
        -- Получение имени первичного ключа из JSON и формирование соответствующего блока SQL
        SELECT json_value(json_str, '$.primary_keys[0]') INTO v_pks
        FROM dual;
        
        v_sql := v_sql || ' ' || '

            create sequence ' || v_tables || '_seq start with 1;' || '
            CREATE OR REPLACE TRIGGER tr_' || v_tables || '_pk_autoincrement
            BEFORE INSERT ON ' || v_tables || '
            FOR EACH ROW
            BEGIN
            SELECT ' || v_tables || '_seq' || '.NEXTVAL
            INTO :NEW.' || v_pks || '
            FROM DUAL;
            END;';
            
        DBMS_OUTPUT.PUT_LINE(v_sql);
            
    -- Обработка запрос на удаление таблицы
    ELSIF v_query_type = 'DROP TABLE' THEN
    
        -- Получение параметров удаления из JSON и запись в v_drop_param
        v_drop_param := v_json_data.get_string('parameters');
        
        -- Получение имени таблицы из JSON и запись в v_tables
        SELECT json_value(json_str, '$.table') INTO v_tables
        FROM dual;
        
        -- Формирование SQL-запроса для удаления таблицы
        v_sql := 'DROP TABLE ' || v_tables;
        
        -- Если параметр удаления равен 'purge', то добавляем его к SQL-запросу
        IF v_drop_param = 'purge' THEN
            v_sql := v_sql || ' purge';
        END IF;
        
    -- Если тип запроса некорректный, то генерируем исключение
    ELSE
        raise_application_error( - 20005, 'Incorrect query type ');
        NULL;
    END IF;

    -- dbms_output.put_line(v_sql);
END;