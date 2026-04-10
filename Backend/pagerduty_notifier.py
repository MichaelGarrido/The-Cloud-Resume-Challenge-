import json
import os
import urllib.request

PAGERDUTY_KEY = os.environ["PAGERDUTY_KEY"]
PAGERDUTY_URL = os.environ["PAGERDUTY_URL"]

def lambda_handler(event, context):
    for record in event["Records"]:
        message = record["Sns"]["Message"]
        subject = record["Sns"].get("Subject", "CloudWatch Alarm")

        payload = {
            "routing_key": PAGERDUTY_KEY,
            "event_action": "trigger",
            "payload": {
                "summary": subject,
                "source": "cloudwatch",
                "severity": "error",
                "custom_details": {
                    "message": message
                }
            }
        }

        req = urllib.request.Request(
            PAGERDUTY_URL,
            data=json.dumps(payload).encode("utf-8"),
            headers={"Content-Type": "application/json"},
            method="POST"
        )

        with urllib.request.urlopen(req) as response:
            response.read()

    return {"statusCode": 200, "body": "ok"}