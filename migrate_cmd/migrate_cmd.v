module migrate_cmd

import dbops
import json
import os

pub const migration_directory_prod = ".vivadb/migrations/prod"
pub const migration_directory_dev = ".vivadb/migrations/dev"
pub const migration_file_path = "schema.v.sql"

pub struct MigrationDetails {
	pub mut:
	version string
	name string
	description string
}

pub struct DatabaseColumn {
	pub:
	name string
	data_type string
	constraints string
}

pub fn create_migration_directory(version string, name string, description string, production bool) ! {
	mut full_path := ""
	if production {
		full_path = migration_directory_prod + "/" + version
	} else {
		full_path = migration_directory_dev + "/" + version
	}
	os.mkdir_all(full_path)!
	migr_info := MigrationDetails{version, name, description}
	os.write_file(full_path + "/migration.json", json.encode(migr_info))!
	os.cp("schema.v.sql", full_path + "/schema.v.sql")!
	println("Successfully created your migration directory. Find information at: ${full_path}/migration.json")
}

pub fn read_migration_file() !(MigrationDetails, map[string]string) {
	content := os.read_file(migration_file_path)!
	lines := os.read_lines(migration_file_path)!
	mut migr_dets := MigrationDetails{}
	for line in lines {
		if line.contains("---") && line.contains("version:") {
			_, ver := line.split_once("version:") or {continue}
			clean_ver := ver.trim_space()
			migr_dets.version = clean_ver
		} else if line.contains("---") && line.contains("schema_name:") {
			_, nm := line.split_once("schema_name:") or {continue}
			clean_nm := nm.trim_space()
			migr_dets.name = clean_nm
		} else if line.contains("---") && line.contains("schema_description:") {
			_, des := line.split_once("schema_description:") or {continue}
			clean_des := des.trim_space()
			migr_dets.description = clean_des
		} else {
			continue
		}
	}
	if migr_dets.name == "" || migr_dets.version == "" {
		return error("Unable to find schema_name and/or version fields in your schema.v.sql file: please check that you included them as comments.")
	}
	tables := content.split("TABLE ").filter(!it.starts_with("---"))
	if tables.len == 0 {
		return error("Unable to find tables within your schema file, please check that the syntax aligns with the rules")
	}
	mut name_to_statement := map[string]string{}
	for table in tables {
		key, val := table.split_once("(") or {continue}
		clean_key := key.trim_space()
		clean_val := "(" + val
		name_to_statement[clean_key] = clean_val
	}
	if name_to_statement.keys().len == 0 {
		return error("Unable to map the table names with the table definition statements. Please check that the syntax is valid SQL.")
	}
	println("Your schema.v.sql file has been succesffully read!")
	println("Found the following details:\nVersion: ${migr_dets.version}\nSchema Name: ${migr_dets.name}\nSchema Description: ${migr_dets.description}")
	return migr_dets, name_to_statement
}

fn register_migration(production bool, version string) ! {
	_ := dbops.execute_query("CREATE TABLE IF NOT EXISTS _vivadb_migrations (version VARCHAR(255) PRIMARY KEY, production BOOLEAN DEFAULT TRUE, applied_at TIMESTAMP DEFAULT NOW())", false, false)!
	mut prod_val := ""
	if production {
		prod_val = "TRUE"
	} else {
		prod_val = "FALSE"
	}
	_ := dbops.execute_query("INSERT INTO _vivadb_migrations (version, production) VALUES ('${version}', ${prod_val})", false, false)!
}

fn table_exists(table_name string) !bool {
	retval := dbops.execute_query("SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = '${table_name}')", false, false)!
	return retval.trim_space().replace("\n", "") == "t"
}

fn create_table(table_name string, table_def string) ! {
	_ := dbops.execute_query("CREATE TABLE ${table_name} ${table_def}", false, false)!
}

fn get_table_columns(table_def string) ![]DatabaseColumn {
	table_def_clean := table_def.replace("(","").replace(")", "").replace("\n", "").replace(";", "")
	cols := table_def_clean.split(",")
	mut table_cols := []DatabaseColumn{}
	for col in cols {
		col_clean := col.trim_space()
		col_fields := col_clean.split_n(" ", 3)
		table_cols << DatabaseColumn{col_fields[0], col_fields[1], col_fields[2] or {""}}
	}
	if table_cols.len == 0 {
		return error("Unable to find columns within your table schema definition... Are you using SQL syntax?")
	}
	return table_cols
}

fn update_table(table_name string, table_def string) ! {
	println(table_name)
	println(get_table_columns(table_def) or {[]})
}

pub fn migrate(production bool) ! {
	migr_dets, schema := read_migration_file()!
	create_migration_directory(migr_dets.version, migr_dets.name, migr_dets.description, production)!
	register_migration(production, migr_dets.version)!
	for key in schema.keys() {
		if table_exists(key) or {false} {
			update_table(key, schema[key])!
		} else {
			create_table(key, schema[key])!
			println("Table ${key} successfully created")
		}
	}
}