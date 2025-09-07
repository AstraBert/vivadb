module dbops

import dotenv

fn test_db_connection_config() {
	dotenv.write_connection_dotenv('prod.db.com', 5432, 'superuser', 'postgres', 'strong_password',
		true)!
	retval := db_connection_config(true)!
	assert retval.host == 'prod.db.com'
	assert retval.port == 5432
	assert retval.user == 'superuser'
	assert retval.dbname == 'postgres'
	assert retval.password == 'strong_password'
	dotenv.write_connection_dotenv('localhost', 5432, 'admin', 'postgres', 'admin', false)!
	retval1 := db_connection_config(false)!
	assert retval1.host == 'localhost'
	assert retval1.port == 5432
	assert retval1.user == 'admin'
	assert retval1.dbname == 'postgres'
	assert retval1.password == 'admin'
}
