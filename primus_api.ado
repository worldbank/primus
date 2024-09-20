*! version 0.1.1  12Sep2014
*! Copyright (C) World Bank 2017-2024 

program define primus_api
    version 16.0

    // shouldn't happen but let's still confirm
    if inlist("$PRIMUS_VERSION", "1", "2") == 0 {
        display as error "Unsupported API version $PRIMUS_VERSION"
        exit 198
    }

    _primus_api_v$PRIMUS_VERSION `0'

    c_local primusrc "`primusrc'"
	c_local prmErrMsg "`prmErrMsg'"
	c_local prmAction "`prmAction'"
    c_local prmFileName "`prmFileName'"
    c_local prmDataSize "`prmDataSize'"
	c_local prmSurveyID "`prmSurveyID'"
	c_local prmTransID "`prmTransID'"
    
end

/*
primusrc:       0
prmDataSize:    1159160
prmFileName:    VNM_2022_VHLSS_v01_M_v01_A_EAPPOV_POV.dta
prmSurveyID:    ALB_2023_EIGHTw3_V03_M
prmTransID:     006-000327173-MNARAW-ALB-679e6
*/
program define _primus_api_v2, rclass
    version 16.0
    syntax, OPTion(integer) [Query(string) OUTfile(string) INfile(string) Token(string)]
	
    capture program define _primus_v2, plugin using("Primus2_`=cond(strpos(`"`=c(machine_type)'"',"64"),64,32)'.dll")	
    if _rc > 0 & _rc != 110 {
        display as error "Unable to load the plugin from its location, please check if Primus2_`=cond(strpos(`"`=c(machine_type)'"',"64"),64,32)'.dll is copied to PLUS folder or no other plugin application is running."
        exit `= _rc'
    }
	
	local user = upper(c(username))
	local user = subinstr("`user'","WB","",.)
	local user = subinstr("`user'","C","",.)
	local user = subinstr("`user'","S","",.)
	local user = subinstr("`user'","D","",.)
			
	//load register first it is asked via dlw_api
	if (`option'==8) { //register token
		if "`token'"~="" {			
			local user = `=9-length("`user'")'*"0" + "`user'"
			cap plugin call _primus_v2, "`option'" "upi=`user'&token=`token'"
			if _rc==0 {
				noi dis as text "PRIMUS/Datalibweb token is registered. The token is valid for 30 days as indicated in the datalibweb website."
			}
			else {
				noi dis as error "PRIMUS/Datalibweb token is invalid or expired. Please visit the datalibweb website to renew the token."
				noi dis as text "Use this: primus_api, option(8) token(your token here)"
				global errcodep `=_rc'				
				error 1
				*exit `= _rc'
			}
		} //token provided
		else {
			noi dis as error "Datalibweb token is needed for the API option 8. Please provide the token in the option token()."
			noi dis as text "Use this: primus register, token(your token here)"
			global errcodep 198
			error 198
		}		
	} //opt 8
	else { //other API options, not 8	
		//2-paras
		if (`option'==3) { //Method 3: Action on a transaction in a process  
			cap plugin call _primus_v2, "`option'" "`query'"
			//plugin call primus, "3" "tranx=&processid=&server=&Decision=&Comments="
		}
		
		//3-paras 0a 0b 1 2a 2b 4 5 6b 7 9  
		if (`option'=="0a" | `option'=="0b" | `option'==1 |`option'=="2a" |`option'=="2b" |`option'==4 |`option'==5 |`option'=="6b" |`option'==7 |`option'==9) { 
			//Method 7:  Explore survey name, surveyid, versioning across processes/servers
			cap plugin call _primus_v2, "`option'" "`query'"  "`outfile'"
			
			//plugin call primus, "7" "server=&country=[&year=&survname=]"  "name&path_to_Output"  
			//Method 0a: Raw Process – File Upload
			//plugin call primus, "0a" "tranx=&processid=&surveyid=&folderpath=&server=" "name&path_to_Input" 

			//Method 0b: Harmonized Process – File Upload
			//plugin call primus, "0b" "tranx=&processid=&surveyid=&folderpath=&server= [&xmlbl=] "  "name&path_to_Input" 
			
			//Method 1: Getting the list of transactions from a processID
			//plugin call primus, "1" "processid=&server[&country=&year=&region=&overallstatus=&pendingwith=]"  "name&path_to_Output"  
			
			//Method 2a: Load details of a transaction
			//plugin call primus, "2a" "tranx=&processid=&server=" "name&path_to_Output"  
			
			//Method 2b: get details of a transaction with the list of file names and its folders 
			//plugin call primus,"2b" "tranx=&processid=&server=" "name&path_to_Output"  
			
			//Method 4: Get the processID list (list of process, its id, name, admin name, active/disable or not)
			//plugin call primus, "4" "server=" "name&path_to_Output"  
			
			//Method 5: Get the folders and its associated file extensions for a processID.
			//plugin call primus, "5" "processid=&server=" "name&path_to_Output"  
			
			//Method 6B: Load/view users: Download user role mapping of the process
			//plugin call primus,"6b" "processid=&server=" "name&path_to_Output"		
		}
		
		//4-paras
		if (`option'=="0c" | `option'=="0d" | `option'=="6a") {
			cap plugin call _primus_v2, "`option'" "`query'"  "`infile'" "`outfile'"
			//4-para
			//Method 0c: Raw Process – Zip File Upload
			//plugin call primus,  "0c" "tranx=&processid=&surveyid=&folders=&server=" "name&path_to_Input" "name&path_to_Output"

			//Method 0d: Harmonized Process – Zip File Upload
			//plugin call primus,"0d" "tranx=&processid=&surveyid=&folders=&server=[&xmlbl=]" "name&path_to_Input" "name&path_to_Output"  
			
			//Method 6a: Assign users:  Upload user role mapping of the process
			//plugin call primus, "6a" "processid=&server=" "name&path_to_Input" "name&path_to_Output" 
		}
				
		if _rc==0 {
			c_local primusrc "`primusrc'"
			c_local prmErrMsg "`prmErrMsg'"
			c_local prmAction "`prmAction'"
			c_local prmFileName "`prmFileName'"
			c_local prmDataSize "`prmDataSize'"
			c_local prmSurveyID "`prmSurveyID'"
			c_local prmTransID "`prmTransID'"			
		}
		else {
			primus_message, error(`=_rc')
			global errcodep `=_rc'			
			error 1
		}
	} //other API options
end
