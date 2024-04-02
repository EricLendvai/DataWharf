# DataWharf - API examples

The following are example settings to demonstrate how to call the Create/Update API of Namespaces, Enumerations with Values, Tables with Columns.

You could use Postman to test the API endpoints.

## Instructions before calling APIs
1. Create a new Application in DataWharf. To match the examples, use "API Test 1" as the name and "APITEST1" as the "Link Code".
2. Go to "API Tokens" under "Settings" and create a new token. Give "Update Anything" to the "API Test 1" application. Set the "Key" to a string you will be using as authorization token".
3. Add the "CreateUpdateNamespaces", "CreateUpdateEnumerations", "CreateUpdateTables" as "API Endpoints" to the new token.
4. In postman, create an Environment with a variable "base_url" and set the "Initial value" and "Current value" to the root of your DataWharf install.

## CreateUpdateNamespaces
1. Use "POST" with URL {{base_url}}api/CreateUpdateNamespaces?ApplicationLinkCode=APITEST1
2. In the "Params" section, create a Key "ApplicationLinkCode" and set the "Value" to "APITEST1"
3. In the "Headers" section, create a Key "AccessToken" and set the "Value" to the string created in DataWharf (Step 2. above)
4. Set the "Body" section to "raw" and past the following:
```
[
    {
        //"ExternalId":1001,
        "Name":"public",
        "Description": "Default Namespace",
        "UseStatus":"Active",
        "DocStatus":"Complete"
    },
    {
        // "ExternalId":1002,
        "Name":"volatile",
        "AKA":"Ville to Paris",
        "UseStatus":"Active",
        "DocStatus":"Composing"
    },
    {
        "ExternalId":1003,
        "Name":"Accounting",
        "AKA":"",
        "UseStatus":"Active",
        "DocStatus":"Composing"
    },
    {
        "ExternalId":1004,
        "Name":"Sales",
        "UseStatus":"Active",
        "DocStatus":"Composing"
    }
]
```
If you only want to create a single Namespace, you can omit the top Array structure.   
"ExternalID" is optional, but if used it will be possible to change the "Name" attribute, otherwise new entries are created.   


## CreateUpdateEnumerations
1. Use "POST" with URL {{base_url}}api/CreateUpdateEnumerations?ApplicationLinkCode=APITEST1
2. In the "Params" section, create a Key "ApplicationLinkCode" and set the "Value" to "APITEST1"
3. In the "Headers" section, create a Key "AccessToken" and set the "Value" to the string created in DataWharf (Step 2. above)
4. Set the "Body" section to "raw" and past the following:
```
[
    {
        "NamespaceName":"public",
        "ExternalId":4001,
        "Name":"Cars",
        "AKA":"Auto",
        "Description":"Car Models",
        "UseStatus":"Active",
        "DocStatus":"Composing",
        "ImplementAs":"Integer",
        // "ImplementLength":2,
        "Values":[
            {
                "ExternalId":5001,
                "Number":1,
                "Name":"Ford",
                "AKA":"American Car",
                "Description":"Popular in USA\nSince Model T",
                "UseStatus":"Active",
                "DocStatus":"Composing"
            },
            {
                "ExternalId":5002,
                "Number":2,
                "Name":"Subaru"
            },
            {
                "Number":3,
                "Name":"Volvo"
            }
        ]
    },
    {
        "NamespaceName":"public",
        // "ExternalId":4002,
        "Name":"Vitamins",
        "AKA":"",
        "Description":"",
        "UseStatus":"Active",
        "ImplementAs":"NativeSQLEnum",
        "Values":[
            {
                "Name":"A"
            },
            {
                "Name":"B"
            },
            {
                "Name":"C"
            }
        ]
    },
    {
        "NamespaceName":"Accounting",
        // "ExternalId":4003,
        "Name":"DisplayMode",
        "AKA":"",
        "Description":"",
        "UseStatus":"Active",
        "ImplementAs":"Numeric",
        "ImplementLength":1
    }
]
```
If you only want to create a single Enumeration, you can omit the top Array structure.   
"ExternalID" is optional, but if used it will be possible to change the "Name" attribute, otherwise new entries are created.   
The order of the "Values" will be replicated in DataWharf.   
Any "Values" no longer defined will be marked as "Discontinued".   


