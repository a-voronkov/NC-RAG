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
        $allowed = ['host', 'port', 'user', 'pass', 'vhost', 'exchange', 'exchange_type', 'routing_prefix'];
        $key = (string)$this->request->getParam('key', '');
        $value = (string)$this->request->getParam('value', '');
        
        // Log the save attempt for debugging
        \OCP\Util::writeLog('webhook_rabbitmq', "Settings save attempt: key='$key', value='$value'", \OCP\Util::INFO);
        
        // Explicitly reject the problematic 'enabled' key
        if ($key === 'enabled') {
            \OCP\Util::writeLog('webhook_rabbitmq', "Rejected attempt to save 'enabled' key", \OCP\Util::WARN);
            return new DataResponse(['status' => 'error', 'message' => 'enabled key is deprecated, use publish_enabled'], 400);
        }
        
        if ($key === '' || !in_array($key, $allowed, true)) {
            \OCP\Util::writeLog('webhook_rabbitmq', "Invalid key rejected: '$key'", \OCP\Util::WARN);
            return new DataResponse(['status' => 'error', 'message' => 'invalid key'], 400);
        }
        
        // Clean up any existing problematic 'enabled' key before and after saving
        $this->config->deleteAppValue(Application::APP_ID, 'enabled');
        $this->config->setAppValue(Application::APP_ID, $key, $value);
        $this->config->deleteAppValue(Application::APP_ID, 'enabled');
        
        \OCP\Util::writeLog('webhook_rabbitmq', "Successfully saved: key='$key', value='$value'", \OCP\Util::INFO);
        return new DataResponse(['status' => 'ok']);
    }
}

