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

cap program drop primus_xml
program primus_xml, rclass
	version 14.0
	syntax [anything] , welflist(varname) weightlist(varname) xmlout(string) COUNtry(string) Year(string) SURVEYID(string) PPPyear(integer) refyear(string) filename(string) pfwid(string) [byvar(varname) cpivar(varname) icpvar(varname)]  	
		
	***************************** XML ***************************
	
	//Prepare the files and naming structures.
	local date = c(current_date)
	local time = c(current_time)
	local datetime `date' `time'
	
	if "`filename'"~="" {
		if (regexm("`filename'","GPWG")==1) {
			cap drop weight_h
			cap rename weight_p weight
			local theW weight
		}
		else {
			cap rename weight weight_p
			local theW weight_p
		}
	}

	//Indicator calculation - XML
	*tempfile xmlout logfile
	cap log close logall
	tempfile logfile
	log using "`logfile'", text replace name(logall)

	//Setup for XML
	//local byvar 
	local countrycode `country'
	*local pppyear 2017
	*local surveyid `surveys'
	*local filename `fname'
	*local year `yyy'

	//default variable of 
	if "`welflist'"=="" local welflist welfare
	if "`weightlist'"=="" local weightlist `theW'
	if "`pppyear'"=="" local pppyear 2017
	if "`plines'"=="" {
		if `pppyear'==2021 {
			local plines 3.00
			local threshold 0.25
		}
		if `pppyear'==2017 {
			local plines 2.15 3.65
			local threshold 0.25
		}
		if `pppyear'==2011 {
			local plines 1.9 3.2
			local threshold 0.22
		}
		if `pppyear'==2005 local plines 1.25 2.0
	}
	local method EmbeddedCPI
	log off logall

	//new values
	dis %10.0g
	levelsof cpi`pppyear', local(newCPIValue)
	levelsof icp`pppyear', local(newPPPValue)

	local cpilist  `newCPIValue' 
	local icplist  `newPPPValue' 
				
	display in red "`icplist'"
	display in red "`cpilist'"
	//adjust local
	local welflist = trim("`welflist'")
	local welflist1 : subinstr local welflist "`=char(32)'" ",", all
	local weightlist = trim("`weightlist'")
	if (`: word count `weightlist''>1) & (`: word count `welflist''>1)  & (`: word count `weightlist'' < `: word count `welflist'') {
		dis in red "No balanced pairs of welfare and weight variables"
		exit 198
	}
	if (`: word count `weightlist''==1) & (`: word count `welflist''>1) {
		local weightlist = "`weightlist' " * `: word count `welflist''
	}

	local weightlist = trim("`weightlist'")
	local weightlist1 : subinstr local weightlist "`=char(32)'" ",", all

	local wset
	forv j=1(1)`: word count `welflist'' {
		local wf : word `j' of `welflist'
		local wt : word `j' of `weightlist'
		local wset "`wset' `wf'|`wt'"
	}
	local wset = trim("`wset'")
	local wset : subinstr local wset "`=char(32)'" ",", all			

	//byvar check
	if "`byvar'"~="" {
		ta `byvar'
		local nbyvar = r(r)
		local byvar2 `byvar'
	}
	else {
		local nbyvar 1
		gen __all__ = 1
		la def __all__ 1 "All sample"
		la val __all__ __all__
		local byvar2 __all__
	}

	//count number of requests
	local nwevar : word count `welflist'
	local nwivar : word count `weightlist'
	local npline : word count `plines'
	local nParamSets = `npline'
	
	/*
	local paset
	foreach vicp of local icplist{
		foreach vcpi of local cpilist{	
			foreach pline of local plines{
				if "`method'"=="CustomCPI" local paset "`paset'&Param=Method=`method'|PL=`pline'|PPP=`vicp'|CPI=`vcpi'"
				if "`method'"=="EmbeddedCPI" local paset "`paset'&Param=Method=`method'|PL=`pline'"
			}
		}
	}
	display in yellow "`paset'"
	*/
	
	//invalid group results can be written as "n/a"
	log on logall

	//Chars for priceframework
	preserve
		tokenize `surveyid', parse(_)
		local _milhouse `5'
		qui primus_pfwdata, code(`countrycode') year(`year') survey(`_milhouse') pfwid(`pfwid')		
	restore

	local pricevars `r(_pricevars)'
	foreach price of local pricevars {
		*char _dta[`price'] `r(_`price')'
		local `price' `r(_`price')'
	}
	
	/*
	//List of important Char
	char _dta[uploaddate] `DATETIME'
	char _dta[filename] `FILENAME'
	char _dta[survey_id] `SURVEY_ID'
	char _dta[use_microdata] `USE_MICRODATA'
	char _dta[unit_observation] `UNIT_OBS'
	char _dta[ref_year] `ref_year'
	char _dta[data_year] `DATA_YEAR'
	*/
	
	*local RequestKey task=Povcal&DataSource=InboundDTA&CountryCode=`countrycode'&DataYear=`year'&By=`byvar'&BaseYear=`pppyear'&welfareSet=`wset'`paset'
	*dis in yellow "`RequestKey'"
	local APP_ID Stata
	local DATETIME `datetime'
	local IS_INTERPOLATED FALSE
	local USE_MICRODATA TRUE
	local USE_GROUPDATA `use_groupdata'
	local USE_BIN `use_bin'
	local USE_IMPUTED `use_imputed'	
	//UNIT_OBS: HH or IND
	local UNIT_OBS 
	local COUNTRY_CODE `countrycode'
	local COUNTRY_NAME `ctryname'
	local SURVEY_ID `surveyid'
	local FILENAME `filename'
	local REGION_CODE `region'
	local DATA_COVERAGE `survey_coverage'
	local DATA_TYPE `datatype'
	local DATA_YEAR `year'
	local REF_YEAR `ref_year'
	local REP_YEAR `rep_year'
	local CPI_YEAR `ref_year'
	local PPP_YEAR `pppyear'
	log off logall

	//PRIMUS log 
	tempfile outdata
	tempname outfile
	file open  `outfile' using "`outdata'", read write text
	file write `outfile' `"<PRIMUS_ANALYSIS>"' _n
	file write `outfile' _col(2) `"<Request>"' _n
	file write `outfile' _col(4) `"<RequestKey><![CDATA[`RequestKey']]></RequestKey>"' _n
	file write `outfile' _col(4) `"<welfare>`welflist1'</welfare>"' _n
	file write `outfile' _col(4) `"<weight>`weightlist1'</weight>"' _n		
	file write `outfile' _col(4) `"<By>`byvar'</By>"' _n	
	file write `outfile' _col(4) `"<N_By_Group>`nbyvar'</N_By_Group>"' _n	
	file write `outfile' _col(4) `"<nParamSets>`nParamSets'</nParamSets>"' _n	
	file write `outfile' _col(4) `"<![CDATA["' _n	
	file write `outfile' _col(4) `"APP_ID;`APP_ID'"' _n
	file write `outfile' _col(4) `"DATETIME;`DATETIME'"' _n
	file write `outfile' _col(4) `"FILE_SIZE;`FILE_SIZE'"' _n
	file write `outfile' _col(4) `"IS_INTERPOLATED;`IS_INTERPOLATED'"' _n
	file write `outfile' _col(4) `"USE_MICRODATA;`USE_MICRODATA'"' _n
	file write `outfile' _col(4) `"USE_GROUPDATA;`USE_GROUPDATA'"' _n
	file write `outfile' _col(4) `"USE_BIN;`USE_BIN'"' _n
	file write `outfile' _col(4) `"USE_IMPUTED;`USE_IMPUTED'"' _n
	file write `outfile' _col(4) `"COUNTRY_CODE;`COUNTRY_CODE'"' _n
	file write `outfile' _col(4) `"COUNTRY_NAME;`COUNTRY_NAME'"' _n
	*file write `outfile' _col(4) `"SURVEY_ID;`SURVEY_ID'"' _n
	file write `outfile' _col(4) `"FILENAME in calculation;`FILENAME'"' _n
	file write `outfile' _col(4) `"REGION_CODE;`REGION_CODE'"' _n
	file write `outfile' _col(4) `"DATA_COVERAGE;`DATA_COVERAGE'"' _n
	file write `outfile' _col(4) `"DATA_TYPE;`DATA_TYPE'"' _n
	file write `outfile' _col(4) `"DATA_YEAR;`DATA_YEAR'"' _n
	file write `outfile' _col(4) `"REF_YEAR;`REF_YEAR'"' _n
	file write `outfile' _col(4) `"REP_YEAR;`REP_YEAR'"' _n
	file write `outfile' _col(4) `"CPI_YEAR;`CPI_YEAR'"' _n
	file write `outfile' _col(4) `"PPP_YEAR;`PPP_YEAR'"' _n
	file write `outfile' _col(4) `"]]>"' _n
	file write `outfile' _col(2) `"</Request>"' _n
	file write `outfile' _col(2) `"<Result>"' _n

	tempfile data0
	save `data0', replace

	log off logall
	local j = 1

	foreach var of local welflist {
		use `data0', clear		
		local wt : word `j' of `weightlist'		
		//welfare and weight
		file write `outfile' _col(4) `"<Welfare var="`var'" weight="`wt'">"' _n
		log on logall
			
		//Byvar
		dis "//Type the below to call your data only if it has already been confirmed and approved"
		dis "dlw, country(`countrycode') year(`year') vera(`veralt_p') verm(`vermast_p') type(`collection') module(gpwg) clear"
		dis "//Type the below to call your data if it has only been confirmed, but not approved"
		dis "dlw, country(`countrycode') year(`year') vera(WRK) verm(`vermast_p') type(`collection') module (gpwg) clear"
		dis "gen double `var'_PPP = `var'/ cpi`pppyear' / icp`pppyear' /365"
		dis "su `var' [aw=`wt']"
		su `var' [aw=`wt']
		local TotalPopAll = `=r(sum_w)'/1000000 
		levelsof `byvar2', local(bylist)
		foreach byv of local bylist {
			use `data0', clear
			keep if `byvar2'==`byv'
			tempfile data2
			save `data2', replace
			
			//data summary
			su `var' [aw=`wt']
			local nRecs = r(N)
			local TotalPopulation = `=r(sum_w)'/1000000 
			local Mean_LCU    = r(mean)
			local TotalWealth_LCU = r(sum)
			local Min_LCU     = r(min)
			local Max_LCU     = r(max)
			dis "ainequal `var' [aw=`wt'], all"
			noi:ainequal `var' [aw=`wt'],all
			local Gini = 100*`=r(gini_1)'
			local MLD  = 100*`=r(mld_1)'
			*local PPPadjuster 1
			sort `var'
			_ebin `var' [fw=`wt'], gen(deciles) nq(10)
			gen double a = `var'*`wt'
			collapse (sum) a, by(deciles)
			egen double all = total(a)
			gen double share = a/all
			sort  deciles
			forv i=1(1)10 {
				local Decile`i' = 100*share[`i']
			}
			
			log off logall
			//byCondition - when there is nothing NULL
			//write PRIMUS LOG - bygroup	
			if  "`byvar2'"=="__all__" file write `outfile' _col(4) `"<ByGroup byCondition="none">"' _n				
			else file write `outfile' _col(4) `"<ByGroup byCondition="`byvar2'==`byv'">"' _n				
			file write `outfile' _col(6) `"<DATASUMMARY>"' _n
			file write `outfile' _col(8) `"<![CDATA["' _n
			file write `outfile' _col(8) `"nRecs;`nRecs'"' _n
			file write `outfile' _col(8) `"TotalPopulation; "' _n
			file write `outfile' _col(8) `"Mean_LCU;`Mean_LCU'"' _n
			file write `outfile' _col(8) `"TotalWealth_LCU;`TotalWealth_LCU'"' _n
			file write `outfile' _col(8) `"Min_LCU;`Min_LCU'"' _n
			file write `outfile' _col(8) `"Max_LCU;`Max_LCU'"' _n
			file write `outfile' _col(8) `"Gini;`Gini'"' _n
			file write `outfile' _col(8) `"MLD;`MLD'"' _n		
			file write `outfile' _col(8) `"Decile1;`Decile1'"' _n
			file write `outfile' _col(8) `"Decile2;`Decile2'"' _n
			file write `outfile' _col(8) `"Decile3;`Decile3'"' _n
			file write `outfile' _col(8) `"Decile4;`Decile4'"' _n
			file write `outfile' _col(8) `"Decile5;`Decile5'"' _n
			file write `outfile' _col(8) `"Decile6;`Decile6'"' _n
			file write `outfile' _col(8) `"Decile7;`Decile7'"' _n
			file write `outfile' _col(8) `"Decile8;`Decile8'"' _n
			file write `outfile' _col(8) `"Decile9;`Decile9'"' _n
			file write `outfile' _col(8) `"Decile10;`Decile10'"' _n
			file write `outfile' _col(8) `"]]>"' _n
			file write `outfile' _col(6) `"</DATASUMMARY>"' _n

			//calculation on poverty
			if "`method'"=="EmbeddedCPI" { //CPI PPP in the data
				foreach pline of local plines {
					use `data2', clear
					
					gen `var'_PPP = `var'/ cpi`pppyear' / icp`pppyear' /365
					drop if `var'<0
					replace `var'_PPP = `threshold' if `var'_PPP < `threshold'
					
					local METHOD "`method'"
					local PPPValue = icp`pppyear'[1]
					local CPIValue = cpi`pppyear'[1]	
					
					noi dis in yellow "`CPIValue'"
					su `var'_PPP [aw=`wt']
					local ReqYearPopulation = `=r(sum_w)'/1000000 
					local MeanPPP = r(mean)
					local PovertyLine_LCU = `=`pline'*`PPPValue'*`CPIValue''
					local PovertyLine_PPP = `pline'
					local PPPadjuster = `PPPValue'*`CPIValue'
					local ByVarShare = (`ReqYearPopulation'/`TotalPopAll')*100
					
					log on logall
					dis "apoverty `var'_PPP [aw=`wt'], line(`pline') all"
					noi:apoverty `var'_PPP [aw=`wt'], line(`pline') all
					local Headcount         = `=r(head_1)'
					local PovertyGap        = `=r(pogapr_1)'
					local PovertyGapSquared = `=r(fogto3_1)'
					local Watt              = `=r(watts_1)'
					local Npoor             = (`Headcount'*`ReqYearPopulation')/100
					log off logall
					
					//calculation log
					file write `outfile' _col(6) `"<CALCULATION>"' _n
					file write `outfile' _col(8) `"<![CDATA["' _n
					file write `outfile' _col(8) `"METHOD;`METHOD'"' _n
					file write `outfile' _col(8) `"PPPValue;`PPPValue'"' _n
					file write `outfile' _col(8) `"CPIValue;`CPIValue'"' _n
					file write `outfile' _col(8) `"MeanPPP;`MeanPPP'"' _n
					file write `outfile' _col(8) `"PovertyLine_LCU;`PovertyLine_LCU'"' _n
					file write `outfile' _col(8) `"PovertyLine_PPP;`PovertyLine_PPP'"' _n
					file write `outfile' _col(8) `"PPPadjuster;`PPPadjuster'"' _n
					file write `outfile' _col(8) `"Headcount;`Headcount'"' _n
					file write `outfile' _col(8) `"PovertyGap;`PovertyGap'"' _n
					file write `outfile' _col(8) `"PovertyGapSquared;`PovertyGapSquared'"' _n
					file write `outfile' _col(8) `"Watt;`Watt'"' _n
					file write `outfile' _col(8) `"ReqYearPopulation;`ReqYearPopulation'"' _n
					file write `outfile' _col(8) `"nPoor;`Npoor'"' _n			
					file write `outfile' _col(8) `"ByVarShare;`ByVarShare'"' _n
					file write `outfile' _col(8) `"]]>"' _n
					file write `outfile' _col(6) `"</CALCULATION>"' _n
				} // nparamset pline
			}
			file write `outfile' _col(4) `"</ByGroup>"' _n
		} //byvar	
		log off logall
		file write `outfile' _col(4) `"</Welfare>"' _n
		local j = `j' + 1
	} //welfare


	//end
	file write `outfile' _col(2) `"</Result>"' _n
	log close logall

	//LOG Detail code
	clear
	qui set obs 1
	tempname note docout mystr
	file write `outfile' _col(2) `"<LOG_DETAIL>"' _n
	file write `outfile' _col(8) `"<![CDATA["' _n
	qui gen strL `note' = fileread("`logfile'")
	scalar `mystr' = `note'[1]
	file write `outfile' `"`=`mystr''"' _n
	file write `outfile' _col(8) `"]]>"' _n
	file write `outfile' _col(2) `"</LOG_DETAIL>"' _n
	file write `outfile'         `"</PRIMUS_ANALYSIS>"'
	file close `outfile'			
	qui cap copy "`outdata'" "`xmlout'", replace
	if _rc {
		display as error "file can not be saved at this location"
		exit 603
	}
	else {
		noi display in yellow "XML File saved in: `xmlout'"
	}
end
