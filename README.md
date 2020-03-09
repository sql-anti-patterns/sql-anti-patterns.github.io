# SQL

* [SELECT * FROM](#select-star)

<a name="select-star"></a>
## SELECT * FROM

### may lead to unexpected results
`SELECT * FROM` is bad because it does not guarantee:

* The number of columns returned
* The order of columns returned

The definition of a table can change at any time. A new business requirement may require to add a new column to the table that is not relevant for your application. Storage optimizations done by the DBA may result in a changed order of the columns. If your application queries a table with `SELECT * FROM`, such changes will be directly reflected in the result set of your query. Your query may retrieve more columns than originally anticipated or in a different order and then tries to interpret the wrong data, potentially causing data conversion errors or silent data corruptions. You should always specify the column names in your `SELECT` statement. This way, your application is protected from such table definition changes.

### can introduce additional performance overhead
`SELECT * FROM` may introduce an additional performance overhead. Imagine a scenario where a table has, for example, 50 columns but your application only needs 3 of these. If your application queries the table via `SELECT * FROM`, all 50 column values are retrieved, memory areas allocated on the database, these column values transmitted via the network to your application, and memory areas allocated by the client driver result set.

### is not the best way to inspect the table definition
If you want to see what columns are available on a table, instead of issuing a `SELECT * FROM` you can use the table definition functionality that the database provides. This will not only give you the column names but also the data types and other remarks about the table:

* MySQL, MariaDB, Oracle: `DESCRIBE table_name`
* Postgres: `\d table_name`
* SQL Server: `sp_columns table_name`
* Db2: `DESCRIBE TABLE table_name`

# Administration

