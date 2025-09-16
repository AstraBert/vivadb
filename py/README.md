# vivadb-py

A python wrapper around [vivadb](https://github.com/AstraBert/vivadb).

## Installation

Install through `pip` (or your favorite dependency manager):

```bash
pip install vivadb-py
```

## Commands

The package comes bundled with the `vivadb` executable and has all its subcommands.

### `config` - Database Configuration

Configure your PostgreSQL connection settings and save them to environment files.

```bash
vivadb config [OPTIONS]
```

**Options:**

- `--host` - PostgreSQL host (default: localhost)
- `--port` - PostgreSQL port (default: 5432)
- `--user` - PostgreSQL username
- `--password` - Password (not recommended for production)
- `--password-stdin` - Input password securely from stdin
- `--dbname` - Database name
- `--prod` - Write to production environment file
- `-h, --help` - Show help for this command

**Examples:**

```bash
# Configure development database with secure password input
vivadb config --host=localhost --port=5432 --user=myuser --dbname=postgres --password-stdin

# Configure production database
vivadb config --host=prod-server --use= prod_user --dbname=production_db --prod --password-stdin
```

### `exec` - Execute SQL Queries

Execute SQL queries with production awareness and optional safety checks.

```bash
vivadb exec [OPTIONS]
```

**Options:**

- `-q, --query` - SQL query to execute
- `-s, --safe` - Execute only safe queries
- `-p, --prod` - Run in production environment
- `-h, --help` - Show help for this command

**Examples:**

```bash
# Execute a safe query in development
vivadb exec --query="SELECT * FROM users LIMIT 10;" --safe

# Execute query in production (use with caution)
vivadb exec --query="UPDATE users SET status = 'active' WHERE created_at > '2024-01-01';" --prod
```

### `new` - Create New Project

Create a new project with database integration and optional Docker setup.

```bash
vivadb new [OPTIONS]
```

**Options:**

- `--host` - PostgreSQL host
- `--port` - PostgreSQL port
- `--user` - PostgreSQL username
- `--password` - Password (not recommended)
- `--password-stdin` - Input password securely from stdin
- `--dbname` - Database name
- `--prod` - Configure for production
- `--docker` - Create Docker Compose configuration
- `-h, --help` - Show help for this command

**Examples:**

```bash
# Create new project with Docker setup
vivadb new --project-name=hello_world --docker --host=localhost --port=5432 --user=myuser --dbname=postgres --password-stdin
```

### `migrate` - Database Migrations

Update your database schema in a production-aware manner.

```bash
vivadb migrate [OPTIONS]
```

**Options:**

- `--prod` - Run migration in production environment
- `-h, --help` - Show help for this command

**Examples:**

```bash
# Run migrations in development
vivadb migrate

# Run migrations in production
vivadb migrate --prod
```

## Environment Files

vivadb manages separate environment files for development and production:

- **Development**: `.vivadb/.env.local`
- **Production**: `.vivadb/.env`

This separation helps prevent accidental operations on production databases during development.

## Security Best Practices

1. **Use `--password-stdin`**: Always use the `--password-stdin` flag instead of `--password` to avoid exposing credentials in your shell history.

2. **Production flag**: Always use the `--prod` flag when working with production databases to ensure proper environment separation.

3. **Safe queries**: Use the `--safe` and/or `--prod` flag with the `exec` command when possible to enable additional safety checks.

## Project Structure

When using `vivadb new`, the tool creates a project structure optimized for database-driven applications, including:

- Environment configuration files
- Optional Docker Compose setup for local PostgreSQL
- Project scaffolding with database integration

Here is how a project would look like:

```txt
.
├── .gitignore
├── .vivadb
│   ├── .env.local
│   └── compose.yaml
├── README.md
└── schema.v.sql
```

## Contributing

Contributions are more than welcome! Find the contribution guidelines [here](https://github.com/AstraBert/vivadb/blob/main/CONTRIBUTING.md)

## License

This project is distributed under an [MIT License](https://github.com/AstraBert/vivadb/blob/main/LICENSE)

## Support

For issues and questions, please [create an issue](https://github.com/AstraBert/vivadb/issues) in the repository.
