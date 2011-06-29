rhocrm
===

A ruby library containing collection of the out-of-box [RhoSync](http://rhomobile.com/products/rhosync) applications 
for various CRM backends.  

Using rhocrm, you can utilize the pre-built set of the  [RhoSync](http://rhomobile.com/products/rhosync/) applications 
for popular CRM backends (SalesForce, Oracle CRM On Demand, Sugar CRM, etc.). Also, this library includes support for writing your own [RhoSync](http://rhomobile.com/products/rhosync/)
CRM applications extending or customizing the default functionality.

## Getting started
Install the 'rhocrm' gem by using the following command:

gem install rhocrm

## Usage
To create a rhosync CRM-based application use the following command:

rhocrm app <app_name> <CRM-backend>

Here, CRM-backend is the name of the CRM backend that you want to base the application upon.
Currently, the following CRM backends are supported:

   - OracleOnDemand

## Meta
Created and maintained by Rhomobile Inc.

Released under the [MIT License](http://www.opensource.org/licenses/mit-license.php).