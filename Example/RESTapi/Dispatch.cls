Class RESTapi.Dispatch Extends %CSP.REST
{

/// Setting Use Session
Parameter UseSession = 1;

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
<!--
<Route Url="/class/:namespace/:classname" Method="GET" Call="GetClass" Cors="true"/>
<Map Prefix="/docserver" Forward="%Api.v1.DocServer"/>
-->
<Route Url="/myapp/person/report" Method="GET" Call="RESTapi.Utils:PersonList" Cors="true" />
<Route Url="/myapp/person/:data" Method="GET" Call="GetPerson" Cors="true" />
<Route Url="/myapp/person/:data" Method="DELETE" Call="DeletePerson" Cors="true"/>
<Route Url="/myapp/person/:data" Method="POST" Call="AddUpdPerson" Cors="true"/>
<Route Url="/myapp/person" Method="POST" Call="AddUpdPerson" Cors="true"/>
</Routes>
}

/// This method Gets called prior to dispatch of the request. Put any common code here
/// that you want to be executed for EVERY request. If pContinue is set to 0, the
/// request will NOT be dispatched according to the UrlMap. If this case it's the
/// responsibility of the user to return a response.
/// 
/// For this dispatch class we will use this to test that any Post method contains
/// JSON and that all requests accept JSON
/// THIS IS SOME CHANGE
ClassMethod OnPreDispatch(pUrl As %String, pMethod As %String, ByRef pContinue As %Boolean) As %Status
{
	set tSC = $$$OK
	set pContinue = 1
	if $zconvert(pMethod,"U") = "POST" {
		if %request.ContentType '= "application/json" {
			set %response.Status = "406" // HTTP not acceptable error
			set RespMsg = %request.ContentType_" is not a supported content type"
			// send back the message in a JSON object
			write "{""ErrorMsg"":"""_RespMsg_"""}"
			set pContinue = 0
		}
	}
	
    Quit tSC
}

ClassMethod GetPerson(PersonID As %String) As %Status
{
	set tSC = $$$OK
	
	try {
		set %response.Status = 200
		set %response.ContentType = "application/json"
		set PersonObj = ##class(RESTexample.Person).%OpenId(PersonID,,.tSC)
		if $System.Status.IsOK(tSC) {
			set PersonJSON = {}
			set PersonJSON.FirstName = PersonObj.FirstName
			set PersonJSON.LastName = PersonObj.LastName
			set PersonJSON.Age = PersonObj.Age
			set PersonJSON.BirthDate = $zdate(PersonObj.BirthDate,3)
			set PersonJSON.Phone = PersonObj.Phone
			
			write PersonJSON.%ToJSON()
		} else {
			// if the error indicates that the record was not found then return 404 "not found"
			// otherwise let the error status generate the response
			if $SYSTEM.Status.GetErrorCodes(tSC) = "5809" {
				set %response.Status = "404"
				set tSC = $$$OK
			}
		}
		
	} Catch Except  {
		set tSC = Except.AsStatus()
	}
	quit tSC
}

ClassMethod DeletePerson(PersonID As %String) As %Status
{
	set tSC = $$$OK
	try {
		set %response.Status = 200
		set %response.ContentType = "application/json"
		set PersonObj = ##class(RESTexample.Person).%OpenId(PersonID,,.tSC)
		if ##class(RESTexample.Person).%ExistsId(PersonID) {
			set tSC = ##class(RESTexample.Person).%DeleteId(PersonID)
		} else {
			set %response.Status = "404"
		}
	} Catch Except  {
		set tSC = Except.AsStatus()
	}
	quit tSC
}

ClassMethod AddUpdPerson(PersonID As %String = "") As %Status
{
	set tSC = $$$OK
	
	try {
		set %response.Status = 200
		set %response.ContentType = "application/json"
		if PersonID '= "" {
			set PersonObj = ##class(RESTexample.Person).%OpenId(PersonID,,.tSC)
		} else {
			set PersonObj = ##class(RESTexample.Person).%New()
			if PersonObj = "" {
				set tSC = $system.Status.Error(5760,"RESTexample.Person")
			}
		}
		if $System.Status.IsOK(tSC) {
			set PersonJSON = {}.%FromJSON(%request.Content)
			set PersonObj.FirstName = PersonJSON.FirstName
			set PersonObj.LastName = PersonJSON.LastName
			set PersonObj.Age = PersonJSON.Age
			set PersonObj.BirthDate = $zdateH(PersonJSON.BirthDate,5)  // Date format 5 allows just about any American date format
			set PersonObj.Phone = PersonJSON.Phone
			set tSC = PersonObj.%Save()
			set SuccessJSON = {"PersonID":(PersonObj.%Id())}
			write:$system.Status.IsOK(tSC) SuccessJSON.%ToJSON() 
		} else {
			if $SYSTEM.Status.GetErrorCodes(tSC) = "5809" {
				set %response.Status = "404"
				set tSC = $$$OK
			}
		}
		
	} Catch Except  {
		set tSC = Except.AsStatus()
	}
	quit tSC
}

}
