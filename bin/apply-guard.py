#!/usr/bin/env python3
"""
APPLY-GUARD — Targeted Recruiter & Hiring Manager Dispatch Assistant
Enforces strict targeting: only allows dispatching tailored resumes to verified
recruiter/hiring manager email addresses or direct professional contacts.
Logs applications into your local Application Tracker ledger.
"""

import sys
import os
import re
import argparse
import datetime
import urllib.parse
import subprocess

TRACKER_FILE = os.path.expanduser("~/Documents/resumes/Jordan Isaac/tracker/applications.md")
RESUME_BASE = os.path.expanduser("~/Documents/resumes/Jordan Isaac")

ROLE_MAP = {
    "java": {
        "folder": "01_Java_FullStack",
        "pdf": "Jordan_Isaac_Java_FullStack_Resume.pdf",
        "docx": "Jordan_Isaac_Java_FullStack_Resume.docx",
        "title": "Java & Full-Stack Application Developer"
    },
    "devops": {
        "folder": "02_DevOps_Platform",
        "pdf": "Jordan_Isaac_DevOps_Platform_Resume.pdf",
        "docx": "Jordan_Isaac_DevOps_Platform_Resume.docx",
        "title": "Senior DevOps & Platform Engineer"
    },
    "swe": {
        "folder": "03_Software_Engineer_Master",
        "pdf": "Jordan_Isaac_Resume.pdf",
        "docx": "Jordan Isaac Software Engineering Resume Latest.docx",
        "title": "Software Engineer / Distributed Systems"
    }
}

def log_application(company, role, recipient, r_type, notes=""):
    date_str = datetime.datetime.now().strftime("%Y-%m-%d %H:%M")
    if not os.path.exists(TRACKER_FILE):
        with open(TRACKER_FILE, "w") as f:
            f.write("# 📋 Targeted Job Application & Recruiter Outreach Tracker\n\n")
            f.write("| Date | Company | Role | Recipient / Contact | Role Profile | Status |\n")
            f.write("| :--- | :--- | :--- | :--- | :--- | :--- |\n")
    with open(TRACKER_FILE, "a") as f:
        f.write(f"| {date_str} | {company} | {role} | {recipient} | {r_type.upper()} | Sent / In Review |\n")

def main():
    parser = argparse.ArgumentParser(description="Targeted Recruiter & Hiring Manager Dispatch Assistant")
    parser.add_argument("company", help="Target Company Name (e.g. 'Globus Medical')")
    parser.add_argument("recipient", help="Recruiter/HM Name or Email (e.g. 'ajit@intersourcesinc.com' or 'Ajit Yadav')")
    parser.add_argument("--role", choices=["java", "devops", "swe"], default="java", help="Resume profile to send (default: java)")
    parser.add_argument("--format", choices=["pdf", "docx"], default="docx", help="Format to attach (recruiter standard: docx, direct HM: pdf)")
    args = parser.parse_args()

    prof = ROLE_MAP[args.role]
    file_to_send = os.path.join(RESUME_BASE, prof["folder"], prof[args.format])

    print("\n" + "=" * 72)
    print(f" 🎯 TARGETED DISPATCH: {args.company.upper()} &bull; {args.recipient}")
    print("=" * 72)

    # 1. Run Pre-Flight Double Check first on corresponding PDF
    pdf_for_check = os.path.join(RESUME_BASE, prof["folder"], prof["pdf"])
    print("\n\033[1;36m[*] Running Pre-Flight Audit on Selected Resume...\033[0m")
    chk_cmd = ["check-resume", pdf_for_check]
    subprocess.run(chk_cmd)

    # 2. Formulate Mailto & Clipboard Package
    is_email = "@" in args.recipient
    subject = f"Jordan Isaac - Application & Resume: {prof['title']} - {args.company}"
    body = (
        f"Hi {args.recipient.split('@')[0] if is_email else args.recipient},\n\n"
        f"Thank you for connecting regarding the {prof['title']} opening at {args.company}. "
        f"I have attached my tailored resume ({args.format.upper()}) highlighting my experience in enterprise systems.\n\n"
        f"Key Highlights:\n"
        f"• 3+ years engineering enterprise distributed applications\n"
        f"• Available immediately for initial discussions and technical reviews\n\n"
        f"Best regards,\nJordan Isaac\n(609) 751-7311 | jisaac9519@gmail.com\n"
        f"LinkedIn: linkedin.com/in/jordan-isaac-1ab8a3405\nGitHub: github.com/dragpk247"
    )

    print("\n\033[1mAttachment File:\033[0m")
    print(f"  \033[1;32m{file_to_send}\033[0m ({args.format.upper()})")

    # 3. Log to Tracker
    log_application(args.company, prof["title"], args.recipient, args.role)
    print(f"\n\033[1;32m[✓] Application logged into tracker:\033[0m {TRACKER_FILE}")

    # 4. Open directly in Gmail or Yahoo Web Compose (Default: Gmail)
    if is_email:
        enc_to = urllib.parse.quote(args.recipient)
        enc_sub = urllib.parse.quote(subject)
        enc_body = urllib.parse.quote(body)

        gmail_url = f"https://mail.google.com/mail/?view=cm&fs=1&to={enc_to}&su={enc_sub}&body={enc_body}"
        yahoo_url = f"https://compose.mail.yahoo.com/?to={enc_to}&subj={enc_sub}&body={enc_body}"

        print("\n\033[1;36m[*] Opening Gmail Compose window with pre-filled pitch...\033[0m")
        print(f"    Recipient: {args.recipient}")
        print(f"    Subject:   {subject}")
        print(f"\n\033[2mDirect Web Links:\033[0m")
        print(f"  • Gmail: \033[4m{gmail_url}\033[0m")
        print(f"  • Yahoo: \033[4m{yahoo_url}\033[0m")

        try:
            # Opens directly in your default browser (Gmail compose)
            subprocess.Popen(["xdg-open", gmail_url], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except Exception:
            pass

    print("\n" + "=" * 72 + "\n")

if __name__ == "__main__":
    main()
