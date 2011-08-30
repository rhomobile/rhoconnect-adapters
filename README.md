rhoconnect-adapters
===

rhoconnect-adapters is a ruby library containing a collection of the out-of-box [RhoConnect](http://rhomobile.com/products/rhoconnect) applications 
for various needs.  

With rhoconnect-adapters, you can utilize the pre-built set of [RhoConnect](http://rhomobile.com/products/rhoconnect/) applications 
for popular CRM backends (SalesForce, Oracle CRM On Demand, Sugar CRM, etc.). Also, this library includes support for writing your own [RhoConnect](http://rhomobile.com/products/rhoconnect/)
CRM applications to extend or customize the default functionality.

## Setup
Install the 'rhoconnect-adapters' gem by using the following command:

	$ [sudo] gem install rhoconnect-adapters


## Usage
The 'rhoconnect-adapters' command creates pre-built [RhoConnect](http://rhomobile.com/products/rhoconnect/) applications.
Visit the [RhoConnect](http://rhomobile.com/products/rhoconnect/) website for more information.

### Generating Standard CRM Application

To create a standard out-of-the-box rhoconnect CRM application use the following command:

	$ rhoconnect-adapters crmapp <app_name> <CRM-backend>

Here, the \<CRM\-backend\> parameter specifies the CRM backend that your application will use.
Currently, the following CRM backends are supported:

   - OracleOnDemand (for [Oracle CRM On Demand](http://crmondemand.oracle.com))
   - MsDynamics (for [Microsoft Dynamics CRM](http://www.microsoft.com/en-us/dynamics/default.aspx))
   - Sugar (for [Sugar CRM](http://http://www.sugarcrm.com/crm/))

The generated Rhoconnect CRM application structure will include typical [RhoConnect](http://rhomobile.com/products/rhoconnect/)
files (for example, application.rb and settings.yml). It will also create a special vendor directory `vendor/\<CRM\-backend\>`
containing all support files specific for the corresponding CRM backend.

By default, the Rhoconnect CRM application will be generated with four standard source adapters corresponding
to the following CRM objects:
	
	- Account
	- Contact
	- Lead
	- Opportunity


### Generating CRM Application without pre-built source adapters

In some cases, it is necessary to generate an application without any standard sources.
For this purpose, use the `--bare` option to generate just the application's skeleton.

	rhoconnect-adapters crmapp <app_name> <CRM-backend> --bare
	
	
### Generating CRM source adapters for the Rhoconnect CRM application

Once you create your Rhoconnect CRM application, you can generate the desired source adapters
based on the CRM objects by typing the following command in your application's directory:

	rhoconnect-adapters crmsource <CRM-object-name> <CRM-backend>
	
Here, \<CRM\-object\-name\> must exactly correspond to the name of the CRM object you're trying to
build the source adapter for.

## Preparing the Rhoconnect CRM Application

### OracleOnDemand settings
All OracleOnDemand-specific settings are located in the `vendor/oracle_on_demand/settings` directory.
In the file `settings.yml` you'll find the entries that you must customize before running the app.
These are:

- **:oraclecrm_service_url:** <oracle_web_services_integration_url> - substitute the default URL with your OracleOnDemand account URL.

For every source adapter based on CRM object there is a corresponding *'vendor/oracle_on_demand/settings/\<CRM\-object\-name\>.yml'*
file containing the descriptions for the OracleOnDemand CRM object.
Every CRM object file has the following entries:

	Query_Fields: hash of the objects's fields 
			(each field's element has the value 
			 in a form of the hash with the field's options , 
			containing the following data):
      	Label => <val> - display name of the field
      	Type => <val> - type of the field data 
			(textinput, textarea, Picklist, id, etc.)
			
	NonQuery_MappingWS_Fields: object's fields that can not be used
	 		in OracleCRM Queries 
			(however, Oracle returns them in GetMapping API)

	StaticPickList: Normally, all picklist fields are queried 
			for the allowed values using GetPicklistValues API
            However, for certain fields OracleCRM API 
			returns the error 'not a valid picklist'
            This entry is a workaround for this error - 
			fields's picklist values are statically hard-coded here.

	ObjectFields: this one specifies a hash of fields 
			that are actually references to other objects. 
         	For example, AccountName field for Contact object 
			is really a reference to the corresponding Account object.'
	
	TitleFields: this setting specifies an array of fields
				used in constructing the object's title in the 'Show' page
				using the Metadata method. Typically, you will want to put 
				`name` fields in here.

For the default generated CRM object adapters, this file is pre-filled with information. However, you can customize it by including or excluding
options. For custom adapters, you need to fill this file with relevant information. List of object's fields, for example, can be obtained
from the Oracle CRM On Demand documentation and then later used to fill the Query_Fields setting. Alternatively, user can customize the adapter and obtain 
the list of fields using the GetMapping API.
 

### MsDynamics settings
All MsDynamics-specific settings are located in the **'vendor/ms_dynamics/settings'** directory.
In the file *'settings.yml'* you'll find the entries that are necessary to customize before running the app.
These are:

- **:msdynamics_ticket_url:** <msdynamics_web_services_integration_url> - substitute the default URL with your MsDynamics account URL.

For every source adapter based on CRM object there is a corresponding *'vendor/msdynamics/settings/\<CRM\-object\-name\>.yml'*
file containing the descriptions for the Sugar CRM object.
Every CRM object file has the following entries:

	Query_Fields: hash of the objects's fields 
			(each field's element has the value 
			 in a form of the hash with the field's options , 
			containing the following data):
      	Label => <val> - display name of the field
      	Type => <val> - type of the field data 
			(textinput, textarea, Picklist, id, etc.)
	
	AttributeTypePicklists: this is a hash of picklist arrays
			for artificially constructed fields
	    	that are really represent some other field's type
			for example, `customerid` field can be either
			`account` or `contact`. In this case
			field `customertype_attrtype` will represent `customerid` field's type
			and will take values from the `AttributeTypePicklists`
			array for the field `customerid_attrtype`

	ObjectFields: this one specifies a hash of fields 
			that are actually references to other objects. 
         	For example, `account_name` field for Contact object 
			is really a reference to the corresponding Account object.
	
	TitleFields: this setting specifies an array of fields
				used in constructing the object's title in the 'Show' page
				using the Metadata method. Typically, you will want to put 
				`name` fields in here.

For the default generated CRM object adapters, this file is pre-filled with information. However, you can customize it by including or excluding
options. For custom adapters, you need to fill this file with relevant information. List of object's fields, for example, can be obtained
from the MsDynamics documentation and then later used to fill the Query_Fields setting. Alternatively, user can customize the adapter and obtain 
the desired list of object's fields using the MsDynamics SOAP API.

### Sugar settings
All Sugar-specific settings are located in the **'vendor/sugar/settings'** directory.
In the file *'settings.yml'* you'll find the entries that are necessary to customize before running the app.
These are:

- **:sugarcrm_uri:** <oracle_web_services_integration_url> - substitute the default URL with your OracleOnDemand account URL.
- **:debug_enabled:** <true/false> - enable debug output of the backend HTTP transactions.

For every source adapter based on CRM object there is a corresponding *'vendor/sugar/settings/\<CRM\-object\-name\>.yml'*
file containing the descriptions for the Sugar CRM object.
Every CRM object file has the following entries:

	Query_Fields: hash of the objects's fields 
			(each field's element has the value 
			 in a form of the hash with the field's options , 
			containing the following data):
      	Label => <val> - display name of the field
      	Type => <val> - type of the field data 
			(textinput, textarea, Picklist, id, etc.)

	ObjectFields: this one specifies a hash of fields 
			that are actually references to other objects. 
         	For example, `account_name` field for Contact object 
			is really a reference to the corresponding Account object.
	
	TitleFields: this setting specifies an array of fields
				used in constructing the object's title in the 'Show' page
				using the Metadata method. Typically, you will want to put 
				`name` fields in here.

For the default generated CRM object adapters, this file is pre-filled with information. However, you can customize it by including or excluding
options. For custom adapters, you need to fill this file with relevant information. List of object's fields, for example, can be obtained
from the SugarCRM documentation and then later used to fill the Query_Fields setting. Alternatively, user can customize the adapter and obtain 
the desired list of object's fields using the SugarCRM REST API.

## Running the CRM Application
Once your Rhoconnect application is customized and ready to run, you can start it like any other Rhoconnect app.
Type the following command in the CRM application's root directory:

	rake rhoconnect:start
	

## Meta
Created and maintained by Rhomobile Inc.

Released under the [MIT License](http://www.opensource.org/licenses/mit-license.php).