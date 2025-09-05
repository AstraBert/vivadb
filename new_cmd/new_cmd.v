module new_cmd

import os
import dotenv

const schema = '--- Welcome to your schema file. Here, you can define the tables of your database, as well as several migration details.
--- In order for the file to work, it has to be named schema.v.sql

--- schema_name: users_db
--- schema_description: a database for tracking users
--- version: 0.0.0

--- `schema_name`, `version` and `schema_description` are special comments: they give vivadb migration details

--- Use the `TABLE` keyword to define a table
TABLE users (
    --- Use SQL syntax to define the fields of a table
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);'
const docker_compose = 'services:
  postgres:
    image: postgres
    container_name: postgres_db
    environment:
      POSTGRES_DB: \${PG_DBNAME}
      POSTGRES_USER: \${PG_USER}
      POSTGRES_PASSWORD: \${PG_PASSWORD}
    ports:
      - "\${PG_PORT}:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
  adminer:
    image: adminer
    ports:
      - 8080:8080

volumes:
  postgres_data:'

const readme_content = '## A vivadb project

Welcome to your new vivadb project!

You can find the `.env` file with all the database connection information, as well as the Docker Compose configuration file, [here](.vivadb/).

In order to migrate your database, you will have to modify the [schema.v.sql](./schema.v.sql) file. The file follows four syntax rules:

- Use `version`, `schema_name` and `schema_description` as comments at the top of the file: they will be used to identify the migration.
- Use the `TABLE` keyword to describe a table.
- Describe a table using SQL syntax
- Always close table statements with `;`

Here is an example:

```sql
--- version: 0.1.0
--- schema_name: users
--- schema_description: track user sign-ups

TABLE users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```'

fn write_schema_file() ! {
	os.write_file("schema.v.sql", schema)!
}

fn write_docker_compose() ! {
	os.write_file(".vivadb/compose.yaml", docker_compose)!
}

fn write_readme_file(project_name string) ! {
  os.write_file("README.md", "# ${project_name}\n\n" + readme_content)!
}

pub fn create_new_project(host string, port int, user string, dbname string, password string, production bool, project_name string, use_docker bool) ! {
	if os.exists("./"+project_name) {
		os.chdir("./"+project_name)!
	} else {
		os.mkdir_all("./"+project_name, os.MkdirParams{})!
		os.chdir("./"+project_name)!
	}
	dotenv.write_connection_dotenv(host, port, user, dbname, password, production) or {panic("unable to write .env")}
	succ_str := "Successfully written your connection configuration to " + if production {dotenv.prod_connection_dotenv} else {dotenv.dev_connection_dotenv}
	println(succ_str)
  write_readme_file(project_name)!
  println("Successfully written README file to README.md")
	write_schema_file()!
	println("Successfully written an example schema file to schema.v.sql")
	if use_docker {
		write_docker_compose()!
		println("Successfully written an example Docker compose config file to .vivadb/compose.yaml")
	}
	println("Your new project has been successfully configured!")
}