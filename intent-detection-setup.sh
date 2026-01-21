#!/usr/bin/env bash

set -e

LOG_FILE="/tmp/intent-detection-setup.log"
echo "Starting Intent Detection setup..." | tee -a "$LOG_FILE"

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to checkout and pull a branch
checkout_and_pull() {
    local repo_path=$1
    local branch=$2
    log "Checking out and pulling $branch in $repo_path..."
    cd "$repo_path"
    git fetch origin
    git checkout "$branch"
    git pull origin "$branch"
    cd - > /dev/null
}

# Add global environment variables to shell profile FIRST
# This needs to be done early so subsequent commands can use these variables
log "Adding global environment variables..."
if ! grep -q "Copilot Mission Control Environment" "$HOME/.bashrc" 2>/dev/null; then
    cat >> "$HOME/.bashrc" << 'EOF'

# Copilot Mission Control Environment
export USER_TOKEN=$MONALISA_PAT
export SESSIONS_API_BASE_URL=http://localhost:2210/api/v1/agents
alias s='script/sessions-api --localhost 2210'
EOF
fi

# Source the updated bashrc for current session
export USER_TOKEN=$MONALISA_PAT
export SESSIONS_API_BASE_URL=http://localhost:2210/api/v1/agents

# Checkout and pull jasonrclark/intent-detection in github-ui (if it exists)
if [ -d "/workspaces/github-ui" ]; then
    log "Setting up github-ui repository..."
    checkout_and_pull "/workspaces/github-ui" "jasonrclark/intent-detection"
else
    log "Skipping github-ui setup - directory doesn't exist yet"
fi

# Run the setup script that creates the other repositories
log "Running setup-codespaces-copilot-swe-agent-v2 --capi..."
log "This will clone copilot-api, sweagentd, and copilot-mission-control repositories..."
cd /workspaces/github
script/setup-codespaces-copilot-swe-agent-v2 --capi

# Now that repositories exist, checkout the required branches
log "Setting up copilot-api repository..."
checkout_and_pull "/workspaces/copilot-api" "jasonrclark/stream-chat-to-session-logs"

log "Setting up copilot-mission-control repository..."
checkout_and_pull "/workspaces/copilot-mission-control" "mitchdevenport/intent-detection-poc"

# Now checkout github-ui if we skipped it earlier
if [ ! -d "/workspaces/github-ui/.git" ]; then
    log "Setting up github-ui repository (second attempt)..."
    checkout_and_pull "/workspaces/github-ui" "jasonrclark/intent-detection"
fi

# Check if we're in phase 2 (after workspace reload)
PHASE2_MARKER="/tmp/intent-detection-setup-phase2"

if [ -f "$PHASE2_MARKER" ]; then
    log "Phase 2: Continuing after workspace reload..."
    rm "$PHASE2_MARKER"
else
    log "Phase 1: Adding folders to VSCode workspace..."
    log "Note: VSCode will reload after adding folders"

    # Create a script that will auto-run after reload
    cat > /tmp/auto-rerun-setup.sh << 'EOF'
#!/usr/bin/env bash
sleep 3

# Open a new terminal and run phase 2 there so output is visible
code --command "workbench.action.terminal.new"
sleep 2
code --command "workbench.action.terminal.sendSequence" --args '{"text":"/workspaces/.codespaces/.persistedshare/dotfiles/intent-detection-setup.sh\n"}'
EOF
    chmod +x /tmp/auto-rerun-setup.sh

    # Add the auto-rerun to bashrc temporarily (will run in background)
    echo "/tmp/auto-rerun-setup.sh &" >> "$HOME/.bashrc"

    # Mark that we're ready for phase 2
    touch "$PHASE2_MARKER"

    # Add all folders (this will cause reload)
    log "Adding workspace folders (will trigger reload)..."
    code --add /workspaces/github-ui
    code --add /workspaces/copilot-api
    code --add /workspaces/sweagentd
    code --add /workspaces/copilot-mission-control

    echo ""
    echo "=========================================="
    echo "Phase 1 Complete"
    echo "=========================================="
    echo ""
    echo "VSCode is reloading with new workspace folders..."
    echo "The script will automatically continue after reload."
    echo ""

    exit 0
fi

# Clean up the auto-rerun from bashrc
sed -i '/auto-rerun-setup.sh/d' "$HOME/.bashrc" 2>/dev/null || true

