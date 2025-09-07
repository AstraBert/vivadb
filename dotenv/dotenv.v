module dotenv

import os

pub const prod_connection_dotenv = '.vivadb/.env'
pub const dev_connection_dotenv = '.vivadb/.env.local'

pub fn load_dotenv(dotenv_path string) ?map[string]string {
	lines := os.read_lines(dotenv_path) or { [] }
	if lines.len == 0 {
		return none
	} else {
		mut dotenv_args := map[string]string{}
		for line in lines {
			mut ln := line.replace('\n', '')
			ln = ln.replace('"', '')
			ln = ln.replace("'", '')
			ln = ln.replace(' = ', '=')
			ln = ln.trim_space()

			if ln == '' || ln.starts_with('#') {
				continue
			}

			if !ln.contains('=') {
				continue
			}

			key, val := ln.split_once('=') or { continue }

			clean_key := key.trim_space()
			clean_val := val.trim_space()

			if clean_key != '' {
				dotenv_args[clean_key] = clean_val
			}
		}
		return dotenv_args
	}
}

pub fn write_connection_dotenv(host string, port int, user string, dbname string, password string, production bool) ! {
	dot_env_content := 'PG_PORT=${port}\nPG_USER=${user}\nPG_HOST=${host}\nPG_DBNAME=${dbname}\nPG_PASSWORD=${password}'
	if !os.exists('.vivadb/') {
		os.mkdir_all('.vivadb/')!
	}
	if production {
		os.write_file(prod_connection_dotenv, dot_env_content)!
	} else {
		os.write_file(dev_connection_dotenv, dot_env_content)!
	}
}
