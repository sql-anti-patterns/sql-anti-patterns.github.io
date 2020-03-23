--
-- Since: March, 2020
-- Author: gvenzl
-- Name: case_sensitive_table_names.mysql.sql
-- Description: Case sensitive tables names test case for MySQL
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
-- MySQL uses case sensitive table names by default on Linux --> Fail (will work on Windows)
--
CREATE TABLE COUNTRIES (id INTEGER, name VARCHAR(100));

select name from countries;

DROP TABLE COUNTRIES;

--
-- Using lower case for table names can still break SQL statement that use upper case --> Fail
--
create table countries (id integer, name varchar(100));

SELECT NAME FROM COUNTRIES;

DROP TABLE countries;

--
-- Column names are not case sensitive in MySQL --> OK
--

create table COUNTRIES (id integer, NAME varchar(100));

select name from COUNTRIES;

drop table COUNTRIES;
