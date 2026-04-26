<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <meta name="description" content="Michael Garrido portfolio: DevOps, Site Reliability, AWS, Terraform, CI/CD, and production operations." />
    <title>Michael Garrido | DevOps & Site Reliability Engineer</title>
    <link rel="stylesheet" href="styles.css" />
</head>

<body>
    <header class="site-header">
        <nav class="nav" aria-label="Primary navigation">
            <a class="brand" href="#top">Michael Garrido</a>
            <div class="nav-links">
                <a href="#about">About</a>
                <a href="#resume">Resume</a>
                <a href="#projects">Projects</a>
                <a href="#contact">Contact</a>
            </div>
        </nav>
    </header>

    <main id="top">
        <section class="hero">
            <div class="hero-copy">
                <p class="eyebrow">DevOps • Site Reliability • Platform Engineering</p>
                <h1>Building reliable cloud systems and the pipelines that keep them moving.</h1>
                <p class="hero-summary">
                    DevOps and Site Reliability Engineer with 2+ years supporting enterprise production systems,
                    repeatable deployments, incident response, and cloud infrastructure across AWS, Linux, Terraform,
                    Kubernetes, Jenkins, and GitHub Actions.
                </p>
                <div class="hero-actions">
                    <a class="button primary" href="#projects">View Projects</a>
                    <a class="button secondary" href="mailto:mpgm1798@gmail.com">Email Me</a>
                </div>
            </div>

            <aside class="signal-panel" aria-label="Professional highlights">
                <div>
                    <span class="metric">12+</span>
                    <span class="label">environments supported</span>
                </div>
                <div>
                    <span class="metric">4</span>
                    <span class="label">monthly production releases</span>
                </div>
                <div>
                    <span class="metric" id="visitor-count">...</span>
                    <span class="label">portfolio visits</span>
                </div>
            </aside>
        </section>

        <section id="about" class="section">
            <div class="section-heading">
                <p class="eyebrow">About</p>
                <h2>Production-minded engineer with a reliability-first workflow.</h2>
            </div>
            <div class="about-grid">
                <p>
                    I support large-scale, mission-critical applications by planning releases, validating deployments,
                    monitoring production behavior, and troubleshooting issues under real operational pressure. My work
                    sits at the intersection of platform operations, automation, observability, and cloud infrastructure.
                </p>
                <p>
                    I like systems that are boring in the best way: repeatable, observable, documented, and protected by
                    tests and automation. This portfolio is also a live project, backed by AWS serverless infrastructure,
                    Terraform, CI/CD, monitoring, security scanning, signed commits, SBOM generation, and Lambda code signing.
                </p>
            </div>
        </section>

        <section id="resume" class="section resume-section">
            <div class="section-heading">
                <p class="eyebrow">Resume</p>
                <h2>Experience, education, and core skills.</h2>
            </div>

            <div class="timeline">
                <article class="timeline-item">
                    <div class="timeline-meta">
                        <span>10/2023 - Present</span>
                        <span>Lake Mary, FL</span>
                    </div>
                    <div class="timeline-body">
                        <h3>DevOps Engineer, Solution Analyst</h3>
                        <p class="company">Deloitte, LLP</p>
                        <ul>
                            <li>Supported enterprise-scale applications across 12 environments, maintaining stability during up to 4 production releases per month.</li>
                            <li>Partnered with engineering, QA, and operations teams to plan, deploy, validate, and monitor releases.</li>
                            <li>Performed production incident response using log analysis, configuration review, endpoint checks, and application behavior analysis.</li>
                            <li>Maintained CI/CD pipelines in Jenkins and Bamboo, including Jenkinsfile updates and deployment validation steps.</li>
                            <li>Built Bash and Linux automation to reduce repetitive operational work and improve deployment consistency.</li>
                            <li>Supported observability with Splunk, CloudWatch-style monitoring patterns, and post-release health validation.</li>
                            <li>Mentored and onboarded engineers on production support, deployment workflows, and operational best practices.</li>
                        </ul>
                    </div>
                </article>

                <article class="timeline-item">
                    <div class="timeline-meta">
                        <span>05/2023</span>
                        <span>Miami, FL</span>
                    </div>
                    <div class="timeline-body">
                        <h3>B.S. Computer Science</h3>
                        <p class="company">Florida International University</p>
                    </div>
                </article>
            </div>

            <div class="skills-grid" aria-label="Technical skills">
                <div>
                    <h3>Cloud & Infrastructure</h3>
                    <p>AWS, S3, CloudFront, Route 53, API Gateway, Lambda, DynamoDB, ACM, Linux, Terraform</p>
                </div>
                <div>
                    <h3>CI/CD & Automation</h3>
                    <p>GitHub Actions, Jenkins, Bamboo, Git, Bitbucket, SVN, Python, Bash</p>
                </div>
                <div>
                    <h3>Containers & Quality</h3>
                    <p>Docker, Kubernetes, EKS, Helm, pytest, Cypress, unit testing, end-to-end testing</p>
                </div>
                <div>
                    <h3>Monitoring & Reliability</h3>
                    <p>CloudWatch, SNS, PagerDuty, Splunk, Grafana, incident response, log analysis, MTTR reduction</p>
                </div>
                <div>
                    <h3>Languages & Collaboration</h3>
                    <p>English, Spanish, JIRA, Confluence, Agile/Scrum, Power BI, ETL pipelines</p>
                </div>
            </div>
        </section>

        <section id="projects" class="section">
            <div class="section-heading">
                <p class="eyebrow">Projects</p>
                <h2>Hands-on cloud and DevOps work.</h2>
            </div>

            <article class="project feature-project">
                <div class="project-copy">
                    <div class="project-header">
                        <h3>Cloud Resume Project</h3>
                        <p>AWS, Terraform, Serverless Architecture, CI/CD, Supply Chain Security</p>
                    </div>
                    <p>
                        A production-style serverless portfolio deployed with AWS S3, CloudFront, Route 53, API Gateway,
                        Lambda, DynamoDB, ACM, CloudWatch, SNS, PagerDuty, and Terraform remote state.
                    </p>
                    <ul>
                        <li>Built a Python Lambda API with DynamoDB-backed visitor tracking and a JavaScript frontend integration.</li>
                        <li>Automated infrastructure and site delivery with GitHub Actions, Terraform, CloudFront invalidations, pytest, and Cypress.</li>
                        <li>Added signed commit enforcement, CodeQL, Syft SBOM generation, Grype vulnerability scanning, and AWS Lambda code signing.</li>
                        <li>Designed a staged deployment workflow with PR test environments, production approval, and test-environment cleanup.</li>
                        <li>Integrated CloudWatch alarms, SNS notifications, and PagerDuty incident routing for operational visibility.</li>
                    </ul>
                    <div class="project-links">
                        <a href="https://github.com/MichaelGarrido/The-Cloud-Resume-Challenge-" target="_blank" rel="noreferrer">GitHub Repository</a>
                        <a href="https://michaelgarridoresume.com/" target="_blank" rel="noreferrer">Live Site</a>
                    </div>
                </div>
                <figure class="architecture">
                    <img src="architecture.svg" alt="Cloud Resume architecture showing GitHub Actions, Terraform, AWS, security scans, monitoring, and the portfolio site." />
                </figure>
            </article>

            <article class="project">
                <div class="project-header">
                    <h3>Infrastructure & CI/CD Pipeline</h3>
                    <p>AWS, EKS, Terraform, Docker, Helm, GitHub Actions</p>
                </div>
                <p>
                    Designed an end-to-end CI/CD workflow for a microservices-based application deployed on AWS EKS,
                    using Terraform for cloud infrastructure, Docker for containerization, and Helm for Kubernetes releases.
                </p>
                <ul>
                    <li>Provisioned infrastructure with validation stages for safer deployments.</li>
                    <li>Automated build, test, and deployment workflows to reduce manual release effort.</li>
                    <li>Integrated SonarCloud static analysis to improve code quality and reliability.</li>
                </ul>
            </article>
        </section>

        <section id="contact" class="section contact-section">
            <div>
                <p class="eyebrow">Contact</p>
                <h2>Let’s talk cloud, reliability, and automation.</h2>
            </div>
            <div class="contact-links">
                <a href="mailto:mpgm1798@gmail.com">mpgm1798@gmail.com</a>
                <a href="tel:+17863548038">(786) 354-8038</a>
                <a href="https://github.com/MichaelGarrido" target="_blank" rel="noreferrer">GitHub</a>
                <span>Orlando, FL</span>
            </div>
        </section>
    </main>

    <script>
        async function updateVisitorCount() {
            const counter = document.getElementById("visitor-count");

            try {
                const response = await fetch("${api_url}/counter");

                if (!response.ok) {
                    throw new Error("API request failed");
                }

                const data = await response.json();
                counter.textContent = data.count;
            } catch (error) {
                console.error("Error fetching visitor count:", error);
                counter.textContent = "Live";
            }
        }

        document.addEventListener("DOMContentLoaded", updateVisitorCount);
    </script>
</body>
</html>
