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
        // Clean up and migrate legacy config key 'enabled' -> 'publish_enabled' once at boot
        try {
            /** @var \OCP\IConfig $cfg */
            $cfg = $serverContainer->get(\OCP\IConfig::class);
            $legacy = $cfg->getAppValue(self::APP_ID, 'enabled', '__MISSING__');
            $current = $cfg->getAppValue(self::APP_ID, 'publish_enabled', '__MISSING__');
            
            // If legacy exists and is problematic (like "1"), clean it up
            if ($legacy !== '__MISSING__') {
                // Check if legacy value is problematic (not proper JSON or just "1")
                if ($legacy === '1' || $legacy === '0' || (!empty($legacy) && json_decode($legacy) === null && $legacy !== 'yes' && $legacy !== 'no')) {
                    // Migrate simple values
                    $migratedValue = ($legacy === '1' || $legacy === 'yes') ? '1' : '0';
                    if ($current === '__MISSING__') {
                        $cfg->setAppValue(self::APP_ID, 'publish_enabled', $migratedValue);
                    }
                    // Remove the problematic legacy key
                    $cfg->deleteAppValue(self::APP_ID, 'enabled');
                } elseif ($current === '__MISSING__') {
                    // Normal migration for non-problematic values
                    $cfg->setAppValue(self::APP_ID, 'publish_enabled', $legacy);
                }
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

