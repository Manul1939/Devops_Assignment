import json
import os
import sys
import time
from kafka import KafkaProducer


def build_payload() -> dict:
    return {
        "eventType": "WebsiteCreated",
        "tenant": os.getenv("TENANT", "unknown"),
        "namespace": os.getenv("NAMESPACE", "unknown"),
        "domain": os.getenv("DOMAIN", "unknown"),
        "image": os.getenv("IMAGE", "unknown"),
        "status": os.getenv("STATUS", "deployed"),
        "timestamp": int(time.time()),
    }


def main() -> int:
    bootstrap = os.getenv("KAFKA_BOOTSTRAP", "localhost:9092")
    topic = os.getenv("KAFKA_TOPIC", "deployment-events")
    payload = build_payload()

    producer = KafkaProducer(
        bootstrap_servers=bootstrap,
        value_serializer=lambda v: json.dumps(v).encode("utf-8"),
    )
    producer.send(topic, payload).get(timeout=10)
    producer.flush()
    print(f"Published event to {topic}: {payload}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
