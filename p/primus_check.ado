cap program drop primus_check
program define primus_check, rclass

	version 11.0
	
	syntax, country(string) verm(string) vera(string) year(numlist int max=1 >1900)  ///
	module(string)
	
	local toup country svy module
	
	foreach x of local toup{
		if ("``x''"!="") local `x' =trim(upper("``x''"))
	}
	
	foreach x of varlist *{
		local tocheck `tocheck' `x'
	}
		
	cap isid hhid
	local hhlev =_rc==0
	if (`hhlev'!=1){
	cap isid hhid pid
		if (_rc==0){
			sort hhid pid	
		}
		else{
			dis as error "Data is not at hh or individual level"
			error 2343
			exit
		}
	}
	else sort hhid
	
	tempfile current
	save `current'
	
	cap datalibweb, country(`country') year(`year') verm(`verm') vera(`vera') module(`module') type(gmd) clear nocpi
	local nogo = _rc
	cap drop cpi*
	cap drop icp*
	cap drop ppp*
	cap drop datalevel
	cap replace countrycode=upper(countrycode)

	if (`nogo'==0){
		cap rename weight weight_h
		
		qui: count
		local NN=r(N)		
					
		foreach x of varlist *{
			qui: count if missing(`x')
			local NNn=r(N)
			if (`NN'!=`NNn') local tocheckn `tocheckn' `x'
		}
			cap isid hhid
			local hhlev =_rc==0
			if (`hhlev'!=1){
			cap isid hhid pid
			local indivlev = _rc==0
				if (`indivlev'==1){
					sort hhid pid	
				}
				else{
					dis as error "Data is not at hh or individual level"
					error 2343
					exit
				}
			}
			else{
				sort hhid
			}
		
		//Check if there are vars in tocheckn not in tocheck
		local notin: list tocheckn - tocheck
		
		if ("`notin'"!=""){
			display as error "Data is different, the following variables are in existing vintage" ///
			_n "that are not in the new data, overwrite is not possible"
			noi dis as error "`notin'"
			error 12111
			exit
		}
		else{
			local check: list tocheckn & tocheck
			local cfrc=0
			foreach bb of local check{
				
				cap cf `bb' using `current', all
				local works = _rc
				if (`works'!=0){
					local diffvars `diffvars' `bb'
				}
				local cfrc = `works' + `cfrc'
				
			}
			if `cfrc'==0{
				return local proceed = 1
			}
			else{
			display as error "The following variables do not match, please check: " ///
			_n "`diffvars'"
				return local proceed = 0
			}			
		}		
	use `current', clear
	}
	else{
		use `current', clear
		display as error "I was unable to call"
		noi dis in yellow "datalibweb, country(`country') year(`year') verm(`verm') vera(`vera') module(`module') type(gmd) clear"
		error 12111
		exit
	}
	
	
end	
