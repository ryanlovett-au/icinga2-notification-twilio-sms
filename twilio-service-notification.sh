#!/bin/bash
#
# Icinga2 Twilio Service Notification Script
# Sends SMS notifications via Twilio API for service alerts
#

# Load configuration from JSON file
CONFIG_FILE="/etc/icinga2/twilio-config.json"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Config file not found: $CONFIG_FILE"
    exit 1
fi

# Parse JSON and export as environment variables
export TWILIO_API_KEY=$(jq -r '.twilio_api_key' "$CONFIG_FILE")
export TWILIO_API_SECRET=$(jq -r '.twilio_api_secret' "$CONFIG_FILE")
export TWILIO_ACCOUNT_SID=$(jq -r '.twilio_account_sid' "$CONFIG_FILE")
export TWILIO_FROM_NUMBER=$(jq -r '.twilio_from_number' "$CONFIG_FILE")

# Notification recipient (passed from Icinga2)
TO_NUMBER="$1"

# Service information (passed from Icinga2)
NOTIFICATION_TYPE="$2"
SERVICE_NAME="$3"
HOST_NAME="$4"
SERVICE_STATE="$5"
SERVICE_OUTPUT="$6"

# Validate required environment variables
if [ "$TWILIO_API_KEY" = "your_api_key" ] || [ "$TWILIO_API_SECRET" = "your_api_secret" ]; then
    echo "ERROR: Twilio credentials not configured. Set TWILIO_API_KEY and TWILIO_API_SECRET environment variables."
    exit 1
fi

if [ "$TWILIO_ACCOUNT_SID" = "your_account_sid" ]; then
    echo "ERROR: Twilio Account SID not configured. Set TWILIO_ACCOUNT_SID environment variable."
    exit 1
fi

# Validate recipient number
if [ -z "$TO_NUMBER" ]; then
    echo "ERROR: No recipient phone number provided"
    exit 1
fi

# Build notification message
case "$SERVICE_STATE" in
    OK)
        STATE_EMOJI="✅"
        ;;
    WARNING)
        STATE_EMOJI="⚠️"
        ;;
    CRITICAL)
        STATE_EMOJI="🔴"
        ;;
    UNKNOWN)
        STATE_EMOJI="❓"
        ;;
    *)
        STATE_EMOJI="❓"
        ;;
esac

MESSAGE="${STATE_EMOJI} Icinga2 Alert

Type: ${NOTIFICATION_TYPE}
Service: ${SERVICE_NAME}
Host: ${HOST_NAME}
State: ${SERVICE_STATE}
Info: ${SERVICE_OUTPUT}"

# URL encode the message
MESSAGE_ENCODED=$(echo -n "$MESSAGE" | jq -sRr @uri)

# Send SMS via Twilio API
RESPONSE=$(curl -s -X POST \
    "https://api.twilio.com/2010-04-01/Accounts/${TWILIO_ACCOUNT_SID}/Messages.json" \
    -u "${TWILIO_API_KEY}:${TWILIO_API_SECRET}" \
    -d "From=${TWILIO_FROM_NUMBER}" \
    -d "To=${TO_NUMBER}" \
    -d "Body=${MESSAGE_ENCODED}")

# Check response
if echo "$RESPONSE" | grep -q '"status":'; then
    echo "SMS sent successfully to ${TO_NUMBER}"
    exit 0
else
    echo "ERROR: Failed to send SMS"
    echo "$RESPONSE"
    exit 1
fi
