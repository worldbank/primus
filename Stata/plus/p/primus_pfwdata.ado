*! primus_pfwdata version 0.1.1  12Sep2014
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

cap program drop primus_pfwdata
program define primus_pfwdata, rclass
	version 16
	syntax, code(string) year(numlist max=1) survey(string) [datalevel(string) pfwid(string)]

	cap datalibweb, country(support) year(2005) type(gmdraw) filename(Survey_price_framework.dta) surveyid(`pfwid') files
	if _rc!=0 {
		dis as error "Unable to load Survey_price_framework.dta"
		error `=_rc'
		exit
	}

	keep if upper(code)==upper("`code'") & year==`year' & upper(survname)==upper("`survey'")
	if _N==0 {
		dis as error "There is no survey price data for your code, year, and survey combination" 
		dis as error "You must submit your data through the survey_price_framework"
		error 1
		exit 
	}
	else if _N>1 {
		dis as error "There are more than one record of price framework data for your code, year, and survey combination" 
		dis as error "Reach out to central team"
		error 1
		exit
	}
	else {
		local pricevars
		foreach x of varlist * {
			levelsof `x', local(`x') 
			local pricevars `pricevars' `x'
		}
		
		return local _pricevars `pricevars'
		foreach x of local pricevars {
			return local _`x' ``x''
		}
	} //_N==1
end
