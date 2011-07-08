rhocrm
===

A ruby library containing collection of the out-of-box [RhoSync](http://rhomobile.com/products/rhosync) applications 
for various CRM backends.  

Using rhocrm, you can utilize the pre-built set of the  [RhoSync](http://rhomobile.com/products/rhosync/) applications 
for popular CRM backends (SalesForce, Oracle CRM On Demand, Sugar CRM, etc.). Also, this library includes support for writing your own [RhoSync](http://rhomobile.com/products/rhosync/)
CRM applications extending or customizing the default functionality.

## Setup
Install the 'rhocrm' gem by using the following command:

	gem install rhocrm


## Usage
'rhocrm' command is used to create CRM-based [RhoSync](http://rhomobile.com/products/rhosync/) applications.
To get familiar with [RhoSync](http://rhomobile.com/products/rhosync/) , please visit the product's [page](http://rhomobile.com/products/rhosync/).

### Generating Standard Application

To create a standard out-of-the box application use the following command:

	rhocrm app <app_name> <CRM-backend>

Here, \<CRM\-backend\> parameter specifies the CRM backend that your application will use.
Currently, the following CRM backends are supported:

   - OracleOnDemand (for [Oracle CRM On Demand](crmondemand.oracle.com))
   - MsDynamics (for [Microsoft Dynamics CRM](http://www.microsoft.com/en-us/dynamics/default.aspx))

In the process of generation, the Rhocrm application structure will include typical [RhoSync](http://rhomobile.com/products/rhosync/)
files (for example, application.rb or settings.yml), plus it will create a special vendor directory 'vendor/<CRM-backend>' 
where the generator will place all support files specific for the corresponding CRM backend. Also, every CRM backend
has a list of settings that are required to prepare and run the application. See below for more detailed instructions.

By default, the Rhocrm application will be generated with four standard source adapters corresponding
to the following CRM objects:
	
	- Account
	- Contact
	- Lead
	- Opportunity


### Generating CRM Application without pre-built source adapters

In some cases, it is necessary to generate an application without any standard sources.
For this purpose, the \-\-bare option can be used to generate just the application's skeleton.

	rhocrm app <app_name> <CRM-backend> --bare
	
	
### Generating CRM source adapters for the Rhocrm application

Once the application is created, it is possible to generate the desired source adapters
based on the CRM objects by typing the following command in the Rhocrm application directory:

	rhocrm source <CRM-object-name> <CRM-backend>
	
Here, \<CRM\-object\-name\> must exactly correspond to the name of the CRM object you're trying to
build the source adapter for.

## Preparing the Rhocrm Application

### OracleOnDemand settings
All OracleOnDemand-specific settings are located in the **'vendor/oracle_on_demand/settings'** directory.
In the file *'settings.yml'* you'll find the entries that are necessary to customize before running the app.
These are:

- **:oraclecrm_service_url:** <oracle_web_services_integration_url> - substitute the default URL with your OracleOnDemand account URL.

Also, for every source adapter based on CRM object there is a corresponding *'vendor/oracle_on_demand/settings/\<CRM\-object\-name\>.yml'*
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
			is really a reference to the corresponding Account object.

For the default generated CRM object adapters, this file is pre-filled with information. However, user can customize it by including or excluding
the desired options. For custom adapters, user will need to fill this file with relevant information. List of object's fields, for example, can be obtained
from the Oracle CRM On Demand documentation and then later used to fill the Query_Fields setting. Alternatively, user can customize the adapter and obtain 
the list of fields using the GetMapping API.
 

### MsDynamics settings
All MsDynamics-specific settings are located in the **'vendor/ms_dynamics/settings'** directory.
In the file *'settings.yml'* you'll find the entries that are necessary to customize before running the app.
These are:


## Running the Rhocrm Application
Once the application is customized and ready to run, it can be started as any other Rhosync app
by typing the following command in the CRM application's root directory:

	rake rhosync:start
	

## Meta
Created and maintained by Rhomobile Inc.

Released under the [MIT License](http://www.opensource.org/licenses/mit-license.php).