--
-- Since: April, 2020
-- Author: gvenzl
-- Name: parameterized_sql_statement.sql.sql
-- Description: Parameterized SQL statements test cases for SQL Server
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
go

--
-- ******
-- INSERT
-- ******
--

--
-- Declare variables
--
DECLARE @id INTEGER;
DECLARE @name VARCHAR(100);

--
-- Execute statement with parameter
--
SET @id = 1;
SET @name = 'Austria';
INSERT INTO countries (id, name) VALUES (@id, @name);


--
-- Execute statement with parameter
--
SET @id = 2;
SET @name = 'Switzerland';
INSERT INTO countries (id, name) VALUES (@id, @name);

--
-- Execute statement with parameter
--
SET @id = 3;
SET @name = 'United States';
INSERT INTO countries (id, name) VALUES (@id, @name);

--
-- Execute statement with parameter
--
SET @id = 4;
SET @name = 'Germany';
INSERT INTO countries (id, name) VALUES (@id, @name);

--
-- Execute statement with parameter
--
SET @id = 5;
SET @name = 'Italy';
INSERT INTO countries (id, name) VALUES (@id, @name);

--
-- Commit rows
--
COMMIT;
go

--
-- ******
-- SELECT
-- ******
--

--
-- Declare variables
--
DECLARE @name VARCHAR(100);

--
-- Execute statement with parameter
--
SET @name ='Austria';
SELECT id, name FROM countries WHERE name = @name;

--
-- Execute statement with parameter
--
SET @name ='Switzerland';
SELECT id, name FROM countries WHERE name = @name;

--
-- Execute statement with parameter
--
SET @name ='Germany';
SELECT id, name FROM countries WHERE name = @name;
go

--
-- Tear down
--
DROP TABLE countries;
go
