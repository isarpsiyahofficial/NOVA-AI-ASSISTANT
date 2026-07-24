#!/usr/bin/env bash
set -euo pipefail

mkdir -p /shared/sounds /shared/recordings /shared/reports
chmod -R 0777 /shared
rm -rf /var/lib/asterisk/sounds/nova-e2e
ln -s /shared/sounds /var/lib/asterisk/sounds/nova-e2e

: "${NOVA_ASTERISK_AMI_SECRET:=nova-ci-ami-secret-not-for-production}"
export NOVA_ASTERISK_AMI_SECRET
envsubst '${NOVA_ASTERISK_AMI_SECRET}' \
  < /opt/nova/manager.conf.template \
  > /etc/asterisk/manager.conf
chmod 0600 /etc/asterisk/manager.conf

carrier_file=/etc/asterisk/pjsip.carrier.conf
: > "$carrier_file"

if [[ -n "${NOVA_SIP_TRUNK_HOST:-}" ]]; then
  required=(NOVA_SIP_TRUNK_USER NOVA_SIP_TRUNK_PASSWORD NOVA_SIP_TRUNK_FROM_DOMAIN)
  for name in "${required[@]}"; do
    if [[ -z "${!name:-}" ]]; then
      echo "Missing required carrier trunk variable: $name" >&2
      exit 2
    fi
  done
  envsubst \
    '${NOVA_SIP_TRUNK_HOST} ${NOVA_SIP_TRUNK_USER} ${NOVA_SIP_TRUNK_PASSWORD} ${NOVA_SIP_TRUNK_FROM_DOMAIN}' \
    < /opt/nova/pjsip.carrier.conf.template \
    > "$carrier_file"
  chmod 0600 "$carrier_file"
  echo "Rendered optional NOVA carrier trunk configuration."
else
  cat > "$carrier_file" <<'EOF'
; Carrier trunk disabled. Set NOVA_SIP_TRUNK_* environment variables to enable.
EOF
fi

exec asterisk -f -T -U root -G root -vvv
