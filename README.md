# django-baremetal-deployment

You can run this script on a brand-new Ubuntu 22.04 VPS as root (or with sudo) to set up a deploy user, harden SSH, configure a firewall, and install basic software.

---

## Usage

**SSH** into the target server, and follow the steps below.

### 1. Copy the latest version of the script to your deployment target

```bash
wget https://raw.githubusercontent.com/mrmurilo75/django-baremetal-deployment/refs/heads/main/setup.sh
```
### 2. Customize the variables

Set the values of the varibales at the top of the script (`NEW_USER`, `SSH_PORT`, `DOMAIN`, etc.) according to your needs.

**(Optional)** Paste your SSH public key into `SSH_PUBLIC_KEY` to have the script automatically install it. Otherwise, plan to add it manually.

```bash
vi setup.sh
```

> CAUTION: If you are not confortable with ViM commands, install another editor.

### 3. Run the script

```bash
chmod +x setup_server.sh
sudo ./setup_server.sh
```

### 4. Restart your SSH connection (Optional) 

**SSH** in using your new user on the specified SSH port. Adjust if you changed the port.

```bash
ssh -p 22 deploy@<server-ip>
```

That’s it! You now have a basic Ubuntu server configured for hosting web apps with minimal dependencies and a straightforward deployment workflow.

> **Important**:  
> 1. Certain steps (like user creation and SSH key handling) may need interactive input, so adapt as needed.  
> 2. This script sets some **defaults** (e.g., `deploy` username). Adjust variables, domain names, or commands to suit your environment.  
> 3. If your workflow is purely manual (SSH + git pull), some steps (like systemd service creation) are optional and provided for completeness.
> **Important**:  
> 1. Certain steps (like user creation and SSH key handling) may need interactive input, so adapt as needed.  
> 2. This script sets some **defaults** (e.g., `deploy` username). Adjust variables, domain names, or commands to suit your environment.  
> 3. If your workflow is purely manual (SSH + git pull), some steps (like systemd service creation) are optional and provided for completeness.
