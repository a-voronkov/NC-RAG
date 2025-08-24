package models

import (
	"encoding/json"
	"time"
)

// FileEvent represents a file event message from RabbitMQ
type FileEvent struct {
	TraceID    string    `json:"trace_id"`
	EventID    string    `json:"event_id"`
	Type       string    `json:"type"`
	Tenant     string    `json:"tenant"`
	File       FileInfo  `json:"file"`
	Share      ShareInfo `json:"share"`
	ReceivedAt time.Time `json:"received_at"`
}

// FileInfo contains file metadata from Nextcloud
type FileInfo struct {
	ID       int64  `json:"id"`
	Path     string `json:"path"`
	Name     string `json:"name"`
	Size     int64  `json:"size"`
	MimeType string `json:"mimetype"`
}

// ShareInfo contains share metadata (for future use)
type ShareInfo struct {
	ID          int64  `json:"id,omitempty"`
	ShareType   int    `json:"share_type,omitempty"`
	ShareWith   string `json:"share_with,omitempty"`
	Permissions int    `json:"permissions,omitempty"`
}

// JobState represents the state of a parsing job
type JobState struct {
	JobID          string                 `json:"job_id"`
	FileID         int64                  `json:"file_id"`
	Tenant         string                 `json:"tenant"`
	OwnerUID       string                 `json:"owner_uid"`
	FilePath       string                 `json:"file_path"`
	Status         JobStatus              `json:"status"`
	SubmittedAt    time.Time              `json:"submitted_at"`
	TraceID        string                 `json:"trace_id"`
	ParserResponse map[string]interface{} `json:"parser_response,omitempty"`
	ErrorMessage   string                 `json:"error_message,omitempty"`
	RetryCount     int                    `json:"retry_count"`
}

// JobStatus represents the status of a parsing job
type JobStatus string

const (
	JobStatusSubmitted  JobStatus = "submitted"
	JobStatusProcessing JobStatus = "processing"
	JobStatusCompleted  JobStatus = "completed"
	JobStatusFailed     JobStatus = "failed"
)

// ParserJobRequest represents a request to the parser API
type ParserJobRequest struct {
	Content  string            `json:"content"`   // Base64 encoded file content
	Filename string            `json:"filename"`
	MimeType string            `json:"mimetype"`
	Metadata map[string]string `json:"metadata"`
}

// ParserJobResponse represents a response from the parser API
type ParserJobResponse struct {
	JobID   string `json:"job_id"`
	Status  string `json:"status"`
	Message string `json:"message,omitempty"`
}

// IsCreateOrUpdateEvent checks if the event is a file create or update
func (e *FileEvent) IsCreateOrUpdateEvent() bool {
	return e.Type == "OCP\\Files\\Events\\Node\\NodeCreatedEvent" ||
		e.Type == "OCP\\Files\\Events\\Node\\NodeUpdatedEvent"
}

// ToJSON converts the struct to JSON string
func (j *JobState) ToJSON() (string, error) {
	data, err := json.Marshal(j)
	if err != nil {
		return "", err
	}
	return string(data), nil
}

// FromJSON creates JobState from JSON string
func JobStateFromJSON(data string) (*JobState, error) {
	var job JobState
	err := json.Unmarshal([]byte(data), &job)
	if err != nil {
		return nil, err
	}
	return &job, nil
}