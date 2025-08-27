<?php
declare(strict_types=1);

namespace OCA\WebhookRabbitMQ\Controller;

use OCA\WebhookRabbitMQ\AppInfo\Application;
use OCP\AppFramework\Controller;
use OCP\AppFramework\Http\DataResponse;
use OCP\IConfig;
use OCP\IRequest;

class SettingsController extends Controller {
    private IConfig $config;

    public function __construct(string $appName, IRequest $request, IConfig $config) {
        parent::__construct($appName, $request);
        $this->config = $config;
    }

    /** @AdminRequired */
    public function save(): DataResponse {
        $allowed = ['enabled', 'host', 'port', 'user', 'pass', 'vhost', 'exchange', 'exchange_type', 'routing_prefix'];
        $key = (string)$this->request->getParam('key', '');
        $value = (string)$this->request->getParam('value', '');
        if ($key === '' || !in_array($key, $allowed, true)) {
            return new DataResponse(['status' => 'error', 'message' => 'invalid key'], 400);
        }
        $this->config->setAppValue(Application::APP_ID, $key, $value);
        return new DataResponse(['status' => 'ok']);
    }
}

