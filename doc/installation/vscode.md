# VS Code Devcontainer

In order to develop in any environment you can use the VS Code devcontainer provided in this repo.
Install remote containers extension: https://aka.ms/vscode-remote/download/containers
For Windows users you can use the following article to learn how to [setup WSL, Docker Desktop](https://harbour.wiki/index.asp?page=PublicArticles&mode=show&id=221022022831&sig=9123873596)

## How to setup on a Mac with Lima instead of Docker Desktop
Source: [here](https://georgik.rocks/how-to-develop-for-esp32-c3-with-rust-on-macos-with-lima-using-dev-container-in-vs-code/)

Install Lima and Docker-CLI:
```
brew install lima docker
```

Create Linux VM with Dockerd:

```
curl https://raw.githubusercontent.com/lima-vm/lima/master/examples/docker.yaml -O
limactl start ./docker.yaml
limactl shell docker
sudo systemctl enable ssh.service
```
There is one important tweak in the Lima configuration. It’s necessary to enable write operation otherwise, the workspace mounted from VS Code is read-only. Open file `~/.lima/docker/lima.yaml` and add writable flag to desired folder:
```
mounts:
- location: "~"
  writable: true
```
Restart Lima to apply changes.
```
limactl stop docker
limactl start docker
```

Create context for Docker-CLI to connect to dockerd running in the VM:


```
docker context create lima --docker "host=unix://${HOME}/.lima/docker/sock/docker.sock"
docker context use lima
```


## Build and run project
- Reopen the folder in the dev container: press `F1` and then do `>Remote-Containers: Open Folder in Container...`
- You can now use the following tasks defined by VS Code to compile/debug:
  - `<Compile Debug>`: Compiles with debug settings and deployes the executable inside the backend part of the apache website: `/var/www/Harbour_websites/fcgi_DataWharf/backend/`. (Note: only the exe will be copied there for now, changes done to website parts such as `.js` or `.css` files need to be copied there manually).
  - `<Compile Release>`: Build without debug settings.
  - `<Debug>`: Attaches to the running executable inside Apache.
- Go to `Ports` view and open the port that exposes port `80` on the host (e.g., http://localhost:60677)
![alt](doc/images/devcontainer-ports.png)

## Database
- The PostgreSQL DB is also accessible from the host via the exposed port `5432`.
- Using e.g., PGAdmin you can connect using the following credentials:
  - Host: `localhost`
  - Port: `5432`
  - Username: `datawharf`
  - Password: `mypassord`
