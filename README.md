# Proyecto 08 – Syslog Central con Alertas Automáticas

📌 **Autor:** Matías Andrés Lagos Barra  
📌 **GitHub:** [Matiaslb14](https://github.com/Matiaslb14)  
📌 **Objetivo:** Centralizar logs de múltiples clientes en un servidor, analizarlos automáticamente y enviar **alertas por correo** cuando se detectan eventos sospechosos.

---

## 📖 Descripción

Este proyecto implementa un **servidor central de syslog (rsyslog)** en Linux que recibe logs de distintos equipos y los almacena en directorios separados por host.  
Luego, mediante un script de análisis (`log-analyzer.sh`), se detectan patrones de seguridad (intentos fallidos de autenticación, usuarios inválidos, etc.) y se envían alertas automáticas a Gmail con un resumen de los eventos.

---

## 🛠️ Arquitectura

[ Cliente Debian ] ----> [ Servidor Central Syslog ] ----> [ Gmail (alertas) ]
rsyslog rsyslog (modo receptor) msmtp + script


- **Servidor**: recibe logs vía UDP/TCP en el puerto 514.  
- **Clientes**: reenvían sus logs al servidor central.  
- **Scripts Bash**: analizan logs y envían alertas.  

---

## ⚙️ Configuración

### 1. Servidor Central
Editar `/etc/rsyslog.conf` y habilitar recepción remota:

```conf
# UDP
module(load="imudp")
input(type="imudp" port="514")

# TCP
module(load="imtcp")
input(type="imtcp" port="514")

Guardar logs en rutas separadas:

$template RemoteLogs,"/var/log/remote/%HOSTNAME%/syslog"
*.* ?RemoteLogs

Reiniciar:

sudo systemctl restart rsyslog

2. Cliente (Debian)

Archivo /etc/rsyslog.d/01-remote.conf:

*.* @IP_DEL_SERVIDOR:514   # UDP
*.* @@IP_DEL_SERVIDOR:514  # TCP

Reiniciar cliente:

sudo systemctl restart rsyslog

📜 Scripts

🔹 log-analyzer.sh

Busca patrones sospechosos en los logs.

Si las coincidencias superan un umbral (THRESHOLD), se genera un reporte y se envía por correo.

Para evitar duplicados, se usa un hash de contenido.

🔹 alerts-gmail.sh

Script auxiliar para enviar correos usando msmtp.

Se apoya en la configuración ~/.msmtprc con App Password de Gmail.

Ejemplo de envío manual:

echo "Test final" | msmtp tu_correo@gmail.com

📧 Configuración de msmtp

Archivo ~/.msmtprc:

defaults
auth           on
tls            on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile        ~/.msmtp.log

account gmail
host smtp.gmail.com
port 587
from tu_correo@gmail.com
user tu_correo@gmail.com
password TU_APP_PASSWORD

account default : gmail

🔑 Nota: se debe usar un App Password de Gmail (no la contraseña normal).

🚀 Ejecución y Pruebas

Ejecutar manualmente:

./log-analyzer.sh


Generar logs de prueba:

logger "Prueba final desde cliente Debian"


Verificar en servidor:

tail -n 10 /var/log/remote/CLIENTE/syslog


Recibir alerta en Gmail:

📩 Ejemplo real:

Asunto: Alerta de Seguridad - Syslog Central (total=88)

Se detectaron eventos potencialmente sospechosos.

Resumen:
Host: mati
Patrón: Failed password (28 coincidencias)

2025-08-12T17:54:30 sshd-session[2594]: Failed password for invalid user fakeuser ...
2025-08-12T17:59:04 sshd-session[2606]: Failed password for invalid user fakeuser ...

🔄 Automatización con Cron

Ejecutar el analizador cada 5 minutos:

( crontab -l 2>/dev/null; echo "*/5 * * * * /home/$USER/linux-projects/08-syslog-central/log-analyzer.sh" ) | crontab -

Verificar:

crontab -l

🛡️ Troubleshooting

Error 454-4.7.0 Too many login attempts
→ Esperar 1h antes de reintentar.
→ Revisar que se use un App Password válido de Gmail.

No llega correo
→ Ver log ~/.msmtp.log.
→ Revisar permisos de ~/.msmtprc (chmod 600).

📌 Conclusiones

✔️ Syslog central funcionando.
✔️ Scripts detectan eventos críticos.
✔️ Alertas enviadas automáticamente por Gmail.
✔️ Listo para producción con cron y logrotate.
