{smcl}
{* *! version 0.0.1 19Jan2018}{...}
{cmd:help primus_download}
{hline}

{title:Title}

{p2colset 5 24 26 2}{...}
{p2col :}{cmd:primus download} {hline 1} Various functions to download metadata, statistics, data from PRIMUS
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:primus download}
{cmd:,} 
[{opt meta} {opt proc:essid()} {opt folders} {opt explore} {opt country()} {opt year()} {opt survname()} {opt xml} {opt ind} {opt file} {opt tran:xid(string)}]

{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:primus upload} download metadata, uploaded indicators, transactions, deposited in PRIMUS based on the microdata uploaded into PRIMUS.

{marker options}{...}
{title:Options}

{dlgtab:Meta}
{pstd}
{cmd:primus download, meta} to see the full list of all available processes in the PRIMUS system and its metadata (admin names, modules, active or not, window to upload if available, etc.) The ProcessID used in {cmd proc:essid()} is in the variable "processid".

{dlgtab:Folders and file extensions}
{pstd}
{cmd: primus download, processid() folders} to know more about the accepted folders and file extensions in each folder. Browse and see the output from the command from the specified ProcessID, for example processid(6).

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