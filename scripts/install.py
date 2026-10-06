#!/usr/bin/env python3
"""
Omarchy Dotfiles Installer / Restorer
Restores all Omarchy shell plugins, shell.json, and HexaCore workstation.
"""

import os
import sys
import json
import shutil
import subprocess
from datetime import datetime
from pathlib import Path

DOTFILES_DIR = Path(__file__).resolve().parent.parent
OMARCHY_PLUGINS_DEST = Path.home() / ".config" / "omarchy" / "plugins"
OMARCHY_SHELL_DEST = Path.home() / ".config" / "omarchy" / "shell.json"
BIN_DEST = Path.home() / ".local" / "bin"
HYPR_BINDINGS = Path.home() / ".config" / "hypr" / "bindings.lua"

MANIFEST_PATH = DOTFILES_DIR / "omarchy" / "plugins" / "plugins.json"
CUSTOM_PLUGINS_SRC = DOTFILES_DIR / "omarchy" / "plugins" / "custom"
HEXACORE_SRC = DOTFILES_DIR / "hexacore"

def run_cmd(cmd, cwd=None, check=True):
    res = subprocess.run(cmd, cwd=cwd, shell=isinstance(cmd, str), capture_output=True, text=True)
    if check and res.returncode != 0:
        raise RuntimeError(f"Command failed ({res.returncode}): {cmd}\nStderr: {res.stderr}")
    return res

def install_plugins():
    print("==> Installing Omarchy plugins...")
    OMARCHY_PLUGINS_DEST.mkdir(parents=True, exist_ok=True)

    if not MANIFEST_PATH.exists():
        print(f"    Error: Manifest file {MANIFEST_PATH} not found.")
        return

    with open(MANIFEST_PATH, "r") as f:
        data = json.load(f)

    # 1. Install upstream plugins
    upstream_list = data.get("upstream_plugins", [])
    print(f"    Found {len(upstream_list)} upstream plugins to install/update.")
    for plugin in upstream_list:
        pid = plugin["id"]
        url = plugin["repo_url"]
        target = OMARCHY_PLUGINS_DEST / pid

        if target.exists() and (target / ".git").exists():
            print(f"    [Updating] {pid}...")
            run_cmd(["git", "-C", str(target), "pull", "--rebase"], check=False)
        else:
            if target.exists():
                shutil.rmtree(target)
            print(f"    [Cloning]  {pid} from {url}...")
            run_cmd(["git", "clone", url, str(target)], check=False)

    # 2. Install custom plugins
    custom_list = data.get("custom_plugins", [])
    print(f"    Found {len(custom_list)} custom plugins to restore.")
    for plugin in custom_list:
        pid = plugin["id"]
        src = CUSTOM_PLUGINS_SRC / pid
        target = OMARCHY_PLUGINS_DEST / pid

        if not src.exists():
            print(f"    Warning: Custom plugin source not found for {pid} at {src}")
            continue

        if target.exists():
            shutil.rmtree(target)
        shutil.copytree(src, target)
        print(f"    [Installed] {pid} -> {target}")

def install_shell_config():
    print("==> Restoring Omarchy shell configuration...")
    src_shell = DOTFILES_DIR / "omarchy" / "shell.json"
    if src_shell.exists():
        if OMARCHY_SHELL_DEST.exists():
            backup_path = OMARCHY_SHELL_DEST.with_suffix(f".json.bak.{int(datetime.now().timestamp())}")
            shutil.copy2(OMARCHY_SHELL_DEST, backup_path)
            print(f"    Backed up existing shell.json to {backup_path.name}")
        shutil.copy2(src_shell, OMARCHY_SHELL_DEST)
        print(f"    Restored {OMARCHY_SHELL_DEST}")
    else:
        print("    Warning: omarchy/shell.json not found in dotfiles.")

def install_hexacore():
    print("==> Installing HexaCore Workstation...")
    BIN_DEST.mkdir(parents=True, exist_ok=True)
    src_wf = HEXACORE_SRC / "bin" / "workflow-hexacore"
    if src_wf.exists():
        target_wf = BIN_DEST / "workflow-hexacore"
        target_alias = BIN_DEST / "hexacore"
        shutil.copy2(src_wf, target_wf)
        target_wf.chmod(0o755)
        if target_alias.exists() or target_alias.is_symlink():
            target_alias.unlink()
        target_alias.symlink_to(target_wf)
        print(f"    Installed {target_wf} and alias {target_alias}")

    # Check keybinding
    if HYPR_BINDINGS.exists():
        content = HYPR_BINDINGS.read_text()
        if "workflow-hexacore" not in content:
            print("    Adding HexaCore keybinding to bindings.lua...")
            with open(HYPR_BINDINGS, "a") as f:
                f.write('\n-- HexaCore 6-workspace environment trigger\no.bind("SUPER + ALT + H", "Launch HexaCore 6-Workspace Workflow", "workflow-hexacore")\n')
            if shutil.which("hyprctl"):
                run_cmd(["hyprctl", "reload"], check=False)
        else:
            print("    HexaCore keybinding already present in bindings.lua.")

def install_cli():
    print("==> Setting up omarchy-dotfiles CLI...")
    cli_src = DOTFILES_DIR / "bin" / "omarchy-dotfiles"
    cli_dest = BIN_DEST / "omarchy-dotfiles"
    if cli_src.exists():
        cli_src.chmod(0o755)
        if cli_dest.exists() or cli_dest.is_symlink():
            cli_dest.unlink()
        cli_dest.symlink_to(cli_src)
        print(f"    Linked {cli_dest} -> {cli_src}")

def main():
    install_plugins()
    install_shell_config()
    install_hexacore()
    install_cli()
    print("\n✓ All components installed successfully!")

if __name__ == "__main__":
    main()
