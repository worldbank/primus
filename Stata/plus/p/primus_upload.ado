*! version 0.1.1  12Sep2014
*! Copyright (C) World Bank 2017-2024 

* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.

* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
* GNU General Public License for more details.

* You should have received a copy of the GNU General Public License
* along with this program. If not, see <http://www.gnu.org/licenses/>.

cap program drop primus_upload
program primus_upload, rclass
	version 16.0
	syntax [anything], PROCessid(string) surveyid(string) type(string) INfile(string) [zip new TRANxid(string)  OUTfile(string) FOLDERpath(string) XMLbl]	
	
	*global errcodep 0	
	tempfile primusout
	
	local reqkey processid=`processid'&surveyid=`surveyid'&server=${webserver}
	local outtxt
	
	//Housecleaning 
	if `=wordcount("`tranxid'")' > 1 {
		noi disp in red `"One transaction ID is allowed."'
		global errcodep = 198
		error 198
	}
	
	if `=wordcount("`surveyid'")' > 1 {
		noi disp in red `"One SurveyID is allowed."'
		global errcodep = 198
		error 198
	}
	else {
		local nunderscore = `=length("`surveyid'")' - `=length(subinstr("`surveyid'", "_", "", .))'		
		if (!inlist("`nunderscore'",4,7)) {
			noi disp in red `"At the moment, the system only accepts these SurveyID format: CCC_YYYY_SURVNAME_V0number1_M or CCC_YYYY_SURVNAME_V0number1_M_V0number1_A_COLLECTION"'
			global errcodep = 198
			error 198
		}
	}
	
	if "`new'"=="" & "`tranxid'"=="" {
		noi dis as error "One option is needed: new or tranxid()."
		global errcodep = 198
		error 198
	}	
	else if "`new'"~="" & "`tranxid'"~="" {
		noi dis as error "One option is allowed: new or tranxid()."
		global errcodep = 198
		error 198
	}
	else {
		if "`new'"~="" local reqkey `reqkey'&tranx=new
		if "`tranxid'"~="" local reqkey `reqkey'&tranx=`tranxid'
	}
	
	//check type
	local type `=upper("`type'")'
	if `=wordcount("`type'")' > 1 {
		noi disp in red `"One type option is allowed: raw or harmonized"'
		global errcodep = 198
		error 198
	}
	else {
		if (!inlist("`type'","RAW", "HARMONIZED")) {
			noi disp as error "One type option is allowed: raw or harmonized."
			global errcodep = 198
			error 198			
		}
	}	
	//check infile
	cap confirm file "`infile'"
	if _rc~=0 {
		noi dis as error "The infile (`infile') is not available or readable."	
		global errcodep `=_rc'			
		error `=_rc'
	}
	
	//zip vs nozip
	if "`zip'"=="" {
		if "`folderpath'"=="" {
			noi dis as error "Relative folderpath() is needed, e.g., Data/Harmonized or Data/Stata."
			global errcodep = 198
			error 198
		}
		else { //folderpath~=""
			if `=wordcount("`folderpath'")' > 1 {
				noi disp in red `"One relative folderpath() is needed, e.g., Data/Harmonized or Data/Stata."'
				global errcodep = 198
				error 198
			}
			else {
				//check to convert \ to /
			}
		}
	}
	else { //zip
		if "`folderpath'"~="" {
			noi dis as error "No need to have Relative folderpath() for the zip upload."
			global errcodep = 198
			error 198
		}
		if "`xmlbl'"~="" {
			noi dis as error "XMLbl cant go with zip. Remove zip if you want to upload the XML file."
			global errcodep = 198
			error 198
		}
	}
		
	//Type and upload	
	/*
	if "`type'"=="RAW" {
		if "`zip'"~="" primus_api, option(0c) query("`reqkey'&folderpath=`folderpath'") infile(`infile') outfile(`outfile')
		else primus_api, option(0a) query("`reqkey'&folderpath=`folderpath'") infile(`infile')
	}
	else { //harmonized
		if "`xmlbl'"~="" local reqkey `reqkey'&xmlbl=true
		else local reqkey `reqkey'&xmlbl=false
		
		if "`zip'"~="" primus_api, option(0d) query("`reqkey'&folderpath=`folderpath'") infile(`infile') outfile(`outfile')
		else primus_api, option(0b) query("`reqkey'&folderpath=`folderpath'") infile(`infile')
	}
	*/
	
	if "`type'"=="RAW" {
		if "`zip'"=="" local opt 0a
		else {
			local opt 0c 
			local outtxt outfile(`outfile')
		}		
	}
	else { //harmonized
		if "`xmlbl'"~="" local reqkey `reqkey'&xmlbl=true
		else local reqkey `reqkey'&xmlbl=false		
		if "`zip'"=="" local opt 0b
		else {
			local opt 0d
			local outtxt outfile(`outfile')
		}		
	}
	
	primus_api, option(`opt') query("`reqkey'&folderpath=`folderpath'") infile(`infile') `outtxt'
	if `primusrc'==0 {
		return local prmFileName "`prmFileName'"
		return local prmDataSize "`=round(`=`prmDataSize'/1048576',.01)'"
		return local prmSurveyID "`prmSurveyID'"
		return local prmTransID "`prmTransID'"
		
		if "`xmlbl'"~="" noi dis as text in yellow "File `prmFileName' (`=round(`=`prmDataSize'/1048576',.01)'mb) is uploaded as transaction details of `prmSurveyID'. The transaction ID is `prmTransID'."	
		else noi dis as text in yellow "File `prmFileName' (`=round(`=`prmDataSize'/1048576',.01)'mb) is uploaded into `prmSurveyID'. The transaction ID is `prmTransID'."
		
		if "`outtxt'"~="" {
			cap insheet using "`primusout'", clear
			if _rc==0 {						
				noi dis as text in yellow "Browse and see the list of successfully uploaded files."
			}
			else {
				noi dis as error "Unknow error - Unable to load the meta datafile."	
				global errcodep `=_rc'
				error `=_rc'	
			}
		} //outtxt
	} // primusrc
	else {
		primus_message, error(`=_rc')
		global errcodep `=_rc'			
		error 1						
	}
end
