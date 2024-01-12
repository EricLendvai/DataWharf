# DataWharf&trade;

## Introduction
DataWharf is a Database Designer/Modeler/Analyzer Tool web application.  

View [Data Architecture and Modeling with DataWharf Article](https://harbour.wiki/index.asp?page=PublicArticles&mode=show&id=230224232407&sig=5928045156) for User and Developer documentation   

View [Data Architecture and Modeling with DataWharf Presentation Deck (Slides)](https://github.com/EricLendvai/DataWharf/blob/main/Presentation/Intro_To_DataWharf.pdf)   

# YouTube Videos
  * [Data Architecture and Modeling with DataWharf](https://www.youtube.com/watch?v=8GfwKYA4Agc)
  * [Tutorial - Installing DataWharf Locally](https://www.youtube.com/watch?v=Gc_Vib6_3is)

# YouTube Channel
[https://www.youtube.com/@EricLendvai](https://www.youtube.com/@EricLendvai)   

Sample screen of Data Dictionary Visualization 
![Sample screen of Data Dictionary Visualization](images/Sample001.png "Sample screen of Data Dictionary Visualization")

# Getting it built, compiled and running

For using:
* [Using docker-compose](doc/installation/docker-compose.md) (simplest if you already have docker-compose)
* [Using docker](doc/installation/docker.md)

For Development:
*	[Using VSCode](doc/installation/vscode.md) (any environment)

# Using Dockerwharf

Open a browser to "http://localhost:8080"   
The initial login ID is "main" and the password is "password".   
Once you logged in, to see DataWharf's own data dictionary use the following steps:   
1. Go to "Settings" and add an "Application", "DataWharf".   
2. Go to "Data Dictionary", select "DataWharf", use the "Import" option, and from the repo use the latest ExportDataDictionary_DataWharf_*.zip   
You can do the same for "Projects" and "Models".   

# Open Source
The following is the list of additional open source projects used to design, build and deploy DataWharf:

| Repo / Website  | Use |
| ------------- | ------------- |
| https://github.com/harbour/core                | The Habour to C Compiler |
| https://github.com/EricLendvai/Harbour_FastCGI | FastCGI web framework |
| https://github.com/EricLendvai/Harbour_ORM     | Database framework |
| https://github.com/EricLendvai/Harbour_VFP     | Additional Harbour/VFP Language Libraries |
| https://www.postgresql.org/                    | Main data store of the web app |
| https://httpd.apache.org/                      | Apache Web server |
| https://getbootstrap.com/                      | Bootstrap 5 |
| https://jquery.com/                            | Browser independent JavaScript library |
| https://jqueryui.com/                          | UI toolkit for jQuery |
| https://github.com/visjs/vis-network           | JavaScript Library used to make interactive diagrams (visualize) |
| https://github.com/maxGraph/maxGraph           | JavaScript Library used to make interactive diagrams (visualize) |
| https://code.visualstudio.com/                 | Also used to automate compilation |

DataWharf can run on Windows, Linux or any platforms supported by the above list of repos/products.

# Changes and development

* View [ChangeLog.md](ChangeLog.md) for list of enhancements and fixes.   
* View [Todo.md](Todo.md) for list of upcoming fixes and enhancements.


