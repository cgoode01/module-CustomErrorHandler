<#
.SYNOPSIS
    An Error Handling module to handle common exceptions and errors

.EXAMPLE
    Invoke-ErrorHandler -err $Error

.INPUTS
    $err - Error Object to process/handle

.OUTPUTS
    Varies based on the error received

.NOTES
    Guaranteed to be the best free Error Handler Module or DOUBLE your money back!
    YOU CAN'T LOSE!

.LINK
    https://github.com/cgoode01/module-CustomErrorHandler
#>

<## Alternate method for Error Handler:  Thoughts?
switch ($ErrorDetails.FullyQualifiedErrorId) {
    "ArgumentNullException" { 
        Write-Error -Exception "ArgumentNullException" -ErrorId "ArgumentNullException" -Message "Either the Url or Path is null." -Category InvalidArgument -TargetObject $Downloader -ErrorAction Stop
    }
    "WebException" {
        Write-Error -Exception "WebException" -ErrorId "WebException" -Message "An error occurred while downloading the resource." -Category OperationTimeout -TargetObject $Downloader -ErrorAction Stop
    }
    "InvalidOperationException" {
        Write-Error -Exception "InvalidOperationException" -ErrorId "InvalidOperationException" -Message "The file at ""$($Path)"" is in use by another process." -Category WriteError -TargetObject $Path -ErrorAction Stop
    }
    Default {
        Write-Error $ErrorDetails -ErrorAction Stop
    }
}#>
Function Invoke-ErrorHandler { 
    [CmdLetBinding()]
    Param($err)

    $exception = $err.Exception.GetType().FullName
    Write-Debug ""
    Write-Debug "EXCEPTION CAUGHT: $exception"
    Try { Invoke-Expression "Debug-$exception" }
    Catch { Invoke-UnhandledException }
}

Function Set-ErrorMessageDetails {
    #[CmdLetBinding()]
    #Param($err)
    $messageDetails = ";Category Info: $($err.CategoryInfo.category);"
    $messageDetails += ";Fully Qualified Error ID: $($err.FullyQualifiedErrorId);"
    $messageDetails += ";Invocation Info: $($err.InvocationInfo.PositionMessage);"
    $messageDetails += ";Exception Message: $($err.Exception);"
    $messageDetails += ";Script Stack Trace:;"
    $messageDetails += "$($err.ScriptStackTrace);"

    $messageDetails = $messageDetails -Replace ("`r`n",";")
    $messageDetails = $messageDetails -Replace ("`t","")
    $messageDetails = $messageDetails -Replace (",","¿")

    Return $messageDetails
}

##################################################################
## DEFINE EXPLICIT EXCEPTION HANDLING FUNCTIONS                 ##
##################################################################

Function Debug-System.Management.Automation.RuntimeException {                                                          ## 60010 ##
    Write-Debug "EXCEPTION HANDLER: System.Management.Automation.RuntimeException"
    Write-Debug "FullyQualifiedErrorId: $($err.FullyQualifiedErrorId)"
    $errorMessage = Set-ErrorMessageDetails

    If ($err.FullyQualifiedErrorId -like "*InvokeMethodOnNull*") { 
        Write-Event -eventLevel 3 -eventID 60010 -message "An InvokeMethodOnNull Runtime exception has occurred. Please see the Error Information Below:;$errormessage" 
        Return
    }
    If ($err.FullyQualifiedErrorId -like "*NullArrayIndex*") { 
        Write-Event -eventLevel 3 -eventID 60010 message "An NullArrayIndex Runtime exception has occurred. Please see the Error Information Below:;$errormessage" 
        Return
    }

    Write-Event -eventLevel 3 -eventID 60010 -Message "A Generic Runtime Exception has occurred.;$errorMessage" 
    Return
}

