module migrate_cmd

import dbops
import json
import os

pub const migration_directory_prod = ".vivadb/migrations/prod/"
pub const migration_directory_dev = ".vivadb/migrations/dev/"

struct MigrationDetails {
	version string
	name string
	description string = ""
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