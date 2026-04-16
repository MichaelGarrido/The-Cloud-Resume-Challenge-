<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Michael Garrido | DevOps Engineer</title>
    <link rel="stylesheet" href="styles.css" />
</head>

<body>
    <header>
        <h1>Michael Garrido</h1>
        <p>DevOps Engineer</p>
    </header>

    <section>
        <h2>Experience</h2>
        <p><strong>Deloitte — DevOps Engineer</strong></p>
        <ul>
            <li>Owned and supported up to 4 monthly production releases across 12 environments, ensuring deployment stability through log validation, endpoint verification, and post-release testing.</li>
            <li>Supported mission-critical enterprise applications during production deployments and post-release validation, resolving issues to maintain service availability.</li>
            <li>Maintained and enhanced CI/CD pipelines using Jenkins, modifying Jenkinsfiles and creating new pipelines to support evolving release and deployment requirements.</li>
            <li>Performed source code versioning and release management using SVN and Bitbucket, merging developer changes into release branches and managing deployment tags.</li>
            <li>Developed Bash and Linux automation scripts to eliminate repetitive operational tasks and improve deployment consistency.</li>
            <li>Executed production troubleshooting and incident response, analyzing logs and configuration issues to restore services under tight release timelines.</li>
            <li>Coordinated weekly deployment planning meetings with developers and QA teams to align on release readiness and deployment schedules.</li>
            <li>Managed patching workflows, coordinating service shutdowns and restorations with cloud teams and validating workloads post-maintenance.</li>
            <li>Mentored and onboarded new team members, providing deployment knowledge transfer and operational guidance to accelerate team productivity.</li>
            <li>Supported deployments and operations for data workflows and reporting systems, including IDMC workflows and Power BI dashboards.</li>
        </ul>
    </section>

    <section>
        <h2>Education</h2>
        <p><strong>Computer Science (B.S):</strong> 05/2023</p>
        <p>Florida International University - Miami, FL, US</p>
    </section>

    <section>
        <h2>Skills</h2>
        <ul>
            <li><strong>Cloud & Infrastructure:</strong> AWS, Linux, Terraform, Ansible, Docker, Kubernetes (EKS), Helm</li>
            <li><strong>CI/CD & Automation:</strong> Jenkins, GitHub Actions, Git, Bitbucket, Python, Bash</li>
            <li><strong>Monitoring & Reliability:</strong> Grafana, Splunk, Log Analysis, Incident Response, Production Support</li>
            <li><strong>Collaboration & Tools:</strong> JIRA, Confluence, Agile/Scrum, Power BI, ETL Pipelines</li>
        </ul>
    </section>

    <section>
        <h2>Languages</h2>
        <ul>
            <li>English (Fluent)</li>
            <li>Spanish (Native)</li>
        </ul>
    </section>

    <section>
        <h2>Projects</h2>

        <p><strong>Cloud Resume Project | AWS, Terraform, Serverless Architecture</strong></p>
        <ul>
            <li>Architected and deployed a fully serverless web application using S3, CloudFront, Route 53, Lambda, API Gateway, and DynamoDB.</li>
            <li>Automated infrastructure provisioning using Terraform.</li>
            <li>Developed a Python-based Lambda API using boto3 for real-time visitor tracking.</li>
            <li>Implemented monitoring and alerting using CloudWatch, SNS, and PagerDuty.</li>
            <li>Established CI/CD workflows using GitHub.</li>
            <li>Resolved real-world AWS issues including IAM permissions and DNS conflicts.</li>
        </ul>

        <p><strong>DevOps Project: Infrastructure & CI/CD (AWS, EKS, Terraform)</strong></p>
        <ul>
            <li>Designed and implemented CI/CD pipelines for microservices deployment using GitHub Actions.</li>
            <li>Provisioned AWS infrastructure using Terraform with validation stages.</li>
            <li>Containerized applications using Docker and deployed to EKS using Helm.</li>
            <li>Integrated SonarCloud for static code analysis.</li>
        </ul>
    </section>

    <section>
        <h2>Visitor Counter</h2>
        <p>Visitors: <span id="visitor-count">Loading...</span></p>
    </section>

    <script>
        async function updateVisitorCount() {
            try {
                const response = await fetch("${api_url}/counter");

                if (!response.ok) {
                    throw new Error("API request failed");
                }

                const data = await response.json();
                document.getElementById("visitor-count").textContent = data.count;

            } catch (error) {
                console.error("Error fetching visitor count:", error);
                document.getElementById("visitor-count").textContent = "Unavailable";
            }
        }

        document.addEventListener("DOMContentLoaded", updateVisitorCount);
    </script>
</body>
</html>