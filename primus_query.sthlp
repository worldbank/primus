{smcl}
{* *! version 0.0.1 19Jan2018}{...}
{cmd:help primus_query}
{hline}

{title:Title}

{p2colset 5 24 26 2}{...}
{p2col :}{cmd:primus query} {hline 1} Query the status of the PRIMUS transactions
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:primus query}
{cmd:,[} 
{opt coun:try(string)} {opt year(string)} {opt r:egion(string)} {opt overalls:tatus(string)} {opt pending:with(string)} {opt tran:xid(string)}]
	
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:primus query} Query the status of the PRIMUS transactions and load it into Stata. Users can filter the results by different optional parameters. There should be at least one parameter in usage.

{marker options}{...}
{title:Options}

{dlgtab:Optional}

{synopt:{opth coun:try(string)}} Three-letter country code; can accept more than one country code separated by comma{p_end}
{synopt:{opth year(string)}} year of the data; can accept more than one year separated by comma{p_end}
{synopt:{opth r:egion(string)}} region of the data and transaction. Options are "ECA", "EAP", "MNA", "LAC", "SSA", or "SAR"{p_end}
{synopt:{opth overalls:tatus(string)}} The overall status of the transaction. It can be "APPROVED", "PENDING", or "REJECTED", and takes only one value{p_end}
{synopt:{opth pending:with(string)}} Find the pending status from approvers, and only take one value. Option is "DECDG", "FINALIZER", "POVCALNET", "REGIONAL", or "UPLOADER"{p_end}
{synopt:{opth tran:xid(string)}} Transaction IDs, can accept more than one transaction separated by comma{p_end}

{marker examples}{...}
{title:Examples}

{phang}{cmd:. primus query, overallstatus(PENDING)} {p_end}
{pstd}
Query the status of the PRIMUS transactions with the overall status as PENDING. 

{phang}{cmd:. primus query, country(ALB,ARM) overalls(pending)} {p_end}
{pstd}
Query the status of the PRIMUS transactions for ALB and ARM with the overall status as PENDING. 

{phang}{cmd:. primus query, region(ECA) overalls(pending)} {p_end}
{pstd}
Query the status of all PRIMUS transactions from the ECA region with the overall status as PENDING. 

{phang}{cmd:. primus query, region(ECA) pending(povcalnet)} {p_end}
{pstd}
Query the status of all PRIMUS transactions from the ECA region with the overall status as PENDING with Povcalnet. 
