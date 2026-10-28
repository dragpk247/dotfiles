#!/usr/bin/env python3
"""
DRAFT-PITCH — Automated Hiring Manager & Recruiter Outreach Generator
Generates personalized, high-converting LinkedIn and email outreach notes
to bypass ATS queues and put your resume directly into decision-maker hands.
"""

import sys
import argparse
import urllib.parse

ROLE_PROFILES = {
    "java": {
        "title": "Java & Full-Stack Application Developer",
        "keywords": "Java, Spring Boot, Angular, Kafka, Microservices, REST APIs, Redis",
        "hook": "architecting Spring Boot microservices, building responsive Angular workflows, and building Kafka pipelines reducing latency by 28%",
        "folder": "01_Java_FullStack"
    },
    "devops": {
        "title": "Senior DevOps & Platform Engineer",
        "keywords": "JFrog Artifactory, X-Ray, DORA Metrics, GitHub Enterprise, LaunchDarkly, CI/CD",
        "hook": "scaling Artifactory clusters, X-Ray security scanning, tracking DORA metrics, and building GitHub Actions templates",
        "folder": "02_DevOps_Platform"
    },
    "swe": {
        "title": "Software Engineer / Distributed Systems",
        "keywords": "Java, Python, Distributed Systems, Cloud Infrastructure, REST APIs",
        "hook": "engineering distributed backends, multi-environment pipelines, and high-volume data flows",
        "folder": "03_Software_Engineer_Master"
    }
}

def main():
    parser = argparse.ArgumentParser(description="Generate outreach pitch and LinkedIn search URLs for hiring managers")
    parser.add_argument("company", help="Company Name (e.g. 'Globus Medical', 'State Street')")
    parser.add_argument("role", help="Role Title (e.g. 'Java Developer', 'DevOps Engineer')")
    parser.add_argument("--type", choices=["java", "devops", "swe"], default="java", help="Profile archetype to use (default: java)")
    parser.add_argument("--recruiter", help="Optional recruiter name if replying to an agency recruiter")
    args = parser.parse_args()

    profile = ROLE_PROFILES.get(args.type, ROLE_PROFILES["java"])
    company_clean = args.company.strip()
    role_clean = args.role.strip()

    # Generate LinkedIn search URLs
    li_hm_query = f'"{company_clean}" ("Engineering Manager" OR "Director of Engineering" OR "Lead Software Engineer")'
    li_hm_url = f"https://www.linkedin.com/search/results/people/?keywords={urllib.parse.quote(li_hm_query)}"

    li_rec_query = f'"{company_clean}" ("Technical Recruiter" OR "Talent Acquisition")'
    li_rec_url = f"https://www.linkedin.com/search/results/people/?keywords={urllib.parse.quote(li_rec_query)}"

    print("\n" + "=" * 70)
    print(f" 🎯 OUTREACH LAUNCHPAD: {company_clean.upper()} — {role_clean.upper()}")
    print("=" * 70)

    print("\n🔎 \033[1;36mStep 1: Find the Decision Makers on LinkedIn\033[0m")
    print(f"  • Hiring Managers: \033[4m{li_hm_url}\033[0m")
    print(f"  • Tech Recruiters: \033[4m{li_rec_url}\033[0m")

    print("\n📩 \033[1;32mStep 2: Direct Hiring Manager LinkedIn Message (300-char limit)\033[0m")
    print("-" * 70)
    msg_hm = (
        f"Hi [Name], saw your team is growing engineering at {company_clean}. "
        f"Over 3+ yrs, I've specialized in Java, Spring Boot, Angular & Kafka microservices reducing latency by 28%. "
        f"Applied for {role_clean}, but wanted to connect directly with the team! Best, Jordan"
    )
    print(msg_hm)
    print(f"\033[2m[Length: {len(msg_hm)} / 300 chars]\033[0m")

    print("\n📧 \033[1;32mStep 3: Direct Email / InMail to Engineering Director or Lead\033[0m")
    print("-" * 70)
    email_body = f"""Subject: Jordan Isaac - Application & Introduction: {role_clean} @ {company_clean}

Hi [Name],

I noticed that your engineering group at {company_clean} is actively hiring for a {role_clean}. 

Rather than just submitting my application through the company portal, I wanted to reach out directly to your desk. Over the last 3+ years supporting enterprise banking and distributed systems (TCS, State Street, PenFed), my focus has been on {profile['hook']}.

Core competencies aligned with your stack:
• {profile['keywords']}
• Microservices, container deployments (Docker/Kubernetes), and CI/CD pipelines
• Agile/Scrum cross-functional execution and engineering code governance

I have attached my concise 1-page resume for your review. Would you or a member of your team be open to a brief 10-minute introductory conversation this week?

Best regards,

Jordan Isaac
(609) 751-7311 | jisaac9519@gmail.com
LinkedIn: linkedin.com/in/jordan-isaac-1ab8a3405
GitHub: github.com/dragpk247
"""
    print(email_body)

    if args.recruiter:
        print("\n🤝 \033[1;32mStep 4: Recruiter / Agency Reply (e.g. for " + args.recruiter + ")\033[0m")
        print("-" * 70)
        rec_reply = f"""Subject: Re: {role_clean} - {company_clean} - Jordan Isaac Resume (.docx attached)

Hi {args.recruiter},

Thank you for reaching out regarding the {role_clean} opportunity with {company_clean}. I am very interested in this role and my background aligns closely with the team's technical requirements.

Key highlights from my experience:
• 3+ years engineering enterprise solutions utilizing {profile['keywords']}
• Track record of {profile['hook']}
• Available immediately for initial phone/video screens and technical interviews

I have attached my updated resume in Word (.docx) format from my {profile['folder']} portfolio. Please let me know the best time to connect for a brief call.

Best regards,

Jordan Isaac
(609) 751-7311 | jisaac9519@gmail.com
"""
        print(rec_reply)

    print("=" * 70)
    print(f"\033[1;33mTip:\033[0m Resume files ready in: ~/Documents/resumes/Jordan Isaac/{profile['folder']}/\n")

if __name__ == "__main__":
    main()
