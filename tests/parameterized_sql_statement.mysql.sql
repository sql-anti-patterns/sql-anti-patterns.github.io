--
-- Since: April, 2020
-- Author: gvenzl
-- Name: parameterized_sql_statement.sql.sql
-- Description: Parameterized SQL statements test cases for MySQL
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
CREATE TABLE countries (id INTEGER, name VARCHAR(100));

--
-- ******
-- INSERT
-- ******
--

--
-- Prepare parameterized INSERT statement
--
PREPARE ins_countries_1 FROM 'INSERT INTO countries (id, name) VALUES (?,?)';

--
-- Execute statement with parameter
--
SET @id = 1;
SET @name = 'Austria';
EXECUTE ins_countries_1 USING @id, @name;

--
-- Execute statement with parameter
--
SET @id = 2;
SET @name = 'Switzerland';
EXECUTE ins_countries_1 USING @id, @name;

--
-- Execute statement with parameter
--
SET @id = 3;
SET @name = 'United States';
EXECUTE ins_countries_1 USING @id, @name;

--
-- Execute statement with parameter
--
SET @id = 4;
SET @name = 'Germany';
EXECUTE ins_countries_1 USING @id, @name;

--
-- Execute statement with parameter
--
SET @id = 5;
SET @name = 'Italy';
EXECUTE ins_countries_1 USING @id, @name;

--
-- Commit rows
--
COMMIT;

--
-- Deallocate parameterized INSERT statement
--
DEALLOCATE PREPARE ins_countries_1;

--
-- ******
-- SELECT
-- ******
--

--
-- Prepare parameterized SELECT statement
--
PREPARE sel_countries_1 FROM 'SELECT id, name FROM countries WHERE name = ?';

--
-- Execute statement with parameter
--
SET @name = 'Austria';
EXECUTE sel_countries_1 USING @name;

--
-- Execute statement with parameter
--
SET @name = 'Switzerland';
EXECUTE sel_countries_1 USING @name;

--
-- Execute statement with parameter
--
SET @name = 'Germany';
EXECUTE sel_countries_1 USING @name;

--
-- Deallocate parameterized INSERT statement
--
DEALLOCATE PREPARE sel_countries_1;

--
-- Tear down
--
DROP TABLE countries;
