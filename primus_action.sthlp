{smcl}
{* *! version 0.0.1 19Jan2018}{...}
{cmd:help primus_action}
{hline}

{title:Title}

{p2colset 5 24 26 2}{...}
{p2col :}{cmd:primus action} {hline 1} Put an action on PRIMUS transactions
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:primus action}
{cmd:,[} 
{opt tran:xid(string)} {opt d:ecision(string)} {opt c:omments(string)} {opt index:id(string)}]
	
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:primus action} Put an action on PRIMUS transaction based on the user's role in the PRIMUS system.

{marker options}{...}
{title:Options}

{dlgtab:Optional}

{synopt:{opth tran:xid(string)}} Transaction ID, accept ONLY one transaction ID{p_end}
{synopt:{opth d:ecision(string)}} Decision to be act on the Transaction ID. Uploader can either "CONFIRMED" or "REJECTED"; and Approvers can "APPROVED" or "REJECTED"{p_end}
{synopt:{opth c:omments(string)}} Comments must be for REJECTED. For CONFIRMED or APPROVED, system can use username as the comments.{p_end}
{synopt:{opth index:id(string)}} It is the calculation index provided by the primus download for each transaction. It indicates the choices based on the combination of several input such as Welfare Set, Method, PPP value, CPI value, Group as indicated in the PRIMUS view. The default value is 1 if it is missing.{p_end}

{marker examples}{...}
{title:Examples}

{phang}{cmd:. primus action, tranxid(TRN-000252482-ECA-MDA-W8CKO) indexid(1) decision(CONFIRMED)} {p_end}
{pstd}
User put an "CONFIRMED" action on the transaction, this is the first step of the PRIMUS workflow. After the confirmation of the Uploader, the transaction will be available for the approvers to act upon.  

{phang}{cmd:. primus action, tranxid(TRN-000252482-SSA-COM-6VJC1) decision(approved)} {p_end}
{pstd}
User put an "APPROVED" action on the transaction. This is only possible when Uploader had confirmed or no one from the approver's role have act upon the transaction. Transaction cannot be approved/rejected more than one or change the action after it goes through.

{phang}{cmd:. primus action, tranxid(TRN-000252482-ECA-ARM-S7F8U) indexid(1) decision(rejected) comments(esyashdhs0 jjjkj)} {p_end}
{pstd}
User put an "REJECTED" action on the transaction. In this case, it could be the rejection from the uploader role or from the approver role, depending on the stage of the transaction ID. Comments are required for any rejections.

