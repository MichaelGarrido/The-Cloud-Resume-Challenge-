import json
import os
import urllib.error
import urllib.request
from pathlib import Path

OPENAI_API_URL = "https://api.openai.com/v1/responses"
MODEL = os.environ.get("OPENAI_MODEL", "gpt-5-mini")

CORS_HEADERS = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type",
    "Access-Control-Allow-Methods": "POST,OPTIONS",
}


def response(status_code, body):
    return {
        "statusCode": status_code,
        "headers": CORS_HEADERS,
        "body": json.dumps(body),
    }


def load_knowledge_base():
    knowledge_path = Path(__file__).with_name("chatbot_knowledge.md")
    return knowledge_path.read_text(encoding="utf-8")


def parse_question(event):
    if event.get("requestContext", {}).get("http", {}).get("method") == "OPTIONS":
        return None

    try:
        body = json.loads(event.get("body") or "{}")
    except json.JSONDecodeError:
        raise ValueError("Request body must be valid JSON.")

    question = str(body.get("question", "")).strip()

    if not question:
        raise ValueError("Question is required.")

    if len(question) > 500:
        raise ValueError("Question must be 500 characters or fewer.")

    return question


def ask_openai(question, knowledge_base):
    api_key = os.environ["OPENAI_API_KEY"]

    payload = {
        "model": MODEL,
        "instructions": (
            "You are Michael Garrido's portfolio assistant. "
            "Answer questions using only the provided knowledge base. "
            "Be concise, professional, and friendly. "
            "If the answer is not in the knowledge base, say you do not have that information "
            "and suggest contacting Michael directly. "
            "Do not invent employers, certifications, salary, personal details, or project claims."
        ),
        "input": (
            f"Knowledge base:\n{knowledge_base}\n\n"
            f"Visitor question:\n{question}"
        ),
        "max_output_tokens": 250,
    }

    request = urllib.request.Request(
        OPENAI_API_URL,
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        },
        method="POST",
    )

    with urllib.request.urlopen(request, timeout=20) as openai_response:
        data = json.loads(openai_response.read().decode("utf-8"))

    answer = data.get("output_text", "").strip()

    if not answer:
        answer = "I could not generate an answer right now. Please contact Michael directly."

    return answer


def lambda_handler(event, context):
    try:
        question = parse_question(event)

        if question is None:
            return response(200, {"ok": True})

        answer = ask_openai(question, load_knowledge_base())
        return response(200, {"answer": answer})

    except ValueError as error:
        return response(400, {"error": str(error)})

    except KeyError:
        return response(500, {"error": "OPENAI_API_KEY is not configured."})

    except urllib.error.HTTPError as error:
        details = error.read().decode("utf-8")
        print(f"OpenAI API error: {details}")
        return response(502, {"error": "The chatbot service could not answer right now."})

    except Exception as error:
        print(f"Unexpected chatbot error: {error}")
        return response(500, {"error": "Unexpected chatbot error."})
