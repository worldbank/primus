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

cap program drop primus_action
program primus_action, rclass
	version 16.0
	syntax [anything] [,                  ///
	TRANxid(string) PROCessid(string) INDEXid(string)       ///
	Decision(string) Comments(string) ]
	
	local option 3	
	tempfile decisionout
	if "`tranxid'"~="" {
		local tranxid `=upper("`tranxid'")'
		local decision `=upper("`decision'")'
		if `= wordcount("`tranxid'")' > 1 {
			noi dis as error "There should be ONLY one transaction ID"
			global errcodep = 1
			error 198
		}
		else { //tranxid2
			if `= wordcount("`decision'")' > 1 {
				noi dis as error "There should be ONLY one decision: APPROVE, or REJECT, or CONFIRM"
				global errcodep = 1
				error 198
			}
			else { //decision
				if (!inlist("`decision'","APPROVE", "REJECT", "CONFIRM")) {
					noi disp as error "The input on the decision() needs to be corrected. Available options are: APPROVE, REJECT."
					global errcodep = 1
					error 198
				}
				else {
					if "`decision'"=="REJECT" & "`comments'"=="" {
						noi dis as error "You must have comments when rejecting a transaction"
						global errcodep = 1
						error 198
					}
					if ("`decision'"=="APPROVE" | "`decision'"=="CONFIRM") & "`comments'"=="" local comments `=c(username)'
					
					//API
					primus_api, option(`option') query("tranx=`tranxid'&processid=`processid'&server=${webserver}&Decision=`decision'&Comments=`comments'")								
					if `primusrc'==0 {
						return local prmAction "`prmAction'"						
						return local prmSurveyID "`prmSurveyID'"
						return local prmTransID "`prmTransID'"
						
						noi dis as text in yellow "{p 4 4 2}Transaction ID `prmTransID' for `prmSurveyID' is `decision'(ED), and it is now in `prmAction'.{p_end}"
					}
					else {
						noi dis as error `"Transaction ID `tranxid' - `prmErrMsg'"'
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
