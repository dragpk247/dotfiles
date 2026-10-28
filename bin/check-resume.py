#!/usr/bin/env python3
"""
CHECK-RESUME — Automated Pre-Flight ATS & Quality Auditor
Validates that a resume satisfies all strict ATS and human-reading requirements
before you send it to a recruiter or hiring manager.
"""

import sys
import os
import re
import argparse
import subprocess

REQUIRED_SECTIONS = [
    r"technical summary|professional summary|summary",
    r"technical skills|skills",
    r"professional experience|experience|work history",
    r"education",
]

CONTACT_FIELDS = [
    (r"jisaac9519@gmail\.com", "Email Address (jisaac9519@gmail.com)"),
    (r"\(?609\)?\s*[-.]?751[-.]?7311", "Phone Number ((609) 751-7311)"),
    (r"linkedin\.com/in/jordan-isaac", "LinkedIn URL"),
    (r"github\.com/dragpk247", "GitHub Profile URL"),
]

def check_resume(file_path, target_role=""):
    print("\n" + "=" * 70)
    print(f" 🛡️  OMNI RESUME PRE-FLIGHT CHECK: {os.path.basename(file_path)}")
    print("=" * 70)

    if not os.path.exists(file_path):
        print(f"\033[1;31m[FAIL] File not found: {file_path}\033[0m")
        return False

    ext = os.path.splitext(file_path)[1].lower()
    text = ""
    is_pdf = False

    # 1. Text extraction
    if ext == ".pdf":
        is_pdf = True
        try:
            res = subprocess.run(["pdftotext", file_path, "-"], capture_output=True, text=True)
            text = res.stdout
        except Exception as e:
            print(f"\033[1;31m[FAIL] Could not extract text from PDF: {e}\033[0m")
            return False
    elif ext in [".html", ".htm", ".md"]:
        with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
            text = f.read()
    else:
        print(f"\033[1;33m[!] Unsupported file type for direct audit: {ext}. (Supported: .pdf, .html, .md)\033[0m")
        return False

    passed = True
    warnings = 0

    # 2. Check 1-Page Constraint (if PDF)
    if is_pdf:
        try:
            res = subprocess.run(["pdfinfo", file_path], capture_output=True, text=True)
            page_match = re.search(r"Pages:\s+(\d+)", res.stdout)
            if page_match:
                pages = int(page_match.group(1))
                if pages == 1:
                    print("  \033[1;32m[PASS]\033[0m Page Count: Exactly 1 page (Optimal ATS & recruiter length).")
                else:
                    print(f"  \033[1;31m[FAIL]\033[0m Page Count: {pages} pages! (Must be strictly 1 page).")
                    passed = False
        except Exception:
            pass

    # 3. Check Contact Information
    print("\n  \033[1mContact Verification:\033[0m")
    for pattern, label in CONTACT_FIELDS:
        if re.search(pattern, text, re.IGNORECASE):
            print(f"    \033[1;32m[PASS]\033[0m {label} verified.")
        else:
            print(f"    \033[1;31m[FAIL]\033[0m Missing {label}!")
            passed = False

    # 4. Check ATS Core Sections
    print("\n  \033[1mCore Section Verification:\033[0m")
    for sec_pattern in REQUIRED_SECTIONS:
        if re.search(sec_pattern, text, re.IGNORECASE):
            sec_name = sec_pattern.split("|")[0].title()
            print(f"    \033[1;32m[PASS]\033[0m Found section '{sec_name}'.")
        else:
            sec_name = sec_pattern.split("|")[0].title()
            print(f"    \033[1;31m[FAIL]\033[0m Missing standard section '{sec_name}'!")
            passed = False

    # 5. Check Quantitative Metrics (Numbers, percentages, dollar signs)
    print("\n  \033[1mImpact & Metric Audit (STAR Method):\033[0m")
    metrics = re.findall(r"(\d+%\s*|\d+x\s*|\$\d+|\b\d+\s*min|\b\d+\s*hours|\b\d{2,}\b)", text)
    if len(metrics) >= 5:
        print(f"    \033[1;32m[PASS]\033[0m Found {len(metrics)} quantitative data points (e.g. 28%, 15 minutes, 100,000+).")
    else:
        print(f"    \033[1;33m[WARN]\033[0m Only found {len(metrics)} metrics. Strong resumes have 6+ quantified achievements.")
        warnings += 1

    # 6. Check for Broken Template Placeholders
    print("\n  \033[1mCleanliness & Placeholder Audit:\033[0m")
    placeholders = re.findall(r"(\{\{[A-Za-z0-9_]+\}\}|\[Name\]|\[Company\]|TODO|FIXME)", text)
    if placeholders:
        print(f"    \033[1;31m[FAIL]\033[0m Unfilled placeholder tags detected: {set(placeholders)}!")
        passed = False
    else:
        print("    \033[1;32m[PASS]\033[0m Zero placeholder tags or un-rendered tokens found.")

    # 7. Target Role Keyword Matching (if specified)
    if target_role:
        print(f"\n  \033[1mTarget Keyword Alignment ({target_role}):\033[0m")
        keywords = [k.strip() for k in target_role.replace(",", " ").split() if len(k) > 2]
        matched = [k for k in keywords if re.search(r"\b" + re.escape(k) + r"\b", text, re.IGNORECASE)]
        pct = (len(matched) / len(keywords)) * 100 if keywords else 100
        print(f"    Keyword Match Rate: {pct:.1f}% ({len(matched)}/{len(keywords)} terms found)")
        if pct < 70:
            missing = set(keywords) - set(matched)
            print(f"    \033[1;33m[WARN]\033[0m Missing key terms: {missing}")
            warnings += 1

    # 8. Final Verdict
    print("\n" + "-" * 70)
    if passed and warnings == 0:
        print("  \033[1;32m🚀 VERDICT: READY TO SEND! (100% Pre-Flight Audit Passed)\033[0m")
    elif passed:
        print("  \033[1;33m⚠️  VERDICT: READY WITH WARNINGS (Minor optimizations suggested)\033[0m")
    else:
        print("  \033[1;31m⛔ VERDICT: DO NOT SEND! Resolve the failing checks above first.\033[0m")
    print("=" * 70 + "\n")
    return passed

def main():
    parser = argparse.ArgumentParser(description="Pre-flight double-checker for resumes before sending to recruiters")
    parser.add_argument("path", help="Path to resume (.pdf, .html, or .md)")
    parser.add_argument("--role", default="", help="Optional target role or keywords to test against")
    args = parser.parse_args()

    check_resume(args.path, args.role)

if __name__ == "__main__":
    main()
