module dbops

import db.pg
import dotenv
import readline

const unsafe_keywords = ["drop", "delete", "update", "insert", "truncate", "alter", ";", "union", "or", "||"]

pub fn db_connection_config(production bool) !pg.Config {
	mut dets := map[string]string{}
	if production {
		dets = dotenv.load_dotenv(dotenv.prod_connection_dotenv) or {panic("no .env")}
	} else {
		dets = dotenv.load_dotenv(dotenv.dev_connection_dotenv) or {panic("no .env")}
	}
	port := dets["PG_PORT"] or {panic("no port available")}
	return pg.Config{
		host: dets["PG_HOST"] or {panic("no host available")}
		port: port.int()
		user: dets["PG_USER"] or {panic("no user available")}
		password: dets["PG_PASSWORD"] or {panic("no password available")}
		dbname: dets["PG_DBNAME"] or {panic("no dbname available")}
	}
}

fn check_query(query string) bool {
	return unsafe_keywords.any(query.to_lower().contains(it))
}

pub fn execute_query(query string, production bool, safe_exec bool) ![]pg.Row {
	if safe_exec {
		if check_query(query) {
			println("You might be running an unsafe query. Turn off safe execution to execute anyway.")
			exit(1)
		}
	}

	if production {
		mut keywords_to_check := unsafe_keywords.clone()
		keywords_to_check << ["create", "grant", "revoke", "set", "show"]
		if keywords_to_check.any(query.to_lower().contains(it)) {
			mut r := readline.Readline{}
			approval := r.read_line('You might be running an unsafe query in a production environment. Are you sure you want to continue? [yes/no]')!
			if approval != "yes" {
				println("Exiting...")
				exit(0)
			}
		}
	}

	conn_conf := db_connection_config(production)!
	
	db := pg.connect(conn_conf)!

	defer {
		db.close() or {panic("unable to close database connection")}
	}

	retval := db.exec(query)!

	return retval
}