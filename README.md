# primus
The World Bank Group monitors and reports statistics on poverty and shared prosperity in order to operationalize and monitor its “twin goals.” This involves a process for data collection, production, review, and dissemination to multiple teams within the organization. 

The Primus system is designed to facilitate this process of generating internal estimates of the World Bank’s poverty indicators and reduce the time for resolving discrepancies. It is a workflow management platform for the submission, review and approval of poverty estimates and a tracking facility to capture the inputs and results of the estimation process for future reference and audits.

The Primus ado files for Stata are a critical component of this process. These allow for data sharing and file upload service that ensures that estimations are based on identical source data. The SM20 version (released in December 2019) incorporates the following minor improvements to the SM19 version: 

-	Age can now be a decimal for individuals younger than 5 yrs, consistent with GMD 2.0 definitions
-	Primus now gives an error message if any of the required GMD 1.5 variables are missing in the upload file. The following GMD 1.5 variables (previously optional) are now required in any GMD upload: imp_wat_rec, imp_san_rec, landphone, cellphone, computer, electricity.
-	Fixed an error in the variable check for empstat
-	You can now upload multiple surveys with different CPIs for any given year
