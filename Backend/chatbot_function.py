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


def local_fallback_answer(question, knowledge_base):
    normalized_question = question.lower()

    if any(greeting in normalized_question for greeting in ["hello", "hi", "hey"]):
        return (
            "Hi. I can answer questions about Michael's DevOps experience, AWS projects, "
            "Terraform work, CI/CD pipelines, monitoring, and portfolio architecture."
        )

    if "terraform" in normalized_question:
        return (
            "Michael uses Terraform for infrastructure as code. In his Cloud Resume project, "
            "Terraform manages AWS resources including S3, CloudFront, Route 53, API Gateway, "
            "Lambda, DynamoDB, CloudWatch, SNS, PagerDuty integration, remote state, and Lambda "
            "code signing. He also used Terraform in an AWS EKS CI/CD project."
        )

    if any(term in normalized_question for term in ["experience", "background", "resume"]):
        return (
            "Michael has 2+ years of DevOps, Site Reliability, and Platform Engineering experience. "
            "He supports large-scale production systems, CI/CD automation, incident response, cloud "
            "infrastructure, observability, and release validation across 12+ environments."
        )

    if any(term in normalized_question for term in ["aws", "cloud", "architecture"]):
        return (
            "Michael's portfolio uses AWS S3, CloudFront, Route 53, API Gateway, Lambda, DynamoDB, "
            "ACM, CloudWatch, SNS, PagerDuty, Terraform, GitHub Actions, pytest, Cypress, CodeQL, "
            "Syft, Grype, and AWS Lambda code signing."
        )

    if any(term in normalized_question for term in ["cicd", "ci/cd", "pipeline", "github actions"]):
        return (
            "Michael has experience with CI/CD using GitHub Actions, Jenkins, and Bamboo. "
            "This portfolio uses GitHub Actions for testing, security scanning, signed Lambda "
            "artifact deployment, Terraform apply, and CloudFront invalidation."
        )

    if any(term in normalized_question for term in ["contact", "email", "github"]):
        return (
            "You can contact Michael at mpgm1798@gmail.com or visit his GitHub profile at "
            "https://github.com/MichaelGarrido."
        )

    return (
        "I can answer questions about Michael's resume, DevOps background, AWS and Terraform "
        "projects, CI/CD work, monitoring, and portfolio architecture. For anything outside that "
        "scope, please contact Michael directly."
    )


def parse_openai_error(error):
    try:
        details = json.loads(error.read().decode("utf-8"))
    except (json.JSONDecodeError, UnicodeDecodeError):
        return "", ""

    error_details = details.get("error", {})
    return error_details.get("code", ""), error_details.get("message", "")


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
        code, message = parse_openai_error(error)
        print(f"OpenAI API error: {code} {message}")

        if code in {"insufficient_quota", "rate_limit_exceeded"}:
            answer = local_fallback_answer(question, load_knowledge_base())
            return response(200, {"answer": answer, "source": "local_fallback"})

        return response(502, {"error": "The chatbot service could not answer right now."})

    except Exception as error:
        print(f"Unexpected chatbot error: {error}")
        return response(500, {"error": "Unexpected chatbot error."})
