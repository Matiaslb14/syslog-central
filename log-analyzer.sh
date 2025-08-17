#!/bin/bash
set -euo pipefail

# === Configuración ===
REMOTE_DIR="/var/log/remote"                 # carpeta donde rsyslog guarda por host
DESTINO="lagos.barra.m@gmail.com"            # a quién alertar
ASUNTO_BASE="Alerta de Seguridad - Syslog Central"
THRESHOLD=3
CACHE_DIR="$HOME/.cache/syslog-central"      # evita correos duplicados
mkdir -p "$CACHE_DIR"

# patrones a buscar (puedes editar/añadir)
PATTERNS=(
  "Failed password"
  "Invalid user"
  "authentication failure"
  "PAM .* authentication failure"
  "sudo: .*authentication"
  "session opened for user root"
  "reverse mapping checking getaddrinfo for .* failed"
)

# === Lógica ===
REPORT=""
TOTAL_MATCHES=0

# Recorre todos los syslog de todos los hosts
shopt -s nullglob
LOGS=("$REMOTE_DIR"/*/syslog)

if [ ${#LOGS[@]} -eq 0 ]; then
  echo "No se encontraron logs en $REMOTE_DIR/*/syslog"; exit 0
fi

for LOG in "${LOGS[@]}"; do
  HOSTNAME="$(basename "$(dirname "$LOG")")"
  REPORT+="\n===== Host: $HOSTNAME =====\n"

  for PAT in "${PATTERNS[@]}"; do
    MATCHES="$(grep -E "$PAT" "$LOG" || true)"
    COUNT="$(printf "%s\n" "$MATCHES" | grep -c . || true)"
    if [ "$COUNT" -gt 0 ]; then
      TOTAL_MATCHES=$((TOTAL_MATCHES + COUNT))
      REPORT+="\n-- Patrón: $PAT ($COUNT coincidencias)\n"
      REPORT+="$MATCHES\n"
    fi
  done
done

if [ "$TOTAL_MATCHES" -ge "$THRESHOLD" ]; then
  # Evitar correos repetidos por mismo contenido
  HASH_CUR="$(printf "%s" "$REPORT" | md5sum | awk '{print $1}')"
  CACHE_FILE="$CACHE_DIR/last.hash"
  HASH_PREV=""
  [ -f "$CACHE_FILE" ] && HASH_PREV="$(cat "$CACHE_FILE")"

  if [ "$HASH_CUR" != "$HASH_PREV" ]; then
    SUBJECT="$ASUNTO_BASE (total=$TOTAL_MATCHES)"
    BODY="Se detectaron eventos potencialmente sospechosos.\n\nResumen:\n$REPORT"
    # Enviar
    "$(dirname "$0")/alerts-gmail.sh" "$SUBJECT" "$BODY" "$DESTINO"
    # Guardar hash
    echo "$HASH_CUR" > "$CACHE_FILE"
    echo "Alerta enviada a $DESTINO (coincidencias: $TOTAL_MATCHES)."
  else
    echo "Coincidencias ($TOTAL_MATCHES) pero mismo contenido que antes; no se reenvía."
  fi
else
  echo "Coincidencias totales: $TOTAL_MATCHES (umbral: $THRESHOLD). No se envía."
fi
