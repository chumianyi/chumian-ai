#!/usr/bin/env python3
import pty, os, time, select, base64

HOST = "103.236.99.177"
PORT = "29982"
USER = "root"
PASSWORD = "YwzmJ4BTT7xrntxh053wiLqRyhCZ2Rv9"

def ssh_exec(commands, timeout=120):
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
                    if not pw_sent and "password:" in decoded.lower():
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

if __name__ == "__main__":
    cmds = [
        "echo '=== BEFORE: All chumian/ime processes ==='",
        "ps aux | grep -iE 'chumian|ime|inputmethod' | grep -v grep",
        "echo ''",
        "echo '=== BEFORE: Port 24512 (TCP+UDP) ==='",
        "ss -tulnp | grep 24512",
        "echo ''",
        "echo '=== BEFORE: Port 24513 ==='",
        "ss -tlnp | grep 24513 || echo '24513 free'",
        "echo ''",
        "echo '=== BEFORE: systemd chumian services ==='",
        "systemctl list-units --type=service --state=running | grep -i chumian || echo 'none running'",
        "echo ''",
        "echo '=== STEP: Stop and disable chumian-ime service ==='",
        "systemctl stop chumian-ime.service 2>&1",
        "systemctl disable chumian-ime.service 2>&1",
        "echo ''",
        "echo '=== STEP: Stop chumian-ai service ==='",
        "systemctl stop chumian-ai.service 2>&1",
        "systemctl disable chumian-ai.service 2>&1",
        "echo ''",
        "echo '=== STEP: Kill any remaining chumian/ime processes (NOT zhijixiaotie) ==='",
        "ps aux | grep -iE 'chumian|ime' | grep -v grep | grep -v zhijixiaotie | awk '{print $2}' | while read p; do",
        "  echo \"Killing PID $p: $(ps -p $p -o comm= 2>/dev/null)\"",
        "  kill -9 $p 2>/dev/null",
        "done",
        "echo ''",
        "echo '=== STEP: Kill node processes for chumian-ime specifically ==='",
        "ps aux | grep 'chumian-ime' | grep -v grep | awk '{print $2}' | xargs -r kill -9 2>/dev/null",
        "echo 'Done'",
        "echo ''",
        "sleep 2",
        "echo '=== AFTER: All chumian/ime processes ==='",
        "ps aux | grep -iE 'chumian|ime|inputmethod' | grep -v grep || echo 'NONE FOUND'",
        "echo ''",
        "echo '=== AFTER: Port 24512 ==='",
        "ss -tulnp | grep 24512",
        "echo ''",
        "echo '=== AFTER: Port 24513 ==='",
        "ss -tlnp | grep 24513 || echo '24513 free'",
        "echo ''",
        "echo '=== AFTER: zhijixiaotie still running? ==='",
        "ps aux | grep zhijixiaotie | grep -v grep | head -3",
        "systemctl is-active zhijixiaotie.service 2>&1",
        "echo ''",
        "echo '=== KILL COMPLETE ==='",
    ]
    print(ssh_exec(cmds, timeout=90))
