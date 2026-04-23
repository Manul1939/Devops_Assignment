import os
from kafka import KafkaConsumer


def main() -> None:
    # Preferred: explicit server list, e.g. "localhost:9092,localhost:29092"
    bootstrap_servers_env = os.getenv("KAFKA_BOOTSTRAP_SERVERS")
    # Backward-compatible single value, e.g. "localhost:9092"
    bootstrap_single_env = os.getenv("KAFKA_BOOTSTRAP")
    host = os.getenv("KAFKA_HOST", "localhost")
    port = os.getenv("KAFKA_PORT", "9092")

    if bootstrap_servers_env:
        bootstrap_servers = [s.strip() for s in bootstrap_servers_env.split(",") if s.strip()]
    elif bootstrap_single_env:
        bootstrap_servers = [bootstrap_single_env]
    else:
        bootstrap_servers = [f"{host}:{port}"]

    topic = os.getenv("KAFKA_TOPIC", "deployment-events")
    group = os.getenv("KAFKA_GROUP", "assignment-consumer")
    consumer = KafkaConsumer(
        topic,
        bootstrap_servers=bootstrap_servers,
        group_id=group,
        auto_offset_reset="earliest",
        enable_auto_commit=True,
    )
    print(f"Listening on topic={topic} bootstrap={bootstrap_servers}")
    for msg in consumer:
        print(msg.value.decode("utf-8"))


if __name__ == "__main__":
    main()
