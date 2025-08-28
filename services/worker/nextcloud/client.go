package nextcloud

import (
	"context"
	"encoding/base64"
	"fmt"
	"io"
	"os"
	"strings"

	"nc-rag-worker/models"

	"github.com/studio-b12/gowebdav"
	log "github.com/sirupsen/logrus"
)

// Client represents a Nextcloud WebDAV client
type Client struct {
	webdav   *gowebdav.Client
	baseURL  string
	username string
}

// NewClient creates a new Nextcloud client
func NewClient(baseURL, username, password string) *Client {
	// Construct WebDAV URL
	webdavURL := strings.TrimSuffix(baseURL, "/") + "/remote.php/dav/files/" + username

	// Create WebDAV client
	client := gowebdav.NewClient(webdavURL, username, password)

	return &Client{
		webdav:   client,
		baseURL:  baseURL,
		username: username,
	}
}

// FetchFile fetches a file from Nextcloud and returns its content as base64
func (c *Client) FetchFile(ctx context.Context, event *models.FileEvent) (string, error) {
	logger := log.WithFields(log.Fields{
		"trace_id": event.TraceID,
		"file_id":  event.File.ID,
		"file_path": event.File.Path,
		"file_size": event.File.Size,
	})

	logger.Info("Fetching file from Nextcloud")

	// Convert Nextcloud path to WebDAV path
	// Remove /username prefix if present
	webdavPath := event.File.Path
	userPrefix := "/" + c.username + "/"
	if strings.HasPrefix(webdavPath, userPrefix) {
		webdavPath = strings.TrimPrefix(webdavPath, userPrefix)
	}
	// Remove leading slash if present
	webdavPath = strings.TrimPrefix(webdavPath, "/")

	logger.WithField("webdav_path", webdavPath).Debug("Converted file path for WebDAV")

	// Check file size limit (50MB)
	const maxFileSize = 50 * 1024 * 1024
	if event.File.Size > maxFileSize {
		return "", fmt.Errorf("file too large: %d bytes (max %d)", event.File.Size, maxFileSize)
	}

	// Read file content
	reader, err := c.webdav.ReadStream(webdavPath)
	if err != nil {
		return "", fmt.Errorf("failed to read file from WebDAV: %w", err)
	}
	defer reader.Close()

	// Read all content
	content, err := io.ReadAll(reader)
	if err != nil {
		return "", fmt.Errorf("failed to read file content: %w", err)
	}

	logger.WithField("content_size", len(content)).Debug("File content read successfully")

	// Encode to base64
	encoded := base64.StdEncoding.EncodeToString(content)

	logger.WithField("encoded_size", len(encoded)).Info("File encoded to base64")

	return encoded, nil
}

// GetFileInfo retrieves file information from Nextcloud
func (c *Client) GetFileInfo(ctx context.Context, filePath string) (os.FileInfo, error) {
	// Convert Nextcloud path to WebDAV path
	webdavPath := filePath
	userPrefix := "/" + c.username + "/"
	if strings.HasPrefix(webdavPath, userPrefix) {
		webdavPath = strings.TrimPrefix(webdavPath, userPrefix)
	}
	webdavPath = strings.TrimPrefix(webdavPath, "/")

	info, err := c.webdav.Stat(webdavPath)
	if err != nil {
		return nil, fmt.Errorf("failed to get file info: %w", err)
	}

	return info, nil
}

// Health checks the connection to Nextcloud
func (c *Client) Health(ctx context.Context) error {
	// Try to list the root directory
	_, err := c.webdav.ReadDir("/")
	if err != nil {
		return fmt.Errorf("Nextcloud health check failed: %w", err)
	}
	return nil
}

// ExtractOwnerFromPath extracts the owner UID from the file path
func (c *Client) ExtractOwnerFromPath(filePath string) string {
	// File paths typically look like: /admin/files/document.pdf
	// Extract the first part as owner
	parts := strings.Split(strings.Trim(filePath, "/"), "/")
	if len(parts) > 0 {
		return parts[0]
	}
	// Fallback to configured username
	return c.username
}

// IsProcessableFile checks if the file type is processable by the parser
func (c *Client) IsProcessableFile(mimeType string) bool {
	processableMimeTypes := map[string]bool{
		// Documents
		"application/pdf":                                                true,
		"application/msword":                                             true,
		"application/vnd.openxmlformats-officedocument.wordprocessingml.document": true,
		"application/vnd.ms-excel":                                       true,
		"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet": true,
		"application/vnd.ms-powerpoint":                                  true,
		"application/vnd.openxmlformats-officedocument.presentationml.presentation": true,
		
		// Text files
		"text/plain":     true,
		"text/markdown":  true,
		"text/csv":       true,
		"text/html":      true,
		"text/xml":       true,
		"application/xml": true,
		"application/json": true,
		
		// Rich text
		"application/rtf": true,
		
		// OpenDocument formats
		"application/vnd.oasis.opendocument.text":         true,
		"application/vnd.oasis.opendocument.spreadsheet":  true,
		"application/vnd.oasis.opendocument.presentation": true,
	}

	return processableMimeTypes[mimeType]
}