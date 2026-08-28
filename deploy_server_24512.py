#!/usr/bin/env python3
import pty, os, time, select, base64, sys

HOST = "103.236.99.177"
PORT = "29982"
USER = "root"
PASSWORD = "YwzmJ4BTT7xrntxh053wiLqRyhCZ2Rv9"

def ssh_exec(commands, timeout=300):
    if isinstance(commands, str):
        commands = [commands]
    script = "\n".join(["set +e", *commands, "echo '__END__'"])
    b64 = base64.b64encode(script.encode()).decode()
    ssh_cmd = [
        "ssh", "-o", "StrictHostKeyChecking=no",
        "-o", "UserKnownHostsFile=/dev/null",
        "-o", "LogLevel=ERROR",
        "-p", PORT, f"{USER}@{HOST}",
        f"echo {b64} | base64 -d | bash"
    ]
    pid, fd = pty.fork()
    if pid == 0:
        os.execvp("ssh", ssh_cmd)
    else:
        output = b""
        start = time.time()
        pw_sent = False
        while time.time() - start < timeout:
            r, _, _ = select.select([fd], [], [], 0.3)
            if r:
                try:
                    data = os.read(fd, 8192)
                    if not data: break
                    output += data
                    decoded = output.decode(errors='replace')
                    if not pw_sent and ("password:" in decoded.lower() or "密码" in decoded):
                        os.write(fd, (PASSWORD + "\n").encode())
                        pw_sent = True
                    if "__END__" in decoded:
                        time.sleep(0.5)
                        break
                except OSError:
                    break
        try: os.close(fd)
        except: pass
        result = output.decode(errors='replace')
        lines = [l for l in result.split('\n') if '__END__' not in l and 'base64 -d' not in l]
        return '\n'.join(lines).strip()

def scp_upload(local_path, remote_path):
    ssh_cmd = [
        "scp", "-o", "StrictHostKeyChecking=no",
        "-o", "UserKnownHostsFile=/dev/null",
        "-o", "LogLevel=ERROR",
        "-P", PORT, local_path, f"{USER}@{HOST}:{remote_path}"
    ]
    pid, fd = pty.fork()
    if pid == 0:
        os.execvp("scp", ssh_cmd)
    else:
        output = b""
        start = time.time()
        pw_sent = False
        while time.time() - start < 120:
            r, _, _ = select.select([fd], [], [], 0.3)
            if r:
                try:
                    data = os.read(fd, 8192)
                    if not data: break
                    output += data
                    decoded = output.decode(errors='replace')
                    if not pw_sent and ("password:" in decoded.lower() or "密码" in decoded):
                        os.write(fd, (PASSWORD + "\n").encode())
                        pw_sent = True
                except OSError:
                    break
        try: os.close(fd)
        except: pass
        return output.decode(errors='replace')

if __name__ == "__main__":
    print("=== Uploading server code ===")
    result = scp_upload(
        "/home/user/.super_doubao/super-doubao-runtime/workspace/chumian_ai/server/main.py",
        "/root/chumian_ai_main.py"
    )
    print(result[-500:] if len(result) > 500 else result)
    
    print("\n=== Deploying to port 24512 ===")
    cmds = [
        "echo 'STEP 1: Kill old services on 24512 and 24513'",
        "fuser -k 24512/tcp 2>/dev/null; fuser -k 24513/tcp 2>/dev/null; sleep 1",
        "echo 'Old services killed'",
        "",
        "echo 'STEP 2: Setup directory'",
        "mkdir -p /opt/chumian-ai/data /opt/chumian-ai/media",
        "",
        "echo 'STEP 3: Setup venv if not exists'",
        "if [ ! -d /opt/chumian-ai/venv ]; then",
        "  python3 -m venv /opt/chumian-ai/venv",
        "  /opt/chumian-ai/venv/bin/pip install fastapi uvicorn aiosqlite httpx python-multipart",
        "fi",
        "",
        "echo 'STEP 4: Copy new main.py'",
        "cp /root/chumian_ai_main.py /opt/chumian-ai/main.py",
        "wc -l /opt/chumian-ai/main.py",
        "",
        "echo 'STEP 5: Ensure port is 24512'",
        "grep 'port=' /opt/chumian-ai/main.py",
        "",
        "echo 'STEP 6: Create systemd service for 24512'",
        "cat > /etc/systemd/system/chumian-ai.service << 'SVCEOF'",
        "[Unit]",
        "Description=Chumian AI Backend",
        "After=network.target",
        "",
        "[Service]",
        "Type=simple",
        "User=root",
        "WorkingDirectory=/opt/chumian-ai",
        "Environment=PATH=/opt/chumian-ai/venv/bin:/usr/local/bin:/usr/bin",
        "ExecStart=/opt/chumian-ai/venv/bin/python3 -m uvicorn main:app --host 0.0.0.0 --port 24512",
        "Restart=always",
        "RestartSec=5",
        "StandardOutput=append:/root/chumian_ai_server.log",
        "StandardError=append:/root/chumian_ai_server.log",
        "",
        "[Install]",
        "WantedBy=multi-user.target",
        "SVCEOF",
        "",
        "echo 'STEP 7: Reload and restart'",
        "systemctl daemon-reload",
        "systemctl enable chumian-ai.service",
        "systemctl restart chumian-ai.service",
        "sleep 4",
        "",
        "echo 'STEP 8: Verify service status'",
        "systemctl status chumian-ai.service --no-pager | head -20",
        "",
        "echo 'STEP 9: Check port 24512'",
        "ss -tlnp | grep 24512",
        "",
        "echo 'STEP 10: Test API endpoints'",
        "curl -s http://127.0.0.1:24512/api/models",
        "echo ''",
        "curl -s -X POST http://127.0.0.1:24512/api/verify-app -H 'Content-Type: application/json' -d '{\"package_name\":\"com.chumian.ai\",\"apk_md5\":\"test\"}'",
        "echo ''",
        "curl -s http://127.0.0.1:24512/api/templates | head -c 200",
        "echo ''",
        "echo '=== DEPLOY COMPLETE ==='",
    ]
    print(ssh_exec(cmds, timeout=180))
