#!/bin/bash
# Uso: ./alerts-gmail.sh "Asunto" "Cuerpo" destino@correo.com
SUBJECT="$1"; BODY="$2"; TO="$3"
FROM="lagos.barra.m@gmail.com"
if [ -z "$SUBJECT" ] || [ -z "$BODY" ] || [ -z "$TO" ]; then
  echo "Uso: $0 \"Asunto\" \"Cuerpo\" destino@correo.com"; exit 1
fi
printf "To: %s\nFrom: %s\nSubject: %s\n\n%s\n" "$TO" "$FROM" "$SUBJECT" "$BODY" | msmtp -a gmail -t
