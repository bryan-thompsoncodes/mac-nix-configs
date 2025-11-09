{ pkgs, config, ... }:

{
  # === Network Storage ===

  # SMB mount service for media
  # Note: Uses explicit credentials from ~/.smb-credentials
  launchd.user.agents.smb-mount = {
    serviceConfig = {
      ProgramArguments = [
        "${pkgs.writeShellScript "mount-smb-media" ''
          # Log all operations
          exec 1>/tmp/smb-mount.log 2>/tmp/smb-mount.error.log

          MOUNT_POINT="$HOME/Media"
          CREDENTIALS_FILE="$HOME/.smb-credentials"
          MAX_RETRIES=30
          RETRY_DELAY=2

          echo "=== SMB Mount Script Started at $(date) ==="

          # Load credentials
          if [ ! -f "$CREDENTIALS_FILE" ]; then
            echo "ERROR: Credentials file not found at $CREDENTIALS_FILE"
            echo "Please create it with the following format:"
            echo "USERNAME=your_username"
            echo "PASSWORD=your_password"
            echo "SERVER=192.168.1.x"
            echo "SHARE=media"
            exit 1
          fi

          source "$CREDENTIALS_FILE"

          # Validate required variables
          if [ -z "$USERNAME" ] || [ -z "$PASSWORD" ] || [ -z "$SERVER" ] || [ -z "$SHARE" ]; then
            echo "ERROR: Missing required credentials in $CREDENTIALS_FILE"
            echo "Required: USERNAME, PASSWORD, SERVER, SHARE"
            exit 1
          fi

          # Check if already mounted
          if mount | grep -q "$MOUNT_POINT"; then
            echo "Mount point $MOUNT_POINT is already mounted, checking if it's accessible..."
            if ls "$MOUNT_POINT" >/dev/null 2>&1; then
              echo "Mount is healthy, exiting successfully"
              exit 0
            else
              echo "Mount is stale, unmounting..."
              /sbin/umount -f "$MOUNT_POINT" 2>&1 || true
            fi
          fi

          # Ensure mount point exists
          if [ ! -d "$MOUNT_POINT" ]; then
            echo "Creating mount point $MOUNT_POINT..."
            mkdir -p "$MOUNT_POINT"
          fi

          # Wait for network to be ready
          echo "Checking network connectivity to $SERVER..."
          for attempt in $(seq 1 $MAX_RETRIES); do
            if /sbin/ping -c 1 -t 2 "$SERVER" >/dev/null 2>&1; then
              echo "Network is ready (attempt $attempt)"
              break
            fi

            if [ $attempt -eq $MAX_RETRIES ]; then
              echo "ERROR: Server $SERVER unreachable after $MAX_RETRIES attempts"
              exit 1
            fi

            echo "Network not ready, waiting... (attempt $attempt of $MAX_RETRIES)"
            sleep $RETRY_DELAY
          done

          # Mount with explicit credentials
          echo "Attempting to mount //$USERNAME@$SERVER/$SHARE to $MOUNT_POINT..."
          if /sbin/mount_smbfs "//$USERNAME:$PASSWORD@$SERVER/$SHARE" "$MOUNT_POINT" 2>&1; then
            echo "Mount successful at $(date)"
            exit 0
          else
            echo "Mount failed at $(date)"
            echo "Check credentials in $CREDENTIALS_FILE and network connectivity"
            exit 1
          fi
        ''}"
      ];
      RunAtLoad = true;
      KeepAlive = false;
      StandardOutPath = "/tmp/smb-mount.log";
      StandardErrorPath = "/tmp/smb-mount.error.log";
    };
  };

  # === Activation Scripts ===

  # Setup SMB mount directory
  system.activationScripts.setup-smb-mount.text = ''
    echo ""
    echo "=== SMB Mount Setup ==="
    echo "For automatic mounting to work, create ~/.smb-credentials with:"
    echo "  USERNAME=username"
    echo "  PASSWORD=your_password"
    echo "  SERVER=192.168.1.x"
    echo "  SHARE=media"
    echo ""
    echo "Then restart or run: launchctl kickstart -k gui/\$(id -u)/org.nixos.smb-mount"
    echo "Check mount status: cat /tmp/smb-mount.log"
    echo ""
  '';
}

