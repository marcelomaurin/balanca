#!/usr/bin/env sh
set -eu

BIN_SOURCE="${1:-./balanca_service}"
INSTALL_DIR="/opt/balanca"
CONFIG_DIR="/etc/balanca"
SERVICE_FILE="/etc/systemd/system/balanca.service"

if [ "$(id -u)" -ne 0 ]; then
  echo "Execute como root."
  exit 1
fi

if [ ! -f "$BIN_SOURCE" ]; then
  echo "Executavel nao encontrado: $BIN_SOURCE"
  exit 1
fi

if ! id balanca >/dev/null 2>&1; then
  useradd --system --home "$INSTALL_DIR" --shell /usr/sbin/nologin balanca
fi

mkdir -p "$INSTALL_DIR" "$CONFIG_DIR"
install -m 0755 "$BIN_SOURCE" "$INSTALL_DIR/balanca_service"
install -m 0644 "$(dirname "$0")/balanca.service" "$SERVICE_FILE"

chown -R balanca:balanca "$INSTALL_DIR" "$CONFIG_DIR"

systemctl daemon-reload
systemctl enable balanca.service

echo "Servico instalado."
echo "Iniciar: systemctl start balanca"
echo "Status:  systemctl status balanca"
echo "Logs:    journalctl -u balanca -f"
