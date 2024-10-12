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

cap program drop primus_roles
program primus_roles, rclass
	version 16.0
	syntax [anything], PROCessid(string) [ upload download infile(string)] 
	tempfile primusout
	
	if "`upload'"~="" & "`download'"~="" {
		noi dis as error "One option is allowed: meta or folders, not together."
		global errcodep 1
		error 1	
	}
	
	//download 
	if "`download'"~="" {
		primus_api, option(6b) query("processid=`processid'&server=${webserver}") outfile(`primusout')
		if `primusrc'==0 {
			cap insheet using "`primusout'", clear
			if _rc==0 {
				noi dis as text in yellow "PRIMUS user roles are loaded in Stata. Browse and see."
			}
			else {
				noi dis as error "Unknow error - Unable to load the downloaded datafile."					
				global errcodep `=_rc'
				error `=_rc'
			}			
		}
		else {
			primus_message, error(`=_rc')
			global errcodep `=_rc'			
			error 1						
		}
	}
	
	//upload
	if "`upload'"~="" {
		cap confirm file "`infile'"
		if _rc==0 {
			primus_api, option(6a) query("processid=`processid'&server=${webserver}") infile(`infile') outfile(`primusout')
			if `primusrc'==0 {
				cap insheet using "`primusout'", clear
				if _rc==0 {
					noi dis as text in yellow "New user roles are uploaded into PRIMUS. Browse and see details of user roles."
				}
				else {
					noi dis as error "Unknow error - Unable to load the downloaded datafile."	
					global errcodep `=_rc'
					error `=_rc'	
				}			
			}
			else {
				primus_message, error(`=_rc')
				global errcodep `=_rc'			
				error 1						
			}		
		}
		else {
			noi dis as error "The infile (`infile') is not available or readable."	
			global errcodep `=_rc'			
			error `=_rc'			
		}
	}
	
end