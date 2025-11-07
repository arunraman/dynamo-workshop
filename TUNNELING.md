# SSH Tunneling Guide for Dynamo Workshop

This guide explains how to set up SSH tunnels to access workshop services running on the shared workstation from your local machine.

## Overview

The workshop uses a shared workstation where each user runs JupyterLab and other services on unique ports. To access these services from your local machine, you need to create SSH tunnels that forward local ports to your assigned remote ports.

## Port Mapping

Your ports are automatically assigned based on your UID. Here's the mapping:

| Service | Your Local Port | Remote Port Formula | Example (UID=1005) |
|---------|----------------|---------------------|-------------------|
| JupyterLab | 8888 | 8888 + (UID - 1000) | 8893 |
| Frontend (Lab 1) | 10000 | 10000 + (UID - 1000) | 10005 |
| Frontend (Lab 2) | 11000 | 11000 + (UID - 1000) | 11005 |
| Prometheus | 19090 | 19090 + (UID - 1000) | 19095 |
| Grafana | 13000 | 13000 + (UID - 1000) | 13005 |

**Note:** The local ports (left column) are standardized for convenience. You'll connect to `localhost:8888` for Jupyter Lab regardless of your UID.

## Quick Start (Recommended)

### Automatic Setup

Use the provided script to automatically set up all tunnels:

```bash
# Make the script executable (first time only)
chmod +x setup-tunnels.sh

# Run the script with your SSH target
./setup-tunnels.sh student01@workshop.example.com

# Or if you have SSH config set up:
./setup-tunnels.sh workshop-server
```

The script will:
1. Detect your UID on the remote system
2. Calculate your assigned ports
3. Create SSH tunnels for all services
4. Display connection URLs

### After Tunnels are Established

Open your browser and navigate to:
- **JupyterLab**: http://localhost:8888
- **Frontend APIs**: http://localhost:10000 or http://localhost:11000
- **Prometheus**: http://localhost:19090
- **Grafana**: http://localhost:13000

## Manual Setup

If you prefer to set up tunnels manually or the script doesn't work:

### Step 1: Find Your Remote Ports

SSH into the workstation and check your assigned ports:

```bash
ssh student01@workshop.example.com

# Once connected, check your ports
source ~/dynamo-workshop/workshop-env.sh
```

This will display your assigned ports.

### Step 2: Create SSH Tunnels

From your **local machine**, create the tunnels (replace `XXXX` with your actual remote ports):

```bash
ssh -N -f \
    -L 8888:localhost:XXXX \
    -L 10000:localhost:YYYY \
    -L 11000:localhost:ZZZZ \
    student01@workshop.example.com
```

**Example** (if your JupyterLab is on remote port 8893):
```bash
ssh -N -f \
    -L 8888:localhost:8893 \
    -L 10000:localhost:10005 \
    -L 11000:localhost:11005 \
    student01@workshop.example.com
```

**Command Explanation:**
- `-N`: Don't execute a remote command (tunnel only)
- `-f`: Go to background after authentication
- `-L local:localhost:remote`: Forward local port to remote port

### Step 3: Verify Tunnels

Check that tunnels are active:

```bash
ps aux | grep ssh | grep -v grep
```

You should see an SSH process with your port forwards.

## VS Code Remote SSH

If you use VS Code with the Remote SSH extension, you can configure automatic port forwarding:

### Option 1: Using VS Code UI

1. Connect to remote host via Remote SSH
2. In VS Code, go to **Ports** panel (View → Ports)
3. Click "Forward a Port"
4. Add each port manually:
   - 8888 → Your JupyterLab port
   - 10000 → Your Frontend port
   - etc.

### Option 2: SSH Config File

Edit your `~/.ssh/config`:

```ssh-config
Host workshop
    HostName workshop.example.com
    User student01
    # Replace XXXX, YYYY, ZZZZ with your actual remote ports
    LocalForward 8888 localhost:XXXX
    LocalForward 10000 localhost:YYYY
    LocalForward 11000 localhost:ZZZZ
    LocalForward 19090 localhost:PPPP
    LocalForward 13000 localhost:GGGG
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

Then connect with:
```bash
ssh workshop
```

Or in VS Code: "Connect to Host" → "workshop"

## Troubleshooting

### Port Already in Use

**Error:** `bind: Address already in use`

**Solution:** Kill existing tunnels or processes using the port:

```bash
# Find process using port 8888
lsof -ti:8888 | xargs kill -9

# Or kill all SSH tunnels to workshop server
pkill -f 'ssh.*workshop.example.com'
```

### Tunnel Disconnects

**Symptom:** Tunnel drops after period of inactivity

**Solutions:**

1. **Use keep alive in SSH config** (`~/.ssh/config`):
```ssh-config
Host *
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

2. **Monitor and auto-reconnect** (run on local machine):
```bash
while true; do
    ./setup-tunnels.sh student01@workshop.example.com
    sleep 60
done
```

### Can't Connect to Service

**Checklist:**
1. ✅ Is the SSH tunnel running? `ps aux | grep ssh | grep workshop`
2. ✅ Is the remote service running? SSH in and check: `lsof -i :$USER_JUPYTER_PORT`
3. ✅ Are you using the correct local port? (8888 for JupyterLab, 10000 for Frontend, etc.)
4. ✅ Firewall blocking? Try `curl localhost:8888` from terminal

### Wrong Port Assignment

**Symptom:** You connect but see another user's session

**Cause:** Using wrong remote port in tunnel

**Solution:**
1. SSH into workstation
2. Run: `source ~/dynamo-workshop/workshop-env.sh`
3. Note your correct ports
4. Update your tunnel with correct ports

## Port Reference Table

Quick reference for local access URLs (same for all users):

| Service | Local URL | Used In |
|---------|-----------|---------|
| JupyterLab | http://localhost:8888 | All labs |
| Frontend API | http://localhost:10000 | Labs 1, 2, 3 |
| Frontend API 2 | http://localhost:11000 | Lab 2 (disaggregated) |
| Prometheus | http://localhost:19090 | Lab 1 monitoring |
| Grafana | http://localhost:13000 | Lab 1 monitoring |

## Advanced: Dynamic Port Forwarding

For advanced users, you can set up a SOCKS proxy:

```bash
ssh -D 8080 -N -f student01@workshop.example.com
```

Then configure your browser to use `localhost:8080` as a SOCKS5 proxy. This allows you to access any port on the remote machine without individual forwards.

## Closing Tunnels

When you're done with the workshop:

```bash
# Kill all SSH tunnels to workshop server
pkill -f 'ssh.*workshop.example.com'

# Or kill specific tunnel by port
lsof -ti:8888 | xargs kill
```

## Getting Help

If you encounter issues:

1. Check this troubleshooting section
2. Verify your SSH configuration
3. Test basic SSH connectivity: `ssh student01@workshop.example.com echo "test"`
4. Ask your workshop instructor

## Security Note

- SSH tunnels are encrypted and secure
- Only you can access services through your tunnels
- Tunnels automatically close when you disconnect
- Never share your SSH credentials

---

**Next Steps:** Once your tunnels are established, proceed to the workshop labs in JupyterLab at http://localhost:8888

