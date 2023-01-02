<a name="top"></a>

* [General](#general)
* [SQL constructs](#sql-constructs)
* [Administration](#administration)

<a name="general"></a>
# General

* [Autocommit](#autocommit)
* [Case sensitive table/column names](#case-sensitive-table-column-names)
* [Not using the appropriate privileges](#appropriate-privileges)
* [Overcommitting](#overcommitting)
* [Row-by-row processing](#row-by-row)

<a name="autocommit"></a>
## Autocommit
[`Autocommit`](https://en.wikipedia.org/wiki/Autocommit) is a built-in database connection mode provided by most databases. When enabled, this mode will issue a `COMMIT` after every single database interaction that started a new transaction, immediately and implicitly completing the transaction before control is returned to the client. This has several drawbacks. For one, transactions cannot be rolled back as they have already been committed by the time control is returned to the client. Second, clients also won't have control over the boundaries of a given transaction, i.e., how many operations should be grouped and hence occur in one atomic transaction. Last but not least, `autocommit` can also have a potential impact on performance, especially on systems that execute many operations concurrently.

### Transactions cannot be rolled back
Because `autocommit` commits transactions on the client's behalf before control is returned to the client, an application has no way to rollback a given transaction because the transaction is already completed. With `autocommit` mode enabled, the following statement

```sql
INSERT INTO countries (id, name) VALUES (1, 'Austria');
INSERT INTO countries (id, name) VALUES (2, 'Switzerland');
INSERT INTO countries (id, name) VALUES (3, 'United States');
COMMIT;
```
will be executed on the database as

```sql
INSERT INTO countries (id, name) VALUES (1, 'Austria');
COMMIT;
INSERT INTO countries (id, name) VALUES (2, 'Switzerland');
COMMIT;
INSERT INTO countries (id, name) VALUES (3, 'United States');
COMMIT;
COMMIT; -- the original COMMIT sent by the application
```

### Loss of transaction boundaries
When `autocommit` is enabled your application no longer has control over the boundaries of a transaction. Take a retail website as an example. At checkout, the application may require require to insert a payment record into the `payments` table, insert items from the `shopping_carts` table into the `shipments` table and then delete the items in the `shopping_carts` table before informing the customer that the purchase has gone through. If anything goes wrong, the entire transaction should be rolled back, i.e. the customer's credit card should not be charged and the items should remain in the customer's shopping cart and not being delivered. Imagine the following scenario: `autocommit` is enabled and an error happens when deleting from the `shopping_carts` table. At this point in time, the payment and shipment records have already been committed and can no longer be rolled back. You think that's not a big deal, just look for the records in the payments and shipments tables and delete them in your exception handling block? What if there were triggers on that `payments` table that already propagated that payment transaction to the finance system? What if the shipping system already send of its own orders to the warehouse to get these items? What if your application doesn't have the permissions to perform `DELETE` operations on either of those tables? You just never know and can quickly end up in a bad spot, just because `autocommit` has been enabled. Instead, if all of these steps occurred in a single transaction, you can simply rollback the entire transactions and do not need to worry about any mediation steps.

Many people use databases for a long time because of their [`ACID`](https://en.wikipedia.org/wiki/ACID) transaction properties. With `autocommit` enabled, you take the `A` (Atomicity) out of `ACID`.

### Potential performance impact
Although a `commit` for a transaction sounds simple, it *can* have quite an impact on your overall performance. The `commit` is what tells the database to write data to disk and make it durable (the `D` part of `ACID`). This usually happens by writing the data to a transaction journal (the modifications by the `DML` statements themselves tend to happen in memory on the database server). Hence, issuing a `commit` directly results in an I/O that your database connection will have to wait for. Besides the I/O, databases have to take a few more steps to complete a transaction during a `commit`, such as releasing locks on rows, etc.

When `autocommit` is enabled, these I/O calls and other steps will be performed for every single DML operation that you issue, which can cause an undesired performance and resource utilization impact. Imagine if you were to load 10,000 rows into a table, it may be faster to load the 10,000 rows all at once and only `commit` at the end, then issuing 10,000 I/Os, one for each individual row. Also, every `commit` issued on the driver side can mean an additional network roundtrip to the database. Some drivers may be smart enough to piggyback the `commit` with the `DML` operations, others may not and send a separate call on your behalf.

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

<a name="appropriate-privileges"></a>
## Not using the appropriate privileges
The database users that your applications connect with should always follow the [principle of least privilege](https://en.wikipedia.org/wiki/Principle_of_least_privilege) and concept of [separation of duties](https://en.wikipedia.org/wiki/Separation_of_duties). In other words, they should only be given the most granular privileges (sometimes referred to as *grants* or *permissions*) to perform their tasks and different database users should be used to perform different tasks. This ensures a fine-grained security model that benefits your application, data model, and the data itself. Below are a couple of rules:

* If an application is only reading data from tables (or views), it shall only have read privileges (`SELECT`) but no write privileges (`INSERT`, `UPDATE`, `DELETE`) on these tables, nor any read or write privileges on any other tables (or views).
* If an application is only reading from and modifying data in tables (or views), it shall only have CRUD privileges (`INSERT`, `SELECT`, `UPDATE`, `DELETE`) on these tables (or views) but not any other tables (or views).
* An application shall not have any Data Definition (`DDL`, e.g. `CREATE TABLE`, `DROP TABLE`, ...) privileges unless it is explicitly designed for such a task (for example, an application needs to truncate a staging table before the next load, hence requiring the `TRUNCATE TABLE` privilege on that table; an application needs privileges to dynamically create and drop supporting database objects at runtime).
* An application shall not have any administrative privileges unless explicitly designed for these tasks.
* An application that is designed for data model modification or administrative tasks shall use a different database user than applications accessing the data, also adhering to the principle of least privileges.
* If a database manages *independent* data for many applications, each associated data model (and corresponding database objects) shall reside in its own `SCHEMA`.

The principle of least privilege and concept of separation of duties not only prevents applications and users from accidental modification or deletion of data but also lowers the risk of exposure via security vulnerability attacks (see  [SQL injections](#sql-injections)).

For more information, see the privileges sections in the documentation:

* PostgreSQL
  * [Privileges](https://www.postgresql.org/docs/current/ddl-priv.html)
  * [Database Roles](https://www.postgresql.org/docs/12/user-manag.html)
* MySQL
  * [Privileges Provided by MySQL](https://dev.mysql.com/doc/refman/8.0/en/privileges-provided.html)
  * [Using Roles](https://dev.mysql.com/doc/refman/8.0/en/roles.html)
* Oracle
  * [GRANT reference: Listings of System and Object Privileges](https://docs.oracle.com/en/database/oracle/oracle-database/20/sqlrf/GRANT.html#GUID-20B4E2C0-A7F8-4BC8-A5E8-BE61BDC41AC3)
  * [Predefined Roles in an Oracle Database Installation](https://docs.oracle.com/en/database/oracle/oracle-database/20/dbseg/configuring-privilege-and-role-authorization.html#GUID-A5B26A03-32CF-4F5D-A6BE-F2452AD8CB8A)
* SQL Server
  * [Permissions](https://docs.microsoft.com/en-us/sql/relational-databases/security/permissions-database-engine?view=sql-server-ver15)
  * [Getting Started with Database Engine Permissions](https://docs.microsoft.com/en-us/sql/relational-databases/security/authentication-access/getting-started-with-database-engine-permissions?view=sql-server-ver15)
* Db2
  * [Grant reference (see all references on the left)](https://www.ibm.com/support/knowledgecenter/en/SSEPGG_11.1.0/com.ibm.db2.luw.sql.ref.doc/doc/r0000966.html)
  * [Creating and granting membership in roles](https://www.ibm.com/support/knowledgecenter/en/SSEPGG_11.1.0/com.ibm.db2.luw.admin.sec.doc/doc/c0050533.html)

[Back to general](#general) [Back to top](#top)

<a name="overcommitting"></a>
## Overcommitting
Overcommitting describes the action of committing too frequently. This usually occurs when using [`Autocommit`](#autocommit) but can also happen when explicitly issuing `COMMIT` within your application code.

### Why does it matter?
Although overcommitting won't break your application nor the database, is has several drawbacks similar to using `Autocommit`. One of them is a negative impact on performance. With every commit that your application issues, you incur an additional network roundtrip to the database but also force the database to write data to disk although that might not be necessary at that point in time. A typical example is when loading a file where each line in the file translates to one or more `INSERT`/`UPDATE`/`MERGE` statements. You may feel like you should commit after you have loaded a line but that may not be necessary. You could also commit after 10 or 100 lines, perhaps even 1000 lines. This is commonly referred to as `batch size`. But what happens when your application terminates halfway through the loading process and you didn't commit after each line? Even if that happens, the file will still be available when your application starts up again and continues the loading process. You will most likely already have a mechanism in place to know at which line to continue. The fact that you have to continue at line 237 or 230 (if you are going with a `batch size` of 10, for example) won't matter much to the application. However, it may matter a lot for the overall performance of your data loading process.  

**Do not underestimate this seemingly trivial anti-pattern. Overcommitting is still today a common reason for bad overall performance!** 

### When should you commit?
The critical question is: **when should you commit?**  
There is only ever going to be one correct answer that you should remember at all times! That answer is: **whenever your business logic requires you to commit!**

#### What does that mean?
In order to save data in a database, you eventually need to commit at some point. Sometimes you have the luxury of flexibility when you want to commit, like with the file load example above. Other times you don't have a choice. An example of having no choice is cash withdrawals from bank accounts. In this scenario, you cannot predict when a withdrawal is going to happen. You probably don't want the customer to wait until, for example, 100 more customers are going to decide to withdraw money as well. And you probably don't want to give your customer the money before you can commit the fact that the withdrawal happened. In this scenario, the business logic requires you to commit after each withdrawal, regardless of whether there is 1 withdrawal per minute or 1000 per second.

The general rule of thumb is:

* **Flexibility** of when you can commit is given **whenever you *can* restart the transaction**.
* **No choice** of when you can commit is given **whenever you *cannot* restart the transaction**.

The file load is an example of a restartable transaction. Even if your application crashes halfway through, the file and all the data is still there and you can pick up where you left off.

The cash withdrawal is an example of a non-restartable transaction. Once the customer got the money, the money is gone. If your application crashes before it can store that fact in the database, you will have an incorrect balance sheet. The money is gone, but the system doesn't reflect that.

[Back to general](#general) [Back to top](#top)

<a name="row-by-row"></a>
## Row-by-row processing
Row-by-row processing describes an iterative technique that loops through a data set and operates on each individual record at a time, hence processing the data set a row at a time, or *row by row*. In a common scenario, an application executes a `SELECT` statement and then fetches each row of the result set from the database in a loop. Usually some operations are executed on each individual row within the loop once retrieved. This technique works well on small data sets and is easy to understand. However, for large data sets this technique has several disadvantages. It requires many network roundtrips to transmit small pieces of data from the database to the application and constrains the processing itself to a serial execution model, preventing it to take advantage of multiple CPU cores on the system.

The alternative to row-by-row processing is usually called *set-based processing* or *batch processing*, which describes a technique that applies an operation on a *set* or *batch* of data inside the database. In a common scenario, an application executes a `SELECT` statement that already performs operations on the data set, only fetching the single-row end result from the database.

To illustrate the differences let's look at an example:

Assume that we have a table called `purchases` that stores every purchase ever made on our globally operating web store. Amongst others, the `purchases` table includes the following columns: `amount` and `country`. Let's say that we want to sum up the total revenue from a given country.

Using the **row-by-row technique**, the `SELECT` statement would look like this:

```sql
SELECT amount
  FROM purchases
    WHERE country = @country;
```

The application would execute this `SELECT` statement, fetch each row of the result set and apply the amount of the current row to a total sum, similar to this:

```java
stmt = prepareStmt("SELECT amount FROM purchases WHERE country = @country");
stmt.setParameter("@country", "Austria");
result = stmt.executeQuery();

total = 0;
while (result.hasNext()) {
  result.fetchNextRow();
  total = total + result.getValue("amount");
}
```

The example above will produce the correct result. However, the iterations of the `while` loop are directly correlated to the number of rows returned by the query and are hence unpredictable and directly dependent on the data itself.

Using the **set-based technique**, the `SELECT` statement would look like this:

```sql
SELECT SUM(amount) AS amount
  FROM purchases
    WHERE country = @country;
```

The difference to the statement above is that this statement applies the `SUM()` aggregate function over the `amount` column. By doing so, we instruct the database to already calculate the sum of all rows in the result set and only send the total sum back to the application. Hence the application would execute this `SELECT` statement and only fetch a single row containing the aggregated sum, similar to this:

```java
stmt = prepareStmt("SELECT SUM(amount) AS amount FROM purchases WHERE country = @country");
stmt.setParameter("@country", "Austria");
result = stmt.executeQuery();
result.fetchNextRow();
total = result.getValue("amount");
```

The main benefit of the **set-based technique** over the **row-by-row technique** in this case is that the set-based technique will only ever require a single network roundtrip to retrieve a couple of bytes representing the total sum, while the row-by-row technique will require an unpredictable amount of network roundtrips and bytes. The **set-based technique** also allows the database to scan the data all at once in the most efficient way it sees fit, rather than performing scattered reads for the additional fetch requests from the application.

**The performance impact by network roundtrips is not to be underestimated!** Let's say that a network roundtrip takes about 1 millisecond, something very reasonable with modern networks, the time spent just to send data back and forth, not having even processed any data yet, is the following:

| Rows          | Time spent on the network                 |
| ------------: | ----------------------------------------- |
|             1 | 1 millisecond                             |
|         1,000 | 1 second                                  |
|        10,000 | 10 seconds                                |
|       100,000 | 1 minute, 40 seconds                      |
|     1,000,000 | 16 minutes, 40 seconds                    |
| 1,000,000,000 | 11 days, 13 hours, 46 minutes, 40 seconds |

Keep these numbers in mind every time you write a loop in which you exchange data with your database. And also keep in mind that your network might not even be as fast as 1 millisecond for a roundtrip!

[[TODO batch DML]]

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
[SQL injection](https://en.wikipedia.org/wiki/SQL_injection) is a code injection technique used to execute malicious SQL statements via vulnerable applications. **SQL injections are a serious security threat that still causes data breaches today! You should be taking every precaution to prevent SQL injections!**

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
