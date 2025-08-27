<?php
declare(strict_types=1);

namespace OCA\WebhookRabbitMQ\Service;

use OCA\WebhookRabbitMQ\AppInfo\Application;
use OCP\ILogger;

class RabbitMQPublisher {
    private ConfigService $config;
    private ILogger $logger;

    public function __construct(ConfigService $config, ILogger $logger) {
        $this->config = $config;
        $this->logger = $logger;
    }

    public function publish(array $message): void {
        if (!\class_exists('AMQPConnection')) {
            $this->logger->warning('php-amqp extension not available; skipping publish', ['app' => Application::APP_ID]);
            return;
        }

        $connection = new \AMQPConnection($this->config->getConnectionOptions());
        try {
            if (!$connection->isConnected()) {
                $connection->connect();
            }
            $channel = new \AMQPChannel($connection);

            $exchange = new \AMQPExchange($channel);
            $exchange->setName($this->config->getExchange());
            $exchange->setType($this->config->getExchangeType());
            $exchange->setFlags(\AMQP_DURABLE);
            $exchange->declareExchange();

            $routingKey = $this->buildRoutingKey($message);
            $body = \json_encode($message, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
            if ($body === false) {
                $body = '{"error":"json_encode_failed"}';
            }

            $attributes = [
                'content_type' => 'application/json',
                'delivery_mode' => 2, // persistent
            ];

            $exchange->publish($body, $routingKey, \AMQP_NOPARAM, $attributes);
        } catch (\Throwable $e) {
            $this->logger->error('RabbitMQ publish failed: ' . $e->getMessage(), [
                'app' => Application::APP_ID,
            ]);
        } finally {
            try {
                if ($connection->isConnected()) {
                    $connection->disconnect();
                }
            } catch (\Throwable $e) {
            }
        }
    }

    private function buildRoutingKey(array $message): string {
        $prefix = $this->config->getRoutingPrefix();
        $class = $message['event']['class'] ?? 'unknown';
        $classKey = \strtolower(\str_replace('\\', '.', (string)$class));
        return $prefix . '.' . $classKey;
    }
}

