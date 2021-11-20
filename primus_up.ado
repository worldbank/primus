*! primus_up.ado
*! December 2019

cap program drop primus_up
cap set matastrict off
program define primus_up, eclass
	version 11.2
	syntax,                    ///
	output(string)              ///
	NATcode(string)             ///
	YEARs(numlist >1900 min=1)  ///
	refyear(string)             ///
	WEFlist(varlist max=1)      ///
	VERMast_p(string)           ///
	VERAlt_p(string)            ///
	SURveys(string)             ///
	FILEname(string)	        ///
	reg(string)                 ///
	ctryname(string)            ///
	no_pweight(numlist max=1)   ///
	povweight(varname)          ///	
	filename(string)            ///
	nopovcal(numlist max=1)     ///
	collection(string)          ///
	[SURVName(string) cpimethod(string)  filepath(string) hhlev(integer 0) byvar(varname)]  			  
	
//Declare locals
local date1 = c(current_date)
local date2 : subinstr local date1 ":" "_", all 	
global output ="`output'"
global file0 ="primus_`date2'"								
global dd  ="uploading"
local aa 1
local ccounT = "`natcode'"
local fname = "`filename'"

tokenize `surveys', parse(_)
local mysvynm `5'
local mysvyY `3'
local myVM  `7'
local myVA  `11'

//Ensure always sorted
cap isid hhid
local itis = _rc
if (`itis'==0) sort hhid
else sort hhid pid	

if ("`cpimethod'"=="") local method CustomCPI   

if (`no_pweight'==1 & `itis'!=0){
// If the data is HH level and the user did not provide a weight, then by default 
// weight_p and weight_i will be equal, thus no check is required. The check is only
// necessary iff you have individual level data and you did not provide a povweight
	preserve
	
	tempvar popw povw
		egen double `povw' = sum(weight_p*(weight_h!=. & hsize!=.)), by(hhid)
		gen double `popw' = weight_h*hsize
		
		count if abs(`povw' - `popw')>0.01 & `povw'!=. & `popw'!=.
		local dif = r(N)
		if (`dif'>0){
			display as error "You need to specify weights to ensure replication of poverty at the individual and household level"
			error 100
			exit
		}
	restore
}

//To ensure old codes run
rename weight_p weight



// Check what versions to compare to:
preserve
primus_vintage, country(`natcode') year(`years') wrk svy(`mysvynm')
local gpwg_wm = r(gpwg_wm)
	local gpwg_wm = subinstr("`gpwg_wm'", ".","",.)
local gpwg_m  = r(gpwg_m)
	local gpwg_m = subinstr("`gpwg_m'", ".","",.)
local gpwg_a  = r(gpwg_a)
	local gpwg_a = subinstr("`gpwg_a'", ".","",.)
local newy    = r(newy)
restore

// Check to verify if Working Version has to be compared

