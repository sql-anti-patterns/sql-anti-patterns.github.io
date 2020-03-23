--
-- Since: March, 2020
-- Author: gvenzl
-- Name: selectstar.sql
-- Description: SELECT * test cases
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
-- Test case: Retrieve a newly added column unintentionally
--
CREATE TABLE selectstar (id INTEGER, txt VARCHAR(255));
INSERT INTO selectstar (id, txt) VALUES (1, 'test');
COMMIT; 

-- Retrieve table data
SELECT * FROM selectstar;

-- Add new column
ALTER TABLE selectstar ADD tms DATE;

-- Retrieve table data (this will now retrieve tms as well)
SELECT * FROM selectstar;


--
-- Example: get table definition
--

-- MySQL, MariaDB, Oracle
DESCRIBE selectstar;

-- Postgres
\d selectstar;

-- SQL Server
sp_columns selectstar;
go

-- Db2
DESCRIBE TABLE selectstar

--
-- Cleanup
--
DROP TABLE selectstar;
