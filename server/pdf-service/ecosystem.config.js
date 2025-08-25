module.exports = {
  apps: [{
    name: 'pdf-service',
    script: 'pdf_server.py',
    interpreter: 'python3',
    cwd: '/var/www/personax.app/server/pdf-service',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '256M',
    env: {
      PYTHONUNBUFFERED: '1',
      FLASK_ENV: 'production'
    },
    error_file: '/var/www/personax.app/logs/pdf-service-error.log',
    out_file: '/var/www/personax.app/logs/pdf-service-out.log',
    log_file: '/var/www/personax.app/logs/pdf-service-combined.log',
    time: true
  }]
};