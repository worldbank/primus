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

cap program drop primus_query
program primus_query, rclass
	version 16.0
	syntax [anything] [,                  ///
	COUNtry(string) Year(string)          ///
	Region(string) OVERALLStatus(string) ///
	PENDINGwith(string) TRANxid(string) PROCessid(string)]

	local opt 1
	local server 3
	*global errcodep = 0
	//housekeeping
	local regionlist `" "ECA", "EAP", "MNA", "LAC", "SSA", "SAR" "'
	local overallstatuslist `" "COMPLETE", "PENDING", "REJECT", "DELETED", "DRAFT" "'
	local pendingwithlist `" "DEC", "FINALIZER", "REGIONAL", "UPLOADER" "'
		
	local RequestKey server=${webserver}

	local loclist country year region overallstatus pendingwith //tranxid
	foreach loc of local loclist {
		if "``loc''" ~="" {
			local `loc' `=upper("``loc''")'
			if "`loc'"=="country" | "`loc'"=="year" | "`loc'"=="tranxid" {
				local `loc' :  subinstr local `loc' " " "", all				
				local RequestKey `RequestKey'&`loc'=``loc''
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
						local RequestKey `RequestKey'&`loc'=``loc''
					}
				}
			}	
		} //real loc	
	} //loclist
	
	//getting API
	tempfile primusout
	primus_api, option(1) query("`RequestKey'") outfile(`primusout')
	if `primusrc'==0 {
		cap insheet using "`primusout'", clear
		if _rc==0 {
			noi dis as text in yellow "PRIMUS transaction ID list is loaded in Stata. Browse and see."
			global errcodep = 0
			gen double date_modified1 = clock(date_modified, "MDYhms")
			format %tc date_modified1
			drop date_modified
			ren date_modified1 date_modified
		}
		else {
			noi dis as error "Unknow error - Unable to load the downloaded meta datafile."	
			global errcodep `=_rc'
			error `=_rc'
		}			
	}
	else {
		primus_message, error(`=_rc')
		global errcode `=_rc'			
		error 1						
	}
end