Function System.Management.Automation.InvokeMethodOnNull {                                                              ## 60011 ##
    Write-Debug "EXCEPTION HANDLER: System.Management.Automation.InvokeMethodOnNull"
    $errorMessage = Set-ErrorMessageDetails
    Write-Event -eventLevel 3 -eventID 60011 -message "An InvokeMethodOnNull exception has occurred. Please see the Error Information Below:;$errorMessage"
    Return
}

Function Debug-System.Net.WebException {                                                                                ## 60012 ##
    Write-Debug "EXCEPTION HANDLER: System.Net.WebException"
    $errorMessage = Set-ErrorMessageDetails

    ## Ref: https://developer.mozilla.org/en-US/docs/Web/HTTP/Status

    ## Redirection Messages
    If ($err.Exception -contains "301") {  }
    If ($err.Exception -contains "302") {  }
    If ($err.Exception -contains "307") {  }
    If ($err.Exception -contains "308") {  }
    ## Client Error Responses
    If ($err.Exception -contains "400") {  }
    If ($err.Exception -contains "401") {  }
    If ($err.Exception -contains "403") {  }
    If ($err.Exception -contains "404") {  }
    If ($err.Exception -contains "405") {  }
    If ($err.Exception -contains "418") { $Response = "The server refuses the attempt to brew coffee with a teapot." }
    If ($err.Exception -contains "429") {  }
    ## Server Error Responses
    If ($err.Exception -contains "500") {  }
    If ($err.Exception -contains "502") {  }
    If ($err.Exception -contains "503") {  }
    If ($err.Exception -contains "504") {  }
    If ($err.Exception -contains "505") {  }
    If ($err.Exception -contains "511") {  }

    #$Message = $errorinfo.invocationinfo+"`r`n"+$errorinfo.TargetObject
    Write-Event -eventLevel 2 -eventID 60012 -Message $errorMessage
    Return $Response
}

Function Debug-System.Management.Automation.SetValueInvocationException {                                               ## 60013 ##
    Write-Debug "EXCEPTION HANDLER: System.Management.Automation.SetValueInvocationException"
    $errorMessage = Set-ErrorMessageDetails
    Write-Event -eventLevel 3 -eventID 60011 -message "An exception occurred while trying to set a value. Please see the Error Information Below:;$errorMessage"
    Return
}

Function Debug-Microsoft.PowerShell.SecretManagement.PasswordRequiredException {                                        ## 60308 ##
    Write-Debug "EXCEPTION HANDLER: Microsoft.PowerShell.SecretManagement.PasswordRequiredException"
    $errorMessage = Set-ErrorMessageDetails
    $message = "An attempt to access the vault failed. This is most likely because the vault is currently locked.;$errormessage"
    Write-Event -eventLevel 0 -eventID 60308 -Message $message
    Unlock-Vault
    Return
}

Function Debug-System.Management.Automation.ErrorRecord {                                                               ## 60323 ##
    Write-Debug "EXCEPTION HANDLER: System.Management.Automation.ErrorRecord"
    
    If ($err.Exception -like "*does not exist at path HKEY_*") {
        $errorMessage = Set-ErrorMessageDetails
        Write-Event -eventLevel 3 -eventID 60323 -message "The requested Identity does not exist or is incorrectly configured. Please see the Error Information Below:;$errorMessage"
        New-MessageBox -Title "Identity Does Not Exist." -Text "The requested Identity does not exist or is incorrectly configured."
        Return
    }
    
}


##################################################################
## Caught the exception but no specific handler exists          ##
##################################################################
Function Invoke-UnhandledException {                                                                                    ## 60999 ##
    Write-Debug "UNHANDLED EXCEPTION! $($err.Exception.FullyQualifiedErrorId)"
    $errorMessage = Set-ErrorMessageDetails
    Write-Event -eventLevel 1 -eventID 60999 -Message "An unhandled exception has occurred.  Please see the error information below;Exception:;$($err.Exception.GetType().FullName)`r`n`r`nFull Details:`r`n`r`n$errorMessage"
    Return
}