# Enable feature flags now (setup script already ran above)
log "Enabling feature flags..."
cd /workspaces/github
fm feature enable --create -n copilot_mission_control_service_proxy
fm feature enable --create -n copilot_agent_task_api
fm feature enable --create -n repo_agents_view
fm feature enable --create -n copilot_mission_control_link_to_sessions_in_repo
fm feature enable --create -n coding_agent_pull_request_toggle
fm feature enable --create -n copilot_swe_agent_ai_name_generation
fm feature enable --create -n mission_control_use_tool_header_icons
fm feature enable --create -n copilot_intent_detection
fm feature enable --create -n copilot_swe_agent_skip_agent_job_concurrency_limit

# Create startup scripts for each terminal
log "Creating terminal startup scripts..."

# Terminal 1a: github workspace (starts server)
cat > /tmp/terminal1a.sh << 'EOF'
#!/usr/bin/env bash
cd /workspaces/github
script/dx/server-stop
script/server --ui
EOF
chmod +x /tmp/terminal1a.sh

# Terminal 1b: github-ui workspace (for working with the intent-detection branch)
cat > /tmp/terminal1b.sh << 'EOF'
#!/usr/bin/env bash
cd /workspaces/github-ui
exec bash
EOF
chmod +x /tmp/terminal1b.sh

# Terminal 2: copilot-api server
cat > /tmp/terminal2.sh << 'EOF'
#!/usr/bin/env bash
cd /workspaces/copilot-api
script/manage-overmind-capi stop
script/server
EOF
chmod +x /tmp/terminal2.sh

# Terminal 3: sweagentd server
cat > /tmp/terminal3.sh << 'EOF'
#!/usr/bin/env bash
cd /workspaces/sweagentd
script/server
EOF
chmod +x /tmp/terminal3.sh

# Terminal 4: copilot-mission-control - initialize and configure
log "Initializing copilot-mission-control (running make run and make stop)..."
cd /workspaces/copilot-mission-control
make run || true
sleep 2
make stop || true

log "Adding timeout configuration to .env/.env.local.rest..."
mkdir -p /workspaces/copilot-mission-control/.env
if ! grep -q "READ_TIMEOUT=9998s" /workspaces/copilot-mission-control/.env/.env.local.rest 2>/dev/null; then
    cat >> /workspaces/copilot-mission-control/.env/.env.local.rest << 'EOF'

READ_TIMEOUT=9998s
REQUEST_TIMEOUT=9997s
SHUTDOWN_TIMEOUT=9999s
WRITE_TIMEOUT=9998s
EOF
fi

cat > /tmp/terminal4.sh << 'EOF'
#!/usr/bin/env bash
cd /workspaces/copilot-mission-control
make run
make watch
EOF
chmod +x /tmp/terminal4.sh

# Terminal 5: Additional workspace terminal
cat > /tmp/terminal5.sh << 'EOF'
#!/usr/bin/env bash
cd /workspaces/copilot-mission-control
exec bash
EOF
chmod +x /tmp/terminal5.sh

# Create a tmux session manager script
cat > /tmp/start-services.sh << 'EOF'
#!/usr/bin/env bash

# Create tmux session with all services
# Window 1: github and github-ui split side by side
tmux new-session -d -s codespaces -n github
tmux send-keys -t codespaces:github '/tmp/terminal1a.sh' C-m
tmux split-window -t codespaces:github -h
tmux send-keys -t codespaces:github.1 '/tmp/terminal1b.sh' C-m

# Window 2: copilot-api, sweagentd, and copilot-mission-control in 3-pane split
tmux new-window -t codespaces -n copilot-api
tmux send-keys -t codespaces:copilot-api '/tmp/terminal2.sh' C-m
tmux split-window -t codespaces:copilot-api -h
tmux send-keys -t codespaces:copilot-api.1 '/tmp/terminal3.sh' C-m
tmux split-window -t codespaces:copilot-api.1 -h
tmux send-keys -t codespaces:copilot-api.2 '/tmp/terminal4.sh' C-m

# Window 3: workspace terminal
tmux new-window -t codespaces -n workspace
tmux send-keys -t codespaces:workspace '/tmp/terminal5.sh' C-m

# Select first window
tmux select-window -t codespaces:github

