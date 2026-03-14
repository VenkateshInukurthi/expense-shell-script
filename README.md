# expense-shell-script

# MySQL

Developer has chosen the database MySQL. Hence, we are trying to install it up and configure it.

**Versions of the DB Software you will get context from the developer, Meaning we need to check with developer.**

Install MySQL Server 8.0.x

```
dnf install mysql-server -y
```

Start MySQL Service

```
systemctl enable mysqld
```
```
systemctl start mysqld
```

Next, We need to change the default root password in order to start using the database service. Use password ExpenseApp@1 or any other as per your choice.

```
mysql_secure_installation --set-root-pass ExpenseApp@1
```

## Verification

We can check data by using client package called mysql.

Usually command to connect mysql server is

```
mysql -h <host-address> -u root -p<password>
```

But if your client and server both are in a single server, you can simply issue.

```
mysql
```

Once you got mysql prompt, you can use below command to check schemas/databases exist.

```
show databases;
```

Once you are in particular schema, you can get the list of tables.

```
show tables;
```

You can get entries of a table using

```
select * from <table_name>;
```


BACKEND

### Backend
Backend service is responsible for adding the given values to database. Backend service is written in NodeJS, Hence we need to install NodeJS.

**Developer has chosen NodeJs, Check with developer which version of NodeJS is needed. Developer has set a context that it can work with NodeJS >20**

Install NodeJS, By default NodeJS 16 is available, We would like to enable 20 version and install this.

**You can list modules by using dnf module list**

```
dnf module disable nodejs -y
```
```
dnf module enable nodejs:20 -y
```

```
dnf install nodejs -y
```

Configure the application.

Add application User
```
useradd expense
```

User expense is a function / daemon user to run the application. Apart from that we don't use this user to login to server.

Also, username expense has been picked because it more suits to our project name.

We keep application in one standard location. This is a usual practice that runs in the organization.

Lets setup an app directory.

```
mkdir /app
```

Download the application code to created app directory.

```
curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip
```
```
cd /app
```
```
unzip /tmp/backend.zip
```

Every application is developed by development team will have some common softwares that they use as libraries. This application also have the same way of defined dependencies in the application configuration.

Lets download the dependencies.

```
cd /app
```
```
npm install
```

We need to setup a new service in systemd so systemctl can manage this service

Setup SystemD Expense Backend Service
```
vim /etc/systemd/system/backend.service
```

```
[Unit]
Description = Backend Service

[Service]
User=expense
Environment=DB_HOST="<MYSQL-SERVER-IPADDRESS>"
ExecStart=/bin/node /app/index.js
SyslogIdentifier=backend

[Install]
WantedBy=multi-user.target
```

**NOTE: Ensure you replace <MYSQL-SERVER-IPADDRESS> with IP address**

Load the service.

```
systemctl daemon-reload
```

Start the service.
```
systemctl start backend
```
```
systemctl enable backend
```

For this application to work fully functional we need to load schema to the Database.

We need to load the schema. To load schema we need to install mysql client.

To have it installed we can use

```
dnf install mysql -y
```

Load Schema

```
mysql -h <MYSQL-SERVER-IPADDRESS> -uroot -pExpenseApp@1 < /app/schema/backend.sql
```

Restart the service.
```
systemctl restart backend
```

FRONTEND:
# Frontend

The frontend is the service in Expense to serve the web content over Nginx. This will have the web frame for the web application.

This is a static content and to serve static content we need a web server. This server

Developer has chosen Nginx as a web server and thus we will install Nginx Web Server.

Install Nginx
```
dnf install nginx -y 
```
Enable nginx
```
systemctl enable nginx
```
Start nginx
```
systemctl start nginx
```

**Try to access the service once over the browser and ensure you get some default content**

Remove the default content that web server is serving.
```
rm -rf /usr/share/nginx/html/*
```

Download the frontend content
```
curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip
```
Extract the frontend content.
```
cd /usr/share/nginx/html
```
```
unzip /tmp/frontend.zip
```

**Try to access the nginx service once more over the browser and ensure you get expense content.**

Create Nginx Reverse Proxy Configuration.
```
vim /etc/nginx/default.d/expense.conf
```
Add the following content
```
proxy_http_version 1.1;

location /api/ { proxy_pass http://localhost:8080/; }

location /health {
  stub_status on;
  access_log off;
}
```

**Ensure you replace the localhost with the actual ip address of backend component server. Word localhost is just used to avoid the failures on the Nginx Server.**

Restart Nginx Service to load the changes of the configuration.

```
systemctl restart nginx
```