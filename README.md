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

CODE HERE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

### Usage
1. Download the `DotNetData.zip` archive file.
1. Extract the archive under one of directories in `$env:PSModulePath`, such as `C:\Program Files\WindowsPowerShell\Modules`.

#### Connecting from an untrusted domain

When connecting to a database instance in one domain from another domain, where there is no trust relationship between those domains, `runs /netonly` can be used to provide authorization.

Using Integrated Security, if there is no trust relationship between the client domain and the server domain, an exception is thrown:

```New-SqlServerConnection : Exception calling "Open" with "0" argument(s): "Login failed. The login is from an untrusted domain and cannot be used with Integrated authentication."```

Running PowerShell with `runas /netonly` allows specifying the credentials for the target domain:

```runas /netonly /user:DOMAIN\username PowerShell_ise```

### Examples
See the files in the Examples directory for examples for each DBMS.

3. Try out some of the test scripts located in the `Examples` directory.
   For each example script:
   - Edit the example with a specific server name and username
   - Execute the test script in PowerShell
