{smcl}
{* *! version 0.0.1 19Jan2018}{...}
{cmd:help primus_upload}
{hline}

{title:Title}

{p2colset 5 24 26 2}{...}
{p2col :}{cmd:primus upload} {hline 1} Various functions to upload data files and/or XML file to PRIMUS
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:primus upload}
{cmd:,} 
[{opt proc:essid()} {opt surveyid()} {opt folderpath()} {opt infile()} {opt type()} {opt new} {opt zip} {opt xmlbl} {opt tran:xid(string)}]

{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:primus upload} upload files and/or XML file to PRIMUS for each process.

{marker options}{...}
{title:Options}

{dlgtab:Raw data upload}
{phang}{cmd:. primus upload, processid() surveyid() type(raw) folderpath() infile() new} {p_end}
{pstd}
To start the upload, user needs to specify the {opt new} one file is uploaded and the transaction ID is returned. Raw data upload can be done one file at a time or with the zip file option. If it is one file, then upload one file as new and get the transaction ID, and then pass that to the code to upload other files. You must specify the destination folder and {opt type} as raw.

{pstd}
Example:

{phang}{cmd:. primus upload, processid(6) surveyid(AGO_2029_He1BS_V01_M) type(raw) folderpath(Data/Stata) infile(c:\Temp\subin.dta) new} {p_end}

{pstd}
Then upload other files using the same transaction ID

{phang}{cmd:.primus upload, proc(6) surveyid(AGO_2029_He1BS_V01_M) type(raw) folderpath(Data/Stata) infile(c:\Temp\spatial_deflators.dta) tranxid(006-000327173-MNARAW-AGO-12944)} {p_end}

{dlgtab:Raw data - zip upload}
{phang}{cmd:. primus upload, processid(6) surveyid(AGO_2022_HBf5_V01_M) type(raw) infile(c:\Temp\AGO_2028_HBS_v01_M.zip) zip new} {p_end}

{pstd}
Upload can also be done via the zip function. The zip file should contain the same folder structures as defined in the process, together with accepted file extensions. Once the upload is done, PRIMUS returns the status, success or fail, of each file in the zip file to the data in the browser.

{pstd}
Users can also reupload the (new/revised) zip file to the same transaction ID.	

{phang}{cmd:. primus upload, processid(6) surveyid(AGO_2021_HBf5_V01_M) type(raw) infile(c:\Temp\AGO_2028_HBS_v01_M.zip) zip tranxid(006-000327173-MNARAW-AGO-67598)} {p_end}


{dlgtab:Explore SurveyIDs}
{pstd}
{cmd: primus download, explore country() [year() survname()]} Survey acronyms and Survey IDs and vintages are important for the system to understand the latest available vintages and how one survey are related to each other. It is best that the same survey can be named/called the same way across the system. To see how surveys are named in the systems (both in DLW or in pending/approved in PRIMUS). Optional parameters for this syntax is either with just country(), or with more information on the survey year and acronym.

{dlgtab:Check XML}
{pstd}
{cmd: primus download, xml processid() tranxid() [out()]}
For harmonized processes, one would need to define the indicator to be clear/reviewed. You can see the example of the format and content of XML file in your collections. The details of the XML file is up to teams to define as long as it follows the main heading format.

{dlgtab:Transaction details}
{pstd}
{cmd: primus download, proc() tranxid() [ind file]} 
User can get the details of uploaded transactions from its metadata/indicators {opt ind} to the file(s) uploaded {opt file}.

{marker examples}{...}
{title:Examples}
{phang}{cmd: primus download, meta} {p_end}
{phang}{cmd: primus download, tranxid(007-000327173-MNAPOV-DJI-b9c57)} {p_end}
{phang}{cmd: primus download, processid(6) folders} {p_end}
{phang}{cmd: primus download, explore country(ALB)} {p_end}
{phang}{cmd: primus download, explore country(ALB) year(2012)} {p_end}
{phang}{cmd: primus download, xml processid(7) tran(007-000327173-MNAPOV-ALB-96331)} {p_end}
{phang}{cmd: primus download, proc(6) ind tranxid(007-000327173-MNAPOV-DJI-b9c57)} {p_end}
{phang}{cmd: primus download, proc(6) file tranxid(006-000327173-MNARAW-ALB-8ef53)} {p_end}
{phang}{cmd: } {p_end}