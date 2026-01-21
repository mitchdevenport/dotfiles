# GitHub Codespaces Dotfiles

This repository contains dotfiles and startup scripts for GitHub Codespaces development environments.

## Files

### [codespaces-startup.sh](codespaces-startup.sh)
Main startup script that runs automatically when a Codespace is created. This script:

1. Configures multiple GitHub repositories with specific branches
2. Sets up VSCode workspace with all required folders
3. Configures environment variables and shell aliases
4. Creates individual terminal scripts for each service
5. Provides a tmux-based service orchestration setup

### [setup.sh](setup.sh)
General setup script that installs development tools:
- Configures git with auto-setup for remote branches
- Installs Claude Code CLI
- Installs OpenAI Codex CLI

## Usage in GitHub Codespaces

When you create a new Codespace with this dotfiles repository:

1. GitHub automatically clones this repository to `~/dotfiles`
2. You manually run the setup script when ready: `~/dotfiles/codespaces-startup.sh`
3. The script sets up all repositories and services

### Starting Services

After running the setup script, start all services using:

```bash
/tmp/start-services.sh
tmux attach -t codespaces
```

This creates a tmux session with multiple windows:
- **github-ui**: Main GitHub UI server
- **copilot-api**: Copilot API server (with sweagentd and copilot-mission-control in split panes)
- **workspace**: General workspace terminal

### Manual Service Start

If you prefer to run services in separate terminals:

```bash
/tmp/terminal1.sh  # github-ui server
/tmp/terminal2.sh  # copilot-api server
/tmp/terminal3.sh  # sweagentd server
/tmp/terminal4.sh  # copilot-mission-control server
/tmp/terminal5.sh  # workspace terminal
```

## What Gets Configured

### Repositories
- **github-ui** → branch: `jasonrclark/intent-detection`
- **copilot-api** → branch: `jasonrclark/stream-chat-to-session-logs`
- **sweagentd** → default branch
- **copilot-mission-control** → branch: `mitchdevenport/intent-detection-poc`

### Environment Variables
```bash
export USER_TOKEN=$MONALISA_PAT
export SESSIONS_API_BASE_URL=http://localhost:2210/api/v1/agents
alias s='script/sessions-api --localhost 2210'
```

### Feature Flags
The script automatically enables these feature flags:
- `copilot_mission_control_service_proxy`
- `copilot_agent_task_api`
- `repo_agents_view`
- `copilot_mission_control_link_to_sessions_in_repo`
- `coding_agent_pull_request_toggle`
- `copilot_swe_agent_ai_name_generation`
- `mission_control_use_tool_header_icons`
- `copilot_intent_detection`
- `copilot_swe_agent_skip_agent_job_concurrency_limit`

### copilot-mission-control Configuration
Adds timeout configuration to `.env/.env.local.rest`:
```
READ_TIMEOUT=9998s
REQUEST_TIMEOUT=9997s
SHUTDOWN_TIMEOUT=9999s
WRITE_TIMEOUT=9998s
```

## Tmux Navigation

When using the tmux session:
- `Ctrl+b` then `n` - Next window
- `Ctrl+b` then `p` - Previous window
- `Ctrl+b` then `w` - List all windows
- `Ctrl+b` then arrow keys - Navigate between split panes
- `Ctrl+b` then `d` - Detach from session (services keep running)
- `tmux attach -t codespaces` - Re-attach to session

## Troubleshooting

### View Setup Logs
```bash
cat /tmp/codespaces-startup.log
```

### View Setup Instructions
```bash
cat /tmp/CODESPACES_SETUP_README.md
```

### Restart a Service
If a service crashes, you can restart it by finding the appropriate tmux pane and re-running the terminal script:
```bash
tmux attach -t codespaces
# Navigate to the window/pane
# Press Ctrl+C to stop the service
# Re-run the terminal script (e.g., /tmp/terminal1.sh)
```

## Running the Setup

To set up your Codespace environment:

```bash
~/dotfiles/codespaces-startup.sh
```

This script is idempotent and can be re-run safely if needed.

## Customization

To modify the startup behavior:
1. Edit [codespaces-startup.sh](codespaces-startup.sh)
2. Commit and push changes to this repository
3. Pull the latest changes in your Codespace: `cd ~/dotfiles && git pull`
4. Re-run the setup script: `~/dotfiles/codespaces-startup.sh`