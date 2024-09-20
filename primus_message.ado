*! version 0.1.1  12Sep2014
*! Copyright (C) World Bank 2017-2024 
//error function
cap program drop primus_message
program define primus_message
	syntax, error(numlist max=1)
	//subscription error
	if `error'==401 noi dis "{err}Unauthorized Error, Token is Invalid/Expired"
	
	//Plugin errors
	if `error'==403 noi dis "{err}Not an authorized user to download (when the plugin user is not the same as input UPI in method 0 and plugin user is not a super admin)"
	if `error'==601 noi dis "{err}Internet bad URL format"
	if `error'==602 noi dis "{err}Internet authentication canceled"
	if `error'==603 noi dis "{err}Internet connectivity failure"
	if `error'==604 noi dis "{err}Internet primus server unreachable"
	if `error'==605 noi dis "{err}Internet unknown local error"
	if `error'==610 noi dis "{err}Response error invalid content type header"
	if `error'==611 noi dis "{err}Response error invalid file name header"
	if `error'==612 noi dis "{err}Response error invalid content length header"
	if `error'==613 noi dis "{err}Response error invalid file extension"
	if `error'==614 noi dis "{err}Response error invalid status header"
	if `error'==701 noi dis "{err}Plugin usage error. The provided input parameters do not meet the required criteria."
	if `error'==702 noi dis "{err}File I/O error, local file system access"
	
	//API errors
	if `error'==801 noi dis "{err}Authorization validation error: User email cannot be empty"
	if `error'==802 noi dis "{err}Operation failed: User lacks Uploader role for specified country"
	if `error'==803 noi dis "{err}The specified folder does not exist in the current process"
	if `error'==804 noi dis "{err}The specified folder does not allow files with this extension"
	if `error'==805 noi dis "{err}For Harmonized transactions the filename must be of the format, SurveyID_Module"
	if `error'==806 noi dis "{err}For Harmonied transactions the specified module in the file name does not exist in this process"
	if `error'==807 noi dis "{err}Action denied: Pending transaction exists for same survey, year, and country"
	if `error'==808 noi dis "{err}An error occurred while generating the Transaction ID"
	if `error'==809 noi dis "{err}Only harmonized processes are allowed, raw processes are not allowed"
	if `error'==810 noi dis "{err}The specified Survey ID does not match the specified Transaction ID"
	if `error'==811 noi dis "{err}Only RAW process is allowed, Harmonized process is not allowed"
	if `error'==812 noi dis "{err}Process ID not found"
	if `error'==813 noi dis "{err}Invalid Transaction Id"	
	if `error'==814 noi dis "{err}No process is available"	
	if `error'==815 noi dis "{err}No folders available in this process"	
	if `error'==816 noi dis "{err}Invalid Survey ID"	
	if `error'==822 noi dis "{err}Transaction is in DRAFT mode"	
	if `error'==825 noi dis "{err}Transaction already Confirmed/Rejected"	
	if `error'==826 noi dis "{err}Please provide a valid TransactionId"	
	if `error'==830 noi dis "{err}ProcessId is not valid with the TransactionId"	
	if `error'==836 noi dis "{err}Operation failed: User lacks Approver role for specified country"	
	if `error'==842 noi dis "{err}No records available in this Transaction."	
	if `error'==851 noi dis "{err}Operation failed: Transaction is in Pending status."	

end
