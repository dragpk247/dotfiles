#!/usr/bin/env python3
"""
Omarchy Dotfiles Synchronization Engine
Scans current Omarchy shell plugins, shell.json, HexaCore layout manager,
and Omarchy shortcuts / keybindings / helper scripts, syncs them into the
dotfiles repository, and updates the manifests.
"""

import os
import sys
import re
import json
import shutil
import subprocess
from datetime import datetime
from pathlib import Path

DOTFILES_DIR = Path(__file__).resolve().parent.parent

# Sources
OMARCHY_PLUGINS_SRC = Path.home() / ".config" / "omarchy" / "plugins"
OMARCHY_SHELL_SRC = Path.home() / ".config" / "omarchy" / "shell.json"
OMARCHY_MENU_SRC = Path.home() / ".config" / "omarchy" / "extensions" / "omarchy-menu.jsonc"

HYPR_DIR_SRC = Path.home() / ".config" / "hypr"
LOCAL_BIN_SRC = Path.home() / ".local" / "bin"
HEXACORE_SRC_DIR = Path.home() / "Projects" / "omarchy-hexacore"
HEXACORE_BIN_SRC = LOCAL_BIN_SRC / "workflow-hexacore"

# Destinations
DEST_OMARCHY = DOTFILES_DIR / "omarchy"
DEST_PLUGINS = DEST_OMARCHY / "plugins"
DEST_CUSTOM_PLUGINS = DEST_PLUGINS / "custom"
DEST_EXTENSIONS = DEST_OMARCHY / "extensions"
DEST_HEXACORE = DOTFILES_DIR / "hexacore"
DEST_HYPR = DOTFILES_DIR / "hypr"
DEST_SHORTCUT_SCRIPTS = DOTFILES_DIR / "shortcuts" / "scripts"

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

def sync_shortcuts():
    print("==> Syncing Omarchy Shortcuts & Hyprland bindings...")
    DEST_HYPR.mkdir(parents=True, exist_ok=True)
    DEST_SHORTCUT_SCRIPTS.mkdir(parents=True, exist_ok=True)
    DEST_EXTENSIONS.mkdir(parents=True, exist_ok=True)

    # 1. Sync Hyprland shortcut files
    tracked_hypr_files = ["bindings.lua", "hyprland.lua", "autostart.lua"]
    for fname in tracked_hypr_files:
        src = HYPR_DIR_SRC / fname
        if src.exists():
            dest = DEST_HYPR / fname
            shutil.copy2(src, dest)
            print(f"    Synced Hyprland config: {fname}")

    # 2. Sync Omarchy Menu extensions
    if OMARCHY_MENU_SRC.exists():
        dest_menu = DEST_EXTENSIONS / "omarchy-menu.jsonc"
        shutil.copy2(OMARCHY_MENU_SRC, dest_menu)
        print("    Synced Omarchy menu shortcuts: omarchy-menu.jsonc")

    # 3. Detect and copy custom scripts referenced by shortcuts
    scripts_to_check = set()

    # Parse bindings.lua
    bindings_file = HYPR_DIR_SRC / "bindings.lua"
    if bindings_file.exists():
        text = bindings_file.read_text()
        # Find command strings in o.bind(...)
        matches = re.findall(r'o\.bind\([^,]+,[^,]+,\s*["\']([^"\']+)["\']', text)
        for cmd in matches:
            first_word = cmd.strip().split()[0]
            bin_name = Path(first_word).name
            scripts_to_check.add(bin_name)

    # Parse omarchy-menu.jsonc
    if OMARCHY_MENU_SRC.exists():
        text = OMARCHY_MENU_SRC.read_text()
        action_matches = re.findall(r'"action":\s*"([^"]+)"', text)
        for act in action_matches:
            first_word = act.strip().split()[0]
            bin_name = Path(first_word).name
            scripts_to_check.add(bin_name)

    copied_scripts = []
    for sname in sorted(scripts_to_check):
        src_script = LOCAL_BIN_SRC / sname
        # Only copy user scripts in ~/.local/bin (skip system binaries like omarchy, kitty, etc.)
        if src_script.exists() and not src_script.is_dir():
            dest_script = DEST_SHORTCUT_SCRIPTS / sname
            shutil.copy2(src_script, dest_script)
            dest_script.chmod(0o755)
            copied_scripts.append(sname)
            print(f"    [Shortcut Script] {sname} -> shortcuts/scripts/{sname}")

    print(f"    Synced {len(copied_scripts)} shortcut helper scripts.")

def sync_plugins():
    print("==> Syncing Omarchy plugins...")
    DEST_CUSTOM_PLUGINS.mkdir(parents=True, exist_ok=True)

    upstream_plugins = []
    custom_plugins = []

    if not OMARCHY_PLUGINS_SRC.exists():
        print(f"    Warning: Plugins directory {OMARCHY_PLUGINS_SRC} does not exist.")
        return

    entries = sorted(OMARCHY_PLUGINS_SRC.iterdir())
    for entry in entries:
        if not entry.is_dir():
            continue
        name = entry.name
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

        dest_plugin_dir = DEST_CUSTOM_PLUGINS / name
        if dest_plugin_dir.exists():
            shutil.rmtree(dest_plugin_dir)
        
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
        },
        "shortcuts": {
            "bindings_file": "hypr/bindings.lua",
            "menu_extensions": "omarchy/extensions/omarchy-menu.jsonc",
            "scripts_dir": "shortcuts/scripts"
        }
    }

    manifest_dest = DEST_PLUGINS / "plugins.json"
    with open(manifest_dest, "w") as f:
        json.dump(manifest_output, f, indent=2)
    print(f"    Saved registry to {manifest_dest}")

def git_commit(custom_message=None):
    print("==> Checking git status in dotfiles repository...")
    status = run_cmd(["git", "status", "--porcelain"], cwd=DOTFILES_DIR).stdout.strip()
    if not status:
        print("    Dotfiles repository is already up to date. No changes to commit.")
        return False

    print("    Staging changes...")
    run_cmd(["git", "add", "."], cwd=DOTFILES_DIR)

    msg = custom_message or f"chore(dotfiles): sync plugins, shortcuts, shell.json, and hexacore [{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}]"
    print(f"    Committing: '{msg}'...")
    run_cmd(["git", "commit", "-m", msg], cwd=DOTFILES_DIR)
    print("    Commit successful!")
    return True

def main():
    import argparse
    parser = argparse.ArgumentParser(description="Sync Omarchy plugins, shortcuts, and HexaCore to dotfiles.")
    parser.add_argument("-m", "--message", help="Custom commit message")
    parser.add_argument("--no-commit", action="store_true", help="Do not commit changes to git")
    parser.add_argument("--push", action="store_true", help="Push to git remote after committing")
    args = parser.parse_args()

    sync_omarchy_shell()
    sync_shortcuts()
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
