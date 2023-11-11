# Running DataWharf using docker-compose

## Prerequisites
-	For Windows and Mac users, the easiest is to Install Docker Desktop.   
	-	For Windows users you can use the following article to learn how to [setup WSL, Docker Desktop](https://harbour.wiki/index.asp?page=PublicArticles&mode=show&id=221022022831&sig=9123873596)   
-	You'll need to have docker-compose installed

## Build and run
```
docker-compose --project-directory . --file hosting/docker/docker-compose.yml --env-file hosting/docker/environment.env up -d
```
The above will:
-	Build your own DataWharf container using the latest Ubuntu
-	Run two containers:
	-	DataWharf
	-	A postgres container

If you want it to behave differently than that, you'll need to use a different docker-compose file.  

Return to the main README and go on to the "Using Dockerwharf" section
