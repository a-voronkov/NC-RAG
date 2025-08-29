<?php
declare(strict_types=1);

namespace OCA\WebhookRabbitMQ\AppInfo;

use OCA\WebhookRabbitMQ\Event\UniversalEventListener;
use OCP\AppFramework\App;
use OCP\AppFramework\Bootstrap\IBootContext;
use OCP\AppFramework\Bootstrap\IBootstrap;
use OCP\AppFramework\Bootstrap\IRegistrationContext;
use OCP\EventDispatcher\Event;
use OCP\EventDispatcher\IEventDispatcher;

class Application extends App implements IBootstrap {
    public const APP_ID = 'webhook_rabbitmq';

    public function __construct() {
        parent::__construct(self::APP_ID);
    }

    public function register(IRegistrationContext $context): void {
        // No-op: we'll attach a universal listener in boot() to the base Event class
    }

    public function boot(IBootContext $context): void {
        $serverContainer = $context->getServerContainer();
        // Migrate legacy config key 'enabled' -> 'publish_enabled' once at boot
        try {
            /** @var \OCP\IConfig $cfg */
            $cfg = $serverContainer->get(\OCP\IConfig::class);
            $legacy = $cfg->getAppValue(self::APP_ID, 'enabled', '__MISSING__');
            $current = $cfg->getAppValue(self::APP_ID, 'publish_enabled', '__MISSING__');
            if ($legacy !== '__MISSING__' && $current === '__MISSING__') {
                $cfg->setAppValue(self::APP_ID, 'publish_enabled', $legacy);
                // Do not delete legacy immediately to avoid surprises; keep for compatibility
            }
        } catch (\Throwable $e) {
            // ignore migration errors silently
        }
        /** @var IEventDispatcher $dispatcher */
        $dispatcher = $serverContainer->query(IEventDispatcher::class);
        // Attach our universal listener to the base Event class to capture all events
        $dispatcher->addServiceListener(Event::class, UniversalEventListener::class);
    }
}

