*! version 0.0.1  23Feb2018
*! Copyright (C) World Bank 2017-18 

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

capture program define _primus, plugin using("Primus`=cond(strpos(`"`=c(machine_type)'"',"64"),64,32)'.dll")
cap program drop primus_query
program primus_query, rclass
	version 11.0
	syntax [anything] [,                  ///
	COUNtry(string) Year(string)          ///
	Region(string) OVERALLStatus(string) ///
	PENDINGwith(string) TRANxid(string)]

	local opt 1
	local server 3
	global errcodep = 0
	//housekeeping
	local regionlist `" "ECA", "EAP", "MNA", "LAC", "SSA", "SAR" "'
	local overallstatuslist `" "APPROVED", "PENDING", "REJECTED" "'
	local pendingwithlist `" "DECDG", "FINALIZER", "POVCALNET", "REGIONAL", "UPLOADER" "'
	
	local yearkey DataYear
	local countrykey Country
	local regionkey Region
	local overallstatuskey OverallStatus
	local pendingwithkey Pendingwith
	local tranxidkey TransactionId
	
	local RequestKey

	local loclist country year region overallstatus pendingwith tranxid
	foreach loc of local loclist {
		if "``loc''" ~="" {
			local `loc' `=upper("``loc''")'
			if "`loc'"=="country" | "`loc'"=="year" | "`loc'"=="tranxid" {
				local `loc' :  subinstr local `loc' " " "", all
				if "`RequestKey'"=="" local RequestKey ``loc'key'=``loc''
				else local RequestKey `RequestKey'&``loc'key'=``loc''
			}
			else { //other locs with checks
				if `=wordcount("``loc''")' > 1 {
					noi disp in red `"The input on the `loc'() is not correct. Available options are: ``loc'list'; and one region at a time."'
					global errcodep = 198
					error 198
				}
				else {
					if (!inlist("``loc''",``loc'list')) {
						noi disp in red `"The input on the region() is not correct. Available options are: ``loc'list'."'
						global errcodep = 198
						error 198
					}
					else {
						if "`RequestKey'"=="" local RequestKey ``loc'key'=``loc''
						else local RequestKey `RequestKey'&``loc'key'=``loc''
					}
				}
			}	
		} //real loc	
	} //loclist
	
	//getting API
	tempfile primusout
	qui plugin call _primus , "`opt'" "`RequestKey'" "`primusout'" "`server'"	
	if `primusRC'==0 {
		cap insheet using "`primusout'", clear	
		if _rc==0 {
			if _N==0 { 
				cap confirm numeric variable transaction_id
				if _rc==0 {
					noi dis in yellow "Nothing found based on the input. Please redefine the parameters."
					global errcodep = 1
					clear
				}
			}
			else {
				noi dis as text "Successful load the query data into Stata!"
				global errcodep = 0
				gen double date_modified1 = clock(date_modified, "MDYhms")
				format %tc date_modified1
				drop date_modified
				ren date_modified1 date_modified
			}
		} //rc insheet
		else {
			noi dis as error "Failed to load the data. Please redefine the parameters."
			global errcodep = 1
			error 1
		}
	} //rc primus

end