if ("`gpwg_wm'"!=""){
	//need natcode years surveys
	preserve
		qui: cap primus_query, country(`natcode') year(`years')
		local qwrk = _rc==0		
		if (`qwrk'==1){
			keep if regexm(survey_id,"`surveys'")==1
			keep if trim(lower(overall_status))=="pending" & trim(lower(uploader))=="true"
			*set trace on
            *set traced 1
			if (_N==0) local donotcompare = 1	
			else{
				split survey_id, parse(_)
				keep if trim(upper(survey_id4))==upper("`vermast_p'") & ///
				upper(survey_id6)==upper("`veralt_p'") & (trim(lower(regional))=="pending"|trim(lower(uploader))=="false")
				if (_N!=0){
					egen double maxdate =max(date_modified)
					levelsof transaction_id if maxdate==date_modified, local(_tid)
					
					capture window stopbox rusure "Do you want to clear transid `_tid' from memory?"  ///
					"`filename'"
					local stwrk = _rc==0
					
					if (`stwrk'==1){
						primus_action, tranxid(`_tid') comments("Cancelled by `c(username)' through Primus upload process") ///
						decision("REJECTED")
						local donotcompare=1
					}
					else{
						dis as error "You may not overwrite data with pending transaction id's"
						error 238374
						exit
					}
				}
				else local donotcompare = 0
			}
		}
		else{
			display as error "Unable to load query data, please try again"
			error 3949444
			exit
		}		
	restore
}
else{
//verify older vintages
	preserve
		qui: cap primus_query, country(`natcode') year(`years')
		local qwrk = _rc==0	
		if (`qwrk'==1){
			if _N!=0{
				keep if regexm(lower(survey_id),lower("`mysvynm'"))==1 
				egen double maxdate =max(date_modified)
				drop if maxdate < `=clock("1 Jan 2018 00:00:00","DMY hms")'
				
				if (_N==0) local donotcompare = 0
				else{
					levelsof transaction_id if lower(survey_id)==lower("`surveys'") & lower(uploader)=="false" & lower(overall_status)=="pending", local(mytrans)
					foreach id of local mytrans{
						primus_action, tranxid(`id') comments("Cancelled by `c(username)' through Primus upload process") ///
						decision("REJECTED")
					}
					
					if (_N==0) local donotcompare = 1
					else local donotcompare = 0
					
				}
			}
			else local donotcompare = 1
		}
		else{
			display as error "Unable to load query data, please try again"
			error 3949444
			exit
		}
	restore
} //END ELSE

//Compare data to previous vintages, or current working versions!!
if ("`collection'"=="GMD"){
	if (`donotcompare'==0){
		noi:primuSCompaRe, newy(`newy') natcode(`natcode') year(`years')  gpwg_a(`gpwg_a') gpwg_m(`gpwg_m') gpwg_wm(`gpwg_wm') hhlev(`hhlev') reg(`reg')
		local gotoprimus=r(gotoprimus)
	}
	else local gotoprimus = 1
}
else{
	local gotoprimus=1
}


