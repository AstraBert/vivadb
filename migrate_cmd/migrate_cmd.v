module migrate_cmd

import dbops
import json
import os

pub const migration_directory_prod = ".vivadb/migrations/prod/"
pub const migration_directory_dev = ".vivadb/migrations/dev/"
pub const migration_file_path = "schema.v.sql"

struct MigrationDetails {
	pub mut:
	version string
	name string
	description string
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
		panic("Unable to find schema_name and/or version fields in your schema.v.sql file: please check that you included them as comments.")
	}
	tables := content.split("TABLE ").filter(!it.starts_with("---"))
	if tables.len == 0 {
		panic("Unable to find tables within your schema file, please check that the syntax aligns with the rules")
	}
	mut name_to_statement := map[string]string{}
	for table in tables {
		key, val := table.split_once("(") or {continue}
		clean_key := key.trim_space()
		clean_val := "(" + val
		name_to_statement[clean_key][clean_val]
	}
	if name_to_statement.keys().len == 0 {
		panic("Unable to map the table names with the table definition statements. Please check that the syntax is valid SQL.")
	}
	return migr_dets, name_to_statement
}