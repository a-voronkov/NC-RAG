<?php
declare(strict_types=1);

namespace OCA\WebhookRabbitMQ\BackgroundJob;

use OCA\WebhookRabbitMQ\AppInfo\Application;
use OCA\WebhookRabbitMQ\Service\ConfigService;
use OCA\WebhookRabbitMQ\Service\RabbitMQPublisher;
use OCP\BackgroundJob\QueuedJob;
use OCP\ILogger;

class RabbitMQPublishJob extends QueuedJob {
    private RabbitMQPublisher $publisher;
    private ConfigService $config;
    private ILogger $logger;

    public function __construct(RabbitMQPublisher $publisher, ConfigService $config, ILogger $logger) {
        $this->publisher = $publisher;
        $this->config = $config;
        $this->logger = $logger;
    }

    protected function run($argument): void {
        if (!$this->config->isEnabled()) {
            return;
        }
        if (!\is_array($argument)) {
            $this->logger->warning('RabbitMQPublishJob argument is not an array', ['app' => Application::APP_ID]);
            return;
        }
        $this->publisher->publish($argument);
    }
}

