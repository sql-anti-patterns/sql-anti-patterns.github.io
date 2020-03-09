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
