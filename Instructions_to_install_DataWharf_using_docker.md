# Instructions to install DataWharf using docker

## Goal
These instructions are for users wanting to use DataWharf locally, or could be used as the basis for cloud installs.   
You can use the following instructions on any platforms supporting Docker Desktop, like Window, Linux and Mac.   
For the purpose of these step by step instructions, we are focusing on Microsoft Windows 10 or above.   

## Prerequisites
1. Microsoft Windows 10 or above.
2. Docker Desktop.
3. An empty PostgreSQL database, with full administrative access rights.
4. Any modern browser like FireFox, Chrome, Microsoft Edge.
5. Access to http://datawharf.org, which will redirect you to https://github.com/EricLendvai/DataWharf

## Installation of Docker Desktop
As stated in the Prerequisites we need to use Docker Desktop. It is free for personal use or for small businesses (fewer than 250 employees and less than $10 millions in annual revenue).   
For the fastest running environment for Docker Desktop on Microsoft Windows, you first need to install the "Windows Subsystem for Linux (WSL)".   
Please review the following document, up to the section "Installing Docker Desktop": [Installing and using WSL, Docker Desktop, VSCode and Harbour Samples](https://harbour.wiki/index.asp?page=PublicArticles&mode=show&id=221022022831&sig=9123873596)   
YOU DO NOT NEED to install VSCODE and the Harbour compiler, unless you intent to build DataWharf from source code, or contribute to the open-source project.   

## Install PostgreSQL
As stated in the Prerequisites, you will need administrative(root) access to an empty PostgreSQL database. The easiest way to achieve this is by installing a PostgreSQL server locally.   
1. [Download one of the latest versions](https://www.enterprisedb.com/downloads/postgres-postgresql-downloads) and install PostgreSQL. Avoid Beta versions.   
2. Install PostgreSQL. When the list of Components is presented, unless needed, unselect "Stack Builder". If you have more than one version of PostgreSQL, select a different port when prompted. Remember the install location (in case you would like to run PostgreSQL backups and restores.), port number and initial password of the "postgres" admin account.

## Create an empty database
You will need to create an empty database in a PostgreSQL server. If you followed the instructions above, you will be able to start the "pgAdmin" application.
1. Start pgAdmin
2. You may need to create a "Server Group..." on the left panel using a right click
3. Use Register (right click), "Server..."
4. On the "General" tab enter a "Name", for example: "localhost15"
5. On the "Connection" tab enter a "Host name/address": "localhost", and change the "Port" if the non default was used during the install.
6. On the same "Connection" tab you may want to enter the "postgres" account password you specified during install and select "Save password?"
7. On the right panel, go to the new registered server and right click to "Create" / "Database..."
8. Give a name for your database, for example: DataWharf
9. You may close down pgAdmin or leave it on to later see what the DataWharf application created for you.

## Install DataWharf
1. Start Docker Desktop
2. Create a local folder on your machine, for example: C:\DataWharfDocker
3. Get the following file from the official DataWharf Repo and place them in C:\DataWharfDocker. On the upper left corner you can use the "Download Raw File" icon.
    * [Dockerfile_Demo_Using_DockerHub_Ubuntu_22_04](https://github.com/EricLendvai/DataWharf/blob/main/Dockerfile_DockerHub_Base_Image_Ubuntu_22_04)
    * [config_demo.txt](https://github.com/EricLendvai/DataWharf/blob/main/config_demo.txt)
4. Optionally, also get the file named like ExportDataDictionary_DataWharf_*.zip from the same repo and place it in C:\DataWharfDocker.
5. Edit the file config_demo.txt and update the following lines as needed:
    * POSTGRESPORT
    * POSTGRESPASSWORD
    * POSTGRESDATABASE
6. Open a Command Prompt and go to c:\DataWharfDocker
7. Run "docker ps" to see of any container are running. 
8. If a previous version of DataWharf is running, you should use "docker stop \<ContainerID\>"
9. Execute the following two commands
    * docker build . -f Dockerfile_Demo_Using_DockerHub_Ubuntu_22_04 -t datawharf_demo_using_dockerhub_baseimage:latest
    * docker run -d -p 8080:80 datawharf_demo_using_dockerhub_baseimage:latest
10. Once the container is running, open a web browser and go to the following: http://localhost:8080
11. By default when DataWharf starts on an empty database, an initial user is created:
    * User ID: main
    * Password: password

## Optionally create your first "Application / Data Dictionary"

You may want to create an application called DataWharf to see the entire data dictionary information of DataWharf itself. Use the following steps:
1. Go to the menu "Settings" than select "Applications / Data Dictionaries"
2."New Application"
    * Name: DataWharf
    * Link Code: DW
3. "Save"
4. Go to the menu "Applications/Data Dictionaries"
5. Select "DataWharf"
6. Go to "Import"
7. In the "Export File" select the latest file "ExportDataDictionary_DataWharf_*-Zulu.zip" available in the DataWharf repo itself.
8. "Import" and Confirm
9. To see if working, goto the "Visualize" option.

You now can create your own Application / Data Dictionary and/or Projects.   
