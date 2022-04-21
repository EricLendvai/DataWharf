# DataWharf
DataWharf is a Database Designer/Modeler/Analyzer Tool web application.  

View [ChangeLog.md](ChangeLog.md) for list of enhancements and fixes.

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
| https://code.visualstudio.com/                 | Also used to automate compilation |

DataWharf can run on Windows, Linux or any platforms supported by the above list of repos/products.

View [Todo.md](Todo.md) for list of upcoming fixes and enhancements.

# VS Code Devcontainer
In order to develop in any environement you can use the VS Code devcontainer provided in this repo.
Install remote containers extension: https://aka.ms/vscode-remote/download/containers

## How to setup on a Mac with Lima instead of Docker Desktop
Configure lima for docker: https://georgik.rocks/how-to-develop-for-esp32-c3-with-rust-on-macos-with-lima-using-dev-container-in-vs-code/

## Build and run project
- Reopen the folder in the dev container: press `F1` and then do `>Remote-Containers: Open Folder in Container...`
- Open the Terminal (e.g., Shift + control + ` on Mac) and run apache and postgres:
`/etc/init.d/postgresql start && apache2ctl start & sleep infinity`

