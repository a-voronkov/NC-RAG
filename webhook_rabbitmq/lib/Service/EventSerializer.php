<?php
declare(strict_types=1);

namespace OCA\WebhookRabbitMQ\Service;

use OCP\EventDispatcher\Event;

class EventSerializer {
    public function serialize(Event $event): array {
        $class = \get_class($event);
        $interfaces = \array_values(\class_implements($event) ?: []);

        $data = [
            'class' => $class,
            'interfaces' => $interfaces,
            'values' => [],
        ];

        $refClass = new \ReflectionClass($event);
        foreach ($refClass->getMethods() as $method) {
            if ($method->isStatic()) {
                continue;
            }
            if ($method->getNumberOfRequiredParameters() > 0) {
                continue;
            }
            $name = $method->getName();
            if (!\preg_match('/^(get|is)[A-Z_].*/', $name)) {
                continue;
            }
            try {
                $value = $method->invoke($event);
                $data['values'][$name] = $this->normalize($value, 2);
            } catch (\Throwable $e) {
                // Ignore non-invokable or failing getters
            }
        }

        return $data;
    }

    /**
     * Normalize values to scalars/arrays convertible to JSON.
     * Depth-limited to prevent deep recursion.
     */
    private function normalize($value, int $depth) {
        if ($value === null) {
            return null;
        }
        if (\is_scalar($value)) {
            return $value;
        }
        if ($value instanceof \DateTimeInterface) {
            return $value->format(\DateTimeInterface::ATOM);
        }
        if ($value instanceof \JsonSerializable) {
            return $value->jsonSerialize();
        }
        if (\is_array($value)) {
            if ($depth <= 0) {
                return '[array]';
            }
            $out = [];
            foreach ($value as $k => $v) {
                $out[$k] = $this->normalize($v, $depth - 1);
            }
            return $out;
        }
        if (\is_object($value)) {
            if ($depth <= 0) {
                return '[' . \get_class($value) . ']';
            }
            // Try common identifier getters
            foreach (['getId', 'getID', 'getUid', 'getUID', 'getName', 'getPath'] as $getter) {
                if (\method_exists($value, $getter) && \is_callable([$value, $getter])) {
                    try {
                        return [
                            '_class' => \get_class($value),
                            $getter => $this->normalize($value->$getter(), $depth - 1),
                        ];
                    } catch (\Throwable $e) {
                    }
                }
            }
            if (\method_exists($value, '__toString')) {
                try {
                    return (string)$value;
                } catch (\Throwable $e) {
                }
            }
            return '[' . \get_class($value) . ']';
        }
        return '[unknown]';
    }
}

