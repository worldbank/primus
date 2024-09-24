{smcl}
{* *! version 0.0.1 19Jan2018}{...}
{cmd:help primus_download}
{hline}

{title:Title}

{p2colset 5 24 26 2}{...}
{p2col :}{cmd:primus download} {hline 1} Download statistics/data from PRIMUS
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:primus download}
{cmd:,} 
{opt tran:xid(string)}]

{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:primus upload} download the statistics/indicators deposited in PRIMUS based on the microdata uploaded into PRIMUS.

{marker options}{...}
{title:Options}

{dlgtab:Optional}

{synopt:{opth tran:xid(string)}} Transaction IDs separated by space{p_end}

{marker examples}{...}
{title:Examples}

{phang}{cmd:. primus download, tranxid(TRN-000408971-MNA-DJI-U0FHW TRN-000408971-MNA-DJI-BD5KM)} {p_end}
