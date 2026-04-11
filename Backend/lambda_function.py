import json
import os
import boto3
from botocore.exceptions import ClientError


def get_table():
    dynamodb = boto3.resource("dynamodb")
    return dynamodb.Table(os.environ["TABLE_NAME"])


def lambda_handler(event, context):
    table = get_table()

    try:
        result = table.update_item(
            Key={"id": "visitor_count"},
            UpdateExpression="SET #count = if_not_exists(#count, :start) + :inc",
            ExpressionAttributeNames={"#count": "count"},
            ExpressionAttributeValues={
                ":start": 0,
                ":inc": 1
            },
            ReturnValues="UPDATED_NEW"
        )

        new_count = int(result["Attributes"]["count"])

        return {
            "statusCode": 200,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Headers": "Content-Type",
                "Access-Control-Allow-Methods": "GET,OPTIONS"
            },
            "body": json.dumps({"count": new_count})
        }

    except ClientError as e:
        return {
            "statusCode": 500,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Headers": "Content-Type",
                "Access-Control-Allow-Methods": "GET,OPTIONS"
            },
            "body": json.dumps({
                "error": "Failed to update visitor count",
                "details": str(e)
            })
        }