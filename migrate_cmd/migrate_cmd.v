module migrate_cmd

import dbops
import json
import encoding.csv
import os

pub const migration_directory_prod = '.vivadb/migrations/prod'
pub const migration_directory_dev = '.vivadb/migrations/dev'
pub const migration_file_path = 'schema.v.sql'

pub struct MigrationDetails {
pub mut:
	version     string
	name        string
	description string
}

pub struct DatabaseColumn {
pub:
	name        string
	data_type   string
	constraints string
}

pub fn create_migration_directory(version string, name string, description string, production bool) ! {
	mut full_path := ''
	if production {
		full_path = migration_directory_prod + '/' + version
	} else {
		full_path = migration_directory_dev + '/' + version
	}
	os.mkdir_all(full_path)!
	migr_info := MigrationDetails{version, name, description}
	os.write_file(full_path + '/migration.json', json.encode(migr_info))!
	os.cp('schema.v.sql', full_path + '/schema.v.sql')!
	println('Successfully created your migration directory. Find information at: ${full_path}/migration.json')
}

pub fn read_migration_file(base_dir ?string) !(MigrationDetails, map[string]string) {
	mut migration_fl_dir := base_dir or { '' }
	if migration_fl_dir != '' {
		migration_fl_dir = migration_fl_dir + '/'
	}
	content := os.read_file(migration_fl_dir + migration_file_path)!
	lines := os.read_lines(migration_fl_dir + migration_file_path)!
	mut migr_dets := MigrationDetails{}
	for line in lines {
		if line.contains('---') && line.contains('version:') {
			_, ver := line.split_once('version:') or { continue }
			clean_ver := ver.trim_space()
			migr_dets.version = clean_ver
		} else if line.contains('---') && line.contains('schema_name:') {
			_, nm := line.split_once('schema_name:') or { continue }
			clean_nm := nm.trim_space()
			migr_dets.name = clean_nm
		} else if line.contains('---') && line.contains('schema_description:') {
			_, des := line.split_once('schema_description:') or { continue }
			clean_des := des.trim_space()
			migr_dets.description = clean_des
		} else {
			continue
		}
	}
	if migr_dets.name == '' || migr_dets.version == '' {
		return error('Unable to find schema_name and/or version fields in your schema.v.sql file: please check that you included them as comments.')
	}
	tables := content.split('TABLE ').filter(!it.starts_with('---'))
	if tables.len == 0 {
		return error('Unable to find tables within your schema file, please check that the syntax aligns with the rules')
	}
	mut name_to_statement := map[string]string{}
	for table in tables {
		key, val := table.split_once('(') or { continue }
		clean_key := key.trim_space()
		clean_val := '(' + val
		name_to_statement[clean_key] = clean_val
	}
	if name_to_statement.keys().len == 0 {
		return error('Unable to map the table names with the table definition statements. Please check that the syntax is valid SQL.')
	}
	println('Your schema.v.sql file has been succesffully read!')
	println('Found the following details:\nVersion: ${migr_dets.version}\nSchema Name: ${migr_dets.name}\nSchema Description: ${migr_dets.description}')
	return migr_dets, name_to_statement
}

pub fn register_migration(production bool, version string) ! {
	_ := dbops.execute_query('CREATE TABLE IF NOT EXISTS _vivadb_migrations (version VARCHAR(255) PRIMARY KEY, production BOOLEAN DEFAULT TRUE, applied_at TIMESTAMP DEFAULT NOW())',
		false, false)!
	mut prod_val := ''
	if production {
		prod_val = 'TRUE'
	} else {
		prod_val = 'FALSE'
	}
	_ := dbops.execute_query("INSERT INTO _vivadb_migrations (version, production) VALUES ('${version}', ${prod_val})",
		false, false)!
}

pub fn get_latest_migration(production bool, current_version string) !string {
	data := dbops.execute_query('SELECT * FROM _vivadb_migrations ORDER BY applied_at;',
		false, false)!
	mut parser := csv.new_reader(data)
	mut values := [][]string{}
	for {
		items := parser.read() or { break }
		values << items
	}
	last_versions := values.filter(current_version !in it)
	if last_versions.len == 0 {
		return error('No previous migrations found')
	}
	last_version := last_versions[last_versions.len - 1][0]
	prod := last_versions[last_versions.len - 1][1] != 'f'
	if prod {
		return migration_directory_prod + '/' + last_version
	} else {
		return migration_directory_dev + '/' + last_version
	}
}

