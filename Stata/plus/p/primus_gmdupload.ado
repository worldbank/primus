*! primus_gmdupload.ado 0.2.1  12Sep2014
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

cap program drop primus_gmdupload
program define primus_gmdupload, rclass
	version 11.0
	syntax [if] [in] ,                          ///
        Countrycode(string) Year(numlist >1900 int max=1)         ///                  
		WELFare(varname) welfaretype(string)                     /// 
        WELFSHprosperity(varname)  welfshprtype(string)          ///
		weight(varname) weighttype(string)                       ///
		HSize(varname) hhid(varname)                            ///
		MODule(string) SURvey(string)  pfwid(string)        	///
        [                                       ///		   
		   CPIPERiod(string)                    ///           
		   pid(varname)							///		                
		   POVWeight(varname) spdef(varname)    ///                          
           welfarenom(varname)  welfaredef(varname) welfareother(varname) welfareothertype(string)              ///                            
           SUBnatid1(varname)   age(varname)  male(varname) URBan(varname) STRATa(varname) psu(varname)                       ///
           collection(string)  HARmonization(string) VERMast(string) VERAlt(string)                      ///              
           FULLsurveyid(string)                     ///           
           OTHERVARiables(varlist)              ///              
           SAVEPath(string)                     ///
           ICPbase(integer 2017)                ///           
           replace                              ///
		   NOPOVcal                             ///		   
           level(varname)                       ///
		   output(string)                       ///
		   welfare_primus(string)				///
		   REFYear(string)                      ///
		   AUTOversion                          ///
		   OVERwrite							///
		   hhlev(integer 0)                     ///		                        
		   default PROCessid(string) ///
        ]
	
	if "`processid'"=="" {
		if ${webserver}==3 global processid 8
		if ${webserver}==4 global processid 16	
	}
	else {
		global processid `processid'
	}
	
	global folderpath Data\Harmonized
	
	/*
	- Survey ID check
	- Version check and assigned the appropriate versioning
	- Check on the specified options 
	- Basic data checks
	- check on the variables based on the option module(ALL) vs module(GPWG)
	- XML filename
	- Split
	- Upload GPWG
	- Upload ALL
	*/
	*qui {
		*===============================================================================
			// 01:Error checks	
		*===============================================================================	
		if ("`vermast'"~="" & "`veralt'"=="") | ("`vermast'"=="" & "`veralt'"~="") {
			noi dis "Both master and adaptation versions are needed."
			error 198
		}
		
		//Split fullname
		if ("`fullsurveyid'"!="") {
			local  n_underscore = length("`fullsurveyid'") - length(subinstr("`fullsurveyid'", "_", "", .))
			if (`n_underscore'==7|`n_underscore'==8) {
				noi dis "Master and adaptation versions from the `fullsurveyid' will be used."
				local fullsurveyid = trim(upper("`fullsurveyid'"))		
				tokenize `fullsurveyid', parse("_")
				local countrycode  = "`1'"
				local year         = "`3'"
				local survey       = "`5'"
				local vermast 	   = subinstr("`7'","V","",.)
				local veralt       = subinstr("`11'","V","",.)
				local collection   = "`15'"
				if ("`17'"!="") local module	= "`17'"			
				local fullfullsurveyidname 
			}
			else {
				noi dis "The format of full SurveyID (`fullsurveyid') is not correct. It should be Code_YYYY_SurveyAcronym_VXX_M_VYY_A_GMD or Code_YYYY_SurveyAcronym_VXX_M_VYY_A_GMD_Module"
				error 198
			}
		}
		
		//Upper case all necessary inputs
		local uppercase countrycode module survey harmonization collection vermast veralt welfaretype welfshprtype welfareothertype weighttype	
		foreach x of local uppercase {
			if ("``x''"!="") local `x' = upper(trim("``x''"))
			local remove1 `remove1' `x'
		}
		
		//Check for uniqueness, before anything!
		if ("`pid'"=="") {
			cap isid `hhid'
			if (_rc!=0) {
				noi dis as error "Data is not unique at `hhid' level, please revise"
				error `=_rc'								
			}
		}
		else {
			cap isid `hhid' `pid'
			if (_rc!=0) {
				noi dis as error "Data is not unique at `hhid' and `pid' level, please revise"
				error 459
				exit
			}	
		}
		
		//Remove vars from othervars
		local othervariables : list othervariables - remove1
		local othervariables : list othervariables - welfare
		local othervariables : list othervariables - weight
		local othervariables : list othervariables - povweight
		
		//Collection
		if ("`collection'"=="") local collection GMD
		else {
			local collection = trim(upper("`collection'"))
			if "`collection'"!="GMD" {
				noi dis as error "`collection' is not a valid collection, only the GMD collection is accepted"
				error 198				
			}
		}
		
		//Specify module 
		if ("`module'"=="") {
			noi dis as error "You must specify a module, such as ALL, GPWG, BIN, GROUP, ASPIRE, L, HIST"
			error 198			
		}
		local modulelist ALL GPWG BIN GROUP ASPIRE HIST L
		local _modch: list modulelist & module
		if ("`_modch'"=="") {
			noi dis as error "You have specified an unrecognized module. Available modules are: ALL GPWG BIN GROUP ASPIRE HIST L"
			error 198			
		}
		
		*===============================================================================
			// 02:Check for valid inputs		
		*===============================================================================
		local flagerr = 0
		
		* ICPbase
		if !inlist(`icpbase', 2005, 2011, 2017, 2021) {
			noi disp in red "ICPbase variable must be either 2005 or 2011 or 2017 or 2021. Default 2017."
			local flagerr = 1
		}
		else {
			cap gen icpbase = `icpbase'
			label var icpbase "ICP reference year `icpbase'"
		}
		cap drop cpi`icpbase' 
		cap drop icp`icpbase'	
		
		//Country code checks
		local countrycode = trim(upper("`countrycode'"))
		if (length("`countrycode'")!=3){
			noi display as error "country code must be 3-letter ISO/WB country code"
			local flagerr=1
		}

		local _thenats AFG ALB DZA ASM AND AGO ATG ARB ARG ARM ABW AUS AUT AZE BHS BHR ///
		BGD BRB BLR BEL BLZ BEN BMU BTN BOL BIH BWA BRA BRN BGR BFA BDI KHM CMR CAN CPV ///
		CSS CYM CAF CUW TCD CHI CHL CHN COL COM COD COG CRI CIV HRV CUB CUW CYP CZE DNK ///
		DJI DMA DOM ECU EGY SLV GNQ ERI EST ETH EUU FRO FJI FIN FRA PYF GAB GMB GEO DEU ///
		GHA GRC GRL GRD GUM GTM GIN GNB GUY HTI HND HKG HUN ISL IND IDN IRN IRQ IRL IMN ///
		ISR ITA JAM JPN JOR KAZ KEN KIR PRK KOR KSV KWT KGZ LAO LVA LBN LSO LBR LBY LIE ///
		LTU LUX MAC MKD MDG MWI MYS MDV MLI MLT MHL MRT MUS MEX FSM MDA MCO MNG MNE MAR ///
		MOZ MMR NAM NPL NLD NCL NZL NIC NER NGA NRU MNP NOR INX OED OMN OSS PSS PAK PLW PAN ///
		PNG PRY PER PHL POL PRT PRI QAT ROU RUS RWA WSM SMR STP SAU SEN SRB SYC SLE SGP ///
		SXM SVK SVN SST SLB SOM ZAF SSD ESP LKA KNA LCA MAF VCT SDN SUR SWZ SWE CHE SYR ///
		TJK TZA THA TLS TGO TON TTO TUN TUR TKM TCA TUV UGA UKR ARE GBR USA URY UZB VUT ///
		VEN VNM VIR PSE YEM ZMB ZWE SXM MAF

		local _natcheck: list _thenats & countrycode
		if ("`_natcheck'"=="") { 
			noi display as error "Country code not recognized, please provide a valid country code"
			local flagerr=1
		}
		
		// Year
		if length("`year'")!=4 {
			noi di as err "year variable needs to be specified with four digits"
			local flagerr = 1
		}
		
		//Check provided survey name is valid!
		preserve
		primus_vintage, country(`countrycode') svyname
		local svnamestocheck = r(thesurveys)
		local _aok: list survey & svnamestocheck
		local _aok = "`_aok'"!=""
		restore

		if (`_aok'==0) {
			noi dis as error "The survey name provided does not exist in the DLW system. Please make sure the survey name is in DLW, either in raw data or regional harmonzied collections. Available survey names are `svnamestocheck'."
			error 3699			
		}
		
		//Welfare type
		local flag2 = inlist("`welfaretype'", "INC", "CONS", "EXP")
		if (`flag2' != 1) {
			noi di as err "Eligible welfare types: INC=INCOME; CONS=CONSUMPTION; EXP=EXPENDITURE"
			local flagerr = 1
		}

		//Welfare shared prosperity type
		local flag2 = inlist("`welfshprtype'", "INC", "CONS", "EXP")
		if (`flag2' != 1) {
			noi di as err "Eligible shared prosperity welfare types: INC=INCOME; CONS=CONSUMPTION; EXP=EXPENDITURE"
			local flagerr = 1
		}

		//Welfare other type!
		if ("`welfareother'" != "") {
			local flag2 = inlist("`welfareothertype'", "INC", "CONS", "EXP")
			if (`flag2' != 1) {
				noi di as err "Eligible other welfare types: INC=INCOME; CONS=CONSUMPTION; EXP=EXPENDITURE"
				local flagerr = 1
			}
		}

		//Weight type
		local flag2 = inlist("`weighttype'", "FW", "PW", "AW", "IW")
		if (`flag2' != 1) {
			noi di as err "Eligible weight types: FW=Frequency weights; PW=Probability weights; AW=Analytical weights; IW=Importance weights"
			local flagerr = 1
		}

		//Spatial Deflation
		if ("`spdef'" != "" & "`subnatid1'" == "") { 
			noi di as err "Spatial deflator can only be entered if data contain one subnational ID variable. Please check."
			local flagerr = 1
		}
		
		*===============================================================================
			// 03:Program assigned inputs	
		*===============================================================================
		//Region codes
		/*
		preserve
			dlw_countryname 
			levelsof region if countrycode=="`countrycode'", local(reg) clean
			local good1: list sizeof reg
			if (`good1'!=1) {
				dis as error "Country code not assigned to a region"
				local flagerr = 1
			}
		restore
		*/
		
		//By var
		local byvar `level'

		//Pov weight --> If missing -> Weight
		if ("`povweight'"=="") {
			local povweight `weight'
			local no_pweight = 1
		}
		else local no_pweight = 0

		//Country name
		preserve
			dlw_countryname
			levelsof countryname if countrycode=="`countrycode'", local(primus_cname)
		restore

		//Local with all variables in data
		local varsindata
		foreach x of varlist * {
			local varsindata `varsindata' `x'
		}

		// If level is not specified
		if "`level'"=="" {
			cap drop _all_
			gen _all_ = 1
			local level2 _all_
		}
		else {
			gen temp = `level'
			local level2 temp
		}

		//Weflare primus, if missing
		if ("`welfare_primus'"=="") local welfare_primus welfare

		//Ref Year, if missing
		if ("`refyear'"=="") local refyear = `year'
		
		*===============================================================================
			// 04:Version control 	
		*===============================================================================	
		//Autoversion
		if ("`autoversion'"!="" & "`collection'"=="GMD") {
			preserve
			primus_vintage, country(`countrycode') year(`year') svy(`survey') module(`module')
			if ("`vermast'"=="") local vermast = "`r(newm)'"
			local veralt  = "`r(newa)'" 
			local _gpwg_a = r(gpwg_a)
			local _gpwg_m = r(gpwg_m)
			/*
			if (upper("`module'")=="GPWG" | upper("`module'")=="ALL") {
				local nm = lower("`module'")
				*primus_vintage, country(`countrycode') year(`year') max svy(`survey') module(`module')
				*if ("`vermast'"=="") local vermast = "`r(maxm)'"
				*local veralt  = "`r(maxa)'" 
				
				primus_vintage, country(`countrycode') year(`year') svy(`survey') module(`module')
				if ("`vermast'"=="") local vermast = "`r(newm)'"
				local veralt  = "`r(newa)'" 
			}
			else { 
				primus_vintage, country(`countrycode') year(`year') module(`module')
				if ("`vermast'"=="") local vermast = "`r(newm)'"
				local veralt  = "`r(newa)'" 
			}
			*/
			restore
		}
		
		//Version requirements once we have assigned these
		if length("`vermast'")!=2 & "`fullsurveyid'" == "" { 
			noi di as err "master version needs to have two digits"
			local flagerr = 1
			local _vm=0
		}
		else local _vm=1

		if length("`veralt'")!=2 & "`fullsurveyid'" == "" {
			noi di as err "harmonization version needs to have two digits"
			local flagerr = 1
			local _va=0
		}
		else local _va = 1
		
		//Check if vintages exists
		if (`_vm'==1 & `_va'==1) {
			preserve
				primus_vintage, country(`countrycode') year(`year') svy(`survey')
				local nm = lower(trim("`module'"))
				local newyear=r(newy)
				local _v_a = r(`nm'_a)
				local _v_m = r(`nm'_m)
				local _v_a = subinstr("`_v_a'", "V","",.)
				local _v_a = subinstr("`_v_a'", ".","",.)
				local _v_m = subinstr("`_v_m'", "V","",.)
				local _v_m = subinstr("`_v_m'", ".","",.)
				local _gpwg_a = r(gpwg_a)
				local _gpwg_m = r(gpwg_m)
			restore
			
			if ("`_v_a'"=="`veralt'" & "`_v_m'"=="`vermast'" & "`newyear'"!="1") {
				if ("`overwrite'"=="") {
					noi dis as error "You may not overwrite an existing vintage"
					local docheck=0
					local flagerr = 1
					error 1
				}
				else local docheck=1
			}
			else {
				local docheck = 0
			}	
		} //vm va
		
		//Full name and components
		if ("`fullsurveyid'" == "") & (("`survey'" == "") | ("`vermast'" == "")) & (("`harmonization'" == "") | ("`veralt'" == "")) {
			noi di as err "Either full name or name components have to be specified. Please check."
			local flagerr = 1
		}
		
		//Variable checks
		if "`module'"=="GPWG" {
			_primus_gmdcheck_gpwg, varsindata(`varsindata')
			local nerr = r(nerror)
			local flagerr = r(flagerr)
		}	
		else if "`module'"=="ALL" {
			_primus_gmdcheck_all, varsindata(`varsindata')
			local nerr = r(nerror)
			local flagerr = r(flagerr)
		}		
		else if "`module'"=="BIN" {
			_primus_gmdcheck_bin, varsindata(`varsindata')
			local nerr = r(nerror)
			local flagerr = r(flagerr)
		}	
		else if "`module'"=="GROUP" {
			_primus_gmdcheck_group, varsindata(`varsindata')
			local nerr = r(nerror)
			local flagerr = r(flagerr)
		}
		else {
			noi dis "No check is done for this module `module'"
		}
		
		if (`flagerr' == 1) {
			noi disp _n(2) as err "There is at least one irreconcilable error (`nerr' errors) in the dataset. Data not uploaded."
			error 1
			exit
		}
		
		*===============================================================================
			// 9) Return list and Data Signature		
		*===============================================================================
		local filename = "`countrycode'_`year'_`survey'_V`vermast'_M_V`veralt'_A_`collection'_`module'.dta"
		if "`module'"=="ALL" local filenameGPWG = "`countrycode'_`year'_`survey'_V`vermast'_M_V`veralt'_A_`collection'_GPWG.dta"
		local foldername = "`countrycode'_`year'_`survey'_V`vermast'_M_V`veralt'_A_`collection'"
		return local foldername = "`foldername'"
		return local filename = "`filename'"
		datasignature		
		local datasig = r(datasignature)
		
		*===============================================================================
			// 10) Notes
		*===============================================================================
		local date : di %tdN/D/CY date("$S_DATE", "DMY")
		local username = c(username)

		if ("`harmonization'"=="NA") {
			note: `date', $S_TIME, `reg', `countrycode', `year', `survey', `harmonization', `username', `countrycode'_`year'_`survey'_V`vermast'_M_`collection', `replace', `surveylevel', `restricted', `savepath' `datasig'
		}
		else {
			note: `date', $S_TIME, `reg', `countrycode', `year', `survey', `harmonization', `username', `countrycode'_`year'_`survey'_V`vermast'_M_V`veralt'_A_`harmonization'_`collection', `replace', `surveylevel', `restricted', `savepath' `datasig'
		}

		*note `if'
		*note `in'
		*note `note'

		// extract notes as local to save in external files
		/*
		local i=1
		qui while `i'!=. {
			if `"`_dta[note`i']'"' != "" {
				di `"`i'. `_dta[note`i']'"'
				local i = `i' + 1
			}
			else {
				local i = .
			}
		}
		*/
		cap drop __00*
		tempfile dataoutfin
		save `dataoutfin', replace
		
		//Price database!
		*cap datalibweb, country(Support) year(2005) type(GMDRAW) surveyid(`pfwid') filename(Final_CPI_PPP_to_be_used.dta) clear files
		*di r(cmdline)
		*local priceproblem=_rc
		*if (`priceproblem'==0) {
		cap datalibweb, country(support) year(2005) type(GMDRAW) surveyid(`pfwid') filename(Final_CPI_PPP_to_be_used.dta) clear files
		if (_rc==0) {
			cap keep if upper(code)==upper("`countrycode'")
			*if (_rc) keep if upper(countrycode)==upper("`countrycode'")
			tempfile cpi_
			save `cpi_'
		}
		else {
			noi dis as error "Unable to load CPI ICP database"
			error `=_rc'
			exit
		}
		
		//merge CPI in from the system
		use `dataoutfin', clear
		qui if strpos("`survey''","EU-SILC")>0 replace year = year - 1				//EUSILC year
		qui if "`=upper("`countrycode'")'"=="CHN" | "`=upper("`countrycode'")'"=="IND"  gen datalevel = urban						
		else gen datalevel = 2	
		gen survname = "`survey'"
		merge m:1 code year datalevel survname using `cpi_', gen(_mcpi) keepus(cpi`icpbase' icp`icpbase')
		qui drop if _mcpi==2		
		qui drop _mcpi
		cap drop datalevel 
		cap drop ppp_note
		qui if strpos("$surveyid","EU-SILC")>0 replace year = year + 1				//EUSILC year
		save `dataoutfin', replace

		*===============================================================================
			// 12) XML preperation 	
		*===============================================================================
			
		//load survey metadata
		primus_pfwdata, code(`countrycode') year(`year') survey(`survey') pfwid(`pfwid')	
		local pricevars `r(_pricevars)'
		
		use `dataoutfin', clear
		foreach price of local pricevars {
			char _dta[`price'] `r(_`price')'
			local `price' `r(_`price')'
		}
		save `dataoutfin', replace
		
		//xml prep
		tempfile xmlout1
		local pathxml "`xmlout1'"		
		local lastslash = strrpos("`pathxml'", "\") 				
		local dirpath = substr("`pathxml'", 1, `lastslash')
			
		primus_xml, welflist(`welfare') weightlist(`povweight') xmlout(`xmlout1') ///
			country(`countrycode') year(`year') surveyid(`foldername') pppyear(`icpbase') ///
			refyear(`refyear') filename(`filename') ///
			pfwid(`pfwid') byvar(`byvar')
		
		copy `xmlout1' "`dirpath'\\`foldername'.xml", replace
		
		*===============================================================================
			// 12) Send to Primus Up command
		*===============================================================================
		
		//upload xml			
		noi dis `"primus upload, processid(${processid}) surveyid(`foldername') type(harmonized) infile("`dirpath'\\`foldername'.xml") xmlbl new"'
		primus upload, processid(${processid}) surveyid(`foldername') type(harmonized) infile("`dirpath'\\`foldername'.xml") xmlbl new
		local prmTransID = r(prmTransId)
		
		rm "`dirpath'\\`foldername'.xml"
		
		//prep path/filename to be uploaded
		tempfile upload1
		
		use `dataoutfin', clear	
		char _dta[filename] `filename'
		char _dta[tranxid] `prmTransID'
		saveold "`dirpath'\\`filename'", replace
			
		if "`module'"~="ALL" {
			//upload data the module defined (GPWG, BIN, GROUP)
			noi dis `"primus upload, processid(${processid}) surveyid(`foldername') type(harmonized) folderpath(${folderpath}) infile("`dirpath'\\`filename'") tranxID(`prmTransID')"'
			primus upload, processid(${processid}) surveyid(`foldername') type(harmonized) folderpath(${folderpath}) infile("`dirpath'\\`filename'") tranxid(`prmTransID')
			return list
			rm "`dirpath'\\`filename'"
		}
		else { //when it is ALL
			//upload ALL
			primus upload, processid(${processid}) surveyid(`foldername') type(harmonized) folderpath(${folderpath}) infile("`dirpath'\\`filename'") tranxid(`prmTransID')
			noi return list
			rm "`dirpath'\\`filename'"
			
			*local _gpwg_a = r(gpwg_a)
			*local _gpwg_m = r(gpwg_m)
			if ("`overwrite'"=="") {
				//Split, save the file, and upload
				use `dataoutfin', clear		
				cap ren gaul_adm1 gaul_adm1_code
				cap ren gaul_adm2 gaul_adm2_code
				cap ren gaul_adm3 gaul_adm3_code	
				local check age male urban hsize welfarenom welfareother welfareothertype welfaredef welfshprosperity gaul_adm1_code gaul_adm2_code gaul_adm3_code gaul_adm1 gaul_adm2 gaul_adm3 subnatid subnatid1 subnatid2 subnatid3 subnatidsurvey
				local oklist
				foreach var of local check {
					cap des `var'
					if _rc==0 local oklist "`oklist' `var'"
				}
				cap drop weight
				cap des weight_p
				if _rc==0 ren weight_p weight
				keep code year hhid pid welfare welfare* weight `oklist' 					
				char _dta[filename] `filenameGPWG'
				char _dta[tranxid] `prmTransID'
				
				saveold "`dirpath'\\`filenameGPWG'", replace
				
				primus upload, processid(${processid}) surveyid(`foldername') type(harmonized) folderpath(${folderpath}) infile("`dirpath'\\`filenameGPWG'") tranxid(`prmTransID')
				noi return list
				rm "`dirpath'\\`filenameGPWG'"
			}
		}
	*} //qui
end

//Subprogram on checking contents of variables
cap program drop _primus_gmdcheck_gpwg
program define _primus_gmdcheck_gpwg, rclass
	syntax [if] [in] , [varsindata(string) ]
	local cnt = 0
	
	local checkvars age male urban hsize welfarenom welfareother welfareothertype welfaredef welfshprosperity gaul_adm1_code gaul_adm2_code gaul_adm3_code gaul_adm1 gaul_adm2 gaul_adm3 subnatid1 subnatid2 subnatid3 subnatidsurvey
					
	noi disp "" _n				
	foreach checkvar of local checkvars {
		cap confirm var `checkvar'
		if _rc {
			noi disp as err "Caution:" in y " variable" in w " `checkvar' " in y "not found in dataset"
			*gen `checkvar' = .
			local check`checkvar' = 0
		}
		else {
			local check`checkvar' = 1
		}
	} // end of checkvars loop
	noi disp "" _n
	
	**************************************************
		/* Value labels values */
	**************************************************
	//male
	if (`checkmale' == 1) {
		cap levelsof male, local(ckmale)
		if regexm("0 1","`ckmale'") { 
			cap lab define male 1 Male 0 Female, modify
			cap lab values male male
		}
		else {
			local cnt = `cnt' + 1
			noi di as err "Error `cnt': male variable [`male'] has values other than 0 and 1 (i.e. male=1, female=0), please check."
			local flagerr = 1			
		}
	}
	
	//urban
	if (`checkurban' == 1) {
		cap levelsof urban, local(ckurban)
		if regexm("0 1","`ckurban'") { 
			cap lab define urban 1 Urban 0 Rural, modify
			cap lab values urban urban
		}
		else {
			local cnt = `cnt' + 1
			noi di as err "Error `cnt': urban variable [`urban'] has values other than 0 and 1 (i.e. urban=1, rural=0), please check."
			local flagerr = 1
		}
	}
	
	//Numeric variables
	local nums welfare weight age hsize
	foreach x of local nums {
		cap confirm var ``x''
		local is = _rc==0
		if (`is'==1) {
			cap confirm numeric variable ``x'', exact
			local is1 = _rc==0
			if (`is1'==0)	local notnum `notnum' ``x''		
		}
	}
	
	if ("`notnum'"!="") {
		local cnt = `cnt' + 1
		dis as err "Error `cnt': The following variables should be numeric:" _n _col(6) in w "`notnum'"
		local flagerr=1
	}
	
	//Subnat id checks...need to add shapefile codes
	forval z=1/3 {			
		if (`checksubnatid`z''==1) {	
			capture confirm string var subnatid`z'
			if (_rc) { 
				local cnt = `cnt' + 1
				noi di as err "Error `cnt': Subnatid`z' was not correctly specified. Please, make sure that the following naming convention (string) is used: # – String"
				local flagerr =1
			}
			cap levelsof subnatid`z', local(mysub)
			local mysub1: list sizeof mysub		
			if (`mysub1'==1 & `"`mysub'"'!="`"."'") {
				local cnt = `cnt' + 1
				noi dis as err "Error `cnt': Subnatid`z' is constant for all entries, please revise"
				local flagerr =1
			}				
		}			
	}

	/* Age */
	* GMD 2.0 allows age to be a decimal for individuals <5 yrs
	if (`checkage' == 1) {
		cap assert missing(age)
		if _rc!=0 {		
			* integers for individuals older than 5 yrs
			cap assert age == int(age) if age>5
			if _rc {
				local cnt = `cnt' + 1
				noi disp as err "Error `cnt': age must be integers only for age >5 yrs. Please check!"
				local flagerr = 1
			}
			
			cap assert age >= 0 		// check age is positive or missing
			if _rc {
				local cnt = `cnt' + 1
				noi disp as err "Error `cnt': age cannot have negative values"
				local flagerr = 1
			}
		}
	}
	
	cap label var countrycode "WDI three letter country codes "
	cap label var year "4 digit year of the survey"
	cap label var spdef "Spatial deflator (if one is used)"	
	cap label var weight "Weight for poverty calculation"
	cap label var weighttype "Weight type (frequency, probability, analytical, importance)"	
	cap label var cpiperiod "Periodicity of CPI (year, year&month, year&quarter, weighted)"	
	cap label var survey "Type of survey"
	cap label var vermast "Version number of master data file"
	cap label var veralt "Version number of adaptation to the master data file"
	cap label var harmonization "Type of harmonization"
	cap label var converfactor "Conversion factor"
	cap label var subnatid1 "Subnational ID - highest level"
	cap label var subnatid2 "Subnational ID - second highest level"
	cap label var subnatid3 "Subnational ID - third highest level"
	cap label var subnatidsurvey "Survey representation of geographical units"
	cap label var strata "Strata"
	cap label var psu "PSU"
	cap label var welfare "Welfare aggregate used for estimating international poverty (provided to PovcalNet)"
	cap label var welfarenom "Welfare aggregate in nominal terms"
	cap label var welfaredef "Welfare aggregate spatially deflated"
	cap label var welfaretype "Type of welfare measure (income, consumption or expenditure) for welfare, welfarenom, welfaredef"
	cap label var welfshprosperity "Welfare aggregate for shared prosperity (if different from poverty)"
	cap label var welfshprtype "Welfare type for shared prosperity indicator (income, consumption or expenditure)"
	cap label var welfareother "Welfare aggregate if different welfare type is used from welfare, welfarenom, welfaredef"
	cap label var welfareothertype "Type of welfare measure (income, consumption or expenditure) for welfareother"
	cap label var hsize "Household size"
	cap label var hhid "Household ID"	
	cap label var pid "Individual identifier"
	cap label var urban "Urban (1) or rural (0)"
	cap label var age "Age of individual (continuous)"
	cap label var agecat "Age of individual (categorical)"
	cap label var male "Sex of household member (male=1)"
	
	local return nerror `cnt'
	local return flagerr `flagerr'
end

cap program drop _primus_gmdcheck_all
program define _primus_gmdcheck_all, rclass
	syntax [if] [in] , [varsindata(string) ]
	local cnt = 0
	
	local checkvars spdef converfactor subnatid1 subnatid2 subnatid3 ///
					strata psu welfarenom welfaredef welfshprosperity welfshprtype ///
					welfareother welfareothertype pid agecat relationharm relationcs ///
					marital lstatus minlaborage empstat industrycat10 industrycat4 school ///
					literacy educy educat4 educat5 educat7 landphone cellphone computer ///
					electricity primarycomp countrycode year welfaretype weighttype age ///
					survey vermast veralt harmonization cpiperiod cpi ppp icpbase ///
					imp_wat_rec imp_san_rec landphone cellphone computer electricity
					
	noi disp "" _n
				
	foreach checkvar of local checkvars {
		cap confirm var `checkvar'
		if _rc {
			noi disp as err "Caution:" in y " variable" in w " `checkvar' " ///
			in y "not found in dataset"
			gen `checkvar' = .
			local check`checkvar' = 0
		}
		else {
			local check`checkvar' = 1
		}
	} // end of checkvars loop
	noi disp "" _n
	
	/*pid*/
	if (`checkpid' == 1 & !missing(pid)) {
		sort code year hhid pid
		duplicates report code year hhid pid
		cap assert r(unique_value) == r(N)
		if ("`pid'" != "") {
			if _rc {
				local cnt = `cnt' + 1
				noi disp as err "Error `cnt': variable pid is not unique for combination household/individual." ///
				_n "{stata duplicates example code year hhid pid: click here}" ///
				" to see examples of duplicated obs."
				local flagerr = 1
			}
		}
	} // end of pid 
	
	//Subnat id checks...need to add shapefile codes
	forval z=1/3 {			
		if (`checksubnatid`z''==1) {	
			capture confirm string var subnatid`z'
			if (_rc) { 
				local cnt = `cnt' + 1
				noi di as err "Error `cnt': Subnatid`z' was not correctly specified. Please, make sure that the following naming convention (string) is used: # – String"
				local flagerr =1
			}
			cap levelsof subnatid`z', local(mysub)
			local mysub1: list sizeof mysub		
			if (`mysub1'==1 & `"`mysub'"'!="`"."'") {
				local cnt = `cnt' + 1
				noi dis as err "Error `cnt': Subnatid`z' is constant for all entries, please revise"
				local flagerr =1
			}				
		}			
	}	
	
	//relationharm
	if (`checkrelationharm' == 1) {
		cap assert missing(relationharm)
		if _rc!=0 {
			levelsof relationharm 
			if wordcount(r(levels)) > 6 {
				local cnt = `cnt' + 1
				noi disp as err "Error `cnt': relationharm should not have more than 6 numeric values." ///
					" It has " wordcount(r(levels)) " values"
				local flagerr = 1
			}
		
			if wordcount(r(levels)) < 6 {
				noi disp as err "Caution:" in y " relationharm has less than 6 values." ///
					" It has " wordcount(r(levels)) " values"
			}
					
			** check only one head per household
			sort code year hhid relationharm
			tempvar nhh 		// number of head of the household
			bysort hhid: egen `nhh' = total(relationharm == 1)
			cap assert `nhh' == 1 | `nhh' == 0
			if _rc {
				local cnt = `cnt' + 1
				noi disp as err "Error `cnt': There is more than one head per household. " ///
					"Please check variable relationharm"
				local flagerr = 1
			}
		
			** check values
			cap assert inrange(relationharm, 1,6) | relationharm == .
			if _rc {
				local cnt = `cnt' + 1
				noi disp as err "Error `cnt': relationharm should not have values outside the range {1,6}"
				local flagerr = 1
			}
		}
	}
	
	//Marital
	if (`checkmarital' == 1) {
		cap assert missing(marital)
			if _rc!=0 {
				levelsof marital
				if wordcount(r(levels)) > 5 {
					local cnt = `cnt' + 1
					noi disp as err "Error `cnt': marital should not have more than 5 numeric values." ///
						" It has " wordcount(r(levels)) " values"
					local flagerr = 1
				}
			
				cap if wordcount(r(levels)) < 5 {
					noi disp as err "Caution:" in y " marital has less than 5 values." 
				}
			
				** check values
				cap assert inrange(marital, 1,5) | marital == .
				if _rc {
					local cnt = `cnt' + 1
					noi disp as err "Error `cnt': marital should not have values outside the range {1,5}"
					local flagerr = 1
			}
		}
	} // end of Marital
	
	//lstatus
	if (`checklstatus' == 1) {
	cap assert missing(lstatus)
		if _rc!=0 {
			levelsof lstatus	
			if wordcount(r(levels)) > 3 {
				local cnt = `cnt' + 1
				noi disp as err "Error `cnt': lstatus should not have more than 3 numeric values." ///
					" It has " wordcount(r(levels)) " values"
				local flagerr = 1
			}
			** check values
			cap assert inrange(lstatus, 1,3) | lstatus == .
			if _rc {
				local cnt = `cnt' + 1
				noi disp as err "Error `cnt': lstatus should not have values outside the range {1,3}"
				local flagerr = 1
			}
		
			if ("`lstatus'" != "" & "`minlaborage'" != "") {
				count if (age < `minlaborage' & lstatus == 1)
				if r(N) > 0 & r(N) < . {
					noi disp as error "Caution:" in y " you have " in w r(N) in y ///
						" underaged individuals (less than `minlaborage' years old) who are employed"
				}
			}
		} //rc 
	} //checklstatus
	
	/*empstat */
	if (`checkempstat' == 1) {	
		cap assert missing(empstat)
		if _rc!=0 {
			levelsof empstat
			if wordcount(r(levels)) > 5 {
				local cnt = `cnt' + 1
				noi disp as err "Error `cnt': empstat should not have more than 5 numeric values." ///
					" It has " wordcount(r(levels)) " values"
				local flagerr = 1
			}
		
			if wordcount(r(levels)) < 5 {
				noi disp as err "Caution:" in y" empstat has less than 5 values." 
			}
		
			** check values
			cap assert inrange(empstat, 1,5) | missing(empstat)
			if _rc {
				local cnt = `cnt' + 1
				noi disp as err "Error `cnt': empstat should not have values outside the range {1,5}"
				local flagerr = 1
			}
		
			** Consistency with other variables. 
			count if inlist(empstat,3,4) & age < minlaborage
			if (r(N)>0 & r(N)<.) {
				noi disp as err "Caution: " in y "There are " r(N) " underaged individuals (less than minlaborage) who" ///
					" are either employers or self-employed. Please check if this is correct"
			}
		}
	}
	
	/*industrycat10 */
	if (`checkindustrycat10' == 1) {
		cap assert missing(industrycat10)
		if _rc!=0 {
			levelsof industrycat10
			if wordcount(r(levels)) > 10 {
				local cnt = `cnt' + 1
				noi disp as err "Error `cnt': industrycat10 should not have more than 10 numeric values." ///
					" It has " wordcount(r(levels)) " values"
				local flagerr = 1
			}
		}
	}

	/*industrycat4 */
	if (`checkindustrycat4' == 1) {
	cap assert missing(industrycat4)
		if _rc!=0 {
			levelsof industrycat4
			if wordcount(r(levels)) > 4 {
				local cnt = `cnt' + 1
				noi disp as err "Error `cnt': industrycat4 should not have more than 4 numeric values." ///
					" It has " wordcount(r(levels)) " values"
				local flagerr = 1
			}
		}
	}

	/*educy */
	if (`checkeducy' == 1) {
		cap assert missing(educy)
		if _rc!=0 {			
			count if (educy >= age & educy <. & educy != 0 ) 
			if (r(N)>0 & r(N)<.) {
				local cnt = `cnt' + 1
				noi disp as err "Error `cnt': educy (years of education) cannot be greater or equal than age." ///
					r(N) " Cases"
				local flagerr = 1
			}
		
			count if ( age - educy <= 2 )
			if (r(N)>0 & r(N)<.) {
				local cnt = `cnt' + 1
				noi disp as err "Error `cnt': Caution:" in y " For " r(N) " obs., educy (years of education) is" ///
				" two or less years smaller than current age. Check if this is correct." 
			}
		}
	}

	/*educat4 */
	if (`checkeducat4' == 1) {
		cap assert missing(educat4)
		if _rc!=0 {
			levelsof educat4
			if wordcount(r(levels)) > 4 {
				local cnt = `cnt' + 1
				noi disp as err "Error `cnt': educat4 should not have more than 4 numeric values." ///
					" It has " wordcount(r(levels)) " values"
				local flagerr = 1
			}
		}
	}

	/*educat5 */
	if (`checkeducat5' == 1) {
		cap assert missing(educat5)
		if _rc!=0 {
			levelsof educat5
			if wordcount(r(levels)) > 5 {
				local cnt = `cnt' + 1
				noi disp as err "Error `cnt': educat5 should not have more than 5 numeric values." ///
					" It has " wordcount(r(levels)) " values"
				local flagerr = 1
			}
		}
	}

	/*educat7 */
	if (`checkeducat7' == 1) {
		cap assert missing(educat7)
		if _rc!=0 {
			levelsof educat7
			if wordcount(r(levels)) > 7 {
				local cnt = `cnt' + 1
				noi disp as err "Error `cnt': educat7 should not have more than 7 numeric values." ///
					" It has " wordcount(r(levels)) " values"
				local flagerr = 1
			}
		}
	}

	/*Assets or check 0 and 1*/
	local lassets school literacy landphone cellphone computer electricity primarycomp imp_wat_rec imp_san_rec 
	foreach asset of local lassets {
		if (`check`asset'' == 1) {
			cap assert missing(`asset')
			if _rc!=0 {
				cap assert inlist(`asset',0,1) | `asset' == .
				if _rc {
					local cnt = `cnt' + 1
					noi disp as err "Error `cnt': `asset' can only take either 0 or 1 as values. Please check"
					local flagerr = 1
				}
			} 
		}
	} //lassets
		
	/* Age */
	* GMD 2.0 allows age to be a decimal for individuals <5 yrs
	if (`checkage' == 1) {
		cap assert missing(age)
		if _rc!=0 {		
			* integers for individuals older than 5 yrs
			cap assert age == int(age) if age>5
			if _rc {
				local cnt = `cnt' + 1
				noi disp as err "Error `cnt': age must be integers only for age >5 yrs. Please check!"
				local flagerr = 1
			}
			
			cap assert age >= 0 		// check age is positive or missing
			if _rc {
				local cnt = `cnt' + 1
				noi disp as err "Error `cnt': age cannot have negative values"
				local flagerr = 1
			}
		}
	}
	
	cap label var countrycode "WDI three letter country codes "
	cap label var code "WDI three letter country codes "
	cap label var year "4 digit year of the survey"
	cap label var spdef "Spatial deflator (if one is used)"
	cap label var weight_h "Individual weights"
	cap label var weight_p "Poverty specific weights"
	cap label var weighttype "Weight type (frequency, probability, analytical, importance)"
	cap label var cpi "CPI ratio value of survey (rebased to `icpbase' on base 1)"
	cap label var cpiperiod "Periodicity of CPI (year, year&month, year&quarter, weighted)"
	cap label var ppp "PPP conversion factor. (`icpbase')"
	cap label var survey "Type of survey"
	cap label var vermast "Version number of master data file"
	cap label var veralt "Version number of adaptation to the master data file"
	cap label var harmonization "Type of harmonization"
	cap label var converfactor "Conversion factor"
	cap label var subnatid1 "Subnational ID - highest level"
	cap label var subnatid2 "Subnational ID - second highest level"
	cap label var subnatid3 "Subnational ID - third highest level"
	cap label var subnatidsurvey "Survey representation of geographical units"
	cap label var strata "Strata"
	cap label var psu "PSU"
	cap label var welfare "Welfare aggregate used for estimating international poverty (provided to PovcalNet)"
	cap label var welfarenom "Welfare aggregate in nominal terms"
	cap label var welfaredef "Welfare aggregate spatially deflated"
	cap label var welfaretype "Type of welfare measure (income, consumption or expenditure) for welfare, welfarenom, welfaredef"
	cap label var welfshprosperity "Welfare aggregate for shared prosperity (if different from poverty)"
	cap label var welfshprtype "Welfare type for shared prosperity indicator (income, consumption or expenditure)"
	cap label var welfareother "Welfare aggregate if different welfare type is used from welfare, welfarenom, welfaredef"
	cap label var welfareothertype "Type of welfare measure (income, consumption or expenditure) for welfareother"
	cap label var hsize "Household size"
	cap label var hhid "Household ID"
	cap label var pid "Individual identifier"
	cap label var urban "Urban (1) or rural (0)"
	cap label var age "Age of individual (continuous)"
	cap label var agecat "Age of individual (categorical)"
	cap label var male "Sex of household member (male=1)"
	cap label var relationharm "Relationship to head of household harmonized across all regions"
	cap label var relationcs "Relationship to head of household country/region specific"
	cap label var marital "Marital status"
	cap label var lstatus "Labor Force Status"
	cap label var minlaborage "Minimum age for employment"
	cap label var empstat "Type of employment"
	cap label var industrycat4 "Sector/industry of employment (4 categories)"
	cap label var industrycat10 "Sector/industry of employment (10 categories)"
	cap label var school "Currently in school"
	cap label var literacy "Individual can read and write"
	cap label var educy "Years of education"
	cap label var educat4 "Level of education 4 categories"
	cap label var educat5 "Level of education 5 categories"
	cap label var educat7 "Level of education 7 categories"
	cap label var landphone "Own Landline (fixed) phone"
	cap label var cellphone "Own mobile phone (at least one)"
	cap label var computer "Own Computer"
	cap label var electricity "Access to electricity"
	cap label var primarycomp "Primary school completion"
	
	local return nerror `cnt'
	local return flagerr `flagerr'
