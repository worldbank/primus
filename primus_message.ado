//error function
cap program drop primus_message
program define primus_message
	syntax, error(numlist max=1)
	//subscription error
	if `error'==2   noi dis "{err}Un-authorized upload into the region that is not assigned to you"
	if `error'==3   noi dis "{err}Transaction: Decision by approvers"
	if `error'==4   noi dis "{err}Transaction: already reviewed by approvers"
	if `error'==5   noi dis "{err}Transaction: is in approved/rejected state, no further action allowed"
	if `error'==683 noi dis "{err}Unable to act by the approvers"
	if `error'==684 noi dis "{err}Current user not authorized to act on the transaction"
	if `error'==685 noi dis "{err}Unable to add comments"
	if `error'==686 noi dis "{err}The transaction does not contain the cal_index"
	if `error'==687 noi dis "{err}Approver decision would be either Rejected or approved"
	if `error'==688 noi dis "{err}Uploader decision would be rejected or confirmed"
	if `error'==671 noi dis "{err}File size exceed the PRIMUS upload limit"
	if `error'==672 noi dis "{err}Result file's REGION_CODE,SURVEY_ID,FILENAME and RequestKey should not be null or empty"	
	if `error'==673 noi dis "{err}Unable to update the PRIMUS System with result data"
	if `error'==674 noi dis "{err}Unable to Access to network share"	
	if `error'==675 noi dis "{err}POVCALNET service failed to Process the STATA file"
	if `error'==676 noi dis "{err}POVCALNET service return null"
	if `error'==677 noi dis "{err}Invalid Result file received from STATA"
	if `error'==678 noi dis "{err}There is no transaction exist in PRIMUS system in the name of: {0}"
	if `error'==679 noi dis "{err}Invalid Result file received from POVCALNET"
	if `error'==682 noi dis "{err}Network error"
	//Plugin error
	if `error'==601 noi dis "{err}Error code 601 - Internet bad url format"
	if `error'==602 noi dis "{err}Error code 602 - Internet authentication canceled"
	if `error'==603 noi dis "{err}Error code 603 - Internet connectivity failure"
	if `error'==604 noi dis "{err}Error code 604 - Internet datalib server unreachable"
	if `error'==605 noi dis "{err}Error code 605 - Internet unknown local error"
	if `error'==610 noi dis "{err}Error code 610 - Response error invalid content type header"
	if `error'==611 noi dis "{err}Error code 611 - Response error invalid file name header"
	if `error'==612 noi dis "{err}Error code 612 - Response error invalid content length header"
	if `error'==613 noi dis "{err}Error code 613 - Response error invalid file extension"
	if `error'==614 noi dis "{err}Error code 614 - Response error invalid status header"					
	if `error'==701 noi dis "{err}Error code 701 - Plugin usage error, parameter list"
	if `error'==702 noi dis "{err}Error code 702 - File I/O error, local file system access"
end
