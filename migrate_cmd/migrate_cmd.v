module migrate_cmd

import dbops
import json
import encoding.csv
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

pub fn read_migration_file(base_dir ?string) !(MigrationDetails, map[string]string) {
	mut migration_fl_dir := base_dir or {""}
	if migration_fl_dir != "" {
		migration_fl_dir = migration_fl_dir + "/" 
	}
	content := os.read_file(migration_fl_dir + migration_file_path)!
	lines := os.read_lines(migration_fl_dir + migration_file_path)!
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

fn get_latest_migration(production bool, current_version string) !string {
	data := dbops.execute_query("SELECT * FROM _vivadb_migrations ORDER BY applied_at;", false, false)!
	mut parser := csv.new_reader(data)
	mut values := [][]string{}
	for {
		items := parser.read() or { break }
		values << items
	}
	last_versions := values.filter(current_version !in it)
	last_version := last_versions[last_versions.len-1][0]
	prod := last_versions[last_version.len-1][1] != "f"
	if prod {
		return migration_directory_prod + "/" + last_version
	} else {
		return migration_directory_dev + "/" + last_version
	}
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

fn get_old_table_def(table_name string, current_version string, production bool) !string {
	path := get_latest_migration(production, current_version)!
	_, schema := read_migration_file(path)!
	if table_name in schema {
		return schema[table_name]
	} else {
		return error("Table ${table_name} does not seem to exist in older versions...")
	}
}

fn get_col_names(cols []DatabaseColumn) []string {
	mut names := []string{}
	for col in cols {
		names << col.name
	}
	return names
}

fn update_table(table_name string, table_def string, current_version string, production bool) ! {
	old_table_def := get_old_table_def(table_name, current_version, production)!
	old_cols_def := get_table_columns(old_table_def)!
	new_cols_def := get_table_columns(table_def)!
	if new_cols_def.len > old_cols_def.len {
		added_cols := new_cols_def.filter(it.name !in get_col_names(old_cols_def))
		for col in added_cols {
			dbops.execute_query("ALTER TABLE ${table_name} ADD COLUMN ${col.name} ${col.data_type} ${col.constraints}", false, false)!
		}
	} else if new_cols_def.len < old_cols_def.len {
		dropped_cols := old_cols_def.filter(it.name !in get_col_names(new_cols_def))
		for col in dropped_cols {
			dbops.execute_query("ALTER TABLE ${table_name} DROP COLUMN ${col.name}", false, false)!
		}
	} else {
		if get_col_names(old_cols_def).all(it in get_col_names(new_cols_def)) {
			for i in 0 .. new_cols_def.len {
				if new_cols_def[i].constraints != old_cols_def[i].constraints {
					dbops.execute_query("ALTER TABLE ${table_name} ADD CONSTRAINT ${table_name}_${new_cols_def[i].name}_${i} ${new_cols_def[i].constraints} (${new_cols_def[i].name});", false, false)!
				}
				if new_cols_def[i].data_type != old_cols_def[i].data_type {
					dbops.execute_query("ALTER TABLE ${table_name} ALTER COLUMN ${new_cols_def[i].name} TYPE ${new_cols_def[i].data_type};", false, false)!
				}
			}
		} else {
			println("You are screwed... for now")
		}
	}
}

pub fn migrate(production bool) ! {
	migr_dets, schema := read_migration_file(?string(none))!
	create_migration_directory(migr_dets.version, migr_dets.name, migr_dets.description, production)!
	register_migration(production, migr_dets.version)!
	for key in schema.keys() {
		if table_exists(key) or {false} {
			update_table(key, schema[key], migr_dets.version, production)!
			println("Table ${key} successfully updated")
		} else {
			create_table(key, schema[key])!
			println("Table ${key} successfully created")
		}
	}
}