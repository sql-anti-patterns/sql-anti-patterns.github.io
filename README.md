<a name="top"></a>

* [General](#general)
* [SQL constructs](#sql-constructs)
* [Administration](#administration)

<a name="general"></a>
# General

* [Autocommit](#autocommit)
* [Case sensitive table/column names](#case-sensitive-table-column-names)
* [Not using the appropriate grants](#appropriate-grants)
* [Overcommitting](#overcommitting)
* [Row-by-row processing](#row-by-row)

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

<a name="case-sensitive-table-column-names"></a>
## Case sensitive table/column names
Most databases support case sensitive table names and allow you to have tables such as `Countries`, `countries`, and `COUNTRIES` coexist within a schema. While this may appear as a handy feature at first, it has several drawbacks and should not be used.

### Not supported by the relational model
The relational model does not define case sensitivity on table nor column names. In the relational world, there is no difference between a table called `Countries`, `countries`, or `COUNTRIES`. The normalization rules instruct to have only one table for all records of a certain entity. In the example above, according to the relational model, all country records belong in one table, whatever name that table might have. The case of the table name (as well as column names) does carry no significance to reason differently about the data.

For example, if you have a table `Countries` and another table `COUNTRIES`, it is not clear which country records can be found in the former and the latter table, nor where a new country record should go.

### Unintentional data fragmentation
If you use case sensitive table names and create a table `COUNTRIES`, there is a risk that someone else may create a table `countries` without realizing that a table for country entities already exists. If you stick to case insensitive table names, the other user/script/tool will not be successful to create that table as it already exists.

### Generated SQL may not work
Many tools and frameworks are capable of generating SQL. However, given the rules of the relational model, or the heterogeneous attributes of the tool/framework to work with as many databases as possible, these tools or frameworks may not respect case sensitivity on table or column names. Hence there is a risk that one tool uses, for example, all upper case characters for the table name, while another uses all lower case characters. If you use case sensitive names one or the other tool will generate SQL that will fail.

### Added complexity for one-off hand-written SQL
Most users who connect to a database and write a quick SQL query to answer a question for the manager or similar don't write well-formatted SQL. Most likely, they will write all lower case SQL and don't bother much about how it looks. By using case sensitive names you add unnecessary complexity to their SQL statement attempts.

### Portability is limited
Some databases support case sensitive names by default, some don't, and some support it on one platform but not on another. Using the case sensitive names feature of a database can quickly become a mess. Here a few examples:

#### MySQL
MySQL's case sensitive feature depends on the underlying file system. As the [documentation](https://dev.mysql.com/doc/refman/8.0/en/identifier-case-sensitivity.html) says:

> In MySQL, databases correspond to directories within the data directory. Each table within a database corresponds to at least one file within the database directory (and possibly more, depending on the storage engine). Triggers also correspond to files. Consequently, the case sensitivity of the underlying operating system plays a part in the case sensitivity of database, table, and trigger names. This means such names are not case-sensitive in Windows but are case-sensitive in most varieties of Unix. One notable exception is macOS, which is Unix-based but uses a default file system type (HFS+) that is not case-sensitive.

In short, if you have a case sensitive database on Linux and ever try to run it on Windows, you may be up for a very bad surprise.

MySQL provides safeguards for this, specifically the [lower\_case\_table\_names](https://dev.mysql.com/doc/refman/8.0/en/server-system-variables.html#sysvar_lower_case_table_names) system variable, which is **set to case sensitive by default.**

#### PostgreSQL, Oracle, Db2
PostgreSQL, Oracle and Db2 all use case insensitive table names by default. The table names `Countries` and `COUNTRIES` are identical in all three databases. PostgreSQL will fold the names into lower case, while Oracle and Db2 will fold them into upper case.

All three of them also support *quoted identifiers* or *delimited identifiers*. These identifiers are formed by an arbitrary sequence of characters in double quotes (`"`). Quoted identifiers will be treated case sensitive in all three databases and require to always appear in double quotes in SQL statements, for example:

```sql
CREATE TABLE "Countries" (id INTEGER, name VARCHAR(100));

SELECT name FROM "Countries"; -- This SQL statement will work

SELECT name FROM countries; -- This SQL statement will fail

SELECT name FROM COUNTRIES; -- This SQL statement will fail
```

For more information, see:

* [PostgreSQL: Identifiers and Key Words](https://www.postgresql.org/docs/current/sql-syntax-lexical.html#SQL-SYNTAX-IDENTIFIERS)
* [Oracle: Database Object Naming Rules](https://docs.oracle.com/en/database/oracle/oracle-database/20/sqlrf/Database-Object-Names-and-Qualifiers.html#GUID-75337742-67FD-4EC0-985F-741C93D918DA)
* [Db2: Making DB2 case-insensitive](https://developer.ibm.com/technologies/databases/articles/making-db2-case-insensitive/)

#### SQL Server
SQL Server does seem to support [case sensitivity](https://docs.microsoft.com/en-us/sql/odbc/reference/develop-app/identifier-case?view=sql-server-ver15) and [*quoted identifiers*](https://docs.microsoft.com/en-us/sql/odbc/reference/develop-app/quoted-identifiers?view=sql-server-ver15) as per the documentation. The default for SQL Server appears to be case insensitivity.

[Back to general](#general) [Back to top](#top)

<a name="appropriate-grants"></a>
## Not using the appropriate grants
[[TODO]]

[Back to general](#general) [Back to top](#top)

<a name="overcommitting"></a>
## Overcommitting
[[TODO]]

[Back to general](#general) [Back to top](#top)

<a name="row-by-row"></a>
## Row-by-row processing
[[TODO]]

[Back to general](#general) [Back to top](#top)

<a name="sql-constructs"></a>
# SQL constructs

* [Concatenate SQL strings with input values](#concatenate-sql-strings)
* [Leaving your SQL statements vulnerable to SQL injections](#sql-injections)
* [SELECT * FROM](#select-star)
* [Not using parameterized SQL statements](#parameterized-sql-statements)

<a name="concatenate-sql-strings"></a>
## Concatenate SQL strings with input values
Concatenated SQL strings with input values can be vulnerable to SQL injections and cause performance degradation. See [Leaving your SQL statements vulnerable to SQL injections](#sql-injections) and [Not using parameterized SQL statements](#parameterized-sql-statements) for more information.

[Back to SQL constructs](#sql-constructs) [Back to top](#top)

<a name="sql-injections"></a>
## Leaving your SQL statements vulnerable to SQL injections
[SQL injection](https://en.wikipedia.org/wiki/SQL_injection) is a code injection technique used to execute malicious SQL statements via vulnerable applications. **SQL injections are a serious security threat that still cause data breaches today! You should be taking every precaution to prevent SQL injections!**

[[TODO]]

[Back to SQL constructs](#sql-constructs) [Back to top](#top)

<a name="select-star"></a>
## SELECT * FROM

### may lead to unexpected results
`SELECT * FROM` is bad practice because it does not guarantee:

* The number of columns returned
* The order of columns returned

The definition of a table can change at any time. A new business requirement from some other application might add a new column to the table that is not relevant for your application. Storage optimizations done by the DBA may result in a changed order of the columns. If your application queries a table with `SELECT * FROM` changes as such will be directly reflected in the result set of your query. Your query may retrieve more columns than originally anticipated. Or it could retrieve them in a different order and then try to interpret the wrong data. This can potentially cause data conversion errors, e.g., the column on index 3 should be a number but now it's a string, or silent data corruption.

You should always specify the column names in your `SELECT` statement. This way, your application is protected from table definition changes.

### can introduce additional performance overhead
`SELECT * FROM` may introduce additional performance overhead. Imagine a scenario where a table has, for example, 50 columns but your application only needs 3 of these. If your application queries the table via `SELECT * FROM`, all 50 column values are retrieved, memory areas allocated on the database server-side, the additional column values transmitted via the network to your application, and memory areas allocated by the client driver result set. All that and some more CPU cycles spent just for your application to never use these values.

### is not the best way to inspect the table definition
If you want to see what columns are available on a table, instead of issuing a `SELECT * FROM` you can use the table definition functionality that the database provides. This will not only give you the column names but also the data types and other remarks about the table:

* MySQL, MariaDB, Oracle: `DESCRIBE table_name`
* PostgreSQL: `\d table_name`
* SQL Server: `sp_columns table_name`
* Db2: `DESCRIBE TABLE table_name`

[Back to SQL constructs](#sql-constructs) [Back to top](#top)

<a name="parameterized-sql-statements"></a>
## Not using parameterized SQL statements
Databases offer functionality to pass on parameters to SQL statements. [Oracle](https://docs.oracle.com/en/database/oracle/oracle-database/20/tgsql/improving-rwp-cursor-sharing.html#GUID-042A85BF-D96E-44AB-9312-4EB115CCE7B0) and [Db2](https://www.ibm.com/developerworks/library/se-bindvariables/index.html) call these parameters *bind variables*, [MySQL *user-defined variables*](https://dev.mysql.com/doc/refman/8.0/en/user-variables.html), [PostgreSQL *parameters*](https://www.postgresql.org/docs/current/sql-prepare.html) and [SQL Server *variables*](https://docs.microsoft.com/en-us/sql/t-sql/language-elements/variables-transact-sql?view=sql-server-ver15). [Parameterized SQL statements](https://en.wikipedia.org/wiki/Prepared_statement) use placeholders for values that allow you to write SQL statements that accept input parameters at runtime.

To illustrate, let's look at the two examples below:  

1. The first SQL statement is not using a parameter or variable in the SQL statement but a string literal (a fixed string value) instead.

2. The second statement is using a parameter in MySQL user-defined variable format.


```sql
SELECT country_code, region_id
  FROM countries
    WHERE name = 'Austria';
```
```sql
SELECT country_code, region_id
  FROM countries
    WHERE name = @country_name;
```

Both statements are semantically identical but the second SQL statement using the variable has several benefits over the first one:

### Your application doesn't need to reconstruct the SQL statement based on the input values
The above example is simple, having only one input parameter. Nevertheless, it proves the point perfectly. Imagine your application has a web-based front-end and users can specify which country information they want to look up. As users select different countries, the application has to execute the statement again to retrieve the country-specific information. If you opted for using string literals your application has to generate a new SQL statement each time a new country is selected, for example:

```sql
SELECT country_code, region_id
  FROM countries
    WHERE name = 'Austria';
```
```sql
SELECT country_code, region_id
  FROM countries
    WHERE name = 'Switzerland';
```
```sql
SELECT country_code, region_id
  FROM countries
    WHERE name = 'United States';
```

If you opted for a parameterized SQL statement instead, all your application has to do is to swap the input parameter and execute the very same statement:

```sql
SET @country_name = 'Austria';

SELECT country_code, region_id
  FROM countries
    WHERE name = @country_name;
```
```sql
SET @country_name = 'Switzerland';

SELECT country_code, region_id
  FROM countries
    WHERE name = @country_name;
```
```sql
SET @country_name = 'United States';

SELECT country_code, region_id
  FROM countries
    WHERE name = @country_name;
```

Now imagine that you have a complex and long SQL statement with many different input parameters. Without using parameters, the task of generating the correct SQL statement can quickly take up quite a few lines of code inside your application, code that needs to be written and maintained. If you use SQL statement variables instead, your application can just use one generic SQL statement and all you have to worry about is to set the values for the variables before you execute the statement again and again.

### The database can reuse the SQL statement
Using parameterized SQL statements does not only mean that your application can reuse the same SQL statement, but the database can reuse it too! This can offer sometimes huge performance benefits, especially on highly concurrent database workloads. In order for a database to execute a SQL statement, it usually runs through the following three steps first:

1. `PARSE`
2. `ANALYZE`
3. `REWRITE`

#### Parse
During the `Parse` phase, the database performs the syntax and semantic check of a SQL statement. It trims new lines and extra white spaces from the statement, check whether it is well-formed and whether the SQL statement is meaningful, i.e., whether the objects and columns in the statement exist and the user has permissions to access these. Some databases, like Oracle, also generate a unique `SQL ID` by hashing the final SQL statement string.

#### Analyze
This is where all the SQL optimization magic happens. Once the database knows that the SQL statement is valid, it will go on and optimize it and eventually generate the SQL execution plan. This is where the SQL optimizer comes to work. The optimizer looks at things like the best data access methods (should the database use an index or should it use a full table scan to retrieve the data, should it use a range scan or is it a unique key lookup, should it prune partitions, etc.) and joins methods (is a nested loop most efficient or is a hash join better, etc.) Naturally, there are many permutations that need to be looked at and the more complex the SQL statement is, the more choices there are. The `Analyze` phase is usually the CPU and resource-intensive part of the three phases before the statement execution and ideally, you want to avoid it if you can.

#### Rewrite
The `Rewrite` phase is still part of the SQL statement optimization. Databases can be really clever and sometimes they can detect your poorly written SQL statement and rewrite it to a semantically identical yet better performing one. Don't take it personally, really, that's kind of what you want databases to do for you unless you make your living as a SQL performance tuning consultant. :) The `Rewrite` phase may not be as expensive as the `Analyze` phase but it can trigger another round of the `Parse` and `Analyze` phases altogether.

#### Parameterized SQL statements and SQL optimization

How does this all tie in with parameterized SQL statements you may ask yourself at this stage?

All of these steps above will always be performed when a database encounters a new statement. This is sometimes referred to as `hard parsing` the SQL statement. Some databases are even smart enough to implicitly cache the statements once they have been parsed, analyzed and potentially rewritten. Oracle is such an example. After all the optimization steps are done Oracle will cache the optimized SQL statement and execution plan in memory under the generated `SQL ID` (a hash of the SQL statement text). If the same statement comes along again, the `SQL ID` matches and Oracle just fetches the ready-to-go execution plan and executes the SQL statement, without having to go through all the `hard parsing` phases again. (Don't worry, Oracle is also smart enough to evict a cached SQL statement if the semantics have changed, i.e., a column has been dropped or a grant has been removed, etc.) If you are using variables, the statement will remain the same regardless of the input values. However, if you are using string literals, the `SQL ID` of the statement will change as the hash for the SQL text will change due to the changing string literal. For the database, the statement will be a brand new one, although it's semantically identical to the previously executed one. You can find a really good and detailed explanation on this topic [here](https://www.ibm.com/developerworks/library/se-bindvariables/index.html).

Other databases, like MySQL and PostgreSQL, do not offer implicit caching of a SQL statement but still provide a similar mechanism of optimizing a SQL statement once and executing it many times via the `PREPARE` instruction ([MySQL](https://dev.mysql.com/doc/refman/8.0/en/prepare.html), [PostgreSQL](https://www.postgresql.org/docs/current/sql-prepare.html)). PostgreSQL also provides two nice examples:

```sql
PREPARE usrrptplan (int) AS
    SELECT * 
      FROM users u, logs l
        WHERE u.usrid=$1 AND u.usrid=l.usrid
          AND l.date = $2;
EXECUTE usrrptplan(1, current_date);
```
```sql
PREPARE fooplan (int, text, bool, numeric) AS
    INSERT INTO foo VALUES($1, $2, $3, $4);
EXECUTE fooplan(1, 'Hunter Valley', 't', 200.00);
```
The second example demonstrates how to use a parameterized SQL statement for an `INSERT` operation. At first, this may seem counter-intuitive but also `INSERT` statements (all SQL statements) need to be parsed and analyzed. Even though the `Analyze` phase for an `INSERT` statement is much less complex than a SQL query (after all, all the database has to do is to insert a new row), the database still has to perform some work in order to execute the `INSERT`. If you have many rows that you would like to insert, you can save the database quite some redundant work by using variables for one `INSERT` statement compared to giving it many different "brand new" `INSERT` statements with different text in the `VALUES` clause.

### Some types of SQL injections cannot occur
Parameterized SQL statements prevent some forms of SQL injections. SQL injections are a serious security risk and should be prevented at all costs. See [Leaving your SQL statements vulnerable to SQL injections](#sql-injections) for more information on SQL injections and how to prevent them.

[Back to SQL constructs](#sql-constructs) [Back to top](#top)

<a name="administration"></a>
# Administration

* [Not testing backup restores](#backup-restore)

<a name="backup-restore"></a>
## Not testing backup restores
A backup that cannot be restored is worthless! What sounds logical at first is often the cause for pulling your hair out when the time has come. Sometimes it is even the reason why somebody lost a job. **Always test whether your backups can be restored!** Do not make the mistake and just test the backup script. Once again, a backup that cannot be restored is worthless. Repeat after me: a backup that cannot be restored is worthless!

Don't just test your restore only once when you create your backup scripts either. Things change, and sometimes changes can lead to your backup & restore procedure not to work as expected anymore. Ideally, you want to regularly test your restores, just like you regularly take your backups.

You may think that this will never happen but arguably [if GitLab would have tested their restores they would not have had a data loss in 2017](https://about.gitlab.com/blog/2017/02/10/postmortem-of-database-outage-of-january-31/):

> When we went to look for the pg\_dump backups we found out they were not there. The S3 bucket was empty, and there was no recent backup to be found anywhere. Upon closer inspection we found out that the backup procedure was using pg\_dump 9.2, while our database is running PostgreSQL 9.6 (for Postgres, 9.x releases are considered major). A difference in major versions results in pg\_dump producing an error, terminating the backup procedure.
>
> The pg\_dump procedure was executed on a regular application server, not the database server. As a result there is no PostgreSQL data directory present on these servers, thus Omnibus defaults to PostgreSQL 9.2. This in turn resulted in pg\_dump terminating with an error.
>
> While notifications are enabled for any cronjobs that error, these notifications are sent by email. For GitLab.com we use DMARC. Unfortunately DMARC was not enabled for the cronjob emails, resulting in them being rejected by the receiver. This means we were never aware of the backups failing, until it was too late.

[Back to Administration](#administration) [Back to top](#top)
