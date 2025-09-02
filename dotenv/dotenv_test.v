module dotenv

fn test_load_dotenv () {
	dotenv_args := load_dotenv(".env.test") or { map[string]string{} }
	assert "FOO" in dotenv_args.keys()
	assert "BAR" in dotenv_args.keys()
	assert "V" in dotenv_args.keys()
	assert dotenv_args["FOO"] == "BAR"
	assert dotenv_args["BAR"] == "FOO"
	assert dotenv_args["V"] == "IS_AWESOME"
}
