import os
import time
import uuid
import requests


BASE_URL = os.environ.get("MOCK_PARSER_URL", "http://127.0.0.1:8080")


def main():
    # Health check
    r = requests.get(f"{BASE_URL}/health", timeout=5)
    r.raise_for_status()
    print("health:", r.json())

    # Submit a small text file
    trace_id = str(uuid.uuid4())
    files = {"file": ("sample.txt", b"Paragraph one.\n\nParagraph two with more details.")}
    data = {"trace_id": trace_id}
    r = requests.post(f"{BASE_URL}/parser/jobs", files=files, data=data, timeout=10)
    r.raise_for_status()
    job = r.json()
    job_id = job["job_id"]
    print("submitted job_id:", job_id)

    # Poll for status
    for _ in range(20):
        s = requests.get(f"{BASE_URL}/jobs/{job_id}/status", timeout=5).json()
        print("status:", s)
        if s["status"] == "succeeded":
            break
        time.sleep(0.5)
    else:
        raise SystemExit("job did not finish in time")

    # Get result
    res = requests.get(f"{BASE_URL}/jobs/{job_id}/result", timeout=10)
    res.raise_for_status()
    payload = res.json()
    print("result keys:", list(payload.keys()))
    assert "paragraphs" in payload and len(payload["paragraphs"]) >= 1
    assert "qa" in payload and len(payload["qa"]) >= 1
    print("OK")


if __name__ == "__main__":
    main()

