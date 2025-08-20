module.exports = {
  apps: [
    {
      name: 'backend-api',
      cwd: '/var/www/personax.app/server',
      script: 'npm',
      args: 'run dev',
      env: {
        NODE_ENV: 'development',
        PORT: 8080,
        DATABASE_URL: 'postgresql://postgres:PersonaX2025Secure@localhost:5432/personax_app',
        LANG_CHECK: 'false'
      },
      watch: false,
      max_memory_restart: '1G',
      error_file: '/var/www/personax.app/logs/backend-error.log',
      out_file: '/var/www/personax.app/logs/backend-out.log',
      log_file: '/var/www/personax.app/logs/backend-combined.log',
      time: true
    },
    {
      name: 'expo-web',
      cwd: '/var/www/personax.app/apps/expo',
      script: 'npx',
      args: 'expo start --web --port 8081 --non-interactive',
      env: {
        NODE_ENV: 'development',
        PORT: 8081,
        CI: 'false'
      },
      watch: false,
      max_memory_restart: '1G',
      error_file: '/var/www/personax.app/logs/expo-error.log',
      out_file: '/var/www/personax.app/logs/expo-out.log',
      log_file: '/var/www/personax.app/logs/expo-combined.log',
      time: true
    }
  ]
};