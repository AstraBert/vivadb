module migrate_cmd

import os

@[assert_continues]
fn test_create_migration_directory() {
	wd := os.getwd()
	tmpdir := os.temp_dir()
	os.chdir(tmpdir)!
	os.write_file(tmpdir + "/schema.v.sql", "hello world")!
	create_migration_directory("0.1.0", "my-schema", "My test schema", true)!
	assert os.exists(tmpdir + "/" + migration_directory_prod + "/0.1.0/migration.json")
	assert os.exists(tmpdir + "/" + migration_directory_prod + "/0.1.0/schema.v.sql")
	os.chdir(tmpdir)!
	os.write_file(tmpdir + "/schema.v.sql", "hello world")!
	create_migration_directory("0.1.0", "my-schema", "My test schema", false)!
	assert os.exists(tmpdir + "/" + migration_directory_dev + "/0.1.0/migration.json")
	assert os.exists(tmpdir + "/" + migration_directory_dev + "/0.1.0/schema.v.sql")
	os.chdir(wd)!
}

@[assert_continues]
fn test_read_migration_file() {
	wd := os.getwd()
	os.chdir("test_data/correct_schema")!
	migr_dets, schema := read_migration_file(?string(none))!
	assert migr_dets.version == "0.1.0", "Version is not correct, actual version is: ${migr_dets.version}"
	assert migr_dets.name == "users", "Schema Name is not correct, actual version is: ${migr_dets.name}"
	assert migr_dets.description == "a database to track users", "Schema Description is not correct, actual version is: ${migr_dets.description}"
	assert "users" in schema.keys() && "user_sessions" in schema.keys(), "users and user_sessions are not in schema.keys(); real keys are: ${schema.keys()}"
	expected_users_components := [
		"id BIGINT PRIMARY KEY AUTO_INCREMENT,", "username VARCHAR(50) UNIQUE NOT NULL,", "email VARCHAR(255) UNIQUE NOT NULL,", "password_hash VARCHAR(255) NOT NULL,", "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP"
	]
	for component in expected_users_components {
		assert schema["users"].contains(component)
	}
	expected_user_sessions_components := [
		"id BIGINT PRIMARY KEY AUTO_INCREMENT,",
		"user_id BIGINT,",
		"start_at TIMESTAMP,",
		"end_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP"
	]
	for component in expected_user_sessions_components {
		assert schema["user_sessions"].contains(component)
	}
	paths := ["wrong_metadata", "wrong_tables"]
	mut v := ""
	for path in paths {
		os.chdir(wd)!
		read_migration_file("test_data/wrong_schema/${path}") or {v = "ERROR while reading ${path}/schema.v.sql"}
		assert v == "ERROR while reading ${path}/schema.v.sql", "No error occurred!"
	}
}

fn test_get_col_names() {
	cols := [DatabaseColumn{"hello", "", ""}, DatabaseColumn{"world", "", ""}]
	names := get_col_names(cols)
	assert names.len == 2
	assert cols.all(it.name in names)
}

struct DiffColTestCase {
	pub:
	old_cols []DatabaseColumn
	new_cols []DatabaseColumn
	expected_to_add []DatabaseColumn
	expected_to_delete []string
}

@[assert_continues]
fn test_get_diff_cols() {
	cases := [
		DiffColTestCase{
			[DatabaseColumn{"hello", "", ""}, DatabaseColumn{"world", "", ""}], 
			[DatabaseColumn{"hello", "", ""}], 
			[], 
			["world"]
		}, 
		DiffColTestCase{
			[DatabaseColumn{"hello", "", ""}, DatabaseColumn{"world", "", ""}],
			[DatabaseColumn{"hello", "", ""}, DatabaseColumn{"world", "", ""}, DatabaseColumn{"test", "", ""}],
			[DatabaseColumn{"test", "", ""}],
			[]
		},
		DiffColTestCase{
			[DatabaseColumn{"hello", "", ""}, DatabaseColumn{"world", "", ""}],
			[DatabaseColumn{"hello", "", ""}, DatabaseColumn{"test", "", ""}],
			[DatabaseColumn{"test", "", ""}],
			["world"]
		},
	]
	for test_case in cases {
		to_add, to_delete := get_diff_cols(test_case.new_cols, test_case.old_cols)
		assert to_add.len == test_case.expected_to_add.len
		assert to_add.all(it in test_case.expected_to_add)
		assert to_delete.len == test_case.expected_to_delete.len
		assert to_delete.all(it in test_case.expected_to_delete)
	}
}