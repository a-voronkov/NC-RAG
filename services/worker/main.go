package main

import (
	"context"
	"os"
	"os/signal"
	"syscall"
	"time"

	"nc-rag-worker/config"
	"nc-rag-worker/consumer"
	"nc-rag-worker/nextcloud"
	"nc-rag-worker/parser"
	"nc-rag-worker/storage"

	log "github.com/sirupsen/logrus"
)

func main() {
	// Initialize logging
	log.SetFormatter(&log.JSONFormatter{})
	log.SetLevel(log.InfoLevel)
	
	log.Info("Starting NC-RAG Worker...")

	// Load configuration
	cfg, err := config.Load()
	if err != nil {
		log.WithError(err).Fatal("Failed to load configuration")
	}

	log.WithFields(log.Fields{
		"rabbitmq_queue": cfg.RabbitMQ.Queue,
		"nextcloud_url":  cfg.Nextcloud.URL,
		"parser_url":     cfg.Parser.URL,
		"worker_concurrency": cfg.Worker.Concurrency,
	}).Info("Configuration loaded")

	// Initialize components
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// Initialize Redis storage
	storage, err := storage.NewRedisStorage(cfg.Redis.URL)
	if err != nil {
		log.WithError(err).Fatal("Failed to initialize Redis storage")
	}
	defer storage.Close()

	// Initialize Nextcloud client
	ncClient := nextcloud.NewClient(cfg.Nextcloud.URL, cfg.Nextcloud.User, cfg.Nextcloud.Password)

	// Initialize Parser client
	parserClient := parser.NewClient(cfg.Parser.URL, cfg.Parser.Secret)

	// Initialize RabbitMQ consumer
	consumer, err := consumer.NewRabbitMQConsumer(
		cfg.RabbitMQ.URL,
		cfg.RabbitMQ.Queue,
		ncClient,
		parserClient,
		storage,
		cfg.Worker.Concurrency,
	)
	if err != nil {
		log.WithError(err).Fatal("Failed to initialize RabbitMQ consumer")
	}
	defer consumer.Close()

	// Start consumer
	go func() {
		if err := consumer.Start(ctx); err != nil {
			log.WithError(err).Error("Consumer error")
			cancel()
		}
	}()

	log.Info("Worker started successfully")

	// Wait for shutdown signal
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

	select {
	case sig := <-sigChan:
		log.WithField("signal", sig).Info("Received shutdown signal")
	case <-ctx.Done():
		log.Info("Context cancelled")
	}

	log.Info("Shutting down worker...")
	
	// Graceful shutdown with timeout
	shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer shutdownCancel()

	cancel() // Cancel main context
	
	// Wait for graceful shutdown or timeout
	select {
	case <-shutdownCtx.Done():
		log.Warn("Shutdown timeout exceeded")
	case <-time.After(5 * time.Second):
		log.Info("Worker shutdown completed")
	}
}