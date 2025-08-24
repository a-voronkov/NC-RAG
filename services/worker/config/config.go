package config

import (
	"fmt"
	"os"
	"strconv"
)

// Config holds all configuration for the worker
type Config struct {
	RabbitMQ  RabbitMQConfig
	Nextcloud NextcloudConfig
	Parser    ParserConfig
	Redis     RedisConfig
	Worker    WorkerConfig
}

// RabbitMQConfig holds RabbitMQ connection settings
type RabbitMQConfig struct {
	URL   string
	Queue string
}

// NextcloudConfig holds Nextcloud connection settings
type NextcloudConfig struct {
	URL      string
	User     string
	Password string
}

// ParserConfig holds parser API settings
type ParserConfig struct {
	URL    string
	Secret string
}

// RedisConfig holds Redis connection settings
type RedisConfig struct {
	URL string
}

// WorkerConfig holds worker-specific settings
type WorkerConfig struct {
	Concurrency int
	Prefetch    int
}

// Load loads configuration from environment variables
func Load() (*Config, error) {
	config := &Config{}

	// RabbitMQ configuration
	config.RabbitMQ.URL = getEnvOrDefault("RABBITMQ_URL", "amqp://guest:guest@localhost:5672/")
	config.RabbitMQ.Queue = getEnvOrDefault("RABBITMQ_QUEUE", "events.files")

	// Nextcloud configuration
	config.Nextcloud.URL = getEnvOrDefault("NEXTCLOUD_URL", "https://localhost")
	config.Nextcloud.User = getEnvOrDefault("NEXTCLOUD_USER", "admin")
	config.Nextcloud.Password = os.Getenv("NEXTCLOUD_PASS")
	if config.Nextcloud.Password == "" {
		return nil, fmt.Errorf("NEXTCLOUD_PASS environment variable is required")
	}

	// Parser configuration
	config.Parser.URL = getEnvOrDefault("PARSER_URL", "https://api.example.com/parser")
	config.Parser.Secret = getEnvOrDefault("PARSER_SECRET", "")

	// Redis configuration
	config.Redis.URL = getEnvOrDefault("REDIS_URL", "redis://localhost:6379/0")

	// Worker configuration
	concurrency, err := strconv.Atoi(getEnvOrDefault("WORKER_CONCURRENCY", "2"))
	if err != nil {
		return nil, fmt.Errorf("invalid WORKER_CONCURRENCY: %w", err)
	}
	config.Worker.Concurrency = concurrency

	prefetch, err := strconv.Atoi(getEnvOrDefault("WORKER_PREFETCH", "1"))
	if err != nil {
		return nil, fmt.Errorf("invalid WORKER_PREFETCH: %w", err)
	}
	config.Worker.Prefetch = prefetch

	return config, nil
}

// getEnvOrDefault returns environment variable value or default if not set
func getEnvOrDefault(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}