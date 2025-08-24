#!/bin/bash

# SSH connection script
SERVER="$SSH_SERVER"
USER="$SSH_USER"
PASSWORD="$SSH_PASSWORD"

# Create expect script
cat > /tmp/ssh_expect.exp << EOF
#!/usr/bin/expect -f
set timeout 30
spawn ssh -o StrictHostKeyChecking=no $USER@$SERVER "\$@"
expect {
    "password:" {
        send "$PASSWORD\r"
        exp_continue
    }
    eof
}
EOF

chmod +x /tmp/ssh_expect.exp
/tmp/ssh_expect.exp "$@"