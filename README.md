# Icinga2 Twilio SMS Notification Integration

This integration allows Icinga2 to send host and service notifications via SMS using the Twilio Messaging API.

## Prerequisites

- Icinga2 installed and configured
- A Twilio account with:
  - Account SID
  - API Key (Standard or Main)
  - API Key Secret
  - A Twilio phone number
- `curl` and `jq` installed on your Icinga2 server

**Note:** Twilio API Keys are the recommended authentication method over using your Account SID and Auth Token directly. API Keys can be created, rotated, and revoked independently in the Twilio Console under Account > API Keys & Tokens.

## Installation Steps

### 1. Install Dependencies

```bash
# On Debian/Ubuntu
sudo apt-get install curl jq

# On RHEL/CentOS
sudo yum install curl jq
```

### 2. Install Notification Scripts

Copy the notification scripts to your system:

```bash
sudo cp twilio-host-notification.sh /usr/local/bin/
sudo cp twilio-service-notification.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/twilio-host-notification.sh
sudo chmod +x /usr/local/bin/twilio-service-notification.sh
```

### 3. Configure Twilio Credentials

#### System Environment Variables (Recommended for security)

Add to `/etc/icinga2/twilio-config.json`:

```bash
{
  "twilio_api_key": "SKxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "twilio_api_secret": "your-api-secret-here",
  "twilio_account_sid": "ACxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "twilio_from_number": "+15551234567"
}
```

Then fix file permissions and ownership
```bash
sudo chown nagios:nagios /etc/icinga2/twilio-config.json
sudo chmod 600 /etc/icinga2/twilio-config.json
```

Then restart Icinga2:
```bash
sudo systemctl restart icinga2
```

### 4. Add Notification Commands

If you are using Director, you will need to add the configuration manually in the Web UI, otherwise...

Copy the command definitions to your Icinga2 configuration:

```bash
sudo cp twilio-commands.conf /etc/icinga2/conf.d/
```

### 5. Configure Users

Edit users in the Web UI

**Important**: Phone numbers must be in E.164 format (e.g., +15551234567 for US numbers).

### 6. Configure Notifications

Create notification templates in the Web UI

### 7. Enable Notifications for Hosts and Services

Assign notifications to host groups/etc

### 8. Validate Configuration

Check your Icinga2 configuration for errors:

```bash
sudo ""icinga2 daemon -C""
```

### 9. Restart Icinga2

```bash
sudo systemctl restart icinga2
```

## Testing

### Test the Scripts Manually

Test host notification:
```bash
export TWILIO_API_KEY="SKxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
export TWILIO_API_SECRET="your_api_secret_here"
export TWILIO_ACCOUNT_SID="ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
export TWILIO_FROM_NUMBER="+15559876543"

/usr/local/bin/twilio-host-notification.sh \
  "+15551234567" \
  "PROBLEM" \
  "testhost" \
  "DOWN" \
  "192.168.1.100" \
  "PING CRITICAL - Host unreachable"
```

Test service notification:
```bash
/usr/local/bin/twilio-service-notification.sh \
  "+15551234567" \
  "PROBLEM" \
  "HTTP" \
  "webserver01" \
  "CRITICAL" \
  "HTTP CRITICAL - Unable to connect"
```

### Trigger a Test Notification from Icinga2

Use the Icinga2 API or web interface to send a test notification:

```bash
curl -k -s -u root:password \
  -H 'Accept: application/json' \
  -X POST 'https://localhost:5665/v1/actions/send-custom-notification' \
  -d '{ "type": "Host", "filter": "host.name==\"webserver01\"", "author": "test", "comment": "Test notification" }'
```

## Notification Message Format

### Host Notifications
```
✅/🔴/⚠️ Icinga2 Alert

Type: PROBLEM/RECOVERY
Host: hostname
State: UP/DOWN/UNREACHABLE
Address: 192.168.1.100
Info: Check output message
```

### Service Notifications
```
✅/⚠️/🔴/❓ Icinga2 Alert

Type: PROBLEM/RECOVERY
Service: service_name
Host: hostname
State: OK/WARNING/CRITICAL/UNKNOWN
Info: Check output message
```

## Customization

### Customize Message Format

Edit the notification scripts to change the message format. The message is built around line 40-50 in each script.

## Troubleshooting

### Check Icinga2 Logs

```bash
sudo tail -f /var/log/icinga2/icinga2.log
```

### Check Notification Script Execution

```bash
sudo tail -f /var/log/icinga2/icinga2.log | grep -i twilio
```

### Common Issues

1. **"ERROR: Twilio credentials not configured"**
   - Ensure environment variables are set or user variables are configured
   - Restart Icinga2 after setting environment variables

2. **"ERROR: Failed to send SMS"**
   - Check Twilio credentials are correct
   - Verify phone numbers are in E.164 format
   - Check network connectivity to api.twilio.com
   - Review Twilio account for errors in the console

3. **Notifications not being sent**
   - Check user has notifications enabled
   - Verify notification filters (states, types, periods)
   - Check if host/service is in downtime or has notifications disabled

4. **Invalid phone number format**
   - Use E.164 format: +[country code][number]
   - Example: +15551234567 (not 555-123-4567 or 15551234567)

## Security Considerations

- **Use API Keys instead of Auth Tokens:** Twilio API Keys provide better security as they can be rotated and revoked independently without affecting your main account credentials
- Store Twilio credentials securely (prefer environment variables over config files)
- Restrict permissions on configuration files: `chmod 600`
- Use Icinga2's built-in encryption for API communication
- Consider using Twilio's subaccounts for different environments
- Rotate API Keys periodically (recommended every 90 days)
- Delete unused API Keys immediately
- Never commit API Keys or secrets to version control

## Resources

- Icinga2 Documentation: https://icinga.com/docs/icinga-2/latest/
- Twilio API Documentation: https://www.twilio.com/docs/sms
- Twilio Console: https://www.twilio.com/console

## License

This integration is provided as-is for use with Icinga2 and Twilio.
