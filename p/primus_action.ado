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
cap program drop primus_action
program primus_action, rclass
	version 11.0
	syntax [anything] [,                  ///
	TRANxid(string) INDEXid(string)       ///
	Decision(string) Comments(string) ]
	
	global errcodep 0
	local opt 3
	local server 3
	global errcodep = 0
	tempfile decisionout
	if "`tranxid'"~="" {
		local tranxid `=upper("`tranxid'")'
		local decision `=upper("`decision'")'
		if `= wordcount("`tranxid'")' > 1 {
			noi dis as error "There should be ONLY one transaction ID"
			global errcodep = 1
		}
		else { //tranxid
			if `= wordcount("`decision'")' > 1 {
				noi dis as error "There should be ONLY one decision"
				global errcodep = 1
				error 198
			}
			else { //decision
				if (!inlist("`decision'","APPROVED", "REJECTED", "CONFIRMED")) {
					noi disp as error "The input on the decision() is not correct. Available options are: APPROVE, REJECT."
					error 198
				}
				else {
					if "`decision'"=="REJECTED" & "`comments'"=="" {
						noi dis as error "You must have comments when rejecting a transaction"
						global errcodep = 1
						error 198
					}
					if ("`decision'"=="APPROVED" | "`decision'"=="CONFIRMED") & "`comments'"=="" local comments `=c(username)'
					
					//API
					qui plugin call _primus , "`opt'" "TransactionId=`tranxid'&Decision=`decision'&Comments=`comments'&IndexID=`indexid'" "`decisionout'" "`server'"					
					if `primusRC'==0 {
						cap insheet using "`decisionout'", clear
						if _rc==0 {
							if _N>0 {
								noi dis as text in red "{p 4 4 2}`=action_status[1]'{p_end}"
								if `=error_code[1]'~=3 {
									clear
									error 1
								}
								else clear
							}
							else {
								noi dis as error "Fail to put action (`decision') for the transaction ID `tranxid'!"
								global errcodep = 1
								error 198
							}
						} //insheet
						else {
							noi dis as error  "Fail to put action (`decision') for the transaction ID `tranxid'!"
							global errcodep = 1
							error 198
						}
					} //plugin
					else {
						noi dis as error  "Fail to put action (`decision') for the transaction ID `tranxid'!"
						global errcodep = 1
						error 198
					}
				}
			} //decision
		} //xid
	}
	else {
		noi dis as error "There should be one transaction ID"
		global errcodep = 1
		error 198
	}
end
