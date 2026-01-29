# Syncthing Setup on Unraid

This guide covers deploying Syncthing as a Docker container on Unraid to serve as an always-on peer for the notes vault sync.

## Prerequisites

- Unraid server with Community Applications plugin installed
- Network access between Unraid and your other devices
- A dedicated share or folder for notes storage

## Container Setup

### 1. Install from Community Apps

1. Go to **Apps** in the Unraid web UI
2. Search for "Syncthing"
3. Select the **linuxserver/syncthing** container (most popular)
4. Click **Install**

### 2. Configure Container Settings

Set the following parameters:

| Parameter | Value | Notes |
|-----------|-------|-------|
| Name | `syncthing` | Container name |
| Network Type | `bridge` | Or `host` if you prefer |
| WebUI Port | `8384` | Access the Web UI |
| Listening Port | `22000` | Sync protocol (TCP/UDP) |
| Discovery Port | `21027` | Local discovery (UDP) |
| PUID | `99` | nobody user (default) |
| PGID | `100` | users group (default) |
| Config Path | `/mnt/user/appdata/syncthing` | Container config |
| Data Path | `/mnt/user/notes` | **Your notes sync folder** |

### 3. Create the Notes Share

Before starting the container:

1. Go to **Shares** → **Add Share**
2. Name: `notes`
3. Set appropriate permissions
4. This will create `/mnt/user/notes`

### 4. Start the Container

Click **Apply** to create and start the container.

## Device Pairing

### 1. Access Web UI

Open `http://[UNRAID_IP]:8384` in your browser.

### 2. Get Unraid Device ID

1. Click **Actions** → **Show ID**
2. Copy the Device ID (looks like: `XXXXXXX-XXXXXXX-XXXXXXX-XXXXXXX-XXXXXXX-XXXXXXX-XXXXXXX-XXXXXXX`)

### 3. Add Remote Devices

On Unraid, add each of your other devices:

1. Click **Add Remote Device**
2. Paste the Device ID from each machine (studio, mbp, gnarbox)
3. Give it a friendly name (e.g., "Studio Mac")
4. Click **Save**

### 4. Accept on Other Devices

On each of your other machines:
1. Open Syncthing Web UI at `http://localhost:8384`
2. You'll see a prompt to add the Unraid device
3. Accept and confirm

## Folder Configuration

### 1. Create Shared Folder on Unraid

1. Click **Add Folder**
2. **Folder Label**: `Notes Vault`
3. **Folder ID**: `notes-vault` (MUST match on all devices)
4. **Folder Path**: `/mnt/user/notes`
5. Click **Save**

### 2. Configure File Versioning (Unraid Only)

Unraid serves as the backup peer, so enable versioning here:

1. Click on the folder → **Edit**
2. Go to **File Versioning** tab
3. Select **Trash Can File Versioning**
4. **Clean out after**: `30` days
5. Click **Save**

### 3. Share with Devices

1. Click on the folder → **Edit**
2. Go to **Sharing** tab
3. Check all devices: studio, mbp, gnarbox
4. Click **Save**

### 4. Accept on Other Devices

On each machine, you'll be prompted to accept the shared folder:
1. Accept the share
2. Set the **Folder Path** to `~/notes` (or `/home/bryan/notes` on Linux)
3. Do NOT enable file versioning on client devices

## Verification

### Check Sync Status

On any device's Web UI:
- All devices should show "Connected"
- The folder should show "Up to Date"

### Test Sync

```bash
# On any machine
echo "test $(date)" >> ~/notes/.sync-test

# Wait 30 seconds, then check on another machine
cat ~/notes/.sync-test
```

### Check Unraid Versioning

After deleting or modifying a file:
1. SSH to Unraid or use terminal
2. Check `/mnt/user/notes/.stversions/`
3. You should see versioned copies of changed files

## Troubleshooting

### Devices Not Connecting

1. Check firewall rules - ports 22000 (TCP/UDP) and 21027 (UDP)
2. Verify devices are on the same network or have proper routing
3. Check container logs: `docker logs syncthing`

### Sync Not Working

1. Verify Folder ID matches exactly on all devices (`notes-vault`)
2. Check folder is shared with all devices
3. Look for conflicts in the Web UI

### Container Not Starting

1. Check container logs in Unraid Docker tab
2. Verify paths exist and have correct permissions
3. Ensure ports aren't in use by another container

## Maintenance

### Backup Syncthing Config

The config is stored at `/mnt/user/appdata/syncthing`. Include this in your Unraid backup strategy.

### Update Container

Unraid can auto-update containers. Check **Docker** tab for updates periodically.

### Monitor Disk Usage

The `.stversions` folder can grow over time. Monitor `/mnt/user/notes/.stversions/` size.
