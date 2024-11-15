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

cap program drop primus
program primus, rclass
	version 16.0
	local version : di "version " string(_caller()) ":"
	set prefix primus
	gettoken subcmd 0 : 0, parse(" :,=[]()+-")
	local l = strlen("`subcmd'")
	
	global PRIMUS_VERSION 2
	global webserver 4
	global errcodep 0
	
	if ("`subcmd'"=="upload") { //upload relelated tasks
		primus_upload `0'
	}
	else if ("`subcmd'"=="query") { //query PRIMUS data
		primus_query `0'
    }
	else if ("`subcmd'"=="download") {
		primus_download `0'		
    }
	else if ("`subcmd'"=="action") {
		primus_action `0'		
    }
	else if ("`subcmd'"=="register") {
		primus_register `0'		
    }
	else if ("`subcmd'"=="roles") {
		primus_roles `0'		
    }
	else { //none of the above
		if ("`subcmd'"=="") {
			di as smcl as err "syntax error"
			di as smcl as err "{p 4 4 2}"
			di as smcl as err "{bf:primus} must be followed by a subcommand."
			di as smcl as err "You might type {bf:primus upload}, or {bf:primus query}, or {bf:primus action}, etc."			
			di as smcl as err "{p_end}"
			exit 198
		}
		capture which primus_`subcmd'
		if (_rc) { 
			if (_rc==1) exit 1
			di as smcl as err "unrecognized subcommand:  {bf:primus `subcmd'}"
			exit 199
			/*NOTREACHED*/
		}
		`version' primus_`subcmd' `0'
	}
	return add
end
