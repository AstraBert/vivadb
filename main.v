module main

import flag
import os
import dotenv
import dbops
import new_cmd
import migrate_cmd

struct Config {
	show_help bool @[long: help; short: h; xdoc: 'Show help message']
}

struct ConfigConnect {
	show_help      bool   @[long: help; short: h; xdoc: 'Show help message']
	host          string @[long: host; xdoc: 'Host for the Postgres DB']
	port          int    @[long: port; xdoc: 'Port for the Postgres DB']
	user          string @[long: user; xdoc: 'Postgres user']
	password_stdin bool   @[long: password_stdin; xdoc: 'Input password from standard input']
	password      string @[long: password; xdoc: 'Password (not recommended for production use)']
	dbname        string @[long: dbname; xdoc: 'Name of the database']
	production    bool   @[long: prod; xdoc: 'Write to production env file']
}

struct ConfigExec {
	show_help      bool   @[long: help; short: h; xdoc: 'Show help message']
	safe bool @[long: safe; short: s; xdoc: 'Execute only safe queries']
	query string @[long: query; short: q; xdoc: 'SQL query to execute']
	production    bool   @[long: prod; short: p; xdoc: 'Whether or not you are running this query in a production environment']
}

struct ConfigNew {
	show_help      bool   @[long: help; short: h; xdoc: 'Show help message']
	host          string @[long: host; xdoc: 'Host for the Postgres DB']
	port          int    @[long: port; xdoc: 'Port for the Postgres DB']
	user          string @[long: user; xdoc: 'Postgres user']
	password_stdin bool   @[long: password_stdin; xdoc: 'Input password from standard input']
	password      string @[long: password; xdoc: 'Password (not recommended for production use)']
	dbname        string @[long: dbname; xdoc: 'Name of the database']
	production    bool   @[long: prod; xdoc: 'Write to production env file']
	project_name string @[xdoc: 'Name of the project']
	docker bool @[xdoc: 'Create a minimal Docker compose configuration file to run a Postgres instance']
}

struct ConfigMigrate {
	show_help      bool   @[long: help; short: h; xdoc: 'Show help message']
	production    bool   @[long: prod; xdoc: 'Whether or not the migration is happening in a production environment']
}

fn main() {
	// Handle sub command `config` if provided
	if os.args.len > 1 && !os.args[1].starts_with('-') {
		if os.args[1] == 'config' {
			config_for_connect, _ := flag.to_struct[ConfigConnect](os.args, skip: 2)! // Fixed: was ConfigSub, now ConfigConnect
			if config_for_connect.show_help {
				println(flag.to_doc[ConfigConnect](
					description: 'config: a command for configuring the connection to a Postgres DB'
				)!)
				exit(0)
			}

			// Declare password variable properly
			mut password := ''
			if config_for_connect.password_stdin {
				password = os.input_password('Your password here: ')!
			} else {
				println("WARNING\tIt is not advisable to provide the password through CLI. Use --password-stdin to input it from standard input")
				password = config_for_connect.password
			}

			host := config_for_connect.host
			port := config_for_connect.port
			user := config_for_connect.user
			dbname := config_for_connect.dbname
			production := config_for_connect.production

			dotenv.write_connection_dotenv(host, port, user, dbname, password, production) or {panic("unable to write .env")}
			succ_str := "Successfully written your connection configuration to " + if production {dotenv.prod_connection_dotenv} else {dotenv.dev_connection_dotenv}
			println(succ_str)
		} else if os.args[1] == "exec" {
			config_for_exec, _ := flag.to_struct[ConfigExec](os.args, skip: 2)!
			if config_for_exec.show_help {
				println(flag.to_doc[ConfigExec](
					description: 'exec: a production-aware command for safely executing SQL queries'
				)!)
				exit(0)
			}
			query := config_for_exec.query
			safe_exec := config_for_exec.safe
			production := config_for_exec.production
			data := dbops.execute_query(query, production, safe_exec)!
			if data.len > 0 {
				println(data)
			} else {
				println("Success! No rows returned.")
			}
		} else if os.args[1] == "new" {
			config_for_new, _ := flag.to_struct[ConfigNew](os.args, skip: 2)!
			if config_for_new.show_help {
				println(flag.to_doc[ConfigNew](
					description: 'new: create a new project and integrate it with vivadb immediately'
				)!)
				exit(0)
			}
			// Declare password variable properly
			mut password := ''
			if config_for_new.password_stdin {
				password = os.input_password('Your password here: ')!
			} else {
				println("WARNING\tIt is not advisable to provide the password through CLI. Use --password-stdin to input it from standard input")
				password = config_for_new.password
			}

			host := config_for_new.host
			port := config_for_new.port
			user := config_for_new.user
			dbname := config_for_new.dbname
			production := config_for_new.production
			project_name := config_for_new.project_name.trim_space().replace(" ", "_")
			use_docker := config_for_new.docker

			new_cmd.create_new_project(host, port, user, dbname, password, production, project_name, use_docker)!
		} else if os.args[1] == "migrate" {
			config_for_migrate, _ := flag.to_struct[ConfigMigrate](os.args, skip: 2)!
			if config_for_migrate.show_help {
				println(flag.to_doc[ConfigMigrate](
					description: 'migrate: update your database effortlessly, in a production-aware way.'
				)!)
				exit(0)
			}

			production := config_for_migrate.production
			migrate_cmd.migrate(production)!
		}
	}

	config, _ := flag.to_struct[Config](os.args, skip: 1)!

	if config.show_help {
		help_message := '
vivadb: a next generation Postgres DB manager

USAGE:
	vivadb [OPTIONS] [SUBCOMMAND]

OPTIONS:
	-h, --help    Show this help message

SUBCOMMANDS:
	config        Configure connection to a Postgres database
	exec          Execute SQL queries in a production-aware manner
	new           Create a new project and integrate it with vivadb
	migrate       Update your database schema effortlessly

Use "vivadb <subcommand> --help" for more information about a specific subcommand.

EXAMPLES:
	vivadb config --host=localhost --port=5432 --user=user --dbname=mydb --password-stdin
	vivadb exec --query="SELECT * FROM users;" --safe
	vivadb new --project-name=my_app --docker --host=localhost --port=5432 --user=user --dbname=mydb --password-stdin
	vivadb migrate --prod
'
		println(help_message)
		exit(0)
	}
}
