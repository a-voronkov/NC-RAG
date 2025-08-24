package consumer

import (
	"context"
	"encoding/json"
	"fmt"
	"sync"
	"time"

	"nc-rag-worker/models"
	"nc-rag-worker/nextcloud"
	"nc-rag-worker/parser"
	"nc-rag-worker/storage"

	"github.com/rabbitmq/amqp091-go"
	log "github.com/sirupsen/logrus"
)

// RabbitMQConsumer handles consuming messages from RabbitMQ
type RabbitMQConsumer struct {
	conn         *amqp091.Connection
	channel      *amqp091.Channel
	queueName    string
	ncClient     *nextcloud.Client
	parserClient *parser.Client
	storage      *storage.RedisStorage
	concurrency  int
	wg           sync.WaitGroup
}

// NewRabbitMQConsumer creates a new RabbitMQ consumer
func NewRabbitMQConsumer(
	amqpURL, queueName string,
	ncClient *nextcloud.Client,
	parserClient *parser.Client,
	storage *storage.RedisStorage,
	concurrency int,
) (*RabbitMQConsumer, error) {
	// Connect to RabbitMQ
	conn, err := amqp091.Dial(amqpURL)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to RabbitMQ: %w", err)
	}

	// Create channel
	channel, err := conn.Channel()
	if err != nil {
		conn.Close()
		return nil, fmt.Errorf("failed to create RabbitMQ channel: %w", err)
	}

	// Set QoS (prefetch count)
	if err := channel.Qos(1, 0, false); err != nil {
		channel.Close()
		conn.Close()
		return nil, fmt.Errorf("failed to set QoS: %w", err)
	}

	return &RabbitMQConsumer{
		conn:         conn,
		channel:      channel,
		queueName:    queueName,
		ncClient:     ncClient,
		parserClient: parserClient,
		storage:      storage,
		concurrency:  concurrency,
	}, nil
}

// Start starts consuming messages
func (c *RabbitMQConsumer) Start(ctx context.Context) error {
	log.WithFields(log.Fields{
		"queue":       c.queueName,
		"concurrency": c.concurrency,
	}).Info("Starting RabbitMQ consumer")

	// Declare queue (ensure it exists)
	_, err := c.channel.QueueDeclare(
		c.queueName, // name
		true,        // durable
		false,       // delete when unused
		false,       // exclusive
		false,       // no-wait
		nil,         // arguments
	)
	if err != nil {
		return fmt.Errorf("failed to declare queue: %w", err)
	}

	// Start consuming
	msgs, err := c.channel.Consume(
		c.queueName, // queue
		"",          // consumer
		false,       // auto-ack (we'll ack manually)
		false,       // exclusive
		false,       // no-local
		false,       // no-wait
		nil,         // args
	)
	if err != nil {
		return fmt.Errorf("failed to register consumer: %w", err)
	}

	// Start worker goroutines
	for i := 0; i < c.concurrency; i++ {
		c.wg.Add(1)
		go c.worker(ctx, msgs, i)
	}

	log.Info("RabbitMQ consumer started successfully")

	// Wait for context cancellation
	<-ctx.Done()
	log.Info("Shutting down RabbitMQ consumer")

	// Wait for workers to finish
	c.wg.Wait()
	log.Info("All workers stopped")

	return nil
}

// worker processes messages from the queue
func (c *RabbitMQConsumer) worker(ctx context.Context, msgs <-chan amqp091.Delivery, workerID int) {
	defer c.wg.Done()

	logger := log.WithField("worker_id", workerID)
	logger.Info("Worker started")

	for {
		select {
		case <-ctx.Done():
			logger.Info("Worker stopping due to context cancellation")
			return

		case msg, ok := <-msgs:
			if !ok {
				logger.Info("Message channel closed, worker stopping")
				return
			}

			// Process message
			if err := c.processMessage(ctx, msg); err != nil {
				logger.WithError(err).Error("Failed to process message")
				// Reject message and requeue (with limit to prevent infinite loops)
				msg.Nack(false, true)
			} else {
				// Acknowledge successful processing
				msg.Ack(false)
			}
		}
	}
}

// processMessage processes a single message
func (c *RabbitMQConsumer) processMessage(ctx context.Context, msg amqp091.Delivery) error {
	// Parse message
	var event models.FileEvent
	if err := json.Unmarshal(msg.Body, &event); err != nil {
		return fmt.Errorf("failed to parse message: %w", err)
	}

	logger := log.WithFields(log.Fields{
		"trace_id":   event.TraceID,
		"event_id":   event.EventID,
		"event_type": event.Type,
		"file_id":    event.File.ID,
		"file_path":  event.File.Path,
	})

	logger.Info("Processing file event")

	// Check if this is a create or update event
	if !event.IsCreateOrUpdateEvent() {
		logger.Debug("Skipping non-create/update event")
		return nil
	}

	// Check if file type is processable
	if !c.ncClient.IsProcessableFile(event.File.MimeType) {
		logger.WithField("mime_type", event.File.MimeType).Debug("Skipping non-processable file type")
		return nil
	}

	// Check if we already have a job for this file
	existingJob, err := c.storage.GetJobByFileID(ctx, event.File.ID)
	if err == nil && existingJob != nil {
		logger.WithField("existing_job_id", existingJob.JobID).Info("File already has a processing job, skipping")
		return nil
	}

	// Fetch file content from Nextcloud
	logger.Info("Fetching file content from Nextcloud")
	content, err := c.ncClient.FetchFile(ctx, &event)
	if err != nil {
		return fmt.Errorf("failed to fetch file: %w", err)
	}

	// Submit to parser
	logger.Info("Submitting file to parser")
	parserResponse, err := c.parserClient.SubmitJob(ctx, &event, content)
	if err != nil {
		return fmt.Errorf("failed to submit to parser: %w", err)
	}

	// Create job state
	jobState := &models.JobState{
		JobID:       parserResponse.JobID,
		FileID:      event.File.ID,
		Tenant:      event.Tenant,
		OwnerUID:    c.ncClient.ExtractOwnerFromPath(event.File.Path),
		FilePath:    event.File.Path,
		Status:      models.JobStatusSubmitted,
		SubmittedAt: time.Now(),
		TraceID:     event.TraceID,
		ParserResponse: map[string]interface{}{
			"initial_status": parserResponse.Status,
			"message":        parserResponse.Message,
		},
		RetryCount: 0,
	}

	// Save job state
	if err := c.storage.SaveJob(ctx, jobState); err != nil {
		return fmt.Errorf("failed to save job state: %w", err)
	}

	logger.WithFields(log.Fields{
		"job_id":        jobState.JobID,
		"parser_status": parserResponse.Status,
	}).Info("File processing job created successfully")

	return nil
}

// Close closes the RabbitMQ connection
func (c *RabbitMQConsumer) Close() error {
	if c.channel != nil {
		c.channel.Close()
	}
	if c.conn != nil {
		c.conn.Close()
	}
	return nil
}

// Health checks RabbitMQ connection health
func (c *RabbitMQConsumer) Health(ctx context.Context) error {
	if c.conn == nil || c.conn.IsClosed() {
		return fmt.Errorf("RabbitMQ connection is closed")
	}
	if c.channel == nil || c.channel.IsClosed() {
		return fmt.Errorf("RabbitMQ channel is closed")
	}
	return nil
}