#!/bin/bash

# SSH connection helper script
SERVER="$1"
USER="$2"
PASSWORD="$3"
COMMAND="$4"

# Create a temporary expect-like script using here document
cat << 'EOF' > /tmp/ssh_auto.sh
#!/bin/bash
exec 3< <(echo "$3")
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PreferredAuthentications=password -o PubkeyAuthentication=no "$2@$1" "$4" < /dev/stdin
EOF

chmod +x /tmp/ssh_auto.sh

# Try direct connection with password authentication
export SSH_ASKPASS_REQUIRE=never
export DISPLAY=
echo "$PASSWORD" | ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PreferredAuthentications=password -o PubkeyAuthentication=no -o PasswordAuthentication=yes "$USER@$SERVER" "$COMMAND"