{smcl}
{* *! version 0.0.1 19Jan2018}{...}
{cmd:help primus_upload}
{hline}

{title:Title}

{p2colset 5 24 26 2}{...}
{p2col :}{cmd:primus_upload} {hline 1} Submits GMD collection files
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:primus_upload}
{ifin}
{cmd:,} 
{opt c:ountrycode(string)} {opt y:ear(string)} {opt welf:are(varname)} welfaretype(string) {opt welfsh:prosperity(varname)} welfshprtype(string) weight(varname) weighttype(string) {opt hs:ize(varname)} hhid(varname)  {opt mod:ule(string)} {opt sur:vey(string)} [{it:options}]

{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:primus_upload} deposits data files for the Global Monitoring Database (GMD) to calculate poverty statistics through Primus. Users must be have access rights to the server for this command to work.

{marker options}{...}
{title:Options}

{dlgtab:Optional}


{synopt:{opth povw:eight(varname)}}Weights to be used for poverty calculation, if left empty, the variable specified in the weight option will be used for poverty calculations {p_end}
{synopt:{opth drive(string)}}Drive to which user has mapped the team's disk where data is stored{p_end}
{synopt:{opth sub:natid1(varname)}}Variable indicating regions for highest level of representativeness of survey{p_end}
{synopt:{opth spdef(varname)}}Variable containing spatial adjustment factor{p_end}
{synopt:{opth t:ime(varname)}}Time variable indicating ??? {p_end}
{synopt:{opth welfarenom(varname)}}Variable containing nominal welfare{p_end}
{synopt:{opth welfaredef(varname)}}Variable containing deflated welfare{p_end}
{synopt:{opth welfareother(varname)}}Variable containing other welfare type{p_end}
{synopt:{opth welfareothertype(string)}}Detail on nature of other welfare variable included{p_end}
{synopt:{opth age(varname)}}Variable containing age variable{p_end}
{synopt:{opth male(varname)}}Variable containing male indicator{p_end}
{synopt:{opth urb:an(varname)}}Variable containing urban location{p_end}
{synopt:{opth tfood(varname)}}Variable containing total food expenditure{p_end}
{synopt:{opth tnfood(varname)}}Variable containing total non-food expenfiture{p_end}
{synopt:{opth rent(varname)}}Variable containing rent expenditure{p_end}
{synopt:{opth durgood(varname)}}Variable containing durable good expenditure{p_end}
{synopt:{opth health(varname)}}Variable containing health expenditure{p_end}
{synopt:{opth verm:ast(string)}}version of survey (2 digits), option is NOT overriden if autoversion option is specified{p_end}
{synopt:{opth har:monization(string)}}harmonization name or code{p_end}
{synopt:{opth vera:lt(string)}}Harmonization version number (2 digits), option is overriden if autoversion option is specified{p_end}
{synopt:{opth fullname(string)}}Final data set name to be applied: CCC_YYYY_SSS_VXX_M_VYY_A_HHH{p_end}
{synopt:{opth conver:factor(varname)}}Variable to be included in final data as conversion factor{p_end}
{synopt:{opth othervariables(varlist)}}Extra variables to be included into final dataset{p_end}
{synopt:{opth strata(varname)}}Strata variable{p_end}
{synopt:{opth psu(varname)}}Primary sampling unit variable{p_end} 
{synopt:{opth note(string)}}Note to be added to data{p_end} 
{synopt:{opth savep:ath(string)}}Directory path for saving files{p_end}
{synopt:{opth icp:base(string)}}Year for PPP conversions{p_end}
{synopt:{opt save13}}Requests data sets to be saved as Stata version 13{p_end}
{synopt:{opt restricted}}Specifies that data is restricted and will not be uploaded to Primus, and will be sent to special folder{p_end}
{synopt:{opt nopov:cal}}Will save data to pre-defined folder and will not be sent to PovCalNet{p_end}
{synopt:{opt replace}}Adds replace option to overwrite previous data with same name{p_end}
{synopt:{opt level(varname)}}Level variable of the PPP variable{p_end}
{synopt:{opt output(string)}}Path to save primus excel information{p_end}
{synopt:{opt welfare_primus(string)}}Primus specific welfare, if empty will take welfare variable{p_end}
{synopt:{opt ref:year(string)}}Specifies reference survey year. If left blank, the value from the year() option is used.{p_end}
{synopt:{opt auto:version}}Auto version control for data. If vermast() is not specified the same vintage as the one from previous version will be used. For new datapoints, both vermast() and veralt() will be equal to 1 {p_end}
{synopt:{opt overwrite}}Allows for replacement of existing vintages. The data is checked for consistency and only addition of new variables is allowed. {p_end}

