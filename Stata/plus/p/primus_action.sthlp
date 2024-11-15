{smcl}
{* *! version 0.0.1.1 7Nov2024}{...}
{cmd:help primus_action}
{hline}

{title:Title}

{p2colset 5 24 26 2}{...}
{p2col :}{cmd:primus action} {hline 1} Put an action on PRIMUS transactions for your process.
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:primus action}
{cmd:,[} 
{opt tran:xid(string)} {opt d:ecision(string)} {opt proc:ess(numeric)} {opt c:omments(string)}]
	
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:primus action} Put an action on PRIMUS transaction based on the user's role and country scope in the PRIMUS system.

{marker options}{...}
{title:Options}

{dlgtab:Optional}

{synopt:{opth tran:xid(string)}} Transaction ID, accept ONLY one transaction ID{p_end}
{synopt:{opth d:ecision(string)}} Decision to be act on the Transaction ID. Uploader can either "CONFIRM" or "REJECT"; and Approvers can "APPROVE" or "REJECT"{p_end}
{synopt:{opth c:omments(string)}} Comments must be for REJECT. For CONFIRM or APPROVE, system can use username as the comments.{p_end}

{marker examples}{...}
{title:Examples}

{phang}{cmd:. primus action, tranxid(006-000327173-MNARAW-AGO-536ce) proc(6) decision(confirm) comments(Good data)} {p_end}
{pstd}
User put an "CONFIRM" action on the transaction, this is the first step of the PRIMUS workflow. After the confirmation of the Uploader, the transaction will be available for the approvers to act upon. Each transaction is linked with a process so the option of process() is needed.  

{phang}{cmd:. primus action, tranxid(006-000327173-MNARAW-ALB-8ef53) proc(6) decision(approve) comments(Ok to confirm)} {p_end}
{pstd}
User put an "APPROVE" action on the transaction. This is only possible when Uploader had confirmed or no one from the approver's role have act upon the transaction. Transaction cannot be approved/rejected more than one or change the action after it goes through. Users without approval role for the country in transaction will not be able to do so and get an error.

{phang}{cmd:. primus action, tranxid(007-000327173-MNAPOV-DJI-24674) proc(7) decision(REJECT) comments(issues with the data)} {p_end}
{pstd}
User put an "REJECT" action on the transaction. In this case, it could be the rejection from the uploader role or from the approver role, depending on the stage of the transaction ID. Comments are required for any rejections.

