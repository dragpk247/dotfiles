#!/usr/bin/env python3
"""
Omarchy Dotfiles Synchronization Engine
Scans current Omarchy shell plugins, shell.json, and HexaCore layout manager,
syncs them into the dotfiles repository, and updates the plugins manifest.
"""

import os
import sys
import json
import shutil
import subprocess
from datetime import datetime
from pathlib import Path

DOTFILES_DIR = Path(__file__).resolve().parent.parent
OMARCHY_PLUGINS_SRC = Path.home() / ".config" / "omarchy" / "plugins"
OMARCHY_SHELL_SRC = Path.home() / ".config" / "omarchy" / "shell.json"
HEXACORE_SRC_DIR = Path.home() / "Projects" / "omarchy-hexacore"
HEXACORE_BIN_SRC = Path.home() / ".local" / "bin" / "workflow-hexacore"

DEST_OMARCHY = DOTFILES_DIR / "omarchy"
DEST_PLUGINS = DEST_OMARCHY / "plugins"
DEST_CUSTOM_PLUGINS = DEST_PLUGINS / "custom"
DEST_HEXACORE = DOTFILES_DIR / "hexacore"

def run_cmd(cmd, cwd=None, check=True):
    res = subprocess.run(cmd, cwd=cwd, shell=isinstance(cmd, str), capture_output=True, text=True)
    if check and res.returncode != 0:
        raise RuntimeError(f"Command failed ({res.returncode}): {cmd}\nStderr: {res.stderr}")
    return res

def sync_omarchy_shell():
    print("==> Syncing Omarchy shell configuration...")
    DEST_OMARCHY.mkdir(parents=True, exist_ok=True)
    if OMARCHY_SHELL_SRC.exists():
        dest = DEST_OMARCHY / "shell.json"
        shutil.copy2(OMARCHY_SHELL_SRC, dest)
        print(f"    Synced {OMARCHY_SHELL_SRC} -> {dest}")
    else:
        print(f"    Warning: {OMARCHY_SHELL_SRC} not found.")

def sync_hexacore():
    print("==> Syncing HexaCore Workstation...")
    DEST_HEXACORE.mkdir(parents=True, exist_ok=True)
    dest_bin = DEST_HEXACORE / "bin"
    dest_hypr = DEST_HEXACORE / "hyprland"
    dest_bin.mkdir(parents=True, exist_ok=True)
    dest_hypr.mkdir(parents=True, exist_ok=True)

    if HEXACORE_SRC_DIR.exists():
        # Sync from Projects/omarchy-hexacore
        for file_name in ["install.sh", "README.md", "LICENSE"]:
            src = HEXACORE_SRC_DIR / file_name
            if src.exists():
                shutil.copy2(src, DEST_HEXACORE / file_name)

        src_wf = HEXACORE_SRC_DIR / "bin" / "workflow-hexacore"
        if src_wf.exists():
            shutil.copy2(src_wf, dest_bin / "workflow-hexacore")
            (dest_bin / "workflow-hexacore").chmod(0o755)

        src_bindings = HEXACORE_SRC_DIR / "hyprland" / "bindings.lua"
        if src_bindings.exists():
            shutil.copy2(src_bindings, dest_hypr / "bindings.lua")
        print(f"    Synced HexaCore from {HEXACORE_SRC_DIR}")
    elif HEXACORE_BIN_SRC.exists():
        shutil.copy2(HEXACORE_BIN_SRC, dest_bin / "workflow-hexacore")
        (dest_bin / "workflow-hexacore").chmod(0o755)
        print(f"    Synced HexaCore binary from {HEXACORE_BIN_SRC}")
    else:
        print("    Warning: HexaCore source not found.")