//Keep only one weight type if GPWG
    if (regexm("`filename'","GPWG")==1){
        cap drop weight_h
        cap rename weight_p weight
        local theW weight
    }
    else{
        cap rename weight weight_p
        local theW weight_p
    }

    if ("`gotoprimus'"!="1" & `nopovcal'!=1){
        dis as error "You have not specified the nopovcal option, and thus data will not be submitted for confirmation"
        error 29024
    exit
    }

    if ("`gotoprimus'"=="1" & `nopovcal'==1){
        dis as error "Your data needs to be uploaded to povcalnet and trigger a transaction ID"
        error 2929292
        exit
    }

    local ccc `natcode'
    local yyy `years'
    di in red "`ccc':`yyy':`surveys':`vermast_p':`veralt_p'"
        
    tempfile MuDAta
    save `MuDAta'

//Price database!
    qui datalibweb, country(Support) year(2005) type(GMDRAW) surveyid(Support_2005_CPI_v06_M) filename(Final_CPI_PPP_to_be_used.dta) clear
    di r(cmdline)
    local priceproblem=_rc
    if (`priceproblem'==111|`priceproblem'==0){
        cap keep if upper(code)==upper("`ccc'")
        if (_rc) keep if upper(countrycode)==upper("`ccc'")
        tempfile cpi_
        save `cpi_'
    }
    else{
        dis as error "Unable to load price database"
        error 128384
        exit
    }
        
	use `MuDAta', clear
	
//Datalevel
    if ("`=upper("`ccc'")'"=="IDN" | "`=upper("`ccc'")'"=="CHN" | "`=upper("`ccc'")'"=="IND"){
        gen datalevel = 1
        local method EmbeddedCPI
    }
    else {
        gen datalevel = 2
    }
    
//Merge CPI
    cap gen code = "`=upper("`ccc'")'"
    cap drop cpi*
    cap drop icp*

    if (strpos("`surveys'","EU-SILC")>0 | strpos("`surveys'","SILC")>0) replace year = year - 1

    cap drop region
    ren survey survname
    qui merge m:1 code year datalevel survname using `cpi_', gen(_mcpi) keepus(region countryname ref_year cpi2011 icp2011)
    ren survname survey 

    * Display error if CPI data cannot be merged into the dataset being uploaded
        *ta _mcpi
        qui count if _mcpi==1 //Count observations that could not be merged with CPI data
        if r(N) !=0{
            dis as error "Your survey could not be fully merged with CPI data. Please contact the Central Team and review Final_CPI_PPP_to_be_used.dta."
            error 12345
        }
        * qui merge m:1 code year datalevel using `cpi_', gen(_mcpi) keepus(region countryname ref_year cpi2011 icp2011) //SM19 code

        qui drop if _mcpi==2            
        qui drop _mcpi
        cap drop datalevel 
        cap drop ppp_note

//define deflators	
    local cpi cpi2011
    local ppp icp2011
    if (strpos("`surveys'","EU-SILC")>0 | strpos("`surveys'","SILC")>0) replace year = year + 1 

    local refyr = `refyear'
    if ("`refyr'"=="."|strpos("`surveys'","SILC")>0){
        if (strpos("`surveys'","EU-SILC")>0 | strpos("`surveys'","SILC-C")>0) local refyr `=`yyy'-1'
        else local refyr `yyy'
    }
                 
tempfile dataout
save `dataout',replace
cap log close logall
			
		
			***************************** XML ***************************
			//Prepare the files and naming structures.
			local date = c(current_date)
			local time = c(current_time)
			local datetime `date' `time'
			
			//Indicator calculation - XML
			tempfile xmlout logfile
			log using "`logfile'", text replace name(logall)
			
			//Setup for XML
			//local byvar 
			local countrycode `ccc'
			local pppyear 2011
			local surveyid `surveys'
			local filename `fname'
			local year `yyy'
			
			
			if "`weflist'"=="" local weflist welfare
			if "`weightlist'"=="" local weightlist `theW'
			if "`pppyear'"=="" local pppyear 2011
			if "`plines'"=="" {
				if `pppyear'==2011 local plines 1.9 3.2
				if `pppyear'==2005 local plines 1.25 2.0
			}
			
			
			log off logall

			//new values
			dis %10.0g
			levelsof `cpi', local(newCPIValue)
			levelsof `ppp', local(newPPPValue)
			
			local cpilist  `newCPIValue' 
			local icplist  `newPPPValue' 
						
			display in red "`icplist'"
			display in red "`cpilist'"
			//adjust local
			local weflist = trim("`weflist'")
			local weflist1 : subinstr local weflist "`=char(32)'" ",", all
			local weightlist = trim("`weightlist'")
			if (`: word count `weightlist''>1) & (`: word count `weflist''>1)  & (`: word count `weightlist'' < `: word count `weflist'') {
				dis in red "No balanced pairs of welfare and weight variables"
				exit 198
			}
			if (`: word count `weightlist''==1) & (`: word count `weflist''>1) {
				local weightlist = "`weightlist' " * `: word count `weflist''
			}

			local weightlist = trim("`weightlist'")
			local weightlist1 : subinstr local weightlist "`=char(32)'" ",", all

			local wset
			forv j=1(1)`: word count `weflist'' {
				local wf : word `j' of `weflist'
				local wt : word `j' of `weightlist'
				local wset "`wset' `wf'|`wt'"
			}
			local wset = trim("`wset'")
			local wset : subinstr local wset "`=char(32)'" ",", all			
			
			//reload the data
			use `dataout', clear
			
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
			local nwevar : word count `weflist'
			local nwivar : word count `weightlist'
			local npline : word count `plines'
			local nParamSets = `npline'
			
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

			//invalid group results can be written as "n/a"
			log on logall
			
			local RequestKey task=Povcal&DataSource=InboundDTA&CountryCode=`countrycode'&DataYear=`year'&By=`byvar'&BaseYear=`pppyear'&welfareSet=`wset'`paset'
			dis in yellow "`RequestKey'"
			local APP_ID Stata
			local DATETIME `datetime'
			local IS_INTERPOLATED FALSE
			local USE_MICRODATA TRUE
			//UNIT_OBS: HH or IND
			local UNIT_OBS 
			local COUNTRY_CODE `countrycode'
			local COUNTRY_NAME `ctryname'
			local SURVEY_ID `surveyid'
			local FILENAME `filename'
			local REGION_CODE `reg'
			local DATA_COVERAGE 3
			local DATA_TYPE 0
			local DATA_YEAR `year'
			local REF_YEAR `refyr'
			local CPI_YEAR `refyr'
			local PPP_YEAR `pppyear'
			log off logall
			
			//PRIMUS log 
			tempfile outdata
			tempname outfile
			file open  `outfile' using "`outdata'", read write text
			file write `outfile' `"<PRIMUS_ANALYSIS>"' _n
			file write `outfile' _col(2) `"<Request>"' _n
			file write `outfile' _col(4) `"<RequestKey><![CDATA[`RequestKey']]></RequestKey>"' _n
			file write `outfile' _col(4) `"<welfare>`weflist1'</welfare>"' _n
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
			file write `outfile' _col(4) `"COUNTRY_CODE;`COUNTRY_CODE'"' _n
			file write `outfile' _col(4) `"COUNTRY_NAME;`COUNTRY_NAME'"' _n
			file write `outfile' _col(4) `"SURVEY_ID;`SURVEY_ID'"' _n
			file write `outfile' _col(4) `"FILENAME;`FILENAME'"' _n
			file write `outfile' _col(4) `"REGION_CODE;`REGION_CODE'"' _n
			file write `outfile' _col(4) `"DATA_COVERAGE;`DATA_COVERAGE'"' _n
			file write `outfile' _col(4) `"DATA_TYPE;`DATA_TYPE'"' _n
			file write `outfile' _col(4) `"DATA_YEAR;`DATA_YEAR'"' _n
			file write `outfile' _col(4) `"REF_YEAR;`REF_YEAR'"' _n
			file write `outfile' _col(4) `"CPI_YEAR;`CPI_YEAR'"' _n
			file write `outfile' _col(4) `"PPP_YEAR;`PPP_YEAR'"' _n
			file write `outfile' _col(4) `"]]>"' _n
			file write `outfile' _col(2) `"</Request>"' _n
			file write `outfile' _col(2) `"<Result>"' _n
			
			//List of important Char
			char _dta[uploaddate] `DATETIME'
			char _dta[filename] `FILENAME'
			char _dta[survey_id] `SURVEY_ID'
			char _dta[use_microdata] `USE_MICRODATA'
			char _dta[unit_observation] `UNIT_OBS'
			char _dta[ref_year] `refyr'
			char _dta[data_year] `DATA_YEAR'
			
			//Chars for priceframework
			
			preserve
				tokenize `surveys', parse(_)
				local _milhouse `5'
				if (inlist(upper("`code'"), "CHN", "IDN", "IND")==1) MyPriCeData, code(`natcode') year(`years') survey(`_milhouse') datalevel(N)
				else MyPriCeData, code(`natcode') year(`years') survey(`_milhouse')
							
			restore
			
			local pricevars `r(_pricevars)'
			foreach price of local pricevars{
				char _dta[`price'] `r(_`price')'
			}
			
						
			tempfile data0
			save `data0', replace

			log off logall
			local j = 1
			
			foreach var of local weflist {
				use `data0', clear		
				local wt : word `j' of `weightlist'		
				//welfare and weight
				file write `outfile' _col(4) `"<Welfare var="`var'" weight="`wt'">"' _n
				log on logall
					
				//Byvar
				dis "//Type the below to call your data only if it has already been confirmed and approved"
				dis "datalibweb, country(`ccc') year(`yyy') vera(`veralt_p') verm(`vermast_p') type(`collection') module(gpwg) clear"
				dis "//Type the below to call your data if it has only been confirmed, but not approved"
				dis "datalibweb, country(`ccc') year(`yyy') vera(WRK) verm(`vermast_p') type(`collection') module (gpwg) clear"
				dis "gen double `var'_PPP = `var'/ `cpi' / `icp' /365"
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
					//repeat as needed (different CPI/PPP and povlines)
					//forv j=1(1)`nParamSets' {
					if "`method'"=="CustomCPI" { //CustomCPI on the query
						foreach vicp of local icplist {
							foreach vcpi of local cpilist {	
								foreach pline of local plines {
									use `data2', clear
									//gen `var'_PPP = `var'/cpi`pppyear'/icp`pppyear'/365
									gen double `var'_PPP = `var'/`vcpi'/`vicp'/365
									local METHOD "`method'"
									local PPPValue = `vicp'
									local CPIValue = `vcpi'
									su `var'_PPP [aw=`wt']
									local ReqYearPopulation = `=r(sum_w)'/1000000 
									local MeanPPP = r(mean)
									local PovertyLine_LCU = `=`pline'*`PPPValue'*`CPIValue''
									local PovertyLine_PPP = `pline'
									local PPPadjuster = `PPPValue'*`CPIValue'
									local ByVarShare = (`ReqYearPopulation'/`TotalPopAll')*100
									
									log on logall
									dis "apoverty `var'_PPP [aw=`wt'], line(`pline') all"
									noi: apoverty `var'_PPP [aw=`wt'], line(`pline') all
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
									file write `outfile' _col(8) `"ReqYearPopulation; "' _n
									file write `outfile' _col(8) `"nPoor; "' _n 
									file write `outfile' _col(8) `"ByVarShare;`ByVarShare'"' _n
									file write `outfile' _col(8) `"]]>"' _n
									file write `outfile' _col(6) `"</CALCULATION>"' _n
								} // nparamset pline
							}
						}
					}
					if "`method'"=="EmbeddedCPI" { //CPI PPP in the data
						foreach pline of local plines {
							use `data2', clear
							//check tosee if CPI and PPP are constant within groups
							qui su `cpi'
							if r(sd) ~= 0 {
								dis as error "CPI values should be constant within a group - `byvar2'==`byv'"
								error 198
							}
							qui su `ppp'
							if r(sd) ~= 0 {
								dis as error "ICP/PPP values should be constant within a group - `byvar2'==`byv'"
								error 198
							}
							gen `var'_PPP = `var'/ `cpi' / `ppp' /365
							//gen `var'_PPP = `var'/`cpi'/`icp'/365
							local METHOD "`method'"
							local PPPValue = `icp'[1]
							local CPIValue = `cpi'[1]	
							
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
							if "`method'"=="CustomCPI" {
								file write `outfile' _col(8) `"PPPValue;`PPPValue'"' _n
								file write `outfile' _col(8) `"CPIValue;`CPIValue'"' _n
							}
							if "`method'"=="EmbeddedCPI" {
								file write `outfile' _col(8) `"PPPValue;varies"' _n
								file write `outfile' _col(8) `"CPIValue;varies"' _n
							}							
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
			qui capture copy "`outdata'" "`xmlout'", replace
			if _rc {
				display as error "file can not be saved at this location"
				exit 603
			}
			else {
				noi display in yellow "XML File saved in: `xmlout'"
			}

			
			//Compress the file
			use `data0', clear
			cap drop __0* 
			cap drop __all__
			if "`method'"=="CustomCPI" local vlist min max cpi ppp cpi2005 icp2005 icp2011 cpi2011 icpbase cpiy conversion  ipc05_sedlac ipc_sedlac filename suryear1 suryear2 weightcheck weightcheck2 update upldatetime username year_adj year_alt datasignature lvlvalue lvlvar
			if "`method'"=="EmbeddedCPI" local vlist min max cpi ppp cpiy conversion  ipc05_sedlac ipc_sedlac filename suryear1 suryear2 weightcheck weightcheck2 update upldatetime username year_adj year_alt datasignature lvlvalue lvlvar
			foreach var of local vlist {
				cap drop `var'
			}
			cap ren subnatid1 subnatid
			cap drop region
			
			//need to add in the SurveyID, filename, data level (hh or ind), micro vs grouped, data date
			
			//Variabels go into characteristics
			local constantlist weighttype welfaretype welfshprtype weighttype survey vermast veralt harmonization cpiperiod level ref_year
			foreach var of local constantlist {
				cap des `var'
				if _rc==0 {
					//check if the variables are really constant
					cap confirm numeric variable `var'
					if _rc==0 {
						qui su `var'
						if r(sd)==0 {
							char _dta[`var'] `=`var'[1]'
							cap drop `var'
						}
					}
					else { //string
						qui ta `var'
						if r(r)==1 {
							char _dta[`var'] `=`var'[1]'
							cap drop `var'
						}
					}		
				}
			}
			
			compress
			cap drop cpi*
			cap drop icp*
			cap datasignature set
			if (_rc!=0) datasignature set, reset
			saveold `dataout', replace	
			
			copy `xmlout' 	"C:\Users\\`c(username)'\\Downloads\_XML", replace
			if (`nopovcal'==0){
				if (`gotoprimus'==1){
					//Send the file and log
					//set trace on
					tempfile resultfile
					local plusdir "`c(sysdir_plus)'"
					cap program define _primus, plugin using("`plusdir'\p\Primus`=cond(strpos(`"`=c(machine_type)'"',"64"),64,32)'.dll")			
					cap plugin call _primus , "0" "`xmlout'" "`dataout'" "`surveyid'" "`resultfile'" "3"
					if _rc==0 {
						ereturn local transid "`primusTxId'"
						insheet using "`resultfile'", noname clear
						noi dis
						loc ++aa
						qui putexcel A`aa'=("`surveys'") B`aa'=("Uploaded")
						noi:display in yellow "PRIMUS YES:`ccc':`yyy'"	
						
					}	
					else {
					noi: display as error "Unable to upload data to system"
						loc ++aa
						qui putexcel A`aa'=("`surveys'") B`aa'=("Not uploaded")
						noi: display in yellow "NO:`ccc':`yyy'"	
						error 233093
					}
				}
			}
			else{
				
				saveold "`filepath'//`filename'", replace
				display as error "Your data has been saved to: "
                display as error "`filepath'/`filename' "
				display as error "Please inform the Central Team (mnguyen3@worldbank.org) about this upload."				
			}
		
		
end


program define primuSCompaRe, rclass
version 11.2
syntax, [newy(numlist) natcode(string) year(numlist) reg(string) gpwg_a(string) gpwg_m(string) gpwg_wm(string) hhlev(integer 0)]


if (`hhlev'==0){
	if (`newy'==0){
		if ("`gpwg_wm'"==""){
			preserve 
			noi: dis in red "datalibweb, country(`natcode') year(`year') vera(`gpwg_a') verm(`gpwg_m') type(gmd) mod(gpwg) clear"
				cap datalibweb, country(`natcode') year(`year') vera(`gpwg_a') verm(`gpwg_m') type(gmd) mod(gpwg) clear
				local _dwcall=_rc
				if (`_dwcall'!=0){
					dis as error "I was unable to call: datalibweb, country(`natcode') year(`years')  vera(`gpwg_a') verm(`gpwg_m') type(gmd) type(gpwg) clear "
					exit
				}
				else{
					cap isid hhid
					if (_rc==0) sort hhid
					else{
						cap sort hhid pid
						if _rc!=0 sort hhid
					}	
					cap recast float weight, force
					cap recast float welfare, force
					
					tempfile tocmp
					save `tocmp'			
				}
			restore
			
			cap recast float weight, force
			cap recast float welfare, force

			
			cap cf welfare weight using `tocmp', verbose
			local cfrc = _rc
			if `cfrc'==0{
				local gotoprimus = 0
				dis as error "Your new vintage does not update welfare or weights, data will not be uploaded through Primus"
				exit 
			}
			else{
				noi: display in y "Your new vintage updates welfare or weights, data will be uploaded through Primus"
				local gotoprimus = 1
			}	
		}
		else{ //compare to WRK version
			preserve
				cap datalibweb, country(`natcode') year(`year') vera(WRK) verm(`gpwg_wm') type(gmd) mod(gpwg) clear
				local _dwcall=_rc
				if (`_dwcall'!=0){
					cap datalibweb, country(`natcode') year(`year') vera(WRK) verm(`gpwg_wm') type(gmd) mod(all) clear
					local _dwcall=_rc
				}			
				if (`_dwcall'!=0){
					dis as error "I was unable to call: datalibweb, country(`natcode') year(`years') vera(WRK) verm(`gpwg_wm') type(gmd) mod(gpwg) clear"
					error 356781
					exit
				}
				else{
					cap isid hhid
					if (_rc==0) sort hhid
					else{
						cap sort hhid pid
						if _rc!=0 sort hhid
					}
					cap recast float weight, force
					cap recast float welfare, force

					
					tempfile tocmp
					save `tocmp'			
				}
			restore
			
			cap recast float weight, force
			cap recast float welfare, force

			
			cap cf welfare weight using `tocmp', verbose
			local cfrc = _rc
			if `cfrc'==0{
				if (("`reg'"=="LAC" | (inlist("`natcode'","BGD","LKA","PAK","BTN","MDV","IND")==1)) & `=date(c(current_date),"DMY")'< `=date("28 Feb 2018","DMY")'){
					dis as error "Your new vintage does not update welfare or weights, but for LAC we will allow it...for now"			
					local gotoprimus = 1
					return local toprimus = 1				
				}
				else{ 
					dis as error "Your new vintage does not update welfare or weights, data will not be uploaded through Primus"
					local gotoprimus = 0
					return local toprimus = 0
				}
	
			}
			else{
				noi: display in y "Your new vintage updates welfare or weights, data will be uploaded through Primus"
				local gotoprimus = 1
			}		
		}
		
	}
	else{
		local gotoprimus = 1
	}
}
else{ //WHEN HH LEVEL COMPARISON IS REQUESTED
	if (`newy'==0){
		if ("`gpwg_wm'"==""){
			preserve
				cap datalibweb, country(`natcode') year(`year') vera(`gpwg_a') verm(`gpwg_m') type(gmd) mod(gpwg) clear
				local _dwcall=_rc
				if (`_dwcall'!=0){
					dis as error "I was unable to call: datalibweb, country(`natcode') year(`years')  vera(`gpwg_a') verm(`gpwg_m') type(gmd) type(gpwg) clear "
                    error 356782 
					exit
				}
				else{
					groupfunction, first(welfare) rawsum(weight) by(hhid) 
					cap recast float weight, force
					cap recast float welfare, force
					tempfile tocmp
					save `tocmp'
				}
			restore	
			
			preserve
			groupfunction, first(welfare) rawsum(weight) by(hhid)
			cap recast float weight, force
			cap recast float welfare, force
			cap cf welfare weight using `tocmp', verbose
			local cfrc = _rc
			if `cfrc'==0{
				local gotoprimus = 0
				dis as error "Your new vintage does not update welfare or weights, data will not be uploaded through Primus"
			}
			else{
				noi: display in y "Your new vintage updates welfare or weights, data will be uploaded through Primus"
				local gotoprimus = 1
			}
			restore
		}
	
	}
	else{ //compare to WRK version
		preserve
			cap datalibweb, country(`natcode') year(`years') vera(WRK) verm(`gpwg_wm') type(gmd) mod(gpwg) clear
			local _dwcall=_rc
			if (`_dwcall'!=0){
				cap datalibweb, country(`natcode') year(`years') vera(WRK) verm(`gpwg_wm') type(gmd) mod(all) clear
				local _dwcall=_rc
			}			
			if (`_dwcall'!=0){
				dis as error "I was unable to call: datalibweb, country(`natcode') year(`years') vera(WRK) verm(`gpwg_wm') type(gmd) mod(gpwg) clear"
				error 356783
				exit
			}
			else{
				groupfunction, first(welfare) rawsum(weight) by(hhid)
				cap recast float weight, force
				cap recast float welfare, force
				tempfile tocmp
				save `tocmp'			
			}
		restore
		
		preserve
		groupfunction, first(welfare) rawsum(weight) by(hhid)
		cap recast float weight, force
		cap recast float welfare, force
		cap cf welfare weight using `tocmp', verbose
		local cfrc = _rc
		if `cfrc'==0{
			if (("`reg'"=="LAC" | (inlist("`natcode'","BGD","LKA","PAK","BTN","MDV","IND")==1)) & `=date(c(current_date),"DMY")'< `=date("28 Feb 2018","DMY")'){
				dis as error "Your new vintage does not update welfare or weights, but for LAC we will allow it...for now"			
				local gotoprimus = 1
				return local toprimus = 1				
			}
			else{ 
				dis as error "Your new vintage does not update welfare or weights, data will no be uploaded through Primus"
				local gotoprimus = 0
				return local toprimus = 0
			}
	
		}
		else{
			noi: display in y "Your new vintage updates welfare or weights, data will be uploaded through Primus"
			local gotoprimus = 1
		}
		
		restore
	}
	else{
		local gotoprimus = 1
	}	
}

return local gotoprimus=`gotoprimus'

end

program define MyPriCeData, rclass
version 11.2
syntax, code(string) year(numlist max=1) survey(string) [datalevel(string)]

cap datalibweb, country(support) year(2005) type(gmdraw) filename(Survey_price_framework.dta) surveyid(Support_2005_CPI_v06_M)
if _rc!=0{
	dis as error "Unable to load Survey_price_framework.dta"
	error 123454
	exit
}

keep if upper(code)==upper("`code'") & year==`year' & upper(survname)==upper("`survey'")

if _N!=0{
	if (inlist(upper("`code'"), "CHN", "IDN", "IND")==1){
		if (inlist(upper("`datalevel'"), "N", "U", "R")!=1){
			dis as error "You must specify datalevel for `code'"
			error 12938478
			exit
		}
		else{
			keep if upper(survey_coverage)==upper("`datalevel'")
			if _N==1{
				local pricevars
				foreach x of varlist *{
					levelsof `x', local(`x') 
					local pricevars `pricevars' `x'
				}
				
				return local _pricevars `pricevars'
				foreach x of local pricevars{
					return local _`x' ``x''
				}
			}
			else{
				dis as error "There is a problem in with the Survey price data, it is not unique"
				dis as error "Reach out to central team"
				error 344555
				exit
			}
		}
	}
	else{
		if _N==1{
			local pricevars
			foreach x of varlist *{
				levelsof `x', local(`x') 
				local pricevars `pricevars' `x'
			}
			
			return local _pricevars `pricevars'
			foreach x of local pricevars{
				return local _`x' ``x''
			}
		}
		else{
			dis as error "There is a problem in with the Survey price data, it is not unique"
			dis as error "Reach out to central team"
			error 344555
			exit
		}
	}
		
}
else{
	dis as error "There is no survey price data for your code, year, and survey combination" 
	dis as error "You must submit your data through the survey_price_framework"
	error 4534545
	exit 
}
end
