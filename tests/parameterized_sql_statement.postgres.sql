--
-- Since: April, 2020
-- Author: gvenzl
-- Name: parameterized_sql_statement.sql.sql
-- Description: Parameterized SQL statements test cases for PostgreSQL
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
PREPARE ins_countries_1 (INTEGER, VARCHAR) AS
  INSERT INTO countries (id, name) VALUES ($1, $2);

--
-- Execute statement with parameter
--
EXECUTE ins_countries_1 (1, 'Austria');

--
-- Execute statement with parameter
--
EXECUTE ins_countries_1 (2, 'Switzerland');

--
-- Execute statement with parameter
--
EXECUTE ins_countries_1 (3, 'United States');

--
-- Execute statement with parameter
--
EXECUTE ins_countries_1 (4, 'Germany');

--
-- Execute statement with parameter
--
EXECUTE ins_countries_1 (5, 'Italy');

--
-- Commit rows
--
COMMIT;

--
-- Deallocate parameterized INSERT statement
--
DEALLOCATE ins_countries_1;

--
-- ******
-- SELECT
-- ******
--

--
-- Prepare parameterized SELECT statement
--
PREPARE sel_countries_1 (VARCHAR) AS
  SELECT id, name FROM countries WHERE name = $1;

--
-- Execute statement with parameter
--
EXECUTE sel_countries_1 ('Austria');

--
-- Execute statement with parameter
--
EXECUTE sel_countries_1 ('Switzerland');

--
-- Execute statement with parameter
--
EXECUTE sel_countries_1 ('Germany');

--
-- Deallocate parameterized INSERT statement
--
DEALLOCATE sel_countries_1;

--
-- Tear down
--
DROP TABLE countries;
