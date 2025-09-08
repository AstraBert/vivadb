# vivadb

A next generation Postgres database manager built with V.

## Overview

vivadb is a command-line tool designed to streamline PostgreSQL database management with production-aware features, safe query execution, and project scaffolding capabilities.

## Features

- **Production-aware operations**: Separate configuration and execution modes for development and production environments
- **Safe query execution**: Built-in safety checks for SQL queries
- **Project scaffolding**: Create new projects with database integration
- **Database migrations**: Effortless schema updates
- **Docker integration**: Optional Docker Compose setup for local PostgreSQL instances
- **Secure password handling**: Support for stdin password input to avoid exposing credentials in command history

## Installation

If you have [v](https://vlang.io) installed, you can clone the repository and compile the code directly:

```bash
# Clone the repository
git clone https://github.com/AstraBert/vivadb
cd vivadb

# Build with V
v -o vivadb .
```

You can also download the executable directly from the [Releases Page](https://github.com/AstraBert/vivadb/releases) or use the command line to do it:

```bash
curl -L -o vivadb https://github.com/AstraBert/vivadb/releases/download/<version>/vivadb-<os> ## e.g. https://github.com/AstraBert/vivadb/releases/download/0.1.1/vivadb-linux

# make sure the downloaded binary is executable
chmod +x vivadb
```

## Commands

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
vivadb new [PROJECT_NAME] [OPTIONS]
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

Contributions are more than welcome! Find the contribution guidelines [here](./CONTRIBUTING.md)

## License

This project is distributed under an [MIT License](./LICENSE)

## Support

For issues and questions, please [create an issue](https://github.com/AstraBert/vivadb/issues) in the repository.
