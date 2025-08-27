<?php
declare(strict_types=1);

namespace OCA\WebhookRabbitMQ\Settings;

use OCA\WebhookRabbitMQ\AppInfo\Application;
use OCP\IConfig;
use OCP\IL10N;
use OCP\Settings\ISettings;
use OCP\AppFramework\Http\TemplateResponse;

class Admin implements ISettings {
    private IConfig $config;
    private IL10N $l;

    public function __construct(IConfig $config, IL10N $l) {
        $this->config = $config;
        $this->l = $l;
    }

    public function getForm(): TemplateResponse {
        $params = [
            'enabled' => $this->config->getAppValue(Application::APP_ID, 'enabled', '0'),
            'host' => $this->config->getAppValue(Application::APP_ID, 'host', '127.0.0.1'),
            'port' => $this->config->getAppValue(Application::APP_ID, 'port', '5672'),
            'user' => $this->config->getAppValue(Application::APP_ID, 'user', 'guest'),
            'pass' => $this->config->getAppValue(Application::APP_ID, 'pass', 'guest'),
            'vhost' => $this->config->getAppValue(Application::APP_ID, 'vhost', '/'),
            'exchange' => $this->config->getAppValue(Application::APP_ID, 'exchange', 'nextcloud.events'),
            'exchange_type' => $this->config->getAppValue(Application::APP_ID, 'exchange_type', 'topic'),
            'routing_prefix' => $this->config->getAppValue(Application::APP_ID, 'routing_prefix', 'nextcloud'),
        ];
        return new TemplateResponse(Application::APP_ID, 'admin', $params);
    }

    public function getSection(): string {
        return 'additional';
    }

    public function getPriority(): int {
        return 50;
    }
}

