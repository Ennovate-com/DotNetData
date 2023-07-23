# DotNetData
## PowerShell implementation of .NET Data

Returns rows of data from database as PowerShell objects, rather than just one line of text data per row.
This allows writing PowerShell code to perform operations involving different database instances or even different DBMS instances.
For example, data can be merged from different DBMS or synchronized from one database instance into another DBMS instance.
The original use case that prompted creating this code was synchronizing data in many edge MySQL instances with a centralized SQL Server instance.

Database Management Systems (DBMS) currently supported:
+ Microsoft SQL Server
+ MySQL from Oracle
+ PostgreSQL

### Usage
1. Download the `DotNetData.zip` archive file.
1. Extract the archive under one of directories in `$env:PSModulePath`, such as `C:\Program Files\WindowsPowerShell\Modules`.

### Examples
See the files in the Examples directory for examples for each DBMS.

3. Try out some of the test scripts located in the `Examples` directory.
   For each example script:
   - Edit the example with a specific server name and username
   - Execute the test script in PowerShell
