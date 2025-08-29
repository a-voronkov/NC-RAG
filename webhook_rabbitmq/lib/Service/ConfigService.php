<?php
declare(strict_types=1);

namespace OCA\WebhookRabbitMQ\Service;

use OCA\WebhookRabbitMQ\AppInfo\Application;
use OCP\IConfig;

class ConfigService {
    private IConfig $config;

    public function __construct(IConfig $config) {
        $this->config = $config;
    }

    public function isEnabled(): bool {
        // If the app is loaded and running, it means it's enabled in Nextcloud
        // No need for additional enabled/disabled logic
        return true;
    }

    public function getHost(): string {
        return $this->getString('host', '127.0.0.1') ?? '127.0.0.1';
    }

    public function getPort(): int {
        return (int)($this->getString('port', '5672') ?? '5672');
    }

    public function getUser(): string {
        return $this->getString('user', 'ncrag-app') ?? 'ncrag-app';
    }

    public function getPassword(): string {
        return $this->getString('pass', 'ncrag-app') ?? 'ncrag-app';
    }

    public function getVHost(): string {
        return $this->getString('vhost', '/') ?? '/';
    }

    public function getExchange(): string {
        return $this->getString('exchange', 'nextcloud.events') ?? 'nextcloud.events';
    }

    public function getExchangeType(): string {
        return $this->getString('exchange_type', 'topic') ?? 'topic';
    }

    public function getRoutingPrefix(): string {
        return $this->getString('routing_prefix', 'nextcloud') ?? 'nextcloud';
    }

    public function getConnectionOptions(): array {
        return [
            'host' => $this->getHost(),
            'port' => $this->getPort(),
            'login' => $this->getUser(),
            'password' => $this->getPassword(),
            'vhost' => $this->getVHost(),
        ];
    }

    /**
     * Read app setting or NC_ env, with app setting taking precedence.
     * @return string|null
     */
    private function getString(string $key, ?string $default): ?string {
        $fromApp = $this->config->getAppValue(Application::APP_ID, $key, '__MISSING__');
        if ($fromApp !== '__MISSING__') {
            return $fromApp;
        }
        // Check environment variable
        $envKey = 'NC_' . Application::APP_ID . '_' . $key;
        $fromEnv = \getenv($envKey);
        if ($fromEnv !== false && $fromEnv !== null && $fromEnv !== '') {
            return (string)$fromEnv;
        }
        return $default;
    }

    private function toBool(string $value): bool {
        $normalized = \strtolower(\trim($value));
        return in_array($normalized, ['1', 'true', 'yes', 'on'], true);
    }
}

