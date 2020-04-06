<a name="top"></a>

* [General](#general)
* [SQL constructs](#sql-constructs)
* [Administration](#administration)

<a name="general"></a>
# General

* [Autocommit](#autocommit)
* [Row-by-row processing](#row-by-row)
* [Case sensitive table/column names](#case-sensitive-table-column-names)
* [Not using the appropriate grants](#appropriate-grants)

<a name="autocommit"></a>
## Autocommit
[`Autocommit`](https://en.wikipedia.org/wiki/Autocommit) is a built-in mode of database connection operation provided by most databases. If enabled, it will issue an implicit `COMMIT` after every single `DML` operation. This has several drawbacks on performance and explicit transaction boundaries control.

### Loss of transaction boundaries
When `autocommit` is enabled your application no longer has control over the boundaries of the transactions. A business transaction may require to insert a payment record into the `payments` table first and then delete the items in the `shopping_carts` table for that customer. If anything goes wrong, the entire transaction should be rolled back, i.e. the customer's credit card should not be charged and the items should remain in the customer's shopping cart. Imagine the following scenario: `autocommit` is enabled and an error happens when deleting from the customer's shopping cart. At this point in time, the payment record has already been committed and can no longer be rolled back. You think that's not a big deal, just look for the payment record and delete it in your exception handling block? What if there were triggers on that `payments` table that already propagated that payment transaction to the finance system? What if there is no trigger `ON DELETE` on the `payments` table that will undo the propagation when you delete the record? What if your application doesn't have the permissions to perform `DELETE` operations on the `payments` table? You just never know and can quickly end up in a bad spot, just because `autocommit` has been enabled.

Many people use databases for a long time because of their [`ACID`](https://en.wikipedia.org/wiki/ACID) transaction properties. With `autocommit` enabled, you take the `A` (Atomicity) out of `ACID`.

### Potential performance impact
Although a `commit` for a transaction sounds simple, it can have quite an impact on your overall performance. The `commit` is what tells the database to write data on disk into the transaction journal (your modifications tend to happen in memory on the database server). Hence a `commit` results directly in an I/O that your database connection will have to wait for until that I/O is done (because of the `ACID` transaction guarantee). There are a few more steps that the database needs to perform in order to mark your transaction complete, such as releasing potential locks on the rows, etc.

When `autocommit` is enabled, all these I/Os and steps will be performed for every single DML operation that you issue, which can cause an undesired performance and resource utilization impact. Also, every `commit` issued on the driver side means an additional network roundtrip to the database.

[Back to general](#general) [Back to top](#top)

<a name="row-by-row"></a>
## Row-by-row processing
[[TODO]]

[Back to general](#general) [Back to top](#top)

<a name="case-sensitive-table-column-names"></a>
## Case sensitive table/column names
Most databases support case sensitive table names and allow you to have tables such as `Countries`, `countries`, and `COUNTRIES` coexist within a schema. While this may appear as a handy feature at first, it has several drawbacks and should not be used.

### Not supported by the relational model
The relational model does not define case sensitivity on table nor column names. In the relational world, there is no difference between a table called `Countries`, `countries`, or `COUNTRIES`. The normalization rules instruct to have only one table for all records of a certain entity. In the example above, according to the relational model all country records belong in one table, whatever name that table might have. The case of the table name (as well as column names) does carry no significance to reason different about the data.

For example, if you have a table `Countries` and another table `COUNTRIES`, it is not clear which country records can be found in the former and the latter table, nor where a new country record should go.

### Unintentional data fragmentation
If you use case sensitive table names and create a table `COUNTRIES`, there is a risk that someone else may create a table `countries` without realizing that a table for country entities already exists. If you stick to case insensitive table names, the other user/script/tool will not be successful to create that table as it already exists.

### Generated SQL may not work
Many tools and frameworks are capable of generating SQL. However, given the rules of the relational model, or the heterogenous attributes of the tool/framework to work with as many databases as possible, these tools or frameworks may not respect case sensitivity on table or column names. Hence there is a risk that one tool uses, for example, all upper case characters for the table name, while another uses all lower case characters. If you use case sensitive names one or the other tool will generate SQL that will fail.

### Added complexity for one-off hand-written SQL
Most users who connect to a database and write a quick SQL query to answer a question for the manager or similar don't write well-formatted SQL. Most likely, they will write all lower case SQL and don't bother much about how it looks. By using case sensitive names you add unnecessary complexity to their SQL statement attempts.

### Portability is limited
Some databases support case sensitive names by default, some don't, and some support it on one platform but not on another. Using the case sensitive names feature of a database can quickly become a mess. Here a few examples:

#### MySQL
MySQL's case sensitive feature depends on the underlying file system. As the [documentation](https://dev.mysql.com/doc/refman/8.0/en/identifier-case-sensitivity.html) says:

> In MySQL, databases correspond to directories within the data directory. Each table within a database corresponds to at least one file within the database directory (and possibly more, depending on the storage engine). Triggers also correspond to files. Consequently, the case sensitivity of the underlying operating system plays a part in the case sensitivity of database, table, and trigger names. This means such names are not case-sensitive in Windows, but are case-sensitive in most varieties of Unix. One notable exception is macOS, which is Unix-based but uses a default file system type (HFS+) that is not case-sensitive.

In short, if you have a case sensitive database on Linux and ever try to run it on Windows, you may be up for a very bad surprise.

MySQL provides safeguards for this, specifically the [lower\_case\_table\_names](https://dev.mysql.com/doc/refman/8.0/en/server-system-variables.html#sysvar_lower_case_table_names) system variable, which is **set to case sensitive by default.**

#### Postgres, Oracle, Db2
Postgres, Oracle and Db2 all use case insensitive table names by default. The table names `Countries` and `COUNTRIES` are identical in all three databases. Postgres will fold the names into lower case, while Oracle and Db2 will fold them into upper case.

All three of them also support *quoted identifiers* or *delimited identifiers*. These identifiers are formed by an arbitrary sequence of characters in double quotes (`"`). Quoted identifiers will be treated case sensitive in all three databases and require to always appear in double quotes in SQL statements, for example:

```sql
CREATE TABLE "Countries" (id INTEGER, name VARCHAR(100));

SELECT name FROM "Countries"; -- This SQL statement will work

SELECT name FROM countries; -- This SQL statement will fail

SELECT name FROM COUNTRIES; -- This SQL statement will fail
```

For more information, see:

* [Postgres: Identifiers and Key Words](https://www.postgresql.org/docs/current/sql-syntax-lexical.html#SQL-SYNTAX-IDENTIFIERS)
* [Oracle: Database Object Naming Rules](https://docs.oracle.com/en/database/oracle/oracle-database/20/sqlrf/Database-Object-Names-and-Qualifiers.html#GUID-75337742-67FD-4EC0-985F-741C93D918DA)
* [Db2: Making DB2 case-insensitive](https://developer.ibm.com/technologies/databases/articles/making-db2-case-insensitive/)

#### SQL Server
SQL Server does seem to support [case sensitivity](https://docs.microsoft.com/en-us/sql/odbc/reference/develop-app/identifier-case?view=sql-server-ver15) and [*quoted identifiers*](https://docs.microsoft.com/en-us/sql/odbc/reference/develop-app/quoted-identifiers?view=sql-server-ver15) as per the documentation. The default for SQL Server appears to be case insensitivity.

[Back to general](#general) [Back to top](#top)

<a name="appropriate-grants"></a>
## Not using the appropriate grants
[[TODO]]

[Back to general](#general) [Back to top](#top)

<a name="sql-constructs"></a>
# SQL constructs

* [SELECT * FROM](#select-star)
* [Concatenate SQL strings](#concatenate-sql-strings)
* [Not using bind variables](#bind-variables)

<a name="select-star"></a>
## SELECT * FROM

### may lead to unexpected results
`SELECT * FROM` is bad practice because it does not guarantee:

* The number of columns returned
* The order of columns returned

The definition of a table can change at any time. A new business requirement from some other application might add a new column to the table that is not relevant for your application. Storage optimizations done by the DBA may result in a changed order of the columns. If your application queries a table with `SELECT * FROM` changes as such will be directly reflected in the result set of your query. Your query may retrieve more columns than originally anticipated. Or it could retrieve them in a different order and then try to interpret the wrong data. This can potentially cause data conversion errors, e.g., column on index 3 should be a number but now it's a string, or silent data corruptions.

You should always specify the column names in your `SELECT` statement. This way, your application is protected from table definition changes.

### can introduce additional performance overhead
`SELECT * FROM` may introduce an additional performance overhead. Imagine a scenario where a table has, for example, 50 columns but your application only needs 3 of these. If your application queries the table via `SELECT * FROM`, all 50 column values are retrieved, memory areas allocated on the database server side, the additional column values transmitted via the network to your application, and memory areas allocated by the client driver result set. All that and some more CPU cycles spent just for your application to never use these values.

### is not the best way to inspect the table definition
If you want to see what columns are available on a table, instead of issuing a `SELECT * FROM` you can use the table definition functionality that the database provides. This will not only give you the column names but also the data types and other remarks about the table:

* MySQL, MariaDB, Oracle: `DESCRIBE table_name`
* Postgres: `\d table_name`
* SQL Server: `sp_columns table_name`
* Db2: `DESCRIBE TABLE table_name`

[Back to SQL constructs](#sql-constructs) [Back to top](#top)

<a name="concatenate-sql-strings"></a>
## Concatenate SQL strings
See [Not using bind variables](#bind-variables).

[Back to SQL constructs](#sql-constructs) [Back to top](#top)

<a name="bind-variables"></a>
## Not using bind variables
[[TODO]]

[Back to SQL constructs](#sql-constructs) [Back to top](#top)

<a name="administration"></a>
# Administration

* [Not testing backup restores](#backup-restore)

<a name="backup-restore"></a>
## Not testing backup restores
A backup that cannot be restored is worthless! What sounds logical at first is often the cause for pulling your hair out when the time has come. Sometimes it is even the reason why somebody lost a job. **Always test whether your backups can be restored!** Do not make the mistake and just test the backup script. Once again, a backup that cannot be restored is worthless. Repeat after me: a backup that cannot be restored is worthless!

Don't just test your restore only once when you create your backup scripts either. Things change, and sometimes changes can lead to your backup & restore procedure not to work as expected anymore. Ideally you want to regularly test your restores, just like you regularly take your backups.

You may think that this will never happen but arguably [if GitLab would have tested their restores they would not have had a data loss in 2017](https://about.gitlab.com/blog/2017/02/10/postmortem-of-database-outage-of-january-31/):

> When we went to look for the pg\_dump backups we found out they were not there. The S3 bucket was empty, and there was no recent backup to be found anywhere. Upon closer inspection we found out that the backup procedure was using pg\_dump 9.2, while our database is running PostgreSQL 9.6 (for Postgres, 9.x releases are considered major). A difference in major versions results in pg\_dump producing an error, terminating the backup procedure.
>
> The pg\_dump procedure was executed on a regular application server, not the database server. As a result there is no PostgreSQL data directory present on these servers, thus Omnibus defaults to PostgreSQL 9.2. This in turn resulted in pg\_dump terminating with an error.
>
> While notifications are enabled for any cronjobs that error, these notifications are sent by email. For GitLab.com we use DMARC. Unfortunately DMARC was not enabled for the cronjob emails, resulting in them being rejected by the receiver. This means we were never aware of the backups failing, until it was too late.

[Back to Administration](#administration) [Back to top](#top)