pub fn table_exists(table_name string) !bool {
	retval := dbops.execute_query("SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = '${table_name}')",
		false, false)!
	return retval.trim_space().replace('\n', '') == 't'
}

pub fn create_table(table_name string, table_def string, production bool) ! {
	_ := dbops.execute_query('CREATE TABLE ${table_name} ${table_def}', production, false)!
}

pub fn get_table_columns(table_def string) ![]DatabaseColumn {
	table_def_clean := table_def.replace('(\n', '').replace(');', '').replace('\n', '')
	cols := table_def_clean.split(', ')
	mut table_cols := []DatabaseColumn{}
	for col in cols {
		col_clean := col.trim_space()
		col_fields := col_clean.split_n(' ', 3)
		table_cols << DatabaseColumn{col_fields[0], col_fields[1], col_fields[2] or { '' }}
	}
	if table_cols.len == 0 {
		return error('Unable to find columns within your table schema definition... Are you using SQL syntax?')
	}
	return table_cols
}

pub fn get_old_table_def(table_name string, current_version string, production bool) !string {
	path := get_latest_migration(production, current_version)!
	_, schema := read_migration_file(path)!
	if table_name in schema {
		return schema[table_name]
	} else {
		return error('Table ${table_name} does not seem to exist in older versions...')
	}
}

pub fn get_col_names(cols []DatabaseColumn) []string {
	mut names := []string{}
	for col in cols {
		names << col.name
	}
	return names
}

pub fn get_diff_cols(new_cols []DatabaseColumn, old_cols []DatabaseColumn) ([]DatabaseColumn, []string) {
	to_add := new_cols.filter(it.name !in get_col_names(old_cols))
	to_delete := old_cols.filter(it.name !in get_col_names(new_cols))
	return to_add, get_col_names(to_delete)
}

