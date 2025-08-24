package storage

import (
	"context"
	"fmt"
	"time"

	"nc-rag-worker/models"

	"github.com/go-redis/redis/v8"
)

// RedisStorage implements job state storage using Redis
type RedisStorage struct {
	client *redis.Client
}

// NewRedisStorage creates a new Redis storage instance
func NewRedisStorage(redisURL string) (*RedisStorage, error) {
	opt, err := redis.ParseURL(redisURL)
	if err != nil {
		return nil, fmt.Errorf("failed to parse Redis URL: %w", err)
	}

	client := redis.NewClient(opt)

	// Test connection
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := client.Ping(ctx).Err(); err != nil {
		return nil, fmt.Errorf("failed to connect to Redis: %w", err)
	}

	return &RedisStorage{
		client: client,
	}, nil
}

// SaveJob saves a job state to Redis
func (r *RedisStorage) SaveJob(ctx context.Context, job *models.JobState) error {
	jobJSON, err := job.ToJSON()
	if err != nil {
		return fmt.Errorf("failed to serialize job: %w", err)
	}

	// Save job state with TTL (24 hours)
	jobKey := fmt.Sprintf("job:%s", job.JobID)
	if err := r.client.Set(ctx, jobKey, jobJSON, 24*time.Hour).Err(); err != nil {
		return fmt.Errorf("failed to save job state: %w", err)
	}

	// Create file-to-job mapping with TTL (24 hours)
	fileKey := fmt.Sprintf("file:%d", job.FileID)
	if err := r.client.Set(ctx, fileKey, job.JobID, 24*time.Hour).Err(); err != nil {
		return fmt.Errorf("failed to save file mapping: %w", err)
	}

	return nil
}

// GetJob retrieves a job state from Redis
func (r *RedisStorage) GetJob(ctx context.Context, jobID string) (*models.JobState, error) {
	jobKey := fmt.Sprintf("job:%s", jobID)
	jobJSON, err := r.client.Get(ctx, jobKey).Result()
	if err != nil {
		if err == redis.Nil {
			return nil, fmt.Errorf("job not found: %s", jobID)
		}
		return nil, fmt.Errorf("failed to get job: %w", err)
	}

	job, err := models.JobStateFromJSON(jobJSON)
	if err != nil {
		return nil, fmt.Errorf("failed to deserialize job: %w", err)
	}

	return job, nil
}

// GetJobByFileID retrieves a job state by file ID
func (r *RedisStorage) GetJobByFileID(ctx context.Context, fileID int64) (*models.JobState, error) {
	fileKey := fmt.Sprintf("file:%d", fileID)
	jobID, err := r.client.Get(ctx, fileKey).Result()
	if err != nil {
		if err == redis.Nil {
			return nil, fmt.Errorf("no job found for file: %d", fileID)
		}
		return nil, fmt.Errorf("failed to get file mapping: %w", err)
	}

	return r.GetJob(ctx, jobID)
}

// UpdateJobStatus updates the status of a job
func (r *RedisStorage) UpdateJobStatus(ctx context.Context, jobID string, status models.JobStatus, errorMessage string) error {
	job, err := r.GetJob(ctx, jobID)
	if err != nil {
		return fmt.Errorf("failed to get job for update: %w", err)
	}

	job.Status = status
	if errorMessage != "" {
		job.ErrorMessage = errorMessage
	}

	return r.SaveJob(ctx, job)
}

// DeleteJob removes a job and its file mapping from Redis
func (r *RedisStorage) DeleteJob(ctx context.Context, jobID string) error {
	// Get job to find file ID
	job, err := r.GetJob(ctx, jobID)
	if err != nil {
		return fmt.Errorf("failed to get job for deletion: %w", err)
	}

	// Delete job state
	jobKey := fmt.Sprintf("job:%s", jobID)
	if err := r.client.Del(ctx, jobKey).Err(); err != nil {
		return fmt.Errorf("failed to delete job: %w", err)
	}

	// Delete file mapping
	fileKey := fmt.Sprintf("file:%d", job.FileID)
	if err := r.client.Del(ctx, fileKey).Err(); err != nil {
		return fmt.Errorf("failed to delete file mapping: %w", err)
	}

	return nil
}

// ListJobs returns all job IDs (for monitoring/debugging)
func (r *RedisStorage) ListJobs(ctx context.Context) ([]string, error) {
	keys, err := r.client.Keys(ctx, "job:*").Result()
	if err != nil {
		return nil, fmt.Errorf("failed to list jobs: %w", err)
	}

	jobIDs := make([]string, 0, len(keys))
	for _, key := range keys {
		// Extract job ID from key (remove "job:" prefix)
		if len(key) > 4 {
			jobIDs = append(jobIDs, key[4:])
		}
	}

	return jobIDs, nil
}

// Close closes the Redis connection
func (r *RedisStorage) Close() error {
	return r.client.Close()
}

// Health checks Redis connection health
func (r *RedisStorage) Health(ctx context.Context) error {
	return r.client.Ping(ctx).Err()
}