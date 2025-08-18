#!/bin/bash

# Health check script for PersonaX services
# Run via cron every 5 minutes

LOG_FILE="/var/www/personax.app/logs/monitor.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

# Check backend API
BACKEND_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/health)
if [ "$BACKEND_STATUS" != "200" ]; then
    echo "[$DATE] WARNING: Backend API not responding (Status: $BACKEND_STATUS)" >> $LOG_FILE
    pm2 restart backend-api
    echo "[$DATE] Backend API restarted" >> $LOG_FILE
fi

# Check Expo web
EXPO_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8081)
if [ "$EXPO_STATUS" != "200" ]; then
    echo "[$DATE] WARNING: Expo web not responding (Status: $EXPO_STATUS)" >> $LOG_FILE
    pm2 restart expo-web
    echo "[$DATE] Expo web restarted" >> $LOG_FILE
fi

# Check website
SITE_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://personax.app)
if [ "$SITE_STATUS" != "200" ]; then
    echo "[$DATE] ERROR: Website not accessible (Status: $SITE_STATUS)" >> $LOG_FILE
fi

# Check memory usage
MEMORY_USAGE=$(free | grep Mem | awk '{print int($3/$2 * 100)}')
if [ "$MEMORY_USAGE" -gt 90 ]; then
    echo "[$DATE] WARNING: High memory usage: $MEMORY_USAGE%" >> $LOG_FILE
    pm2 restart all
    echo "[$DATE] All services restarted due to high memory" >> $LOG_FILE
fi