end

cap program drop _primus_gmdcheck_bin
program define _primus_gmdcheck_bin, rclass
	syntax [if] [in] , [varsindata(string) ]
	local cnt = 0
	
	local checkvars code year bins welfare weight share
					
	noi disp "" _n				
	foreach checkvar of local checkvars {
		cap confirm var `checkvar'
		if _rc {
			noi disp as err "Caution:" in y " variable" in w " `checkvar' " in y "not found in dataset"
			*gen `checkvar' = .
			local check`checkvar' = 0
		}
		else {
			local check`checkvar' = 1
		}
	} // end of checkvars loop
	noi disp "" _n
	
	//Numeric variables
	local nums year bins welfare weight share
	foreach x of local nums {
		cap confirm var ``x''
		local is = _rc==0
		if (`is'==1) {
			cap confirm numeric variable ``x'', exact
			local is1 = _rc==0
			if (`is1'==0)	local notnum `notnum' ``x''		
		}
	}
	
	if ("`notnum'"!="") {
		local cnt = `cnt' + 1
		dis as err "Error `cnt': The following variables should be numeric:" _n _col(6) in w "`notnum'"
		local flagerr=1
	}
	
	cap label var code "WDI three letter country codes "
	cap label var year "4 digit year of the survey or reference year"
	cap label var bins "Data bins"
	cap label var welfare "Annual per capita welfare with the THEN currency"
	cap label var weight "Weight"
	cap label var share "Bin share"
	
	local return nerror `cnt'
	local return flagerr `flagerr'