pub fn update_table(table_name string, table_def string, current_version string, production bool) ! {
	old_table_def := get_old_table_def(table_name, current_version, production)!
	old_cols_def := get_table_columns(old_table_def)!
	new_cols_def := get_table_columns(table_def)!
	if new_cols_def.len > old_cols_def.len {
		to_add, to_delete := get_diff_cols(new_cols_def, old_cols_def)
		for col in to_add {
			dbops.execute_query('ALTER TABLE ${table_name} ADD COLUMN ${col.name} ${col.data_type} ${col.constraints}',
				production, false)!
		}
		if to_delete.len > 0 {
			for col_name in to_delete {
				dbops.execute_query('ALTER TABLE ${table_name} DROP COLUMN ${col_name}',
					production, false)!
			}
		}
	} else if new_cols_def.len < old_cols_def.len {
		to_add, to_delete := get_diff_cols(new_cols_def, old_cols_def)
		for col_name in to_delete {
			dbops.execute_query('ALTER TABLE ${table_name} DROP COLUMN ${col_name}', production,
				false)!
		}
		if to_add.len > 0 {
			for col in to_add {
				dbops.execute_query('ALTER TABLE ${table_name} ADD COLUMN ${col.name} ${col.data_type} ${col.constraints}',
					production, false)!
			}
		}
	} else {
		if get_col_names(old_cols_def).all(it in get_col_names(new_cols_def)) {
			for i in 0 .. new_cols_def.len {
				if new_cols_def[i].constraints != old_cols_def[i].constraints {
					if new_cols_def[i].constraints != '' {
						mut constr_to_check := new_cols_def[i].constraints
						mut constraint_queries := []string{}

						if constr_to_check.contains('NOT NULL') {
							// NOT NULL is handled differently - no ADD CONSTRAINT syntax
							constraint_queries << 'ALTER TABLE ${table_name} ALTER COLUMN ${new_cols_def[i].name} SET NOT NULL'
							constr_to_check = constr_to_check.replace('NOT NULL ', '').replace('NOT NULL',
								'')
						}

						if constr_to_check.contains('UNIQUE') {
							constraint_queries << 'ALTER TABLE ${table_name} ADD CONSTRAINT ${table_name}_${new_cols_def[i].name}_${i}_unique UNIQUE(${new_cols_def[i].name})'
							constr_to_check = constr_to_check.replace('UNIQUE ', '').replace('UNIQUE',
								'')
						}

						if constr_to_check.contains('PRIMARY KEY') {
							constraint_queries << 'ALTER TABLE ${table_name} ADD CONSTRAINT ${table_name}_${new_cols_def[i].name}_${i}_pkey PRIMARY KEY (${new_cols_def[i].name})'
							constr_to_check = constr_to_check.replace('PRIMARY KEY ',
								'').replace('PRIMARY KEY', '')
						}

						// CHECK constraint handling
						if constr_to_check.contains('CHECK') {
							// Extract the CHECK condition (everything between CHECK and the next constraint or end)
							check_start := constr_to_check.index('CHECK') or { -1 }
							if check_start >= 0 {
								check_part := constr_to_check[check_start..]
								// Find the CHECK condition - it should be in parentheses
								paren_start := check_part.index('(') or { -1 }
								if paren_start >= 0 {
									mut paren_count := 0
									mut paren_end := paren_start
									for j in paren_start .. check_part.len {
										if check_part[j] == `(` {
											paren_count++
										} else if check_part[j] == `)` {
											paren_count--
											if paren_count == 0 {
												paren_end = j
												break
											}
										}
									}
									check_condition := check_part[paren_start..paren_end + 1]
									constraint_queries << 'ALTER TABLE ${table_name} ADD CONSTRAINT ${table_name}_${new_cols_def[i].name}_${i}_check CHECK ${check_condition}'
								}
							}
							constr_to_check = constr_to_check.replace_each(['CHECK ', '', 'CHECK',
								''])
						}

						// FOREIGN KEY constraint handling
						if constr_to_check.contains('REFERENCES')
							|| constr_to_check.contains('FOREIGN KEY') {
							// Extract the REFERENCES part
							refs_start := constr_to_check.index('REFERENCES') or { -1 }
							if refs_start >= 0 {
								refs_part := constr_to_check[refs_start..]
								// Parse: REFERENCES table_name(column_name)
								constraint_queries << 'ALTER TABLE ${table_name} ADD CONSTRAINT ${table_name}_${new_cols_def[i].name}_${i}_fkey FOREIGN KEY (${new_cols_def[i].name}) ${refs_part}'
							}
							constr_to_check = constr_to_check.replace_each([
								'REFERENCES ',
								'',
								'REFERENCES',
								'',
								'FOREIGN KEY ',
								'',
								'FOREIGN KEY',
								'',
							])
						}
						for query in constraint_queries {
							dbops.execute_query(query, production, false)!
						}
					}
				}
				if new_cols_def[i].data_type != old_cols_def[i].data_type {
					dbops.execute_query('ALTER TABLE ${table_name} ALTER COLUMN ${new_cols_def[i].name} TYPE ${new_cols_def[i].data_type};',
						production, false)!
				}
			}
		} else {
			to_add, to_delete := get_diff_cols(new_cols_def, old_cols_def)
			for col in to_add {
				dbops.execute_query('ALTER TABLE ${table_name} ADD COLUMN ${col.name} ${col.data_type} ${col.constraints}',
					production, false)!
			}
			for col_name in to_delete {
				dbops.execute_query('ALTER TABLE ${table_name} DROP COLUMN ${col_name}',
					production, false)!
			}
		}
	}
}

pub fn migrate(production bool) ! {
	migr_dets, schema := read_migration_file(?string(none))!
	create_migration_directory(migr_dets.version, migr_dets.name, migr_dets.description,
		production)!
	register_migration(production, migr_dets.version)!
	for key in schema.keys() {
		if table_exists(key) or { false } {
			update_table(key, schema[key], migr_dets.version, production)!
			println('Table ${key} successfully updated')
		} else {
			create_table(key, schema[key], production)!
			println('Table ${key} successfully created')
		}
	}
}
