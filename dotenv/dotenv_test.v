module dotenv

import os

fn test_load_dotenv () {
	dotenv_args := load_dotenv(".env.test") or { map[string]string{} }
	assert "FOO" in dotenv_args.keys()
	assert "BAR" in dotenv_args.keys()
	assert "V" in dotenv_args.keys()
	assert dotenv_args["FOO"] == "BAR"
	assert dotenv_args["BAR"] == "FOO"
	assert dotenv_args["V"] == "IS_AWESOME"
}

fn test_write_connection_dotenv () {
	write_connection_dotenv("localhost", 5432, "admin", "postgres", "admin", false)!
	content_dev := os.read_file(dev_connection_dotenv)  or { "" }
	assert content_dev == "PG_PORT=5432\nPG_USER=admin\nPG_HOST=localhost\nPG_DBNAME=postgres\nPG_PASSWORD=admin"
	write_connection_dotenv("localhost", 5432, "admin", "postgres", "strong_password", true)!
	content_prod := os.read_file(prod_connection_dotenv) or { "" }
	assert content_prod == "PG_PORT=5432\nPG_USER=admin\nPG_HOST=localhost\nPG_DBNAME=postgres\nPG_PASSWORD=strong_password"
}