end

cap program drop _primus_gmdcheck_group
program define _primus_gmdcheck_group, rclass
	syntax [if] [in] , [varsindata(string) ]
	local cnt = 0
	
	local checkvars welfare weight gd_type welfare_type code year
					
	noi disp "" _n				
	foreach checkvar of local checkvars {
		cap confirm var `checkvar'
		if _rc {
			noi disp as err "Caution:" in y " variable" in w " `checkvar' " in y "not found in dataset"
			*gen `checkvar' = .
			local check`checkvar' = 0
		}
		else {
			local check`checkvar' = 1
		}
	} // end of checkvars loop
	noi disp "" _n
	
	//Numeric variables
	local nums year welfare weight 
	foreach x of local nums {
		cap confirm var ``x''
		local is = _rc==0
		if (`is'==1) {
			cap confirm numeric variable ``x'', exact
			local is1 = _rc==0
			if (`is1'==0)	local notnum `notnum' ``x''		
		}
	}
	
	if ("`notnum'"!="") {
		local cnt = `cnt' + 1
		dis as err "Error `cnt': The following variables should be numeric:" _n _col(6) in w "`notnum'"
		local flagerr=1
	}
	
	cap label var code "WDI three letter country codes "
	cap label var year "4 digit year of the survey or reference year"
	cap label var gd_type "Group data type"
	cap label var welfare_type "Welfare type"
	cap label var welfare "Annual per capita welfare with the THEN currency"
	cap label var weight "Weight"
	
	local return nerror `cnt'
	local return flagerr `flagerr'
end