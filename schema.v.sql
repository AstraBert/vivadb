--- version: 0.1.0
--- schema_name: customers
--- schema_description: a database to track customers

TABLE customers (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

TABLE customer_sessions (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    start_at TIMESTAMP,
    end_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);