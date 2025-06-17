# mpulse_reference_update
MPULSE OBJECTS' REFERENCES BULK UPDATE
------------------------------------------------------------------------------------------------
>> Usage: ./update_mpulse_references.sh <domains_file> <api_token> <tenant> [<output_csv>]

>> Example: ./update_mpulse_references.sh domains.txt "your_api_token" "your_tenant" results.csv
------------------------------------------------------------------------------------------------
This Bash script levarages the mPULSE API to update mpulse objects' references in bulk.

1. Reads a domain from an input text file containing a domain list.

And for each of the domains:

2.Lists the object based on a domain name search and saves the object-ID.
3. Updates the object reference(s) specified in the reference.json file.
4. Generates an output file with following details: DOMAIN, OBJECT_ID, UPDATE-STATUS

To use the mPulse API you will first need to generate an apiToken:
https://techdocs.akamai.com/mpulse/reference/put-token

To generate the token you will need either your mpulse user/password or a API-Token-Json key (if SSO is enabled), which you can get from your user profile, in mpuls portal.

![image](https://github.com/user-attachments/assets/49be6082-a7ac-4fd7-8afb-e8006dcbe57a)

------------------------------------------------------------------------------------------------
Example of reference.json file used to update to boomerang version 1.803

{
"references": [
    {
    "internalID": "boomr",
    "id": 28008,
    "embedded": false,
    "type": "boomerang",
    "path": null,
    "name": "boomerang-1.803.70"
    }
  ]
}

------------------------------------------------------------------------------------------------
Example of domains.txt input file:
>> www.domain1.com
>> 
>> www.domain2.com
>> 
>> www.domain3.com

------------------------------------------------------------------------------------

MPULSE API DOCCUMENTATION:
https://techdocs.akamai.com/mpulse/reference/api






