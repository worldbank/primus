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
cap program drop primus_download
program primus_download, rclass
	version 11.0
	syntax [anything], [TRANxid(string) ]
	local server 3
	local opt 2
	global errcodep 0
	tempfile primusout
	if "`tranxid'"~="" {
		if `= wordcount("`tranxid'")' > 1 {
			local tranxid0
			foreach tranx of local tranxid {
				if "`tranxid0'"~=""  local tranxid0 "`tranxid0',`tranx'"
				else local tranxid0 `tranx'
			}
		}
		else local tranxid0 `tranxid'
		tempfile primusout
		qui plugin call _primus , "`opt'" "TransactionId=`tranxid0'" "`primusout'" "`server'"		
		if `primusRC'==0 {
			*cap import delimited using "`primusout'", clear	
			cap insheet using "`primusout'", clear	
			if _rc==0 {
				if _N==0 { 
					noi dis in yellow "Nothing found based on the input. Please redefine the parameters."
					global errcodep = 1
					clear
				}
				else {
					noi dis as text "Successful load the query into Stata!"
					global errcodep = 0
				}
			}
			else {
				noi dis as error "Failed to load the data. Please redefine the parameters."
				global errcodep = 1
				error 1
			}
		}
	} //tranxid
	else {
		noi dis as error "There should be at least one transaction ID"
		global errcodep = 1
		error 1
	}
end
