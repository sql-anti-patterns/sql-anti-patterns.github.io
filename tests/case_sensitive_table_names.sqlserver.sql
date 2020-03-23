--
-- Since: March, 2020
-- Author: gvenzl
-- Name: case_sensitive_table_names.sqlserver.sql
-- Description: Case sensitive tables names test cases for SQL Server
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
-- Case insensitive table names --> OK
--
CREATE TABLE COUNTRIES (id INTEGER, name VARCHAR(100));

select name from countries;

DROP TABLE countries;
--
-- Case sensitive table names --> Will still work because SQL Server doesn't support quoted identifiers
--
CREATE TABLE "Countries" (id INTEGER, name VARCHAR(100));

SELECT name FROM COUNTRIES;

INSERT INTO "countries" (id, name) values (1,'bla');
INSERT INTO "Countries" (id, name) values (2,'boo');
INSERT INTO COUNTRIES (id, name) values (3,'hihi');

DROP TABLE COUNTRIES;
