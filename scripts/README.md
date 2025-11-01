# open-webui Automation Scripts

This directory contains automation scripts for managing open-webui in a Nix-darwin environment.

## Scripts Overview

### `open-webup` - Main Setup and Management Script

Automated setup and update script for open-webui that handles:
- Static file copying from Nix store to writable user directory
- Service management (start/stop/restart)
- Version detection and updates
- Health checks and accessibility testing

**Usage:**
```bash
./open-webup [COMMAND]
```

**Commands:**
- `setup` - Full setup (default)
- `update` - Update static files and restart service only
- `status` - Show current status and version information
- `help` - Show help message

**Examples:**
```bash
./open-webup              # Full setup
./open-webup setup         # Full setup
./open-webup update        # Update only
./open-webup status        # Show status
```

### `open-webui-update-hook` - Update Detection Hook

Git hook that detects when open-webui package has changed and triggers updates automatically.

**Usage:**
```bash
./open-webui-update-hook [--force]
```

**Features:**
- Compares current vs previous open-webui version
- Only runs update when version actually changed
- Stores version tracking in `~/.open-webui-version`

### `rebuild-with-webui` - Rebuild Wrapper

Wrapper around `darwin-rebuild` that automatically handles open-webui updates after system rebuilds.

**Usage:**
```bash
./rebuild-with-webui
```

**Example:**
```bash
./rebuild-with-webui
```

**Example:**
```bash
./rebuild-with-webui
```

**Features:**
- Runs `sudo darwin-rebuild switch --flake '.#studio'`
- Automatically updates open-webui if package changed
- Shows final service status
- Provides accessibility URLs

## How It Works

### Problem Solved
The original issue was that open-webui tries to write to read-only Nix store paths. These scripts solve this by:

1. **Detection**: Automatically find the current open-webui package in Nix store
2. **Copying**: Copy static files to writable user directory (`~/.open-webui/static`)
3. **Configuration**: Set proper environment variables (`STATIC_DIR`, `DATA_DIR`)
4. **Service Management**: Restart services with new configuration
5. **Verification**: Test that the web UI is accessible

### Directory Structure
```
~/.open-webui/
├── static/          # Copied from Nix store (writable)
├── cache/           # Application cache
├── uploads/         # User uploads
├── vector_db/       # Vector database
└── webui.db        # SQLite database
```

### Environment Variables Used
- `DATA_DIR=/Users/bryan/.open-webui`
- `STATIC_DIR=/Users/bryan/.open-webui/static`
- `WEBUI_SECRET_KEY` (from studio.nix)
- `OLLAMA_BASE_URL=http://127.0.0.1:11434`

## Integration with Nix-darwin

### Current Setup
The scripts work with your existing `studio.nix` configuration:
- open-webui package installed via Nix
- LaunchAgent configured with proper environment variables
- Services managed by launchd

### Update Workflow
1. **Normal Update**: `./rebuild-with-webui studio`
   - Rebuilds Nix configuration
   - Detects if open-webui package changed
   - Updates static files if needed
   - Restarts services

2. **Manual Update**: `./open-webup update`
   - Updates static files only
   - Restarts service
   - Tests accessibility

3. **Status Check**: `./open-webup status`
   - Shows current version and status
   - Useful for troubleshooting

## Benefits

### ✅ **Sustainable**
- Automatically handles package updates
- No manual file copying required
- Works with any open-webui version

### ✅ **Robust**
- Error handling and logging
- Backup of existing static files
- Service health checks

### ✅ **User-Friendly**
- Colored output and clear status messages
- Help documentation
- Multiple usage patterns

### ✅ **Maintainable**
- Simple bash scripts (easy to understand/modify)
- Modular design (separate concerns)
- No complex Nix derivation required

## Troubleshooting

### Common Issues

1. **Service not starting**
   ```bash
   ./open-webup status
   tail -f /tmp/open-webui.error.log
   ```

2. **Web UI not accessible**
   ```bash
   ./open-webup update
   curl -I http://localhost:8080
   ```

3. **Permission issues**
   ```bash
   ls -la ~/.open-webui/
   chmod -R 755 ~/.open-webui/static/
   ```

### Logs
- Setup log: `/tmp/open-webui-setup.log`
- Service log: `/tmp/open-webui.log`
- Error log: `/tmp/open-webui.error.log`

## Migration from Manual Setup

If you previously manually copied static files, the scripts will:
1. Detect existing files in `~/.open-webui/static`
2. Create backup before overwriting
3. Use new automated going forward

## Future Enhancements

Potential improvements:
- Automatic update notifications
- Integration with `nix flake update`
- Support for multiple open-webui instances
- Health monitoring and alerts