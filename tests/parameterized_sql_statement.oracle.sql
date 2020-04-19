--
-- Since: April, 2020
-- Author: gvenzl
-- Name: parameterized_sql_statement.sql.sql
-- Description: Parameterized SQL statements test cases for Oracle
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
-- ******
-- INSERT
-- ******
--

--
-- Declare variables
--
VARIABLE id NUMBER;
VARIABLE name VARCHAR2(100);

--
-- Execute statement with parameter
--
EXEC :id := 1;
EXEC :name := 'Austria';
INSERT INTO countries (id, name) VALUES (:id, :name);

--
-- Execute statement with parameter
--
EXEC :id := 2;
EXEC :name := 'Switzerland';
INSERT INTO countries (id, name) VALUES (:id, :name);

--
-- Execute statement with parameter
--
EXEC :id := 3;
EXEC :name := 'United States';
INSERT INTO countries (id, name) VALUES (:id, :name);

--
-- Execute statement with parameter
--
EXEC :id := 4;
EXEC :name := 'Germany';
INSERT INTO countries (id, name) VALUES (:id, :name);

--
-- Execute statement with parameter
--
EXEC :id := 5;
EXEC :name := 'Italy';
INSERT INTO countries (id, name) VALUES (:id, :name);

--
-- Commit rows
--
COMMIT;

--
-- ******
-- SELECT
-- ******
--

VARIABLE name VARCHAR2(100);

--
-- Execute statement with parameter
--
EXEC :name := 'Austria';
SELECT id, name FROM countries WHERE name = :name;

--
-- Execute statement with parameter
--
EXEC :name := 'Switzerland';
SELECT id, name FROM countries WHERE name = :name;

--
-- Execute statement with parameter
--
EXEC :name := 'Germany';
SELECT id, name FROM countries WHERE name = :name;

--
-- Tear down
--
DROP TABLE countries;
