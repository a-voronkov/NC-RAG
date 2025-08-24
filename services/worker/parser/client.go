package parser

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"time"

	"nc-rag-worker/models"

	log "github.com/sirupsen/logrus"
)

// Client represents a parser API client
type Client struct {
	baseURL    string
	secret     string
	httpClient *http.Client
}

// NewClient creates a new parser client
func NewClient(baseURL, secret string) *Client {
	return &Client{
		baseURL: strings.TrimSuffix(baseURL, "/"),
		secret:  secret,
		httpClient: &http.Client{
			Timeout: 30 * time.Second,
		},
	}
}

// SubmitJob submits a file for parsing and returns the job ID
func (c *Client) SubmitJob(ctx context.Context, event *models.FileEvent, content string) (*models.ParserJobResponse, error) {
	logger := log.WithFields(log.Fields{
		"trace_id":  event.TraceID,
		"file_id":   event.File.ID,
		"file_name": event.File.Name,
		"file_size": event.File.Size,
		"parser_url": c.baseURL,
	})

	logger.Info("Submitting file to parser API")

	// Create request payload
	request := &models.ParserJobRequest{
		Content:  content,
		Filename: event.File.Name,
		MimeType: event.File.MimeType,
		Metadata: map[string]string{
			"tenant":     event.Tenant,
			"file_id":    fmt.Sprintf("%d", event.File.ID),
			"file_path":  event.File.Path,
			"trace_id":   event.TraceID,
			"event_id":   event.EventID,
		},
	}

	// Serialize request
	requestBody, err := json.Marshal(request)
	if err != nil {
		return nil, fmt.Errorf("failed to serialize request: %w", err)
	}

	logger.WithField("request_size", len(requestBody)).Debug("Request serialized")

	// Create HTTP request
	url := c.baseURL + "/jobs"
	req, err := http.NewRequestWithContext(ctx, "POST", url, bytes.NewReader(requestBody))
	if err != nil {
		return nil, fmt.Errorf("failed to create HTTP request: %w", err)
	}

	// Set headers
	req.Header.Set("Content-Type", "application/json")
	if c.secret != "" {
		req.Header.Set("Authorization", "Bearer "+c.secret)
	}

	logger.WithField("url", url).Debug("Sending request to parser API")

	// Send request
	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to send request to parser: %w", err)
	}
	defer resp.Body.Close()

	logger.WithField("status_code", resp.StatusCode).Debug("Received response from parser API")

	// Check response status
	if resp.StatusCode != http.StatusOK && resp.StatusCode != http.StatusCreated {
		return nil, fmt.Errorf("parser API returned error status: %d", resp.StatusCode)
	}

	// Parse response
	var response models.ParserJobResponse
	if err := json.NewDecoder(resp.Body).Decode(&response); err != nil {
		return nil, fmt.Errorf("failed to parse response: %w", err)
	}

	logger.WithFields(log.Fields{
		"job_id": response.JobID,
		"status": response.Status,
	}).Info("Job submitted to parser successfully")

	return &response, nil
}

// GetJobStatus retrieves the status of a parsing job
func (c *Client) GetJobStatus(ctx context.Context, jobID string) (*models.ParserJobResponse, error) {
	logger := log.WithField("job_id", jobID)
	logger.Debug("Getting job status from parser API")

	// Create HTTP request
	url := fmt.Sprintf("%s/jobs/%s", c.baseURL, jobID)
	req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create HTTP request: %w", err)
	}

	// Set headers
	if c.secret != "" {
		req.Header.Set("Authorization", "Bearer "+c.secret)
	}

	// Send request
	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to send request to parser: %w", err)
	}
	defer resp.Body.Close()

	logger.WithField("status_code", resp.StatusCode).Debug("Received response from parser API")

	// Check response status
	if resp.StatusCode == http.StatusNotFound {
		return nil, fmt.Errorf("job not found: %s", jobID)
	}
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("parser API returned error status: %d", resp.StatusCode)
	}

	// Parse response
	var response models.ParserJobResponse
	if err := json.NewDecoder(resp.Body).Decode(&response); err != nil {
		return nil, fmt.Errorf("failed to parse response: %w", err)
	}

	logger.WithField("status", response.Status).Debug("Job status retrieved")

	return &response, nil
}

// GetJobResult retrieves the result of a completed parsing job
func (c *Client) GetJobResult(ctx context.Context, jobID string) (map[string]interface{}, error) {
	logger := log.WithField("job_id", jobID)
	logger.Debug("Getting job result from parser API")

	// Create HTTP request
	url := fmt.Sprintf("%s/jobs/%s/result", c.baseURL, jobID)
	req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create HTTP request: %w", err)
	}

	// Set headers
	if c.secret != "" {
		req.Header.Set("Authorization", "Bearer "+c.secret)
	}

	// Send request
	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to send request to parser: %w", err)
	}
	defer resp.Body.Close()

	logger.WithField("status_code", resp.StatusCode).Debug("Received response from parser API")

	// Check response status
	if resp.StatusCode == http.StatusNotFound {
		return nil, fmt.Errorf("job result not found: %s", jobID)
	}
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("parser API returned error status: %d", resp.StatusCode)
	}

	// Parse response
	var result map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, fmt.Errorf("failed to parse result: %w", err)
	}

	logger.Info("Job result retrieved successfully")

	return result, nil
}

// Health checks the parser API health
func (c *Client) Health(ctx context.Context) error {
	// Create HTTP request
	url := c.baseURL + "/health"
	req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
	if err != nil {
		return fmt.Errorf("failed to create health check request: %w", err)
	}

	// Send request
	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("parser health check failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("parser health check returned status: %d", resp.StatusCode)
	}

	return nil
}