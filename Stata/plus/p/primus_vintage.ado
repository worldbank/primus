*! primus_vintage version 0.2.1  12Sep2014
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

cap program drop primus_vintage
program define primus_vintage, rclass

	version 11.0
	
	syntax, country(string) [wrk all module(string) svy(string) ///
	year(numlist int max=1 >1900) max SVYname server(string) collection(string)]
	
	global DATALIBWEB_VERSION 2
	
	tempfile _cattmp
	if "`server'"=="" local server GMD
	if "`collection'"=="" local collection GMD
	
	if "`collection'"=="GMD" & "`module'"=="" local module GPWG
	
	local opt 
	if ("`wrk'"!="") local opt wrkvintage
	if ("`all'"!="") local opt allvintages
	
	foreach x in module country svy {
		if ("``x''"!="") local `x' =trim(upper("``x''"))
	}
	
	//Local which returns all country surveys
	if ("`svyname'"!="") {
		dlw_catalog, savepath("`_cattmp'") full code(`country') 
		if (_N!=0) levelsof acronym, local(thesurveys) clean
		else local thesurveys = ""
		return local thesurveys `thesurveys'
		exit
	}
	else {
		//Bring in the Catalog
		dlw_catalog, savepath("`_cattmp'") server(`server') `opt' 
		if ("`year'"!="") keep if code=="`country'" & year==`year' & trim(upper(col))=="`collection'"
		else keep if code=="`country'" & trim(upper(col))=="`collection'"
		if ("`svy'"!="") keep if survname=="`svy'"
		//Is year new?
		return local newy=(_N==0)
		
		if (_N!=0) {
			replace surveyid = trim(upper(surveyid))
			split surveyid, parse(_)
			drop surveyid1 surveyid2 surveyid3 surveyid5 surveyid7 surveyid8
			replace surveyid6=subinstr(surveyid6,"V", "",.)
			replace surveyid4=subinstr(surveyid4,"V", "",.)
			
			rename surveyid6 vera
			rename surveyid4 verm
			gen newa1 = real(vera)+1
			gen newm1 = real(verm)
			gen newa = "0"+string(newa1) if length(string(newa1))==1
			replace newa = string(newa1) if length(string(newa1))==2
	
			//Latest GPWG
			levelsof verm if mod=="GPWG" & vera!="WRK", local(verm) clean
			levelsof vera if mod=="GPWG" & vera!="WRK", local(vera) clean
			if ("`vera'"!="") return local gpwg_a = "`vera'"
			else return local gpwg_a = ""
			
			if ("`verm'"!="") return local gpwg_m= "`verm'"
			else              return local gpwg_m= ""
			
			//Latest working
			levelsof verm if vera=="WRK", local(verm) clean
			if ("`verm'"!="") return local gpwg_wm= "`verm'"
			else              return local gpwg_wm= ""
				
			//Latest all
			levelsof verm if mod=="ALL" & vera!="WRK", local(verm) clean
			levelsof vera if mod=="ALL" & vera!="WRK", local(vera) clean
			if ("`vera'"!="") return local all_a = "`vera'"
			else return local all_a = ""
			
			if ("`verm'"!="") return local all_m= "`verm'"
			else              return local all_m= ""
			
			
			if ("`max'"!="") {
				egen maxa=max(newa1), by(survname)
				if ("`svy'"=="") {
					count
					if (r(N)!=0) levelsof newa if newa1==maxa, local(maxa) clean
					else local maxa = ""
				}
				else {
					count 
					if (r(N)!=0) levelsof newa if newa1==maxa & trim(upper(survname))==trim(upper("`svy'")), local(maxa) clean
					else local maxa = ""
				}
				
				if ("`maxa'"!="") return local maxa = "`maxa'"
				else return local maxa = "01"	
				
				egen maxm=max(newm1), by(survname)
				if ("`svy'"=="") {
					count 
					if (r(N)!=0) levelsof verm if newm1==maxm, local(maxm) clean
					else local maxm = ""
				}
				else {
					count 
					if (r(N)!=0) levelsof verm if newm1==maxm & trim(upper(survname))==trim(upper("`svy'")), local(maxm) clean
					else local maxm=""
				}
				
				if ("`maxm'"!="") return local maxm = "`maxm'"
				else return local maxm = "01"			
			}
			
			if ("`module'"!="") {
				drop if upper(trim(mod))!=upper(trim("`module'"))
				count
				local _b = r(N)
				return local newy_`module'=(`_b'==0)
			
				if (`_b'!=0) {
					levelsof verm, local(newm) clean
					levelsof newa, local(newa) clean
					
					if ("`newa'"!="") return local newa = "`newa'"
					else return local newa = ""
					
					if ("`newm'"!="") return local newm = "`newm'"
					else return local newm = ""	
				}
				else{
					return local newa = "01"
					return local newm = "01"
				}
			} //module
		} //_N
		else {
			return local all_m = "01"
			return local all_a = "01"
			return local gpwg_m = "01"
			return local gpwg_a = "01"
			return local gpwg_wm= ""
			if ("`max'"!="") {
				return local maxm = "01"
				return local maxa = "01"				
			}
		} //else
	}

end