def sync_plugins():
    print("==> Syncing Omarchy plugins...")
    DEST_CUSTOM_PLUGINS.mkdir(parents=True, exist_ok=True)

    upstream_plugins = []
    custom_plugins = []

    if not OMARCHY_PLUGINS_SRC.exists():
        print(f"    Warning: Plugins directory {OMARCHY_PLUGINS_SRC} does not exist.")
        return

    # List plugin directories
    entries = sorted(OMARCHY_PLUGINS_SRC.iterdir())
    for entry in entries:
        if not entry.is_dir():
            continue
        name = entry.name
        # Skip backup and hidden directories
        if name.startswith(".") or ".bak" in name:
            continue

        manifest_file = entry / "manifest.json"
        manifest_data = {}
        if manifest_file.exists():
            try:
                manifest_data = json.loads(manifest_file.read_text())
            except Exception:
                pass

        git_dir = entry / ".git"
        if git_dir.exists() and git_dir.is_dir():
            # Upstream git repo
            git_url_proc = run_cmd(["git", "-C", str(entry), "config", "--get", "remote.origin.url"], check=False)
            git_url = git_url_proc.stdout.strip()
            if git_url:
                commit_proc = run_cmd(["git", "-C", str(entry), "rev-parse", "HEAD"], check=False)
                commit_hash = commit_proc.stdout.strip()
                branch_proc = run_cmd(["git", "-C", str(entry), "branch", "--show-current"], check=False)
                branch = branch_proc.stdout.strip() or "main"

                plugin_info = {
                    "id": name,
                    "name": manifest_data.get("name", name),
                    "description": manifest_data.get("description", ""),
                    "version": manifest_data.get("version", ""),
                    "repo_url": git_url,
                    "commit": commit_hash,
                    "branch": branch,
                    "kinds": manifest_data.get("kinds", [])
                }
                upstream_plugins.append(plugin_info)
                print(f"    [Upstream] {name} ({git_url})")
                continue

        # Custom / local plugin
        dest_plugin_dir = DEST_CUSTOM_PLUGINS / name
        if dest_plugin_dir.exists():
            shutil.rmtree(dest_plugin_dir)
        
        # Copy plugin files, excluding any stray .git
        shutil.copytree(
            entry, 
            dest_plugin_dir, 
            ignore=shutil.ignore_patterns(".git", "*.bak*", "*~")
        )

        plugin_info = {
            "id": name,
            "name": manifest_data.get("name", name),
            "description": manifest_data.get("description", ""),
            "version": manifest_data.get("version", ""),
            "kinds": manifest_data.get("kinds", []),
            "path": f"omarchy/plugins/custom/{name}"
        }
        custom_plugins.append(plugin_info)
        print(f"    [Custom]   {name} -> {dest_plugin_dir}")

    # Remove deleted custom plugins from dotfiles that are no longer in ~/.config/omarchy/plugins
    active_custom_ids = {p["id"] for p in custom_plugins}
    for existing in DEST_CUSTOM_PLUGINS.iterdir():
        if existing.is_dir() and existing.name not in active_custom_ids:
            print(f"    [Removed] Pruning old custom plugin: {existing.name}")
            shutil.rmtree(existing)

    manifest_output = {
        "version": 1,
        "updated_at": datetime.now().isoformat(),
        "total_plugins": len(upstream_plugins) + len(custom_plugins),
        "upstream_count": len(upstream_plugins),
        "custom_count": len(custom_plugins),
        "upstream_plugins": upstream_plugins,
        "custom_plugins": custom_plugins,
        "hexacore": {
            "installed": True,
            "entrypoint": "bin/workflow-hexacore",
            "keybinding": "SUPER ALT, H"
        }
    }

    manifest_dest = DEST_PLUGINS / "plugins.json"
    with open(manifest_dest, "w") as f:
        json.dump(manifest_output, f, indent=2)
    print(f"    Saved plugin registry to {manifest_dest}")

def git_commit(custom_message=None):
    print("==> Checking git status in dotfiles repository...")
    status = run_cmd(["git", "status", "--porcelain"], cwd=DOTFILES_DIR).stdout.strip()
    if not status:
        print("    Dotfiles repository is already up to date. No changes to commit.")
        return False

    print("    Staging changes...")
    run_cmd(["git", "add", "."], cwd=DOTFILES_DIR)

    msg = custom_message or f"chore(dotfiles): sync omarchy plugins, shell.json, and hexacore [{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}]"
    print(f"    Committing: '{msg}'...")
    run_cmd(["git", "commit", "-m", msg], cwd=DOTFILES_DIR)
    print("    Commit successful!")
    return True

def main():
    import argparse
    parser = argparse.ArgumentParser(description="Sync Omarchy plugins and HexaCore to dotfiles.")
    parser.add_argument("-m", "--message", help="Custom commit message")
    parser.add_argument("--no-commit", action="store_true", help="Do not commit changes to git")
    parser.add_argument("--push", action="store_true", help="Push to git remote after committing")
    args = parser.parse_args()

    sync_omarchy_shell()
    sync_hexacore()
    sync_plugins()

    if not args.no_commit:
        committed = git_commit(args.message)
        if committed and args.push:
            print("==> Pushing to remote...")
            run_cmd(["git", "push"], cwd=DOTFILES_DIR, check=False)

    print("\n✓ Synchronization complete!")

if __name__ == "__main__":
    main()
