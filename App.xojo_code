#tag Class
Protected Class App
Inherits WebApplication
	#tag Event
		Function HandleURL(request As WebRequest, response As WebResponse) As Boolean
		  // Create a new "Luna" APIRequest object for this request.
		  Dim APIRequest As new Luna(Request, response, SecureConnectionsRequired, DatabaseHost, DatabaseUserName, DatabasePassword, DatabaseName, DatabaseSchema)
		  
		  // If this is a request for the root, or an error was encountered while preparing to process the request...
		  If (Request.Path = "") or (Response.Status <> 200) Then
		    Return True
		  End If
		  
		  // If this is a preflight request for CORS...
		  If Request.Method = "OPTIONS" Then
		    
		    // We're responding to a preflight request, so we want to add access-control headers.
		    Response.Header("Access-Control-Allow-Origin") = APIRequest.AccessControlAllowOrigin
		    Response.Header("Access-Control-Allow-Credentials") = APIRequest.AccessControlAllowCredentials
		    Response.Header("Access-Control-Allow-Methods") = APIRequest.AccessControlAllowMethods
		    Response.Header("Access-Control-Allow-Headers") = APIRequest.AccessControlAllowHeaders
		    Response.Write("")
		    Return True
		    
		  End If
		  
		  Dim strPath As String=Request.Path
		  'if strPath <> "" and  Left(strPath,1) <> "/" Then
		  'strPath = "/" + Lowercase(strPath)
		  'end if
		  
		  //swagger.json does not need to be authenticated
		  If strPath<>"/v1/swagger.json" Then 
		    // If the request is not authenticated...
		    If not RequestAuthenticate(Request, APIRequest) Then 
		      Response.Status = 401
		      Return True
		    End If
		  End If
		  
		  if strPath="/v1/Reset" Then
		    If not RequestResetPermission(Request, APIRequest) Then 
		      Response.Status = 401
		      Return True
		    End If
		  end if
		  
		  // See if the app has a method that can process this request.
		  Dim method As Introspection.MethodInfo = APIRequest.AppMethodGet(self, Request)
		  
		  // If a method was found...
		  If method <> nil Then
		    
		    // Create an array of parameters to use when calling the method.
		    Dim params() As Variant
		    
		    // Add the APIRequest to the params.
		    params.Append(APIRequest)
		    
		    // Invoke the method.
		    Dim LocalResponse As Dictionary = method.Invoke(self, params)
		    
		    // Set the request status and body.
		    Response.Status = LocalResponse.Value("ResponseStatus")
		    Response.Write(LocalResponse.Value("ResponseBody"))
		    
		  Else
		    Response.Status = 404
		    Response.Write( APIRequest.ErrorResponseCreate ( "404", "Unsupported API Version, Entity, and/or Method " + strPath + "HandleURL", "") )
		  End If
		  
		  
		  // Close the connection to the database.
		  #if UseMySQL
		    APIRequest.DatabaseConnection.Close
		  #elseif UsePostgreSQL
		    APIRequest.pgDatabaseConnection.Close
		  #endif
		  
		  
		  // Return True to avoid sending back the default 404 response.
		  Return True
		End Function
	#tag EndEvent

	#tag Event
		Sub Opening(args() As String)
		  System.Log(System.LogLevelNotice, "Luna Started")
		  #If Not DebugBuild Then
		    If not Daemonize Then
		      System.Log(system.LogLevelError, "Could not daemonize Luna")
		    End If
		  #endif
		  
		End Sub
	#tag EndEvent


	#tag Method, Flags = &h0
		Function GetFieldName(strFieldname As String) As String
		  #if UseMySQL
		    Return strFieldname
		  #elseif UsePostgreSQL
		    Return Lowercase(strFieldname)
		  #elseif UseSQLite
		    Return strFieldname
		  #endif
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function RequestAuthenticate(Request As WebRequest, APIRequest As Luna) As Boolean
		  // Implement your authentication scheme here.
		  // Note: This is a *very* simple example of an authentication scheme.
		  
		  // Get the Authorization header.
		  Dim AuthorizationHeader As String = Request.Header("Authorization")
		  
		  // If the Authorization has not been specified correctly...
		  If InStr(0, AuthorizationHeader, "Bearer ") <> 1 Then
		    Return False
		  End if
		  
		  // Remove the "Bearer" prefix from the value.
		  AuthorizationHeader = Replace(AuthorizationHeader, "Bearer ", "")
		  
		  // In this case, we have a single, hard-coded key that needs to be passed.
		  Dim APIKey As String = "taWFk8Z4gR8oGoYtG+7Kycm97UswXW8i87T]HnjcNCGQJgi8JD"
		  
		  If AuthorizationHeader = APIKey Then
		    Return True
		  Else
		    Return False
		  End If
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function RequestResetPermission(Request As WebRequest, APIRequest As Luna) As Boolean
		  // Implement your reset authentication scheme here.
		  // Note: This is a *very* simple example of a reset authentication scheme.
		  
		  // Get the ResetAuthorization header.
		  Dim ResetAuthorizationHeader As String = Request.Header("ResetAuthorization")
		  
		  // If the Authorization has not been specified correctly...
		  If InStr(0, ResetAuthorizationHeader, "Bearer ") <> 1 Then
		    Return False
		  End if
		  
		  // Remove the "Bearer" prefix from the value.
		  ResetAuthorizationHeader = Replace(ResetAuthorizationHeader, "Bearer ", "")
		  
		  
		  // In this case, we have a single, hard-coded key that needs to be passed.
		  Dim ResetKey As String = "MySuperSecretResetPassword"
		  
		  If ResetAuthorizationHeader = ResetKey Then
		    Return True
		  Else
		    Return False
		  End If
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function V1_Contacts_Delete(APIRequest As Luna) As Dictionary
		  // Attempt to delete the record, and return the result.
		  // Note: The params being passed are the table name and the column name of the primary key.
		  Return APIRequest.SQLDELETEProcess("Contacts", "EmailAddress")
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function V1_Contacts_Get(APIRequest As Luna) As Dictionary
		  // If no record ID was specified...
		  //changed 2 to 1 in the next line because otherwise I only got results if I ended the request with a /
		  //ending the request with a slash to me does not look like expected functionality (maybe it worked correctly with MySQL?)
		  If APIRequest.RequestPathComponents.Ubound = 1 Then
		    #if UseMySQL
		      APIRequest.SQLStatement = APIRequest.DatabaseConnection.Prepare("SELECT " + APIRequest.SQLColumnsPrepare + " FROM Contacts")
		    #elseif UsePostgreSQL
		      APIRequest.pgSQLStatement = APIRequest.pgDatabaseConnection.Prepare("SELECT " + APIRequest.SQLColumnsPrepare + " FROM contacts")
		    #elseif UseSQLite
		      APIRequest.SQLiteStatement =  APIRequest.db.Prepare("SELECT " + APIRequest.SQLColumnsPrepare + " FROM Contacts")
		    #endif
		  Else
		    #if UseMySQL
		      APIRequest.SQLStatement = APIRequest.DatabaseConnection.Prepare("SELECT " + APIRequest.SQLColumnsPrepare + " FROM Contacts WHERE ? = ?")
		      APIRequest.SQLStatement.BindType(0, MySQLPreparedStatement.MYSQL_TYPE_STRING)
		      APIRequest.SQLStatement.Bind(0, APIRequest.RequestPathComponents(2))
		      APIRequest.SQLStatement.BindType(1, MySQLPreparedStatement.MYSQL_TYPE_STRING)
		      APIRequest.SQLStatement.Bind(1, APIRequest.RequestPathComponents(3))
		      
		    #elseif UsePostgreSQL
		      APIRequest.pgSQLStatement = APIRequest.pgDatabaseConnection.Prepare("SELECT " + APIRequest.SQLColumnsPrepare + " FROM contacts WHERE $1 = $2")
		      APIRequest.pgSQLStatement.Bind(0, APIRequest.RequestPathComponents(2))
		      APIRequest.pgSQLStatement.Bind(1, APIRequest.RequestPathComponents(3))
		    #elseif UseSQLite
		      var ColumnRequest As String = APIRequest.RequestPathComponents(2)
		      // select case RequestPathComponents(2)
		      // case "emailaddress"
		      // ColumnRequest = "emailaddress"
		      // case "SurName"
		      // ColumnRequest = "SurName"
		      // end select
		      APIRequest.SQLiteStatement = APIRequest.db.Prepare("SELECT " + APIRequest.SQLColumnsPrepare + " FROM contacts WHERE "+ColumnRequest+" = ?")
		      // APIRequest.SQLiteStatement.BindType(0, SQLitePreparedStatement.SQLITE_TEXT)
		      // APIRequest.SQLiteStatement.Bind(0, APIRequest.RequestPathComponents(2))
		      APIRequest.SQLiteStatement.BindType(0, SQLitePreparedStatement.SQLITE_TEXT)
		      APIRequest.SQLiteStatement.Bind(0, APIRequest.RequestPathComponents(3))
		    #endif
		  End If
		  
		  // Get and return the record.
		  Return APIRequest.SQLSELECTProcess
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function V1_Contacts_Patch(APIRequest As Luna) As Dictionary
		  Dim Response As New Dictionary
		  
		  
		  // Get the record to be updated.
		  #if UseMySQL
		    APIRequest.SQLStatement = APIRequest.DatabaseConnection.Prepare("SELECT * FROM Contacts WHERE EmailAddress = ?")
		    APIRequest.SQLStatement.BindType(0, MySQLPreparedStatement.MYSQL_TYPE_STRING)
		    APIRequest.SQLStatement.Bind(0, APIRequest.RequestPathComponents(2))
		  #elseif UsePostgreSQL
		    APIRequest.pgSQLStatement = APIRequest.pgDatabaseConnection.Prepare("SELECT * FROM contacts WHERE emailaddress = $1")
		    APIRequest.pgSQLStatement.Bind(0, APIRequest.RequestPathComponents(2))
		  #elseif UseSQLite
		    APIRequest.SQLiteStatement = APIRequest.db.Prepare("SELECT * FROM Contacts WHERE EmailAddress = ?")
		    APIRequest.SQLiteStatement.BindType(0, SQLitePreparedStatement.SQLITE_TEXT)
		    APIRequest.SQLiteStatement.Bind(0, APIRequest.RequestPathComponents(2))
		  #endif
		  Response = APIRequest.SQLSELECTProcess
		  
		  
		  // If the attempt to get the record has failed...
		  If Response.Value("ResponseStatus") <> 200 Then
		    // Abort the request.
		    Return Response
		  End If
		  
		  
		  // Convert the response body from text to JSON.
		  Var LocalBody As String = Response.Value("ResponseBody")
		  Dim LocalCurrentRecord As New JSONItem(LocalBody)
		  
		  
		  // An array of records is returned, so grab the first one.
		  LocalCurrentRecord = LocalCurrentRecord(0)
		  
		  
		  // For any value that could have been provided, but wasn't, use the current value...
		  If not APIRequest.RequestJSON.HasName("City") Then
		    APIRequest.RequestJSON.Value("City") = LocalCurrentRecord.Value(GetFieldName("City"))
		  End If
		  If not APIRequest.RequestJSON.HasName("Company") Then
		    APIRequest.RequestJSON.Value("Company") = LocalCurrentRecord.Value(GetFieldName("Company"))
		  End If
		  If not APIRequest.RequestJSON.HasName("Domain") Then
		    APIRequest.RequestJSON.Value("Domain") = LocalCurrentRecord.Value(GetFieldName("Domain"))
		  End If
		  If not APIRequest.RequestJSON.HasName("EmailAddress") Then
		    APIRequest.RequestJSON.Value("EmailAddress") = LocalCurrentRecord.Value(GetFieldName("EmailAddress"))
		  End If
		  If not APIRequest.RequestJSON.HasName("GivenName") Then
		    APIRequest.RequestJSON.Value("GivenName") = LocalCurrentRecord.Value(GetFieldName("GivenName"))
		  End If
		  If not APIRequest.RequestJSON.HasName("Occupation") Then
		    APIRequest.RequestJSON.Value("Occupation") = LocalCurrentRecord.Value(GetFieldName("Occupation"))
		  End If
		  If not APIRequest.RequestJSON.HasName("State") Then
		    APIRequest.RequestJSON.Value("State") = LocalCurrentRecord.Value(GetFieldName("State"))
		  End If
		  If not APIRequest.RequestJSON.HasName("StreetAddress") Then
		    APIRequest.RequestJSON.Value("StreetAddress") = LocalCurrentRecord.Value(GetFieldName("StreetAddress"))
		  End If
		  If not APIRequest.RequestJSON.HasName("Surname") Then
		    APIRequest.RequestJSON.Value("Surname") = LocalCurrentRecord.Value(GetFieldName("Surname"))
		  End If
		  If not APIRequest.RequestJSON.HasName("TelephoneNumber") Then
		    APIRequest.RequestJSON.Value("TelephoneNumber") = LocalCurrentRecord.Value(GetFieldName("TelephoneNumber"))
		  End If
		  If not APIRequest.RequestJSON.HasName("Title") Then
		    APIRequest.RequestJSON.Value("Title") = LocalCurrentRecord.Value(GetFieldName("Title"))
		  End If
		  If not APIRequest.RequestJSON.HasName("ZipCode") Then
		    APIRequest.RequestJSON.Value("ZipCode") = LocalCurrentRecord.Value(GetFieldName("ZipCode"))
		  End If
		  
		  
		  // Build the UPDATE statement.
		  #if UseMySQL
		    Dim sql As String = "UPDATE Contacts SET " _
		    + "City = ?, " _
		    + "Company = ?, " _
		    + "Domain = ?, " _
		    + "EmailAddress = ?, " _
		    + "GivenName = ?, " _
		    + "Occupation = ?, " _
		    + "State = ?, " _
		    + "StreetAddress = ?, " _
		    + "Surname = ?, " _
		    + "TelephoneNumber = ?, " _
		    + "Title = ?, " _
		    + "ZipCode = ? " _
		    + "WHERE " _
		    + "EmailAddress = ?"
		  #elseif UsePostgreSQL
		    Dim sql As String = "UPDATE contacts SET " _
		    + "city = $1, " _
		    + "company = $2, " _
		    + "domain = $3, " _
		    + "emailaddress = $4, " _
		    + "givenname = $5, " _
		    + "occupation = $6, " _
		    + "state = $7, " _
		    + "streetaddress = $8, " _
		    + "surname = $9, " _
		    + "telephonenumber = $10, " _
		    + "title = $11, " _
		    + "zipcode = $12 " _
		    + "WHERE " _
		    + "emailaddress = $13"
		  #elseif UseSQLite
		    Dim sql As String = "UPDATE Contacts SET " _
		    + "City = ?, " _
		    + "Company = ?, " _
		    + "Domain = ?, " _
		    + "EmailAddress = ?, " _
		    + "GivenName = ?, " _
		    + "Occupation = ?, " _
		    + "State = ?, " _
		    + "StreetAddress = ?, " _
		    + "Surname = ?, " _
		    + "TelephoneNumber = ?, " _
		    + "Title = ?, " _
		    + "ZipCode = ? " _
		    + "WHERE " _
		    + "EmailAddress = ?"
		  #endif
		  
		  
		  // Create the prepared statement.
		  #if UseMySQL
		    APIRequest.SQLStatement = APIRequest.DatabaseConnection.Prepare(sql)
		  #elseif UsePostgreSQL
		    APIRequest.pgSQLStatement = APIRequest.pgDatabaseConnection.Prepare(sql)
		  #elseif UseSQLite
		    APIRequest.SQLiteStatement = APIRequest.db.Prepare(sql)
		  #endif
		  
		  // Specify the binding types.
		  // For additional BindType methods, see:
		  // http://docs.xojo.com/index.php/MySQLPreparedStatement
		  #if UseMySQL
		    APIRequest.SQLStatement.BindType(0, MySQLPreparedStatement.MYSQL_TYPE_STRING)
		    APIRequest.SQLStatement.BindType(1, MySQLPreparedStatement.MYSQL_TYPE_STRING)
		    APIRequest.SQLStatement.BindType(2, MySQLPreparedStatement.MYSQL_TYPE_STRING)
		    APIRequest.SQLStatement.BindType(3, MySQLPreparedStatement.MYSQL_TYPE_STRING)
		    APIRequest.SQLStatement.BindType(4, MySQLPreparedStatement.MYSQL_TYPE_STRING)
		    APIRequest.SQLStatement.BindType(5, MySQLPreparedStatement.MYSQL_TYPE_STRING)
		    APIRequest.SQLStatement.BindType(6, MySQLPreparedStatement.MYSQL_TYPE_STRING)
		    APIRequest.SQLStatement.BindType(7, MySQLPreparedStatement.MYSQL_TYPE_STRING)
		    APIRequest.SQLStatement.BindType(8, MySQLPreparedStatement.MYSQL_TYPE_STRING)
		    APIRequest.SQLStatement.BindType(9, MySQLPreparedStatement.MYSQL_TYPE_STRING)
		    APIRequest.SQLStatement.BindType(10, MySQLPreparedStatement.MYSQL_TYPE_STRING)
		    APIRequest.SQLStatement.BindType(11, MySQLPreparedStatement.MYSQL_TYPE_STRING)
		    APIRequest.SQLStatement.BindType(12, MySQLPreparedStatement.MYSQL_TYPE_STRING)
		  #elseif UseSQLite
		    APIRequest.SQLiteStatement.BindType(0, SQLitePreparedStatement.SQLITE_TEXT)
		    APIRequest.SQLiteStatement.BindType(1, SQLitePreparedStatement.SQLITE_TEXT)
		    APIRequest.SQLiteStatement.BindType(2, SQLitePreparedStatement.SQLITE_TEXT)
		    APIRequest.SQLiteStatement.BindType(3, SQLitePreparedStatement.SQLITE_TEXT)
		    APIRequest.SQLiteStatement.BindType(4, SQLitePreparedStatement.SQLITE_TEXT)
		    APIRequest.SQLiteStatement.BindType(5, SQLitePreparedStatement.SQLITE_TEXT)
		    APIRequest.SQLiteStatement.BindType(6, SQLitePreparedStatement.SQLITE_TEXT)
		    APIRequest.SQLiteStatement.BindType(7, SQLitePreparedStatement.SQLITE_TEXT)
		    APIRequest.SQLiteStatement.BindType(8, SQLitePreparedStatement.SQLITE_TEXT)
		    APIRequest.SQLiteStatement.BindType(9, SQLitePreparedStatement.SQLITE_TEXT)
		    APIRequest.SQLiteStatement.BindType(10, SQLitePreparedStatement.SQLITE_TEXT)
		    APIRequest.SQLiteStatement.BindType(11, SQLitePreparedStatement.SQLITE_TEXT)
		    APIRequest.SQLiteStatement.BindType(12, SQLitePreparedStatement.SQLITE_TEXT)
		  #endif
		  
		  
		  // Bind the values.
		  #if UseMySQL
		    APIRequest.SQLStatement.Bind(0, APIRequest.RequestJSON.Value("City"))
		    APIRequest.SQLStatement.Bind(1, APIRequest.RequestJSON.Value("Company"))
		    APIRequest.SQLStatement.Bind(2, APIRequest.RequestJSON.Value("Domain"))
		    APIRequest.SQLStatement.Bind(3, APIRequest.RequestJSON.Value("EmailAddress"))
		    APIRequest.SQLStatement.Bind(4, APIRequest.RequestJSON.Value("GivenName"))
		    APIRequest.SQLStatement.Bind(5, APIRequest.RequestJSON.Value("Occupation"))
		    APIRequest.SQLStatement.Bind(6, APIRequest.RequestJSON.Value("State"))
		    APIRequest.SQLStatement.Bind(7, APIRequest.RequestJSON.Value("StreetAddress"))
		    APIRequest.SQLStatement.Bind(8, APIRequest.RequestJSON.Value("Surname"))
		    APIRequest.SQLStatement.Bind(9, APIRequest.RequestJSON.Value("TelephoneNumber"))
		    APIRequest.SQLStatement.Bind(10, APIRequest.RequestJSON.Value("Title"))
		    APIRequest.SQLStatement.Bind(11, APIRequest.RequestJSON.Value("ZipCode"))
		    APIRequest.SQLStatement.Bind(12, APIRequest.RequestPathComponents(2))
		  #elseif UsePostgreSQL
		    APIRequest.pgSQLStatement.Bind(0, APIRequest.RequestJSON.Value("City"))
		    APIRequest.pgSQLStatement.Bind(1, APIRequest.RequestJSON.Value("Company"))
		    APIRequest.pgSQLStatement.Bind(2, APIRequest.RequestJSON.Value("Domain"))
		    APIRequest.pgSQLStatement.Bind(3, APIRequest.RequestJSON.Value("EmailAddress"))
		    APIRequest.pgSQLStatement.Bind(4, APIRequest.RequestJSON.Value("GivenName"))
		    APIRequest.pgSQLStatement.Bind(5, APIRequest.RequestJSON.Value("Occupation"))
		    APIRequest.pgSQLStatement.Bind(6, APIRequest.RequestJSON.Value("State"))
		    APIRequest.pgSQLStatement.Bind(7, APIRequest.RequestJSON.Value("StreetAddress"))
		    APIRequest.pgSQLStatement.Bind(8, APIRequest.RequestJSON.Value("Surname"))
		    APIRequest.pgSQLStatement.Bind(9, APIRequest.RequestJSON.Value("TelephoneNumber"))
		    APIRequest.pgSQLStatement.Bind(10, APIRequest.RequestJSON.Value("Title"))
		    APIRequest.pgSQLStatement.Bind(11, APIRequest.RequestJSON.Value("ZipCode"))
		    APIRequest.pgSQLStatement.Bind(12, APIRequest.RequestPathComponents(2))
		  #elseif UseSQLite
		    APIRequest.SQLiteStatement.Bind(0, APIRequest.RequestJSON.Value("City"))
		    APIRequest.SQLiteStatement.Bind(1, APIRequest.RequestJSON.Value("Company"))
		    APIRequest.SQLiteStatement.Bind(2, APIRequest.RequestJSON.Value("Domain"))
		    APIRequest.SQLiteStatement.Bind(3, APIRequest.RequestJSON.Value("EmailAddress"))
		    APIRequest.SQLiteStatement.Bind(4, APIRequest.RequestJSON.Value("GivenName"))
		    APIRequest.SQLiteStatement.Bind(5, APIRequest.RequestJSON.Value("Occupation"))
		    APIRequest.SQLiteStatement.Bind(6, APIRequest.RequestJSON.Value("State"))
		    APIRequest.SQLiteStatement.Bind(7, APIRequest.RequestJSON.Value("StreetAddress"))
		    APIRequest.SQLiteStatement.Bind(8, APIRequest.RequestJSON.Value("Surname"))
		    APIRequest.SQLiteStatement.Bind(9, APIRequest.RequestJSON.Value("TelephoneNumber"))
		    APIRequest.SQLiteStatement.Bind(10, APIRequest.RequestJSON.Value("Title"))
		    APIRequest.SQLiteStatement.Bind(11, APIRequest.RequestJSON.Value("ZipCode"))
		    APIRequest.SQLiteStatement.Bind(12, APIRequest.RequestPathComponents(2))
		  #endif
		  
		  
		  // Execute the statement.
		  #if UseMySQL
		    APIRequest.SQLStatement.SQLExecute
		  #elseif UseMySQL
		    APIRequest.pgSQLStatement.SQLExecute
		  #elseif UseSQLite
		    APIRequest.SQLiteStatement.SQLExecute
		  #endif
		  
		  // If an error was thrown...
		  Dim bError As Boolean=False
		  #if UseMySQL
		    bError=APIRequest.DatabaseConnection.Error
		  #elseif UsePostgreSQL
		    bError=APIRequest.pgDatabaseConnection.Error
		  #elseif UseSQLite
		    bError=APIRequest.db.Error
		  #endif
		  If bError Then
		    Response.Value("ResponseStatus") = 500
		    #if UseMySQL
		      Response.Value("ResponseBody") = APIRequest.ErrorResponseCreate ( "500", "SQL UPDATE Failure", "Database error code: " + APIRequest.DatabaseConnection.ErrorCode.ToText) 
		    #elseif UsePostgreSQL
		      Response.Value("ResponseBody") = APIRequest.ErrorResponseCreate ( "500", "SQL UPDATE Failure", "Database error code: " + APIRequest.pgDatabaseConnection.ErrorCode.ToText) 
		    #elseif UseSQLite
		      Response.Value("ResponseBody") = APIRequest.ErrorResponseCreate ( "500", "SQL UPDATE Failure", "Database error code: " + APIRequest.db.ErrorCode.ToText) 
		    #endif
		    Return Response
		  End If
		  
		  
		  // Prepare the SQL and prepared statement to get the record that was just udpated.
		  #if UseMySQL
		    sql = "SELECT * FROM Contacts WHERE EmailAddress = ?"
		    APIRequest.SQLStatement = APIRequest.DatabaseConnection.Prepare(sql)
		    APIRequest.SQLStatement.BindType(0, MySQLPreparedStatement.MYSQL_TYPE_STRING)
		    APIRequest.SQLStatement.Bind(0, APIRequest.RequestJSON.Value("EmailAddress"))
		  #elseif UsePostgreSQL
		    sql = "SELECT * FROM contacts WHERE emailaddress = $1"
		    APIRequest.pgSQLStatement = APIRequest.pgDatabaseConnection.Prepare(sql)
		    APIRequest.pgSQLStatement.Bind(0, APIRequest.RequestJSON.Value("EmailAddress"))
		  #elseif UseSQLite
		    sql = "SELECT * FROM Contacts WHERE EmailAddress = ?"
		    APIRequest.SQLiteStatement = APIRequest.db.Prepare(sql)
		    APIRequest.SQLiteStatement.BindType(0, SQLitePreparedStatement.SQLITE_TEXT)
		    APIRequest.SQLiteStatement.Bind(0, APIRequest.RequestJSON.Value("EmailAddress"))
		  #endif
		  
		  
		  // Return the updated record.
		  Return APIRequest.SQLSELECTProcess
		  
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function V1_Contacts_Post(APIRequest As Luna) As Dictionary
		  Dim Response As New Dictionary
		  
		  
		  // Check to see that all of the expected values have been provided.
		  If not APIRequest.RequestJSON.HasName("EmailAddress") Then
		    Response.Value("ResponseStatus") = 400
		    Response.Value("ResponseBody") = APIRequest.ErrorResponseCreate ( "400", "Required column is missing", "EmailAddress is missing from the request body.")
		    Return Response
		  End If
		  
		  
		  // Build the INSERT statement.
		  #if UseMySQL
		    Dim sql As String = "INSERT INTO Contacts " _
		    + "( City, Company, Domain, EmailAddress, GivenName, Occupation, State, StreetAddress, Surname, TelephoneNumber, Title, ZipCode) " _
		    + "VALUES ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ? )"
		  #elseif UsePostgreSQL
		    Dim sql As String = "INSERT INTO contacts " _
		    + "( city, company, domain, emailaddress, givenname, occupation, state, streetaddress, surname, telephonenumber, title, zipcode) " _
		    + "VALUES ( $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12 )"
		  #elseif UseSQLite
		    Dim sql As String = "INSERT INTO Contacts " _
		    + "( City, Company, Domain, EmailAddress, GivenName, Occupation, State, StreetAddress, Surname, TelephoneNumber, Title, ZipCode) " _
		    + "VALUES ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ? )"
		  #endif
		  
		  // Create the prepared statement.
		  #if UseMySQL
		    APIRequest.SQLStatement = APIRequest.DatabaseConnection.Prepare(sql)
		  #elseif UsePostgreSQL
		    APIRequest.pgSQLStatement = APIRequest.pgDatabaseConnection.Prepare(sql)
		  #elseif UseSQLite
		    APIRequest.SQLiteStatement = APIRequest.db.Prepare(sql)
		  #endif
		  
		  // Specify the binding types.
		  // For additional BindType methods, see:
		  // http://docs.xojo.com/index.php/MySQLPreparedStatement
		  #if UseMySQL
		    APIRequest.SQLStatement.BindType(0, MySQLPreparedStatement.MYSQL_TYPE_STRING)
		    APIRequest.SQLStatement.BindType(1, MySQLPreparedStatement.MYSQL_TYPE_STRING)
		    APIRequest.SQLStatement.BindType(2, MySQLPreparedStatement.MYSQL_TYPE_STRING)
		    APIRequest.SQLStatement.BindType(3, MySQLPreparedStatement.MYSQL_TYPE_STRING)
		    APIRequest.SQLStatement.BindType(4, MySQLPreparedStatement.MYSQL_TYPE_STRING)
		    APIRequest.SQLStatement.BindType(5, MySQLPreparedStatement.MYSQL_TYPE_STRING)
		    APIRequest.SQLStatement.BindType(6, MySQLPreparedStatement.MYSQL_TYPE_STRING)
		    APIRequest.SQLStatement.BindType(7, MySQLPreparedStatement.MYSQL_TYPE_STRING)
		    APIRequest.SQLStatement.BindType(8, MySQLPreparedStatement.MYSQL_TYPE_STRING)
		    APIRequest.SQLStatement.BindType(9, MySQLPreparedStatement.MYSQL_TYPE_STRING)
		    APIRequest.SQLStatement.BindType(10, MySQLPreparedStatement.MYSQL_TYPE_STRING)
		    APIRequest.SQLStatement.BindType(11, MySQLPreparedStatement.MYSQL_TYPE_STRING)
		  #elseif UseSQLite
		    APIRequest.SQLiteStatement.BindType(0, SQLitePreparedStatement.SQLITE_TEXT)
		    APIRequest.SQLiteStatement.BindType(1, SQLitePreparedStatement.SQLITE_TEXT)
		    APIRequest.SQLiteStatement.BindType(2, SQLitePreparedStatement.SQLITE_TEXT)
		    APIRequest.SQLiteStatement.BindType(3, SQLitePreparedStatement.SQLITE_TEXT)
		    APIRequest.SQLiteStatement.BindType(4, SQLitePreparedStatement.SQLITE_TEXT)
		    APIRequest.SQLiteStatement.BindType(5, SQLitePreparedStatement.SQLITE_TEXT)
		    APIRequest.SQLiteStatement.BindType(6, SQLitePreparedStatement.SQLITE_TEXT)
		    APIRequest.SQLiteStatement.BindType(7, SQLitePreparedStatement.SQLITE_TEXT)
		    APIRequest.SQLiteStatement.BindType(8, SQLitePreparedStatement.SQLITE_TEXT)
		    APIRequest.SQLiteStatement.BindType(9, SQLitePreparedStatement.SQLITE_TEXT)
		    APIRequest.SQLiteStatement.BindType(10, SQLitePreparedStatement.SQLITE_TEXT)
		    APIRequest.SQLiteStatement.BindType(11, SQLitePreparedStatement.SQLITE_TEXT)
		  #endif
		  
		  
		  // Bind the values.
		  #if UseMySQL
		    APIRequest.SQLStatement.Bind(0, APIRequest.RequestJSON.Value("City"))
		    APIRequest.SQLStatement.Bind(1, APIRequest.RequestJSON.Value("Company"))
		    APIRequest.SQLStatement.Bind(2, APIRequest.RequestJSON.Value("Domain"))
		    APIRequest.SQLStatement.Bind(3, APIRequest.RequestJSON.Value("EmailAddress"))
		    APIRequest.SQLStatement.Bind(4, APIRequest.RequestJSON.Value("GivenName"))
		    APIRequest.SQLStatement.Bind(5, APIRequest.RequestJSON.Value("Occupation"))
		    APIRequest.SQLStatement.Bind(6, APIRequest.RequestJSON.Value("State"))
		    APIRequest.SQLStatement.Bind(7, APIRequest.RequestJSON.Value("StreetAddress"))
		    APIRequest.SQLStatement.Bind(8, APIRequest.RequestJSON.Value("Surname"))
		    APIRequest.SQLStatement.Bind(9, APIRequest.RequestJSON.Value("TelephoneNumber"))
		    APIRequest.SQLStatement.Bind(10, APIRequest.RequestJSON.Value("Title"))
		    APIRequest.SQLStatement.Bind(11, APIRequest.RequestJSON.Value("ZipCode"))
		  #elseif UsePostgreSQL
		    APIRequest.pgSQLStatement.Bind(0, APIRequest.RequestJSON.Value("City"))
		    APIRequest.pgSQLStatement.Bind(1, APIRequest.RequestJSON.Value("Company"))
		    APIRequest.pgSQLStatement.Bind(2, APIRequest.RequestJSON.Value("Domain"))
		    APIRequest.pgSQLStatement.Bind(3, APIRequest.RequestJSON.Value("EmailAddress"))
		    APIRequest.pgSQLStatement.Bind(4, APIRequest.RequestJSON.Value("GivenName"))
		    APIRequest.pgSQLStatement.Bind(5, APIRequest.RequestJSON.Value("Occupation"))
		    APIRequest.pgSQLStatement.Bind(6, APIRequest.RequestJSON.Value("State"))
		    APIRequest.pgSQLStatement.Bind(7, APIRequest.RequestJSON.Value("StreetAddress"))
		    APIRequest.pgSQLStatement.Bind(8, APIRequest.RequestJSON.Value("Surname"))
		    APIRequest.pgSQLStatement.Bind(9, APIRequest.RequestJSON.Value("TelephoneNumber"))
		    APIRequest.pgSQLStatement.Bind(10, APIRequest.RequestJSON.Value("Title"))
		    APIRequest.pgSQLStatement.Bind(11, APIRequest.RequestJSON.Value("ZipCode"))
		  #elseif UseSQLite
		    APIRequest.SQLiteStatement.Bind(0, APIRequest.RequestJSON.Value("City"))
		    APIRequest.SQLiteStatement.Bind(1, APIRequest.RequestJSON.Value("Company"))
		    APIRequest.SQLiteStatement.Bind(2, APIRequest.RequestJSON.Value("Domain"))
		    APIRequest.SQLiteStatement.Bind(3, APIRequest.RequestJSON.Value("EmailAddress"))
		    APIRequest.SQLiteStatement.Bind(4, APIRequest.RequestJSON.Value("GivenName"))
		    APIRequest.SQLiteStatement.Bind(5, APIRequest.RequestJSON.Value("Occupation"))
		    APIRequest.SQLiteStatement.Bind(6, APIRequest.RequestJSON.Value("State"))
		    APIRequest.SQLiteStatement.Bind(7, APIRequest.RequestJSON.Value("StreetAddress"))
		    APIRequest.SQLiteStatement.Bind(8, APIRequest.RequestJSON.Value("Surname"))
		    APIRequest.SQLiteStatement.Bind(9, APIRequest.RequestJSON.Value("TelephoneNumber"))
		    APIRequest.SQLiteStatement.Bind(10, APIRequest.RequestJSON.Value("Title"))
		    APIRequest.SQLiteStatement.Bind(11, APIRequest.RequestJSON.Value("ZipCode"))
		  #endif
		  
		  // Execute the statement.
		  #if UseMySQL
		    APIRequest.SQLStatement.SQLExecute
		  #elseif UsePostgreSQL
		    APIRequest.pgSQLStatement.SQLExecute
		  #elseif UseSQLite
		    APIRequest.SQLiteStatement.SQLExecute
		  #endif
		  
		  
		  // If an error was thrown...
		  Dim bError As Boolean=False
		  #if UseMySQL
		    bError=APIRequest.DatabaseConnection.Error
		  #elseif UsePostgreSQL
		    bError=APIRequest.pgDatabaseConnection.Error
		  #elseif UseSQLite
		    bError=APIRequest.db.Error
		  #endif
		  If bError Then
		    Response.Value("ResponseStatus") = 500
		    #if UseMySQL
		      Response.Value("ResponseBody") = APIRequest.ErrorResponseCreate ( "500", "SQL INSERT Failure", "Database error code: " + APIRequest.DatabaseConnection.ErrorCode.ToText) 
		    #elseif UsePostgreSQL
		      Response.Value("ResponseBody") = APIRequest.ErrorResponseCreate ( "500", "SQL INSERT Failure", "Database error code: " + APIRequest.pgDatabaseConnection.ErrorCode.ToText) 
		    #elseif UseSQLite
		      Response.Value("ResponseBody") = APIRequest.ErrorResponseCreate ( "500", "SQL INSERT Failure", "Database error code: " + APIRequest.db.ErrorCode.ToText) 
		    #endif
		    Return Response
		  End If
		  
		  
		  // Prepare the SQL and prepared statement to get the record that was just added.
		  #if UseMySQL
		    sql = "SELECT * FROM Contacts WHERE EmailAddress = ?"
		    APIRequest.SQLStatement = APIRequest.DatabaseConnection.Prepare(sql)
		    APIRequest.SQLStatement.BindType(0, MySQLPreparedStatement.MYSQL_TYPE_STRING)
		    APIRequest.SQLStatement.Bind(0, APIRequest.RequestJSON.Value("EmailAddress"))
		  #elseif UsePostgreSQL
		    sql = "SELECT * FROM contacts WHERE emailaddress = $1"
		    APIRequest.pgSQLStatement = APIRequest.pgDatabaseConnection.Prepare(sql)
		    APIRequest.pgSQLStatement.Bind(0, APIRequest.RequestJSON.Value("EmailAddress"))
		  #elseif UseSQLite
		    sql = "SELECT * FROM Contacts WHERE EmailAddress = ?"
		    APIRequest.SQLiteStatement = APIRequest.db.Prepare(sql)
		    APIRequest.SQLiteStatement.BindType(0, SQLitePreparedStatement.SQLITE_TEXT)
		    APIRequest.SQLiteStatement.Bind(0, APIRequest.RequestJSON.Value("EmailAddress"))
		  #endif
		  
		  // Get the newly added record.
		  Response = APIRequest.SQLSELECTProcess
		  
		  
		  // Update the status to 201 Created.
		  Response.Value("ResponseStatus") = 201
		  
		  
		  Return Response
		  
		  
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function V1_Contacts_Put(APIRequest As Luna) As Dictionary
		  Dim Response As New Dictionary
		  Dim sql As String
		  
		  // Check to see that all of the expected values have been provided.
		  If not APIRequest.RequestJSON.HasName("EmailAddress") Then
		    Response.Value("ResponseStatus") = 400
		    Response.Value("ResponseBody") = APIRequest.ErrorResponseCreate ( "400", "Required column is missing", "EmailAddress is missing from the request body.")
		    Return Response
		  End If
		  
		  
		  // Get the record to be updated.
		  #if UseMySQL
		    APIRequest.SQLStatement = APIRequest.DatabaseConnection.Prepare("SELECT * FROM Contacts WHERE EmailAddress = ?")
		    APIRequest.SQLStatement.BindType(0, MySQLPreparedStatement.MYSQL_TYPE_STRING)
		    APIRequest.SQLStatement.Bind(0, APIRequest.RequestPathComponents(2))
		  #elseif UsePostgreSQL
		    APIRequest.pgSQLStatement = APIRequest.pgDatabaseConnection.Prepare("SELECT * FROM contacts WHERE emailaddress = $1")
		    APIRequest.pgSQLStatement.Bind(0, APIRequest.RequestPathComponents(2))
		  #elseif UseSQLite
		    APIRequest.SQLiteStatement = APIRequest.db.Prepare("SELECT * FROM Contacts WHERE EmailAddress = ?")
		    APIRequest.SQLiteStatement.BindType(0,SQLitePreparedStatement.SQLITE_TEXT)
		    APIRequest.SQLiteStatement.Bind(0, APIRequest.RequestPathComponents(2))
		  #endif
		  Response = APIRequest.SQLSELECTProcess
		  
		  // If the attempt to get the record has failed...
		  If Response.Value("ResponseStatus") <> 200 Then
		    // Abort the request.
		    Return Response
		  End If
		  
		  
		  // Build the UPDATE statement.
		  #if UseMySQL
		    sql = "UPDATE Contacts SET " _
		    + "City = ?, " _
		    + "Company = ?, " _
		    + "Domain = ?, " _
		    + "EmailAddress = ?, " _
		    + "GivenName = ?, " _
		    + "Occupation = ?, " _
		    + "State = ?, " _
		    + "StreetAddress = ?, " _
		    + "Surname = ?, " _
		    + "TelephoneNumber = ?, " _
		    + "Title = ?, " _
		    + "ZipCode = ? " _
		    + "WHERE " _
		    + "EmailAddress = ?"
		  #elseif UsePostgreSQL
		    sql = "UPDATE contacts SET " _
		    + "city = $1, " _
		    + "company = $2, " _
		    + "domain = $3, " _
		    + "emailaddress = $4, " _
		    + "givenname = $5, " _
		    + "occupation = $6, " _
		    + "state = $7, " _
		    + "streetaddress = $8, " _
		    + "surname = $9, " _
		    + "telephonenumber = $10, " _
		    + "title = $11, " _
		    + "zipcode = $12 " _
		    + "WHERE " _
		    + "emailaddress = $13"
		  #elseif UseSQLite
		    sql = "UPDATE Contacts SET " _
		    + "City = ?, " _
		    + "Company = ?, " _
		    + "Domain = ?, " _
		    + "EmailAddress = ?, " _
		    + "GivenName = ?, " _
		    + "Occupation = ?, " _
		    + "State = ?, " _
		    + "StreetAddress = ?, " _
		    + "Surname = ?, " _
		    + "TelephoneNumber = ?, " _
		    + "Title = ?, " _
		    + "ZipCode = ? " _
		    + "WHERE " _
		    + "EmailAddress = ?"
		  #endif
		  
		  // Create the prepared statement.
		  #if UseMySQL
		    APIRequest.SQLStatement = APIRequest.DatabaseConnection.Prepare(sql)
		  #elseif UsePostgreSQL
		    APIRequest.pgSQLStatement = APIRequest.pgDatabaseConnection.Prepare(sql)
		  #elseif UseSQLite
		    APIRequest.SQLiteStatement = APIRequest.db.Prepare(sql)
		  #endif
		  
		  // Specify the binding types.
		  // For additional BindType methods, see:
		  // http://docs.xojo.com/index.php/MySQLPreparedStatement
		  #if UseMySQL
		    APIRequest.SQLStatement.BindType(0, MySQLPreparedStatement.MYSQL_TYPE_STRING)
		    APIRequest.SQLStatement.BindType(1, MySQLPreparedStatement.MYSQL_TYPE_STRING)
		    APIRequest.SQLStatement.BindType(2, MySQLPreparedStatement.MYSQL_TYPE_STRING)
		    APIRequest.SQLStatement.BindType(3, MySQLPreparedStatement.MYSQL_TYPE_STRING)
		    APIRequest.SQLStatement.BindType(4, MySQLPreparedStatement.MYSQL_TYPE_STRING)
		    APIRequest.SQLStatement.BindType(5, MySQLPreparedStatement.MYSQL_TYPE_STRING)
		    APIRequest.SQLStatement.BindType(6, MySQLPreparedStatement.MYSQL_TYPE_STRING)
		    APIRequest.SQLStatement.BindType(7, MySQLPreparedStatement.MYSQL_TYPE_STRING)
		    APIRequest.SQLStatement.BindType(8, MySQLPreparedStatement.MYSQL_TYPE_STRING)
		    APIRequest.SQLStatement.BindType(9, MySQLPreparedStatement.MYSQL_TYPE_STRING)
		    APIRequest.SQLStatement.BindType(10, MySQLPreparedStatement.MYSQL_TYPE_STRING)
		    APIRequest.SQLStatement.BindType(11, MySQLPreparedStatement.MYSQL_TYPE_STRING)
		    APIRequest.SQLStatement.BindType(12, MySQLPreparedStatement.MYSQL_TYPE_STRING)
		  #elseif UseSQLite
		    APIRequest.SQLiteStatement.BindType(0, SQLitePreparedStatement.SQLITE_TEXT)
		    APIRequest.SQLiteStatement.BindType(1, SQLitePreparedStatement.SQLITE_TEXT)
		    APIRequest.SQLiteStatement.BindType(2, SQLitePreparedStatement.SQLITE_TEXT)
		    APIRequest.SQLiteStatement.BindType(3, SQLitePreparedStatement.SQLITE_TEXT)
		    APIRequest.SQLiteStatement.BindType(4, SQLitePreparedStatement.SQLITE_TEXT)
		    APIRequest.SQLiteStatement.BindType(5, SQLitePreparedStatement.SQLITE_TEXT)
		    APIRequest.SQLiteStatement.BindType(6, SQLitePreparedStatement.SQLITE_TEXT)
		    APIRequest.SQLiteStatement.BindType(7, SQLitePreparedStatement.SQLITE_TEXT)
		    APIRequest.SQLiteStatement.BindType(8, SQLitePreparedStatement.SQLITE_TEXT)
		    APIRequest.SQLiteStatement.BindType(9, SQLitePreparedStatement.SQLITE_TEXT)
		    APIRequest.SQLiteStatement.BindType(10, SQLitePreparedStatement.SQLITE_TEXT)
		    APIRequest.SQLiteStatement.BindType(11, SQLitePreparedStatement.SQLITE_TEXT)
		    APIRequest.SQLiteStatement.BindType(12, SQLitePreparedStatement.SQLITE_TEXT)
		  #endif
		  
		  // Bind the values.
		  #if UseMySQL
		    APIRequest.SQLStatement.Bind(0, APIRequest.RequestJSON.Value("City"))
		    APIRequest.SQLStatement.Bind(1, APIRequest.RequestJSON.Value("Company"))
		    APIRequest.SQLStatement.Bind(2, APIRequest.RequestJSON.Value("Domain"))
		    APIRequest.SQLStatement.Bind(3, APIRequest.RequestJSON.Value("EmailAddress"))
		    APIRequest.SQLStatement.Bind(4, APIRequest.RequestJSON.Value("GivenName"))
		    APIRequest.SQLStatement.Bind(5, APIRequest.RequestJSON.Value("Occupation"))
		    APIRequest.SQLStatement.Bind(6, APIRequest.RequestJSON.Value("State"))
		    APIRequest.SQLStatement.Bind(7, APIRequest.RequestJSON.Value("StreetAddress"))
		    APIRequest.SQLStatement.Bind(8, APIRequest.RequestJSON.Value("Surname"))
		    APIRequest.SQLStatement.Bind(9, APIRequest.RequestJSON.Value("TelephoneNumber"))
		    APIRequest.SQLStatement.Bind(10, APIRequest.RequestJSON.Value("Title"))
		    APIRequest.SQLStatement.Bind(11, APIRequest.RequestJSON.Value("ZipCode"))
		    APIRequest.SQLStatement.Bind(12, APIRequest.RequestPathComponents(2))
		  #elseif UsePostgreSQL
		    APIRequest.pgSQLStatement.Bind(0, APIRequest.RequestJSON.Value("City"))
		    APIRequest.pgSQLStatement.Bind(1, APIRequest.RequestJSON.Value("Company"))
		    APIRequest.pgSQLStatement.Bind(2, APIRequest.RequestJSON.Value("Domain"))
		    APIRequest.pgSQLStatement.Bind(3, APIRequest.RequestJSON.Value("EmailAddress"))
		    APIRequest.pgSQLStatement.Bind(4, APIRequest.RequestJSON.Value("GivenName"))
		    APIRequest.pgSQLStatement.Bind(5, APIRequest.RequestJSON.Value("Occupation"))
		    APIRequest.pgSQLStatement.Bind(6, APIRequest.RequestJSON.Value("State"))
		    APIRequest.pgSQLStatement.Bind(7, APIRequest.RequestJSON.Value("StreetAddress"))
		    APIRequest.pgSQLStatement.Bind(8, APIRequest.RequestJSON.Value("Surname"))
		    APIRequest.pgSQLStatement.Bind(9, APIRequest.RequestJSON.Value("TelephoneNumber"))
		    APIRequest.pgSQLStatement.Bind(10, APIRequest.RequestJSON.Value("Title"))
		    APIRequest.pgSQLStatement.Bind(11, APIRequest.RequestJSON.Value("ZipCode"))
		    APIRequest.pgSQLStatement.Bind(12, APIRequest.RequestPathComponents(2))
		  #elseif UseSQLite
		    APIRequest.SQLiteStatement.Bind(0, APIRequest.RequestJSON.Value("City"))
		    APIRequest.SQLiteStatement.Bind(1, APIRequest.RequestJSON.Value("Company"))
		    APIRequest.SQLiteStatement.Bind(2, APIRequest.RequestJSON.Value("Domain"))
		    APIRequest.SQLiteStatement.Bind(3, APIRequest.RequestJSON.Value("EmailAddress"))
		    APIRequest.SQLiteStatement.Bind(4, APIRequest.RequestJSON.Value("GivenName"))
		    APIRequest.SQLiteStatement.Bind(5, APIRequest.RequestJSON.Value("Occupation"))
		    APIRequest.SQLiteStatement.Bind(6, APIRequest.RequestJSON.Value("State"))
		    APIRequest.SQLiteStatement.Bind(7, APIRequest.RequestJSON.Value("StreetAddress"))
		    APIRequest.SQLiteStatement.Bind(8, APIRequest.RequestJSON.Value("Surname"))
		    APIRequest.SQLiteStatement.Bind(9, APIRequest.RequestJSON.Value("TelephoneNumber"))
		    APIRequest.SQLiteStatement.Bind(10, APIRequest.RequestJSON.Value("Title"))
		    APIRequest.SQLiteStatement.Bind(11, APIRequest.RequestJSON.Value("ZipCode"))
		    APIRequest.SQLiteStatement.Bind(12, APIRequest.RequestPathComponents(2))
		  #endif
		  
		  // Execute the statement.
		  #if UseMySQL
		    APIRequest.SQLStatement.SQLExecute
		  #elseif UsePostgreSQL
		    APIRequest.pgSQLStatement.SQLExecute
		  #elseif UseSQLite
		    APIRequest.SQLiteStatement.SQLExecute
		  #endif
		  
		  
		  // If an error was thrown...
		  Dim bError As Boolean=False
		  #if UseMySQL
		    bError=APIRequest.DatabaseConnection.Error
		  #elseif UsePostgreSQL
		    bError=APIRequest.pgDatabaseConnection.Error
		  #elseif UseSQLite
		    bError=APIRequest.db.Error
		  #endif
		  If bError Then
		    Response.Value("ResponseStatus") = 500
		    #if UseMySQL
		      Response.Value("ResponseBody") = APIRequest.ErrorResponseCreate ( "500", "SQL UPDATE Failure", "Database error code: " + APIRequest.DatabaseConnection.ErrorCode.ToText) 
		    #elseif UsePostgreSQL
		      Response.Value("ResponseBody") = APIRequest.ErrorResponseCreate ( "500", "SQL UPDATE Failure", "Database error code: " + APIRequest.pgDatabaseConnection.ErrorCode.ToText) 
		    #elseif UseSQLite
		      Response.Value("ResponseBody") = APIRequest.ErrorResponseCreate ( "500", "SQL UPDATE Failure", "Database error code: " + APIRequest.db.ErrorCode.ToText) 
		    #endif
		    Return Response
		  End If
		  
		  
		  // Prepare the SQL and prepared statement to get the record that was just udpated.
		  #if UseMySQL
		    sql = "SELECT * FROM Contacts WHERE EmailAddress = ?"
		    APIRequest.SQLStatement = APIRequest.DatabaseConnection.Prepare(sql)
		    APIRequest.SQLStatement.BindType(0, MySQLPreparedStatement.MYSQL_TYPE_STRING)
		    APIRequest.SQLStatement.Bind(0, APIRequest.RequestJSON.Value("EmailAddress"))
		  #elseif UsePostgreSQL
		    sql = "SELECT * FROM contacts WHERE emailaddress = $1"
		    APIRequest.pgSQLStatement = APIRequest.pgDatabaseConnection.Prepare(sql)
		    APIRequest.pgSQLStatement.Bind(0, APIRequest.RequestJSON.Value("EmailAddress"))
		  #elseif UseSQLite
		    sql = "SELECT * FROM Contacts WHERE EmailAddress = ?"
		    APIRequest.SQLiteStatement = APIRequest.db.Prepare(sql)
		    APIRequest.SQLiteStatement.BindType(0, SQLitePreparedStatement.SQLITE_TEXT)
		    APIRequest.SQLiteStatement.Bind(0, APIRequest.RequestJSON.Value("EmailAddress"))
		  #endif
		  
		  // Return the updated record.
		  Return APIRequest.SQLSELECTProcess
		  
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function v1_Reset_Get(APIRequest As Luna) As Dictionary
		  Dim strScript As String
		  Dim sqlFile As FolderItem
		  sqlFile = GetFolderItem("")
		  sqlFile = sqlFile.Child("db")
		  #if UseMySQL
		    sqlFile = sqlFile.Child( "Reset_Contacts_Table_Create_And_Load.sql") 
		  #elseif UsePostgreSQL
		    sqlFile = sqlFile.Child( "Reset_Contacts_Table_Create_And_Load_Postgresql.sql") 
		  #elseif UseSQLite
		    sqlFile = sqlFile.Child( "Reset_Contacts_Table_Create_And_Load_SQLite.sql") 
		  #endif
		  
		  If sqlFile <> Nil Then
		    If sqlFile.Exists Then
		      // Be aware that TextInputStream.Open could raise an exception
		      Dim t As TextInputStream
		      Try
		        t = TextInputStream.Open(sqlFile)
		        t.Encoding = Encodings.UTF8
		        strScript = t.ReadAll
		      Catch e As IOException
		        t.Close
		        strScript=""
		      End Try
		    End If
		  End If
		  
		  // Reset the database.
		  Return APIRequest.SQLResetProcess(strScript,"Contacts")
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function v1_Swagger_Get(APIRequest As Luna) As Dictionary
		  Dim Response As New Dictionary
		  Dim strSwagger As String
		  Dim swFile As FolderItem
		  swFile = GetFolderItem("")
		  swFile = swFile.Child("db")
		  swFile = swFile.Child( "swagger.json") 
		  If swFile <> Nil Then
		    If swFile.Exists Then
		      // Be aware that TextInputStream.Open could raise an exception
		      Dim t As TextInputStream
		      Try
		        t = TextInputStream.Open(swFile)
		        t.Encoding = Encodings.UTF8
		        strSwagger = t.ReadAll
		      Catch e As IOException
		        t.Close
		        strSwagger=""
		      End Try
		    End If
		  End If
		  
		  Response.Value("ResponseStatus") = 200
		  Response.Value("ResponseBody") = strSwagger
		  
		  Return Response
		  
		End Function
	#tag EndMethod


	#tag Property, Flags = &h0
		DatabaseHost As String = "your.database.server.address"
	#tag EndProperty

	#tag Property, Flags = &h0
		DatabaseName As String = "testdb"
	#tag EndProperty

	#tag Property, Flags = &h0
		DatabasePassword As String = "your.database.account.password"
	#tag EndProperty

	#tag Property, Flags = &h0
		DatabaseSchema As String = "your.database.schema"
	#tag EndProperty

	#tag Property, Flags = &h0
		DatabaseUserName As String = "your.database.account.username"
	#tag EndProperty

	#tag Property, Flags = &h0
		SecureConnectionsRequired As Boolean = False
	#tag EndProperty


	#tag ViewBehavior
		#tag ViewProperty
			Name="DatabaseHost"
			Visible=false
			Group="Behavior"
			InitialValue="internal-db.s156317.gridserver.com"
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="DatabaseName"
			Visible=false
			Group="Behavior"
			InitialValue="db156317_prefireplan"
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="DatabasePassword"
			Visible=false
			Group="Behavior"
			InitialValue="2jrFFBWn2c^Qb4o#jDbC^QYnTFnoLYhh6?RRtdbZLBoLNateFe"
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="DatabaseSchema"
			Visible=false
			Group="Behavior"
			InitialValue="your.database.schema"
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="DatabaseUserName"
			Visible=false
			Group="Behavior"
			InitialValue="db156317_prefire"
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="SecureConnectionsRequired"
			Visible=false
			Group="Behavior"
			InitialValue="False"
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