{dlgtab:Required}


{phang}
{opth countrycode(string)} specifies the three letter country code.  See the Remarks section below for a {help upload##codes:list of WDI country codes}.

{phang}
{opth year(string)} specifies the four digit year (YYYY) in which the survey interviews were conducted for this data file. 
If this period spans two years (e.g. 2012-2013), specify the year with the greater number of months for the survey data collection, 
or if the number of months are equal (e.g. 6 months in first year and 6 months in second year) specify the more recent year.  
OR year of the first day of the interviews. 

{phang}
{opth welfaretype(string)} specifies the type of welfare measure for {cmd: welfare(varname)}. Accepted values are: {bf:INC} for income, {bf:CONS} for consumption, or {bf:EXP} for expenditure.

{phang}
{opth welfare(varname)} specifies {it:varname} for the welfare variable (e.g. per capita consumption) in the data file. This variable should be in {bf:LCU at current prices}.

{phang}
{opth weight(varname)} specifies {it:varname} for the survey weight in the data file.

{phang}
{opth weighttype(string)} specifies the type of weight for {cmd: weight(varname)}. Accepted values are: {bf:FW} for frequency weights, or {bf:PW} for probability weights.
   
{phang}
{opth hsize(string)} specifies {it:varname} for household size.

{phang}
{opth hhid(varname)} specifies {it:varname} for the unique household identification number in the data file.

{phang}
{opth ppp(varname)} specifies {it:varname} for the PPP conversion factor from the 2011 ICP for year 2011 in the data file; this must be a constant.

{phang}
{opth cpi(varname)} specifies {it:varname} for the temporal price adjustment factor with respect to the ppp specified period.

{phang}
{opth cpiperiod(string)} period that the CPI value covers.

{phang}
{opth module(string)} Module that is being uploaded, if user specifies "ALL", or "GPWG" the data will be sent to the Primus approval process.

{marker examples}{...}
{title:Examples}

{phang}{cmd:. primus, countrycode(GEO) year(2015) welfare(gallT) welfaretype(CONS) welfshprosperity(gallT2) welfshprtype(CONS) weight(weight1) weighttype(FW) hsize(hhsize) hhid(hhid1) cpi(cpi2011) cpiperiod(year)	ppp(icp2011) welfaredef(gallT) urban(urb) survey("`surveys'") vermast("`vermast_p'") harmonization(ECAPOV) veralt("`veralt_p'") othervariables(quarter gallT2) icpbase(2011) save13 savepath(\\wbntst01.worldbank.org\TeamDisk\GPWG\datalib\all_region) module(GPWG) output(\\Ecafile\eca-special\ECA_Databank\ECAPOVII\On_demand\GPWG\test.xlsx)} {p_end}

{marker remarks}{...}
{title:Remarks}

{marker codes}{...}
{pstd}
WDI three letter country codes: 

{space 6}{bf:Country}{col 41}{bf:Code}
{space 6}{hline 38}
{space 6}Afghanistan{col 41}AFG
{space 6}Albania	{col 41}ALB
{space 6}Algeria	{col 41}DZA
{space 6}American Samoa	{col 41}ASM
{space 6}Andorra	{col 41}ADO
{space 6}Angola	{col 41}AGO
{space 6}Antigua and Barbuda	{col 41}ATG
{space 6}Argentina	{col 41}ARG
{space 6}Armenia	{col 41}ARM
{space 6}Aruba	{col 41}ABW
{space 6}Australia	{col 41}AUS
{space 6}Austria	{col 41}AUT
{space 6}Azerbaijan	{col 41}AZE
{space 6}Bahamas, The	{col 41}BHS
{space 6}Bahrain	{col 41}BHR
{space 6}Bangladesh	{col 41}BGD
{space 6}Barbados	{col 41}BRB
{space 6}Belarus	{col 41}BLR
{space 6}Belgium	{col 41}BEL
{space 6}Belize	{col 41}BLZ
{space 6}Benin	{col 41}BEN
{space 6}Bermuda	{col 41}BMU
{space 6}Bhutan	{col 41}BTN
{space 6}Bolivia	{col 41}BOL
{space 6}Bosnia and Herzegovina	{col 41}BIH
{space 6}Botswana	{col 41}BWA
{space 6}Brazil	{col 41}BRA
{space 6}Brunei Darussalam	{col 41}BRN
{space 6}Bulgaria	{col 41}BGR
{space 6}Burkina Faso	{col 41}BFA
{space 6}Burundi	{col 41}BDI
{space 6}Cambodia	{col 41}KHM
{space 6}Cameroon	{col 41}CMR
{space 6}Canada	{col 41}CAN
{space 6}Cape Verde	{col 41}CPV
{space 6}Cayman Islands	{col 41}CYM
{space 6}Central African Republic	{col 41}CAF
{space 6}Chad	{col 41}TCD
{space 6}Channel Islands	{col 41}CHI
{space 6}Chile	{col 41}CHL
{space 6}China	{col 41}CHN
{space 6}Colombia	{col 41}COL
{space 6}Comoros	{col 41}COM
{space 6}Congo, Dem. Rep.	{col 41}ZAR
{space 6}Congo, Rep.	{col 41}COG
{space 6}Costa Rica	{col 41}CRI
{space 6}Côte d'Ivoire	{col 41}CIV
{space 6}Croatia	{col 41}HRV
{space 6}Cuba	{col 41}CUB
{space 6}Curaçao	{col 41}CUW
{space 6}Cyprus	{col 41}CYP
{space 6}Czech Republic	{col 41}CZE
{space 6}Denmark	{col 41}DNK
{space 6}Djibouti	{col 41}DJI
{space 6}Dominica	{col 41}DMA
{space 6}Dominican Republic	{col 41}DOM
{space 6}Ecuador	{col 41}ECU
{space 6}Egypt, Arab Rep.	{col 41}EGY
{space 6}El Salvador	{col 41}SLV
{space 6}Equatorial Guinea	{col 41}GNQ
{space 6}Eritrea	{col 41}ERI
{space 6}Estonia	{col 41}EST
{space 6}Ethiopia	{col 41}ETH
{space 6}Faeroe Islands	{col 41}FRO
{space 6}Fiji	{col 41}FJI
{space 6}Finland	{col 41}FIN
{space 6}France	{col 41}FRA
{space 6}French Polynesia	{col 41}PYF
{space 6}Gabon	{col 41}GAB
{space 6}Gambia, The	{col 41}GMB
{space 6}Georgia	{col 41}GEO
{space 6}Germany	{col 41}DEU
{space 6}Ghana	{col 41}GHA
{space 6}Greece	{col 41}GRC
{space 6}Greenland	{col 41}GRL
{space 6}Grenada	{col 41}GRD
{space 6}Guam	{col 41}GUM
{space 6}Guatemala	{col 41}GTM
{space 6}Guinea	{col 41}GIN
{space 6}Guinea-Bissau	{col 41}GNB
{space 6}Guyana	{col 41}GUY
{space 6}Haiti	{col 41}HTI
{space 6}Honduras	{col 41}HND
{space 6}Hong Kong SAR, China	{col 41}HKG
{space 6}Hungary	{col 41}HUN
{space 6}Iceland	{col 41}ISL
{space 6}India	{col 41}IND
{space 6}Indonesia	{col 41}IDN
{space 6}Iran, Islamic Rep.	{col 41}IRN
{space 6}Iraq	{col 41}IRQ
{space 6}Ireland	{col 41}IRL
{space 6}Isle of Man	{col 41}IMY
{space 6}Israel	{col 41}ISR
{space 6}Italy	{col 41}ITA
{space 6}Jamaica	{col 41}JAM
{space 6}Japan	{col 41}JPN
{space 6}Jordan	{col 41}JOR
{space 6}Kazakhstan	{col 41}KAZ
{space 6}Kenya	{col 41}KEN
{space 6}Kiribati	{col 41}KIR
{space 6}Korea, Dem. Rep.	{col 41}PRK
{space 6}Korea, Rep.	{col 41}KOR
{space 6}Kosovo	{col 41}KSV
{space 6}Kuwait	{col 41}KWT
{space 6}Kyrgyz Republic	{col 41}KGZ
{space 6}Lao PDR	{col 41}LAO
{space 6}Latvia	{col 41}LVA
{space 6}Lebanon	{col 41}LBN
{space 6}Lesotho	{col 41}LSO
{space 6}Liberia	{col 41}LBR
{space 6}Libya	{col 41}LBY
{space 6}Liechtenstein	{col 41}LIE
{space 6}Lithuania	{col 41}LTU
{space 6}Luxembourg	{col 41}LUX
{space 6}Macao SAR, China	{col 41}MAC
{space 6}Macedonia, FYR	{col 41}MKD
{space 6}Madagascar	{col 41}MDG
{space 6}Malawi	{col 41}MWI
{space 6}Malaysia	{col 41}MYS
{space 6}Maldives	{col 41}MDV
{space 6}Mali	{col 41}MLI
{space 6}Malta	{col 41}MLT
{space 6}Marshall Islands	{col 41}MHL
{space 6}Mauritania	{col 41}MRT
{space 6}Mauritius	{col 41}MUS
{space 6}Mexico	{col 41}MEX
{space 6}Micronesia, Fed. Sts.	{col 41}FSM
{space 6}Moldova	{col 41}MDA
{space 6}Monaco	{col 41}MCO
{space 6}Mongolia	{col 41}MNG
{space 6}Montenegro	{col 41}MNE
{space 6}Morocco	{col 41}MAR
{space 6}Mozambique	{col 41}MOZ
{space 6}Myanmar	{col 41}MMR
{space 6}Namibia	{col 41}NAM
{space 6}Nepal	{col 41}NPL
{space 6}Netherlands	{col 41}NLD
{space 6}New Caledonia	{col 41}NCL
{space 6}New Zealand	{col 41}NZL
{space 6}Nicaragua	{col 41}NIC
{space 6}Niger	{col 41}NER
{space 6}Nigeria	{col 41}NGA
{space 6}Northern Mariana Islands	{col 41}MNP
{space 6}Norway	{col 41}NOR
{space 6}Oman	{col 41}OMN
{space 6}Pakistan	{col 41}PAK
{space 6}Palau	{col 41}PLW
{space 6}Panama	{col 41}PAN
{space 6}Papua New Guinea	{col 41}PNG
{space 6}Paraguay	{col 41}PRY
{space 6}Peru	{col 41}PER
{space 6}Philippines	{col 41}PHL
{space 6}Poland	{col 41}POL
{space 6}Portugal	{col 41}PRT
{space 6}Puerto Rico	{col 41}PRI
{space 6}Qatar	{col 41}QAT
{space 6}Romania	{col 41}ROM
{space 6}Russian Federation	{col 41}RUS
{space 6}Rwanda	{col 41}RWA
{space 6}Samoa	{col 41}WSM
{space 6}San Marino	{col 41}SMR
{space 6}São Tomé and Principe	{col 41}STP
{space 6}Saudi Arabia	{col 41}SAU
{space 6}Senegal	{col 41}SEN
{space 6}Serbia	{col 41}SRB
{space 6}Seychelles	{col 41}SYC
{space 6}Sierra Leone	{col 41}SLE
{space 6}Singapore	{col 41}SGP
{space 6}Sint Maarten (Dutch part)	{col 41}SXM
{space 6}Slovak Republic	{col 41}SVK
{space 6}Slovenia	{col 41}SVN
{space 6}Solomon Islands	{col 41}SLB
{space 6}Somalia	{col 41}SOM
{space 6}South Africa	{col 41}ZAF
{space 6}South Sudan	{col 41}SSD
{space 6}Spain	{col 41}ESP
{space 6}Sri Lanka	{col 41}LKA
{space 6}St. Kitts and Nevis	{col 41}KNA
{space 6}St. Lucia	{col 41}LCA
{space 6}St. Martin (French part)	{col 41}MAF
{space 6}St. Vincent and the Grenadines	{col 41}VCT
{space 6}Sudan	{col 41}SDN
{space 6}Suriname	{col 41}SUR
{space 6}Swaziland	{col 41}SWZ
{space 6}Sweden	{col 41}SWE
{space 6}Switzerland	{col 41}CHE
{space 6}Syrian Arab Republic	{col 41}SYR
{space 6}Tajikistan	{col 41}TJK
{space 6}Tanzania	{col 41}TZA
{space 6}Thailand	{col 41}THA
{space 6}Timor-Leste	{col 41}TMP
{space 6}Togo	{col 41}TGO
{space 6}Tonga	{col 41}TON
{space 6}Trinidad and Tobago	{col 41}TTO
{space 6}Tunisia	{col 41}TUN
{space 6}Turkey	{col 41}TUR
{space 6}Turkmenistan	{col 41}TKM
{space 6}Turks and Caicos Islands	{col 41}TCA
{space 6}Tuvalu	{col 41}TUV
{space 6}Uganda	{col 41}UGA
{space 6}Ukraine	{col 41}UKR
{space 6}United Arab Emirates	{col 41}ARE
{space 6}United Kingdom	{col 41}GBR
{space 6}United States	{col 41}USA
{space 6}Uruguay	{col 41}URY
{space 6}Uzbekistan	{col 41}UZB
{space 6}Vanuatu	{col 41}VUT
{space 6}Venezuela, RB	{col 41}VEN
{space 6}Vietnam	{col 41}VNM
{space 6}Virgin Islands (U.S.)	{col 41}VIR
{space 6}West Bank and Gaza	{col 41}WBG
{space 6}Yemen, Rep.	{col 41}YEM
{space 6}Zambia	{col 41}ZMB
{space 6}Zimbabwe	{col 41}ZWE



