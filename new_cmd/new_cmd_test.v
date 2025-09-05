module new_cmd

import os

fn test_create_new_project() {
	tmpdir := os.temp_dir()
	os.chdir(tmpdir)!
	create_new_project("localhost", 5432, "user", "postgres", "admin", true, "test", true)!
	assert os.exists(tmpdir + "/test/.vivadb/.env")
	assert os.exists(tmpdir + "/test/.vivadb/compose.yaml")
	assert os.exists(tmpdir + "/test/schema.v.sql")
	assert os.exists(tmpdir + "/test/README.md")
	os.chdir(tmpdir)!
	create_new_project("localhost", 5432, "user", "postgres", "admin", false, "test_1", false)!
	assert os.exists(tmpdir + "/test_1/.vivadb/.env.local")
	assert !os.exists(tmpdir + "/test_1/.vivadb/compose.yaml")
	assert os.exists(tmpdir + "/test_1/README.md")
	assert os.exists(tmpdir + "/test_1/schema.v.sql")
}