--
-- Since: April, 2020
-- Author: gvenzl
-- Name: overcommitting.oracle.sql
-- Description: Overcommitting example test cases for Oracle
--
-- Copyright 2020 Gerald Venzl
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

--
-- Setup
--
CREATE TABLE countries (id NUMBER, name VARCHAR2(100));

--
-- **************************
-- INSERT WITH OVERCOMMITTING
-- **************************
--

SET SERVEROUTPUT ON;
DECLARE
  v_begin DATE;
  v_end   DATE;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE countries';
  
  v_begin := sysdate;
  
  FOR n in 1..100000 LOOP
    INSERT INTO countries (id, name) VALUES (n, 'Country ' || n);
    COMMIT;
  END LOOP;
  
  v_end := sysdate;
  
  DBMS_OUTPUT.PUT_LINE('INSERT took: ' || ROUND(((v_end - v_begin)*86400),3) || ' seconds');
END;
/

--
-- *************************************
-- INSERT WITH COMMITTING EVERY 10k ROWS
-- *************************************
--

SET SERVEROUTPUT ON;
DECLARE
  v_begin DATE;
  v_end   DATE;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE countries';
  
  v_begin := sysdate;
  
  FOR n in 1..100000 LOOP
    INSERT INTO countries (id, name) VALUES (n, 'Country ' || n);
    IF MOD(n, 10000) = 0 THEN
      COMMIT;
    END IF;
  END LOOP;
  
  COMMIT;
  
  v_end := sysdate;
  
  DBMS_OUTPUT.PUT_LINE('INSERT took: ' || ROUND(((v_end - v_begin)*86400),3) || ' seconds');
END;
/

--
-- Tear down
--
DROP TABLE countries;
