import json
import io
import urllib.error
from unittest.mock import patch

from Backend import chatbot_function


def test_parse_question_success():
    event = {
        "body": json.dumps({"question": "What AWS services has Michael used?"})
    }

    assert chatbot_function.parse_question(event) == "What AWS services has Michael used?"


def test_parse_question_requires_question():
    event = {
        "body": json.dumps({"question": "   "})
    }

    result = chatbot_function.lambda_handler(event, {})

    assert result["statusCode"] == 400
    body = json.loads(result["body"])
    assert body["error"] == "Question is required."


def test_options_request_returns_ok():
    event = {
        "requestContext": {
            "http": {
                "method": "OPTIONS"
            }
        }
    }

    result = chatbot_function.lambda_handler(event, {})

    assert result["statusCode"] == 200
    body = json.loads(result["body"])
    assert body["ok"] is True


@patch("Backend.chatbot_function.load_knowledge_base")
@patch("Backend.chatbot_function.ask_openai")
def test_lambda_handler_returns_answer(mock_ask_openai, mock_load_knowledge_base):
    mock_load_knowledge_base.return_value = "Michael knows AWS and Terraform."
    mock_ask_openai.return_value = "Michael has hands-on experience with AWS and Terraform."

    event = {
        "body": json.dumps({"question": "What cloud tools does Michael use?"})
    }

    result = chatbot_function.lambda_handler(event, {})

    assert result["statusCode"] == 200
    body = json.loads(result["body"])
    assert body["answer"] == "Michael has hands-on experience with AWS and Terraform."

    mock_ask_openai.assert_called_once_with(
        "What cloud tools does Michael use?",
        "Michael knows AWS and Terraform."
    )


def test_missing_openai_key_returns_error():
    event = {
        "body": json.dumps({"question": "Tell me about Michael."})
    }

    with patch("Backend.chatbot_function.load_knowledge_base", return_value="Knowledge"):
        with patch("Backend.chatbot_function.ask_openai", side_effect=KeyError("OPENAI_API_KEY")):
            result = chatbot_function.lambda_handler(event, {})

    assert result["statusCode"] == 500
    body = json.loads(result["body"])
    assert body["error"] == "OPENAI_API_KEY is not configured."


def test_quota_error_returns_local_fallback_answer():
    event = {
        "body": json.dumps({"question": "What is Michael's Terraform experience?"})
    }
    error_body = json.dumps({
        "error": {
            "code": "insufficient_quota",
            "message": "You exceeded your current quota."
        }
    }).encode("utf-8")
    quota_error = urllib.error.HTTPError(
        url="https://api.openai.com/v1/responses",
        code=429,
        msg="Too Many Requests",
        hdrs={},
        fp=io.BytesIO(error_body),
    )

    with patch("Backend.chatbot_function.load_knowledge_base", return_value="Knowledge"):
        with patch("Backend.chatbot_function.ask_openai", side_effect=quota_error):
            result = chatbot_function.lambda_handler(event, {})

    assert result["statusCode"] == 200
    body = json.loads(result["body"])
    assert body["source"] == "local_fallback"
    assert "Terraform" in body["answer"]
