-- Extra autostart processes.
-- o.launch_on_start("my-service")

-- Ensure menu IPC state is cleanly initialized and synchronized on session startup
o.exec_on_start("omarchy-menu close")

-- Auto-connect and verify AI services (Tailscale Desktop GPU / local Ollama)
o.exec_on_start("ai-startup-check")

