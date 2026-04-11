import json
from unittest.mock import MagicMock, patch
from botocore.exceptions import ClientError

from Backend import lambda_function


@patch("Backend.lambda_function.get_table")
def test_lambda_handler_success(mock_get_table):
    mock_table = MagicMock()
    mock_table.update_item.return_value = {
        "Attributes": {
            "count": 7
        }
    }
    mock_get_table.return_value = mock_table

    result = lambda_function.lambda_handler({}, {})

    assert result["statusCode"] == 200
    assert result["headers"]["Content-Type"] == "application/json"
    assert result["headers"]["Access-Control-Allow-Origin"] == "*"

    body = json.loads(result["body"])
    assert body["count"] == 7


@patch("Backend.lambda_function.get_table")
def test_lambda_handler_dynamodb_error(mock_get_table):
    mock_table = MagicMock()
    mock_table.update_item.side_effect = ClientError(
        error_response={
            "Error": {
                "Code": "ProvisionedThroughputExceededException",
                "Message": "Throughput exceeded"
            }
        },
        operation_name="UpdateItem"
    )
    mock_get_table.return_value = mock_table

    result = lambda_function.lambda_handler({}, {})

    assert result["statusCode"] == 500
    assert result["headers"]["Content-Type"] == "application/json"
    assert result["headers"]["Access-Control-Allow-Origin"] == "*"

    body = json.loads(result["body"])
    assert body["error"] == "Failed to update visitor count"