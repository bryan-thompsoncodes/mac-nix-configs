# Quick Start Guide

## Setup Complete! 🎉

Your automated open-webui management system is now ready. Here's how to use it:

## 📁 Scripts Created

- `open-webup` - Main setup and management script
- `open-webui-update-hook` - Update detection hook  
- `rebuild-with-webui` - Rebuild wrapper with auto-update
- `README.md` - Full documentation

## 🚀 Quick Usage

### 1. Check Current Status
```bash
~/code/nix-configs/scripts/open-webup status
```

### 2. Update open-webui Only (Fast)
```bash
~/code/nix-configs/scripts/open-webup update
```

### 3. Full System Rebuild with open-webui Update
```bash
~/code/nix-configs/scripts/rebuild-with-webui
```

## 🔄 How It Works

### Problem Solved
- ✅ **Automatic static file management** - No more manual copying
- ✅ **Version detection** - Only updates when needed  
- ✅ **Service management** - Automatic restart with health checks
- ✅ **Error handling** - Backup and recovery options

### Update Workflow
1. **Normal Updates**: Use `rebuild-with-webui studio` for system changes
2. **Quick Updates**: Use `open-webup update` for static file refreshes
3. **Status Checks**: Use `open-webup status` for troubleshooting

## 🌐 Access Your Web UI

**Main Interface**: http://localhost:8080
**Ollama API**: http://localhost:11434

## 📋 What the Scripts Do

### `open-webup setup`
- Finds current open-webui package in Nix store
- Copies static files to writable user directory
- Configures proper environment variables
- Restarts services with health checks
- Tests web UI accessibility

### `rebuild-with-webui studio`
- Runs `sudo darwin-rebuild switch --flake '.#studio'`
- Detects if open-webui package changed
- Updates static files automatically if needed
- Shows final service status

## 🛠️ Maintenance

### After Nix Updates
```bash
# If you ran nix flake update or changed packages
~/code/nix-configs/scripts/rebuild-with-webui studio
```

### If Web UI Has Issues
```bash
# Quick fix for most issues
~/code/nix-configs/scripts/open-webup update
```

### Check Everything
```bash
# See current status and version
~/code/nix-configs/scripts/open-webup status
```

## 📁 File Locations

- **Data**: `~/.open-webui/`
- **Static Files**: `~/.open-webui/static/`
- **Logs**: `/tmp/open-webui*.log`
- **Version Tracking**: `~/.open-webui-version`

## 🎯 Benefits

### ✅ **Sustainable**
- Works with any open-webui version
- Automatic update detection
- No manual intervention needed

### ✅ **Reliable** 
- Error handling and recovery
- Backup before changes
- Health checks and verification

### ✅ **Simple**
- One-command updates
- Clear status reporting
- No complex Nix derivation needed

## 🆘 Troubleshooting

### Service Not Running
```bash
~/code/nix-configs/scripts/open-webup status
tail -f /tmp/open-webui.error.log
```

### Web UI Not Accessible
```bash
~/code/nix-configs/scripts/open-webup update
curl -I http://localhost:8080
```

### Permission Issues
```bash
# Scripts handle most permission issues automatically
# If needed, check static directory permissions:
ls -la ~/.open-webui/static/
```

## 📝 Next Steps

1. **Test it out**: Run `~/code/nix-configs/scripts/open-webup status`
2. **Bookmark**: Save http://localhost:8080 to your browser
3. **Use it**: For future updates, use `rebuild-with-webui studio`

Your open-webui setup is now fully automated and sustainable! 🎉