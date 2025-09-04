module migrate_cmd

import os

fn test_create_migration_directory() {
	tmpdir := os.temp_dir()
	os.chdir(tmpdir)!
	create_migration_directory("0.1.0", "my-schema", "My test schema", true)!
	assert os.exists(tmpdir + "/" + migration_directory_prod + "/0.1.0/migration.json")
	os.chdir(tmpdir)!
	create_migration_directory("0.1.0", "my-schema", "My test schema", false)!
	assert os.exists(tmpdir + "/" + migration_directory_dev + "/0.1.0/migration.json")
}