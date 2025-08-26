<?php
declare(strict_types=1);

namespace OCA\WebhookRabbitMQ\Event;

use OCA\WebhookRabbitMQ\AppInfo\Application;
use OCA\WebhookRabbitMQ\BackgroundJob\RabbitMQPublishJob;
use OCA\WebhookRabbitMQ\Service\ConfigService;
use OCA\WebhookRabbitMQ\Service\EventSerializer;
use OCP\AppFramework\Utility\ITimeFactory;
use OCP\BackgroundJob\IJobList;
use OCP\EventDispatcher\Event;
use OCP\EventDispatcher\IEventListener;
use OCP\ILogger;
use OCP\IUserSession;

class UniversalEventListener implements IEventListener {
    private IJobList $jobList;
    private ConfigService $config;
    private EventSerializer $serializer;
    private ILogger $logger;
    private ITimeFactory $timeFactory;
    private IUserSession $userSession;

    public function __construct(
        IJobList $jobList,
        ConfigService $config,
        EventSerializer $serializer,
        ILogger $logger,
        ITimeFactory $timeFactory,
        IUserSession $userSession
    ) {
        $this->jobList = $jobList;
        $this->config = $config;
        $this->serializer = $serializer;
        $this->logger = $logger;
        $this->timeFactory = $timeFactory;
        $this->userSession = $userSession;
    }

    public function handle(Event $event): void {
        if (!$this->config->isEnabled()) {
            return;
        }

        try {
            $eventData = $this->serializer->serialize($event);

            $currentUserId = null;
            $user = $this->userSession->getUser();
            if ($user !== null) {
                $currentUserId = $user->getUID();
            }

            $payload = [
                'meta' => [
                    'timestamp' => $this->timeFactory->getTime(),
                    'currentUserId' => $currentUserId,
                    'host' => \function_exists('gethostname') ? (gethostname() ?: null) : null,
                    'appId' => Application::APP_ID,
                ],
                'event' => $eventData,
            ];

            $this->jobList->add(RabbitMQPublishJob::class, $payload);
        } catch (\Throwable $e) {
            $this->logger->warning('Failed to enqueue RabbitMQ publish job: ' . $e->getMessage(), [
                'app' => Application::APP_ID,
            ]);
        }
    }
}

