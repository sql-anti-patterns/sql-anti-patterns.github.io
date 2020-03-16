* [General](#general)
* [SQL constructs](#sql-constructs)

<a name="general"></a>
# General

* [Autocommit](#autocommit)

<a name="autocommit"></a>
## Autocommit
[`Autocommit`](https://en.wikipedia.org/wiki/Autocommit) is a built-in mode of database connection operation provided by most databases. If enabled, it will issue an implicit `COMMIT` after every single `DML` operation. This has several drawbacks.

### Loss of transaction boundaries
When `autocommit` is enabled your application no longer has control over the boundaries of the transactions. A business transaction may require to insert a payment record into the `payments` table first and then delete the items in the `shopping_carts` table for that customer. If anything goes wrong, the entire transaction should be rolled back, i.e. the customer's credit card should not be charged and the items should remain in the customer's shopping cart. Imagine the following scenario: `autocommit` is enabled and an error happens when deleting from the customer's shopping cart. At this point in time, the payment record has already been committed and can no longer be rolled back. You think that's not a big deal, just look for the payment record and delete it in your exception handling block? What if there were triggers on that `payments` table that already propagated that payment transaction to the finance system? What if there is no trigger `ON DELETE` on the `payments` table that will undo the propagation when you delete the record? What if your application doesn't have the permissions to perform `DELETE` operations on the `payments` table? You just never know and can quickly end up in a bad spot, just because `autocommit` has been enabled.

Many people use databases for a long time because of their [`ACID`](https://en.wikipedia.org/wiki/ACID) transaction properties. With `autocommit` enabled, you take the `A` (Atomicity) out of `ACID`.

### Potential performance impact
Although a `commit` for a transaction sounds simple, it can have quite an impact on your overall performance. The `commit` is what tells the database to write data on disk into the transaction journal (your modifications tend to happen in memory on the database server). Hence a `commit` results directly in an I/O that your database connection will have to wait for until that I/O is done (because of the `ACID` transaction guarantee). There are a few more steps that the database needs to perform in order to mark your transaction complete, such as releasing potential locks on the rows, etc.

When `autocommit` is enabled, all these I/Os and steps will be performed for every single DML operation that you issue, which can cause an undesired performance and resource utilization impact. Also, every `commit` issued on the driver side means an additional network roundtrip to the database.

<a name="sql-constructs"></a>
# SQL constructs

* [SELECT * FROM](#select-star)


<a name="select-star"></a>
## SELECT * FROM

### may lead to unexpected results
`SELECT * FROM` is bad practice because it does not guarantee:

* The number of columns returned
* The order of columns returned

The definition of a table can change at any time. A new business requirement from some other application might add a new column to the table that is not relevant for your application. Storage optimizations done by the DBA may result in a changed order of the columns. If your application queries a table with `SELECT * FROM`, changes as such will be directly reflected in the result set of your query. Your query may retrieve more columns than originally anticipated. Or it could retrieve them in a different order and then try to interpret the wrong data. This can potentially cause data conversion errors, e.g. column on index 3 should be a number but now it's a string, or silent data corruptions.

You should always specify the column names in your `SELECT` statement. This way, your application is protected from table definition changes.

### can introduce additional performance overhead
`SELECT * FROM` may introduce an additional performance overhead. Imagine a scenario where a table has, for example, 50 columns but your application only needs 3 of these. If your application queries the table via `SELECT * FROM`, all 50 column values are retrieved, memory areas allocated on the database server side, the additional column values transmitted via the network to your application, and memory areas allocated by the client driver result set. All that and some more CPU cycles spent just for your application to never use these values.

### is not the best way to inspect the table definition
If you want to see what columns are available on a table, instead of issuing a `SELECT * FROM` you can use the table definition functionality that the database provides. This will not only give you the column names but also the data types and other remarks about the table:

* MySQL, MariaDB, Oracle: `DESCRIBE table_name`
* Postgres: `\d table_name`
* SQL Server: `sp_columns table_name`
* Db2: `DESCRIBE TABLE table_name`