echo "All services started in tmux session 'codespaces'"
echo "Run 'tmux attach -t codespaces' to view the services"
EOF
chmod +x /tmp/start-services.sh

log "Setup complete! Run '/tmp/start-services.sh' to start all services in tmux"
log "Or manually run the scripts in /tmp/terminal*.sh"

# Create a README with instructions
cat > /tmp/CODESPACES_SETUP_README.md << 'EOF'
# GitHub Codespaces Setup

This setup script has prepared your environment. Here's what was done:

## Repositories Configured:
1. github-ui (branch: jasonrclark/intent-detection)
2. copilot-api (branch: jasonrclark/stream-chat-to-session-logs)
3. sweagentd
4. copilot-mission-control (branch: mitchdevenport/intent-detection-poc)

## Services Available:
- Terminal 1: github-ui server (script/server --ui)
- Terminal 2: copilot-api server (script/server)
- Terminal 3: sweagentd server (script/server)
- Terminal 4: copilot-mission-control server (make run && make watch)
- Terminal 5: General workspace terminal

## To Start All Services:
```bash
/tmp/start-services.sh
tmux attach -t codespaces
```

## Manual Start (if needed):
```bash
# In separate terminals:
/tmp/terminal1.sh  # github-ui
/tmp/terminal2.sh  # copilot-api
/tmp/terminal3.sh  # sweagentd
/tmp/terminal4.sh  # copilot-mission-control
/tmp/terminal5.sh  # workspace
```

## Environment Variables Set:
- USER_TOKEN=$MONALISA_PAT
- SESSIONS_API_BASE_URL=http://localhost:2210/api/v1/agents
- Alias: s='script/sessions-api --localhost 2210'

## Feature Flags Enabled:
- copilot_mission_control_service_proxy
- copilot_agent_task_api
- repo_agents_view
- copilot_mission_control_link_to_sessions_in_repo
- coding_agent_pull_request_toggle
- copilot_swe_agent_ai_name_generation
- mission_control_use_tool_header_icons
- copilot_intent_detection
- copilot_swe_agent_skip_agent_job_concurrency_limit
EOF

log "Setup README created at /tmp/CODESPACES_SETUP_README.md"
cat /tmp/CODESPACES_SETUP_README.md

# Open VSCode terminals and run the scripts
log "Opening VSCode terminals..."

# Terminal 1: github server (will be split)
code --command "workbench.action.terminal.new"
sleep 1
code --command "workbench.action.terminal.sendSequence" --args '{"text":"/tmp/terminal1a.sh\n"}'
sleep 1

# Split terminal 1 for github-ui
code --command "workbench.action.terminal.split"
sleep 1
code --command "workbench.action.terminal.sendSequence" --args '{"text":"/tmp/terminal1b.sh\n"}'
sleep 1

# Terminal 2: copilot-api server (new terminal, will be split)
code --command "workbench.action.terminal.new"
sleep 1
code --command "workbench.action.terminal.sendSequence" --args '{"text":"/tmp/terminal2.sh\n"}'
sleep 1

# Split terminal 2 for sweagentd
code --command "workbench.action.terminal.split"
sleep 1
code --command "workbench.action.terminal.sendSequence" --args '{"text":"/tmp/terminal3.sh\n"}'
sleep 1

# Split terminal 2 again for copilot-mission-control
code --command "workbench.action.terminal.split"
sleep 1
code --command "workbench.action.terminal.sendSequence" --args '{"text":"/tmp/terminal4.sh\n"}'
sleep 1

# Terminal 3: workspace (new terminal)
code --command "workbench.action.terminal.new"
sleep 1
code --command "workbench.action.terminal.sendSequence" --args '{"text":"/tmp/terminal5.sh\n"}'

echo ""
echo "=========================================="
echo "Intent Detection setup complete!"
echo "=========================================="
echo ""
echo "VSCode terminals have been opened and services are starting!"
echo ""
echo "Terminal layout:"
echo "  Terminal 1: github server | github-ui workspace (split)"
echo "  Terminal 2: copilot-api | sweagentd | copilot-mission-control (3-way split)"
echo "  Terminal 3: workspace"
echo ""
echo "Alternatively, use tmux:"
echo "  /tmp/start-services.sh"
echo "  tmux attach -t codespaces"
echo ""
echo "For more information, see: /tmp/CODESPACES_SETUP_README.md"
echo ""
