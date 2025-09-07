--- version: 0.1.0
--- schema_name: users
--- schema_description: a database to track users

TABLE users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

TABLE user_sessions (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT,
    start_at TIMESTAMP,
    end_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
