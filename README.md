# Syslog Central with Automatic Alerts

📌 Author: Matías Andrés Lagos Barra
📌 GitHub: Matiaslb14
📌 Goal: Centralize logs from multiple clients on a server, analyze them automatically, and send email alerts when suspicious events are detected.

📖 Description

This project implements a central syslog server (rsyslog) on Linux that receives logs from different clients and stores them in host-specific directories.
A Bash script (log-analyzer.sh) analyzes the logs, detects suspicious security events (failed login attempts, invalid users, etc.), and sends automatic alerts to Gmail with a summary of the findings.

🛠️ Architecture

[ Cliente Debian ] ----> [ Servidor Central Syslog ] ----> [ Gmail (alertas) ]
rsyslog rsyslog (modo receptor) msmtp + script

Server: receives logs via UDP/TCP on port 514

Clients: forward their logs to the central server

Bash Scripts: analyze logs and send alerts

⚙️ Setup

1. Central Server

Edit /etc/rsyslog.conf and enable remote reception:

UDP
module(load="imudp")
input(type="imudp" port="514")

TCP
module(load="imtcp")
input(type="imtcp" port="514")

Save logs by host:

$template RemoteLogs,"/var/log/remote/%HOSTNAME%/syslog"
*.* ?RemoteLogs

Restart service:

sudo systemctl restart rsyslog

2. Client (Debian)

File: /etc/rsyslog.d/01-remote.conf

*.* @SERVER_IP:514   # UDP  
*.* @@SERVER_IP:514  # TCP  

Restart client:

sudo systemctl restart rsyslog

📜 Scripts

🔹 log-analyzer.sh

Searches for suspicious patterns in logs.

If matches exceed a threshold (THRESHOLD), generates a report and sends an email alert.

Uses hashing to avoid duplicate alerts.

🔹 alerts-gmail.sh

Helper script for sending emails with msmtp.

Relies on ~/.msmtprc configuration with a Gmail App Password.

Example manual test:

echo "Final test" | msmtp your_email@gmail.com

📧 msmtp Configuration

File: ~/.msmtprc

defaults
auth           on
tls            on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile        ~/.msmtp.log

account gmail
host smtp.gmail.com
port 587
from your_email@gmail.com
user your_email@gmail.com
password YOUR_APP_PASSWORD

account default : gmail

🔑 Note: You must use a Gmail App Password, not your regular password.

🚀 Usage & Testing

Run analyzer manually:

./log-analyzer.sh

Generate test log:

logger "Final test from Debian client"

Check logs on server:

tail -n 10 /var/log/remote/CLIENT/syslog

Receive alert in Gmail:

Example subject:

Security Alert - Syslog Central (total=88)

🔄 Automation with Cron

Run every 5 minutes:

( crontab -l 2>/dev/null; echo "*/5 * * * * /home/$USER/linux-projects/08-syslog-central/log-analyzer.sh" ) | crontab -


Check:

crontab -l

🛡️ Troubleshooting

Error 454-4.7.0 Too many login attempts
→ Wait 1 hour before retrying
→ Ensure App Password is correct

No email received
→ Check log at ~/.msmtp.log
→ Check file permissions (chmod 600 ~/.msmtprc)

📌 Conclusions

✔️ Central syslog server running
✔️ Scripts detect critical events
✔️ Automatic Gmail alerts working
✔️ Ready for production with cron + logrotate
