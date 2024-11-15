*! primus_gmd_upload.ado 0.2.1  12Sep2014
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

cap program drop primus_gmd_upload
program define primus_gmd_upload, rclass
	version 11.0
	syntax [if] [in] ,                          ///
        Countrycode(string)                     ///
        Year(numlist >1900 int max=1)           ///
		WELFare(varname)                        ///
        welfaretype(string)                     /// 
        WELFSHprosperity(varname)               ///
        welfshprtype(string)                    /// 
        weight(varname)                         ///
        weighttype(string)                      ///
        HSize(varname)                          ///
        hhid(varname)                           ///
		MODule(string)         					///
		SURvey(string)                          ///
        [                                       ///
		   cpi(varname)                         ///
		   CPIPERiod(string)                    ///
           ppp(varname)                         ///	
		   pid(varname)							///
		   collection(string)                 	///
		   POVWeight(varname)                   ///
           drive(string)                        ///
           SUBnatid1(varname)                   ///
           spdef(varname)                       ///
           Time(string)                         /// 
           welfarenom(varname)                  ///
           welfaredef(varname)                  ///
           welfareother(varname)                ///
           welfareothertype(string)             ///
           age(varname)                         ///
           male(varname)                        ///
           URBan(varname)                       ///
           tfood(varname)                       ///
           tnfood(varname)                      ///
           rent(varname)                        ///
           durgood(varname)                     ///
           health(varname)                      ///          
           VERMast(string)                      ///
           HARmonization(string)                ///
           VERAlt(string)                       ///
           FULLname(string)                     ///
           CONVERfactor(varname)                ///
           OTHERVARiables(varlist)              ///
           STRATa(varname)                      ///
           psu(varname)                         ///
           note(string)                         ///
           SAVEPath(string)                     ///
           ICPbase(integer 2017)                ///
           save13                               ///
           restricted                           ///
           replace                              ///
		   NOPOVcal                             ///		   
           level(varname)                       ///
		   output(string)                       ///
		   welfare_primus(string)				///
		   REFYear(string)                      ///
		   AUTOversion                          ///
		   OVERwrite							///
		   hhlev(integer 0)                     ///
		   pfwid(string)                        ///
        ]
	
	global processid 8
	global folderpath Data\Stata
	*===============================================================================
	//00:Keep Data; and necessary programs
	*===============================================================================
	qui {
		if ("`keepdata'" != "") {
			tempfile _tmp
			save `_tmp', replace
		}

		//Necessary ados
		local vout lstrfun mdesc confirmdir
		foreach vf of local vout {
			cap which `vf'
			if _rc ssc install `vf'
		}
				
		*===============================================================================
		// 01:Error checks
		*===============================================================================
		//Split fullname
		if ("`fullname'"!="") {
			local fullname = trim(upper("`fullname'"))
			
			tokenize `fullname', parse("_")
			local countrycode  = "`1'"
			local year         = "`3'"
			local survey       = "`5"
			local verm 		   = subinstr("`7'","V","",.)
			local vera         = subinstr("`11'","V","",.)
			local collection   = "`15'"
			if ("`17'"!="") local module	= "`17'"			
			local fullname 
		}
		
		//Upper case all necessary inputs
		local uppercase countrycode module survey harmonization collection vermast veralt ///
		fullname welfaretype welfshprtype welfareothertype weighttype
		
		foreach x of local uppercase {
			if ("``x''"!="") local `x' = upper(trim("``x''"))
			local remove1 `remove1' `x'
		}

		//...Check for uniqueness, before anything!
		if ("`pid'"=="") {
			cap isid `hhid'
			if (_rc!=0) {
				dis as error "Data is not unique at `hhid' level, please revise"
				error 459
				exit
			}
		}
		else {
		cap isid `hhid' `pid'
			if (_rc!=0) {
				dis as error "Data is not unique at `hhid' and `pid' level, please revise"
				error 459
				exit
			}	
		}

		// Check if welfare and weights are double
		foreach x of varlist `welfare' `weight' `povweight' {
			cap confirm existence `x'
			if (_rc==0) {
				* Examine precision of variables being uploaded
				local thetype: type `x'
				if ("`thetype'"!="double") & ("`nopovcal'"!=""){ //display error for nopovcal uploads, not dialog box
					display as error "It is preferable that you upload variable `x' with double precision."
				} 
				else {
					capture window stopbox rusure "It is preferable that you upload variable `x' with double precision." ///
					"Would you like to continue as is?"
					local stwrk = _rc==0
					if (`stwrk'==0) { //If user selects "No" to the previous dialog box
						dis as error "Variable `x' must be stored with double precision."
						error 34567 
						exit
					}
				}
				
				qui: sum `x'
				if (r(mean) ==0) {
					dis as error "Variable `x' has mean 0, this should not be the case"
					error 198
					exit
				}
			}
			else {
				dis as error "Variable `x' not found"
				error 198
				exit
			}
		} //basic check welfare weight

		//Remove vars from othervars
		local othervariables : list othervariables - remove1
		local othervariables : list othervariables - welfare
		local othervariables : list othervariables - weight
		local othervariables : list othervariables - povweight

		//Collection
		if ("`collection'"=="") local collection GMD
		local collection =trim(upper("`collection'"))

		if (inlist("`collection'", "GMD", "PCN")==0) {
			dis as error "`collection' is not a valid collection, only GMD or PCN are accepted"
			error 1203934
			exit
		}

		//Specify module and ensure path is there
		if ("`module'"=="") {
			dis as error "You must specify a module, such as GPWG or ALL"
			error 12734764
			exit
		}
		local modulelist ALL GPWG BIN GROUP
		local _modch: list modulelist & module
		if ("`_modch'"=="") {
			dis as error "You have specified an unrecognized module"
			error 1637344
			exit
		}

		//Ensure excel file for file uploads is specified
		if (trim(upper("`module'"))=="ALL"|trim(upper("`module'"))=="GPWG") {
			if ("`output'"=="") {
				display as error "You must specify an excel file for storing upload details"
				error 102939
				exit
			}
			else {
				local _dd=c(current_date)
				putexcel set "`output'", sh("`_dd'", replace) modify
				putexcel A1=("Unique_ID") B1=("Category") C1=("`_dd'")	
			}
		}

		*===============================================================================
		// 02:Check for valid inputs
		*===============================================================================
		local flagerr = 0

		//Country code checks
		local countrycode = trim(upper("`countrycode'"))
		if (length("`countrycode'")!=3){
			display as error "country code must be 3 digit iso country code"
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
			display as error "Country code not recognized, please provide a valid country code"
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

		if (`_aok'==0){
			dis as error "The survey name provided does not exist, talk to central team"
			error 3699
			exit
		}

		//Welfare type
		local flag2 = inlist("`welfaretype'", "INC", "CONS", "EXP")
		if (`flag2' != 1) {
			noi di as err "eligible welfare types: INC=INCOME; CONS=CONSUMPTION; EXP=EXPENDITURE"
			local flagerr = 1
		}

		//Welfare shared prosperity type
		local flag2 = inlist("`welfshprtype'", "INC", "CONS", "EXP")
		if (`flag2' != 1) {
			noi di as err "eligible shared prosperity welfare types: INC=INCOME; CONS=CONSUMPTION; EXP=EXPENDITURE"
			local flagerr = 1
		}

		//Welfare other type!
		if ("`welfareother'" != "") {
			local flag2 = inlist("`welfareothertype'", "INC", "CONS", "EXP")
			if (`flag2' != 1) {
				noi di as err "eligible other welfare types: INC=INCOME; CONS=CONSUMPTION; EXP=EXPENDITURE"
				local flagerr = 1
			}
		}

		//Weight type
		local flag2 = inlist("`weighttype'", "FW", "PW", "AW", "IW")
		if (`flag2' != 1) {
			noi di as err "eligible weight types: FW=Frequency weights; PW=Probability weights; AW=Analytical weights; IW=Importance weights"
			local flagerr = 1
		}

		//Spatial Deflation
		if ("`spdef'" != "" & "`subnatid1'" == "") { 
			noi di as err "Spatial deflator can only be entered if data contain subnational ID. Please check."
			local flagerr = 1
		}

		*===============================================================================
		// 03:Program assigned inputs
		*===============================================================================
		//Region codes
		preserve
			dlw_countryname 
			levelsof region if countrycode=="`countrycode'", local(reg) clean
			local good1: list sizeof reg
			if (`good1'!=1) {
				dis as error "Country code not assigned to a region"
				local flagerr = 1
			}
		restore

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

		//Output
		if ("`output'"=="") local output "c:\Users\\`c(username)'\Downloads\" 
	
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
			if (upper("`module'")=="GPWG" | upper("`module'")=="ALL") {
				local nm = lower("`module'")
				primus_vintage, country(`countrycode') year(`year') max svy(`survey')
				
				if ("`vermast'"=="") local vermast = "`r(maxm)'"
				local veralt  = "`r(maxa)'" 
			}
			else { 
				primus_vintage, country(`countrycode') year(`year') module(`module')
				if ("`vermast'"=="") local vermast = "`r(newm)'"
				local veralt  = "`r(newa)'" 
			}
			restore
		}

		//Version requirements once we have assigned these
		if length("`vermast'")!=2 & "`fullname'" == "" { 
			noi di as err "master version needs to have two digits"
			local flagerr = 1
			local _vm=0
		}
		else local _vm=1

		if length("`veralt'")!=2 & "`fullname'" == "" {
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
			restore
			
			if ("`_v_a'"=="`veralt'" & "`_v_m'"=="`vermast'" & "`newyear'"!="1") {
				if ("`overwrite'"=="") {
					noi dis as error "You may not overwrite an existing vintage"
					local docheck=0
					local flagerr = 1
					error 100000
				}
				else local docheck=1
			}
			else {
				local docheck = 0
			}	
		} //vm va

		//Full name and components
		if ("`fullname'" == "") & (("`survey'" == "") | ("`vermast'" == "")) & (("`harmonization'" == "") | ("`veralt'" == "")) {
			noi di as err "Either full name or name components have to be specified. Please check."
			local flagerr = 1
		}

		*===============================================================================
		// 6) Variables to be kept for collections, Select, rename, label Variables 
		// and value labels
		*===============================================================================
		if ("`collection'" == "GMD" & "`module'"=="GPWG") {

			local gpwgvars `welfare' `weight' `age' `male' `urban' `hhid' `hsize' `cpi' ///
				`ppp' `strata' `psu' `time' `welfshprosperity' `othervariables' ///
				`subnatid1' `spdef' `converfactor' `povweight'
			
			local varstodrop: list varsindata - gpwgvars
			if ("`varstodrop'" != "") noi disp in red _n "Caution: " in y ///
				"the following variables in your dataset wont be included" ///
				" in the `collection' collection:" _n _col(6) in w "`varstodrop'"
				
			keep `welfare' `weight' `age' `male' `urban' `hhid' `hsize' `cpi' ///
				`ppp' `strata' `psu' `time' `welfshprosperity' `othervariables' ///
				`subnatid1' `spdef' `converfactor' `povweight' `pid'
		}

		if ("`collection'"=="PCN") {
			keep `hsize' `urban' `weight' `povweight' `hhid' `welfare' `cpi' `ppp'
		}

		**************************************************
		/* select and rename variables */
		**************************************************
		cap clonevar pp_welfare                =`welfare' 
		cap clonevar pp_welfarenom             =`welfarenom' 
		cap clonevar pp_welfaredef             =`welfaredef' 
		cap clonevar pp_welfareother           =`welfareother'
		cap clonevar pp_weight_h               =`weight' 
		cap clonevar pp_weight_p               =`povweight'
		cap clonevar pp_age                    =`age'
		cap clonevar pp_male                   =`male'
		cap clonevar pp_urban                  =`urban'
		cap clonevar pp_hsize                  =`hsize'
		cap clonevar pp_hhid                   =`hhid'
		cap clonevar pp_cpi                    =`cpi'
		cap clonevar pp_ppp                    =`ppp'
		cap clonevar pp_strata                 =`strata'
		cap clonevar pp_psu                    =`psu'
		cap clonevar pp_welfshprosperity       =`welfshprosperity'
		cap clonevar pp_subnatid1              =`subnatid1'
		cap clonevar pp_spdef                  =`spdef'
		cap clonevar pp_converfactor           =`converfactor'
		
		local myvardrop `welfare' `welfarenom' `welfaredef' `welfareother' ///
			`weight' `age' `male' `urban' `hsize' `hhid' `cpi'    ///
			`ppp' `strata' `psu' `welfshprosperity' `subnatid1'   ///
			`spdef' `converfactor'
			
		foreach V of local myvardrop {
			cap drop `V'
		}
		cap drop `povweight'
		renpfix pp_
		
		cap drop countrycode
		cap drop year
		
		cap gen countrycode = upper("`countrycode'")
		cap gen year = `year'
		cap gen welfaretype = upper("`welfaretype'")
		cap gen welfshprtype = upper("`welfshprtype'")
		
		if ("`welfareothertype'" != "") cap gen welfareothertype = upper("`welfareothertype'")
		
		cap gen weighttype	= upper("`weighttype'")
		cap gen cpiperiod	= "`cpiperiod'"
		
		cap gen survey = "`survey'"
		cap gen vermast = "`vermast'"
		cap gen veralt = "`veralt'"
		cap gen harmonization = "`harmonization'"
		
		* ICPbase
		if !inlist(`icpbase', 2005, 2011, 2017, 2021) {
			noi disp in red "ICPbase variable must be either 2005 or 2011 or 2017. Default 2017."
			local flagerr = 1
		}
		else {
			cap gen icpbase = `icpbase'
			label var icpbase "ICP reference year `icpbase'"
		}
		
		** other variables
		if ("`age'" != "") | ("`male'" != "") {
			local surveylevel "individual"
			order countrycode year hhid welfaretype welfare //age male urban cpi* ppp weight
		}
		else {
			local surveylevel "household"
			order countrycode year hhid welfaretype welfare //urban cpi* ppp weight 
		}
		
		**************************************************
		/* label variables and values for GPWG databse */
		**************************************************	
		cap label var countrycode "WDI three letter country codes "
		cap label var year "4 digit year of the survey"
		cap label var spdef "Spatial deflator (if one is used)"
		cap label var weight_h "Weight"
		cap label var weight_p "Weight for poverty calculation"
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

		**************************************************
		/* Value labels values */
		**************************************************
		cap levelsof male, local(ckmale)
		if regexm("0 1","`ckmale'") { 
			cap lab define male 1 Male 0 Female, modify
			cap lab values male male
		}
		else {
			if "`male'"!="" {
				noi di as err "male variable [`male'] has values other than 0 and 1 (i.e. male=1, female=0), please check."
				local flagerr = 1
			}
		}
		
		cap levelsof urban, local(ckurban)
		if regexm("0 1","`ckurban'") { 
			cap lab define urban 1 Urban 0 Rural, modify
			cap lab values urban urban
		}
		else {
				if "`urban'"!="" {
					noi di as err "urban variable [`urban'] has values other than 0 and 1 (i.e. urban=1, rural=0), please check."
					local flagerr = 1
				}
			}

		*==============================================================================
		 //7: Variables Checks
		*===============================================================================
		//GPWG Variable CHECKS
		if (("`collection'" == "GMD"|"`collection'" == "PCN") & "`module'"=="GPWG") {
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
				dis as err "The following variables should be numeric:" ///
				_n _col(6) in w "`notnum'"
				local flagerr=1
			}
			
			if "`ppp'"!="" & "`countrycode'"!="IND" & "`countrycode'"!="IDN" & "`countrycode'"!="CHN"{
				qui sum ppp		
				if (r(Var)>1e-6) {
					noi di as err "PPP conversion factor is not constant within survey, please check."
					local flagerr = 1
				}
			}
			
			if ("`cpi'" != "" & "`countrycode'"!="IND" & "`countrycode'"!="IDN" & "`countrycode'"!="CHN") {
				qui sum cpi
				if (r(Var)>1e-6) {
					noi di as err "CPI is not constant within survey, please specify period of reference variable."
				local flagerr = 1
				}
			}

			if ("`subnatid1'" != "") {	
				capture confirm string var subnatid1
				if (_rc) { 
					noi di as err "Subnatid1 was not correctly specified. Please, make sure that the following naming convention (string) is used: # – String"
					local flagerr =1
				}
				cap levelsof subnatid1, local(mysub)
				local mysub: list sizeof mysub		
				if (`mysub'==1) {
					noi dis as err "Subnatid1 is constant for all entries, please revise"
					local flagerr =1
				}	
			}
				
			if ("`spdef'" != "") {
				qui sum spdef
				local var2spdef = r(Var)
				if (`var2spdef' == 0) /*& (("`bypass'" != ""))*/ {
					noi di as err "Spatial deflator is constant for all entries. Please check."
					local flagerr = 1
				}
			}
			
			/*household weights */
			if ("`weight'"!="" & "`countrycode'"!="PSE" & "`countrycode'"!="MAR") {
				sort hhid
				qui by hhid: egen double min=min(weight_h)
				qui by hhid: egen double max=max(weight_h)
				gen weightcheck2= min==max 
				qui: sum weightcheck2
				local wvalid = r(mean)
				if `wvalid'!=0 {	
					noi di in red "Caution: "in y "Household weights are not unique within households. Please check."
				}
				drop min max weightcheck2
			}
				
			if ("`povweight'"!="" & "`countrycode'"!="PSE" & "`countrycode'"!="MAR") {
				sort hhid
				qui by hhid: egen double min=min(weight_p)
				qui by hhid: egen double max=max(weight_p)
				gen weightcheck2= min==max 
				qui: sum weightcheck2
				local wvalid = r(mean)
				if `wvalid'!=0 {		
					noi di in red "Caution: "in y "Household weights for poverty are not unique within households. Please check."
				}
				drop min max weightcheck2
			}
		} //GPWG var checks

		//GMD ALL Checks
		if (trim(upper("`module'"))=="ALL" & "`collection'"=="GMD") {
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
				sort countrycode year hhid pid
				duplicates report countrycode year hhid pid
				cap assert r(unique_value) == r(N)
				if ("`pid'" != "") {
					if _rc {
						noi disp as err "variable pid is not unique for combination household/individual." ///
						_n "{stata duplicates example countrycode year hhid pid: click here}" ///
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
						noi di as err "Subnatid`z' was not correctly specified. Please, make sure that the following naming convention (string) is used: # – String"
						local flagerr =1
					}
					cap levelsof subnatid`z', local(mysub)
					local mysub1: list sizeof mysub		
					if (`mysub1'==1 & `"`mysub'"'!="`"."'") {
						noi dis as err "Subnatid`z' is constant for all entries, please revise"
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
						noi disp as err "relationharm should not have more than 6 numeric values." ///
							" It has " wordcount(r(levels)) " values"
						local flagerr = 1
					}
				
					if wordcount(r(levels)) < 6 {
						noi disp as err "Caution:" in y " relationharm has less than 6 values." ///
							" It has " wordcount(r(levels)) " values"
					}
							
					** check only one head per household
					sort countrycode year hhid relationharm
					tempvar nhh 		// number of head of the household
					bysort hhid: egen `nhh' = total(relationharm == 1)
					cap assert `nhh' == 1 | `nhh' == 0
					if _rc {
						noi disp as err "There is more than one head per household. " ///
							"Please check variable relationharm"
						local flagerr = 1
					}
				
					** check values
					cap assert inrange(relationharm, 1,6) | relationharm == .
					if _rc {
						noi disp as err "relationharm should not have values outside the range {1,6}"
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
							noi disp as err "marital should not have more than 5 numeric values." ///
								" It has " wordcount(r(levels)) " values"
							local flagerr = 1
						}
					
						cap if wordcount(r(levels)) < 5 {
							noi disp as err "Caution:" in y " marital has less than 5 values." 
						}
					
						** check values
						cap assert inrange(marital, 1,5) | marital == .
						if _rc {
							noi disp as err "marital should not have values outside the range {1,5}"
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
						noi disp as err "lstatus should not have more than 3 numeric values." ///
							" It has " wordcount(r(levels)) " values"
						local flagerr = 1
					}
					** check values
					cap assert inrange(lstatus, 1,3) | lstatus == .
					if _rc {
						noi disp as err "lstatus should not have values outside the range {1,3}"
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
						noi disp as err "empstat should not have more than 5 numeric values." ///
							" It has " wordcount(r(levels)) " values"
						local flagerr = 1
					}
				
					if wordcount(r(levels)) < 5 {
						noi disp as err "Caution:" in y" empstat has less than 5 values." 
					}
				
					** check values
					cap assert inrange(empstat, 1,5) | missing(empstat)
					if _rc {
						noi disp as err "empstat should not have values outside the range {1,5}"
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
						noi disp as err "industrycat10 should not have more than 10 numeric values." ///
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
						noi disp as err "industrycat4 should not have more than 4 numeric values." ///
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
						noi disp as err "educy (years of education) cannot be greater or equal than age." ///
							r(N) " Cases"
						local flagerr = 1
					}
				
					count if ( age - educy <= 2 )
					if (r(N)>0 & r(N)<.) {
						noi disp as err "Caution:" in y " For " r(N) " obs., educy (years of education) is" ///
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
						noi disp as err "educat4 should not have more than 4 numeric values." ///
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
						noi disp as err "educat5 should not have more than 5 numeric values." ///
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
						noi disp as err "educat7 should not have more than 7 numeric values." ///
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
							noi disp as err "`asset' can only take either 0 or 1 as values. Please check"
							local flagerr = 1
						}
					} 
				}
			} //lassets
				
			/* relationcs */
			if (`checkrelationcs' == 1) {
				* This is region specific... 
			}
			
			/* Age */
			* GMD 2.0 allows age to be a decimal for individuals <5 yrs
			if (`checkage' == 1) {
			cap assert missing(age)
				if _rc!=0 {		
					* integers for individuals older than 5 yrs
					cap assert age == int(age) if age>5
					if _rc {
						noi disp as err "age must be integers only for age >5 yrs. Please check!"
						local flagerr = 1
					}
					
					cap assert age >= 0 		// check age is positive or missing
					if _rc {
						noi disp as err "age cannot have negative values"
						local flagerr = 1
					}
				}
			}

			/* Survey */
			if (`checksurvey' == 1 & !missing(survey)) {
				cap assert missing(survey)
				if _rc!=0 {
					cap assert regexm(survey,`"[a-zA-Z]+"')
					if _rc {
						noi disp as err "survey must contain only alphabetic values"
						local flagerr = 1
					}
				}
			}
			
			**************************************************
			/* label variables and values for GMD database */
			**************************************************	
			cap label var countrycode "WDI three letter country codes "
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
			
			** Keep variables
			if (trim(upper("`module'"))=="ALL") {
				local gmdvars `welfare' `weight' `age' `male' `urban' `hhid' `hsize' ///
				`strata' `psu' `time' `welfshprosperity' `othervariables' ///
				`subnatid1' `spdef' `converfactor' `checkvars' `povweight'
					
				local varstodrop: list varsindata - gmdvars
				if ("`varstodrop'" != "") noi disp in red _n "Caution: " in y ///
				"the following variables in your dataset wont be included" ///
				" in the `collection' collection:" _n _col(6) in w "`varstodrop'"
						
				local constantlist weighttype welfaretype welfshprtype weighttype survey vermast ///
				veralt harmonization cpiperiod level ref_year
				
				keep `welfare' weight_h weight_p `age' `male' `urban' `hhid' `hsize' ///
					`strata' `psu' `time' `welfshprosperity' `othervariables' ///
					`subnatid1' `spdef' `converfactor' `checkvars' 
			}	
		}  //END OF GMD VAR CHECKS

		if (`flagerr' == 1) {
			noi disp _n(2) as err "There is at least one irreconcilable error in the " ///
				"dataset. Data not uploaded."
			error 1
			exit
		}

		*===============================================================================
		// 8) Map temporary directories and file name
		*===============================================================================

		*===============================================================================
		// 9) Return list and Data Signature
		*===============================================================================
		**************************************************
		/* Return list */
		**************************************************
		if ("`harmonization'" == "NA") {
			local filename = "`countrycode'_`year'_`survey'_V`vermast'_M_V`veralt'_A_`collection'_`module'"
			local foldername = "`countrycode'_`year'_`survey'_V`vermast'_M_V`veralt'_A_`collection'"
		}
		else {
			local filename = "`countrycode'_`year'_`survey'_V`vermast'_M_V`veralt'_A_`collection'_`module'"
			local foldername = "`countrycode'_`year'_`survey'_V`vermast'_M_V`veralt'_A_`collection'"
		}
		local filepath = "`path'\\`countrycode'\\`countrycode'_`year'_`survey'\\`countrycode'_`year'_`survey'_V`vermast'_M_V`veralt'_A_`collection'"
		
		return local foldername = "`foldername'"
		return local filepath = "`filepath'"
		return local filename = "`filename'"
		 
		**************************************************
		/* Data signature */
		**************************************************		
		preserve
			cap drop ppp
			cap drop cpi
			cap drop cpiperiod
			datasignature		
			local datasig = r(datasignature)	
		restore	
		
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

		note `if'
		note `in'
		note `note'

		// extract notes as local to save in external files
		local i=1
		while `i'!=. {
			if `"`_dta[note`i']'"' != "" {
				di `"`i'. `_dta[note`i']'"'
				local i = `i' + 1
			}
			else {
				local i = .
			}
		}
		cap drop __00*

		*===============================================================================
		// 11) Check Vintage
		*===============================================================================
		noi:dis in green "Foldername: `foldername'"
		noi:dis in green "Filename: `filename'"
		
		if (`docheck'==1 & "`collection'"=="GMD") {

			noi: primus_check, country(`countrycode') verm(`vermast') vera(`veralt') year(`year') module(`module')
			local replaceok = r(proceed)
			
			if (`replaceok'==0) {
				dis as error "You requested to overwrite data, but your data is different from the one in the system"
				error 378665
				exit
			}
			else {
				local nopovcal=1
			}
		}
		if ("`nopovcal'"!="") local nopovcal=1
		else local nopovcal=0
		
		tempfile dataoutfin
		save `dataoutfin', replace
		
		//Price database!
		cap datalibweb, country(Support) year(2005) type(GMDRAW) surveyid(`pfwid') filename(Final_CPI_PPP_to_be_used.dta) clear files
		di r(cmdline)
		local priceproblem=_rc
		if (`priceproblem'==111|`priceproblem'==0){
			cap keep if upper(code)==upper("`countrycode'")
			if (_rc) keep if upper(countrycode)==upper("`countrycode'")
			tempfile cpi_
			save `cpi_'
		}
		else{
			dis as error "Unable to load CPI ICP database"
			error 128384
			exit
		}
	
		//merge CPI in from the system
		use `dataoutfin', clear
		merge m:1 code year survname using `cpi_', keepus(cpi`pppyear' icp`pppyear')
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
		primus_xml, welflist(`welfare') weightlist(`povweight') xmlout(`xmlout1') ///
			country(`countrycode') year(`year') surveyid(`foldername') pppyear(`icpbase') ///
			refyear(`refyear') filename(`filename') ///
			pfwid(`pfwid') byvar(`byvar')
 
		*===============================================================================
		// 12) Send to Primus Up command
		*===============================================================================
		if ("`module'"=="ALL"|"`module'"=="GPWG") {
			//upload xml			
			primus upload, processid(${processid}) surveyid(`foldername') type(harmonized) infile(`xmlout1') xmlbl new
			local prmTransID = r(prmTransID)
			
			//upload data
			primus upload, processid(${processid}) surveyid(`foldername') type(harmonized) folderpath(${folderpath}) infile(`dataoutfin') tranxID(`prmTransID')
			
			/*
			noi: primus_up, nopovcal(`nopovcal') output(`output') natcode(`countrycode') year(`year')  ///
			weflist(`welfare_primus') vermast_p(`vermast') veralt_p(`veralt') surveys(`foldername') ///
			ctryname(`primus_cname') filename(`filename') reg(`reg') refyear(`refyear') ///
			no_pweight(`no_pweight') povweight(weight_p) filepath(`filepath2') filename(`filename') hhlev(`hhlev') byvar(`byvar') collection(`collection')
			
			return local primusid = "`e(transid)'"
			*/
		}
		
		*===============================================================================
		// 13) Log file 
		*===============================================================================	
		*cd "`cpath'"			// restore original current directory
	}		// end of Quietly

	if ("`keepdata'" != "") {
		use `_tmp', clear
	}
end //END OF PRIMUS UPLOAD!!