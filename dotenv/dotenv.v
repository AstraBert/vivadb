module dotenv

import os

pub fn load_dotenv(dotenv_path string) ?map[string]string {
	lines := os.read_lines(dotenv_path) or { [] }
	if lines.len == 0 {
		return none
	} else {
		mut dotenv_args := map[string]string{}
		for line in lines {
			mut ln := line.replace('\n', '')
			ln = ln.replace('"', '')
			ln = ln.replace("'", '')
			ln = ln.replace(' = ', '=')
			ln = ln.trim_space()
			
			if ln == '' || ln.starts_with('#') {
				continue
			}
			
			if !ln.contains('=') {
				continue
			}
			
			key, val := ln.split_once('=') or { continue }
			
			clean_key := key.trim_space()
			clean_val := val.trim_space()
			
			if clean_key != '' {
				dotenv_args[clean_key] = clean_val
			}
		}
		return dotenv_args
	}
}