## CreateUpdateTables
1. Use "POST" with URL {{base_url}}api/CreateUpdateTables?ApplicationLinkCode=APITEST1
2. In the "Params" section, create a Key "ApplicationLinkCode" and set the "Value" to "APITEST1"
3. In the "Headers" section, create a Key "AccessToken" and set the "Value" to the string created in DataWharf (Step 2. above)
4. Set the "Body" section to "raw" and past the following:
```
[
    {
        "NamespaceName":"Sales",
        // "ExternalId":2001,
        "Name":"Client",
        "AKA":"Customer",
        "Description":"A Customer2",
        "UseStatus":"Active",
        "DocStatus":"Composing",
        "Columns":[
            {
                "ExternalId":3001,
                "Name":"pk",
                "AKA":"Primary Key",
                "Description":"A Primary Key",
                "UseStatus":"Active",
                "DocStatus":"Composing",
                "Type":"I",
                "UsedAs":"Primary",
                "Length":5,
                "Scale":2
            },
            {
                "ExternalId":3002,
                "Name":"sysc",
                "AKA":"Creation Time",
                "Description":"Used Internally",
                "UseStatus":"Active",
                "DocStatus":"Complete",
                "Type":"DT",
                "Scale":0,
                "UsedAs":"Support"
            },
            {
                "ExternalId":3003,
                "Name":"sysm",
                "AKA":"Modified Time",
                "Description":"Used Internally",
                "UseStatus":"Active",
                "DocStatus":"Complete",
                "Type":"DT",
                "Scale":0,
                "UsedAs":"Support"
            },
            {
                // "ExternalId":3004,
                "Name":"FName",
                "AKA":"First Name",
                "UseStatus":"Active",
                "DocStatus":"Complete",
                "Type":"CV",
                "Length":30,
                "Scale":0,
                "Nullable":false,
                "DefaultType":"NotSet",
                "DefaultCustom":"",
                "ForeignKeyUse":"",
                "ForeignKeyOptional":false,
                "OnDelete":"NotSet",
                "Unicode":true
            },
            {
                "Name":"VIP",
                "Type":"L",
                "Nullable":false,
                // "Array":true,
                "DefaultType":"True"
            },
            {
                "Name":"FavoriteVitamin",
                "Type":"E",
                "Enumeration":"public.Vitamins"
            }
        ]
    },
    {
        "NamespaceName":"Accounting",
        // "ExternalId":2002,
        "Name":"Invoice",
        "AKA":"Facture",
        "Description":"",
        "UseStatus":"Active",
        "Columns":[
            {
                "Name":"pk",
                "AKA":"Primary Key",
                "UseStatus":"Active",
                "Type":"I",
                "UsedAs":"Primary"
            },
            {
                // "ExternalId":3002,
                "Name":"fk_Client",
                "Type":"I",
                "UsedAs":"Foreign",
                "Nullable":true,
                "ForeignTable":"Sales.Client",
                "ForeignKeyUse":"Billed To",
                // "ForeignKeyOptional":"true",
                "ForeignKeyOptional":false,
                "OnDelete":"Protect"
            }
        ]
    },
    {
        "NamespaceName":"Accounting",
        // "ExternalId":2003,
        "Name":"Credit",
        "AKA":"",
        "Description":"",
        "UseStatus":"Active"
    },
    {
        "NamespaceName":"volatile",
        // "ExternalId":2004,
        "Name":"ServerLog",
        "AKA":"",
        "Description":"",
        "UseStatus":"Active"
    }
]
```
If you only want to create a single Table, you can omit the top Array structure.   
"ExternalID" is optional, but if used it will be possible to change the "Name" attribute, otherwise new entries are created.   
The order of the "Columns" will be replicated in DataWharf.   
Any "Columns" no longer defined will be marked as "Discontinued".   
