# Google OAuth Setup Guide for PersonaX

## Google Cloud Console Ayarları

### 1. Google Cloud Console'a Giriş
1. [Google Cloud Console](https://console.cloud.google.com/) adresine gidin
2. Proje seçin veya yeni proje oluşturun

### 2. OAuth 2.0 Client ID Yapılandırması

#### Mevcut Client ID'yi Güncelleme:
Client ID: `1081510942447-mpjnej5fbs9vn262m4sccp3lcufmr9du.apps.googleusercontent.com`

1. **APIs & Services > Credentials** bölümüne gidin
2. Yukarıdaki Client ID'yi bulun ve düzenleyin
3. **Authorized JavaScript origins** bölümüne şu URL'leri ekleyin:
   ```
   https://personax.app
   https://www.personax.app
   http://localhost:8081
   http://localhost:8080
   http://localhost:3000
   ```

4. **Authorized redirect URIs** bölümüne şu URL'leri ekleyin:
   ```
   https://personax.app
   https://www.personax.app
   https://personax.app/redirect
   https://www.personax.app/redirect
   http://localhost:8081
   http://localhost:8081/redirect
   com.personax.app://redirect
   ```

### 3. OAuth Consent Screen Ayarları

1. **APIs & Services > OAuth consent screen** bölümüne gidin
2. **User Type**: External seçin
3. **App Information**:
   - App name: PersonaX
   - User support email: [Your email]
   - App logo: Upload PersonaX logo

4. **App Domain**:
   - Application home page: `https://personax.app`
   - Application privacy policy: `https://personax.app/privacy`
   - Application terms of service: `https://personax.app/terms`

5. **Authorized domains**:
   ```
   personax.app
   ```

6. **Developer contact information**: [Your email]

7. **Scopes**: Add these scopes:
   - `email`
   - `profile`
   - `openid`

### 4. iOS Safari Özel Ayarları

iOS Safari'de çalışması için:

1. **Apple Developer Account** gerekli (opsiyonel ama önerilen)
2. **Associated Domains** yapılandırması:
   - Xcode'da projeyi açın
   - Capabilities > Associated Domains ekleyin
   - `applinks:personax.app` ekleyin

3. **Apple App Site Association (AASA)** dosyası:
   `/var/www/personax.app/.well-known/apple-app-site-association` dosyası oluşturun:
   ```json
   {
     "applinks": {
       "apps": [],
       "details": [
         {
           "appID": "TEAM_ID.com.personax.app",
           "paths": ["/redirect", "/oauth/*", "/auth/*"]
         }
       ]
     },
     "webcredentials": {
       "apps": ["TEAM_ID.com.personax.app"]
     }
   }
   ```

### 5. Web Server Yapılandırması (Nginx)

Nginx'e AASA dosyası için MIME type ekleyin:

```nginx
location /.well-known/apple-app-site-association {
    default_type application/json;
    add_header Content-Type "application/json";
}
```

### 6. Test Etme

1. **Web (Chrome/Firefox)**: 
   - https://personax.app açın
   - "Google ile giriş yap" butonuna tıklayın
   - Google hesabınızı seçin

2. **iOS Safari**:
   - https://personax.app açın
   - "Google ile giriş yap" butonuna tıklayın
   - Popup engelleme uyarısı gelirse izin verin
   - Google hesabınızı seçin

3. **Android**:
   - PersonaX uygulamasını açın
   - "Google ile giriş yap" butonuna tıklayın
   - Google hesabınızı seçin

### 7. Yaygın Hatalar ve Çözümleri

#### "Access blocked: This app's request is invalid"
- **Sebep**: Redirect URI eşleşmiyor
- **Çözüm**: Google Console'da tüm redirect URI'leri kontrol edin

#### "Error 400: redirect_uri_mismatch"
- **Sebep**: Gönderilen redirect URI, Google Console'da kayıtlı değil
- **Çözüm**: Console'da exact match olarak redirect URI ekleyin

#### iOS Safari'de "Cannot open page"
- **Sebep**: Popup blocker veya cookie ayarları
- **Çözüm**: 
  - Settings > Safari > Block Pop-ups kapatın
  - Settings > Safari > Prevent Cross-Site Tracking kapatın (test için)

#### "This browser or app may not be secure"
- **Sebep**: Google, embedded webview'leri güvenli görmüyor
- **Çözüm**: `useProxy: false` kullanın (kod zaten güncellenmiş)

### 8. Production Checklist

- [ ] Google Console'da production redirect URI'leri eklenmiş
- [ ] OAuth consent screen production'a alınmış
- [ ] HTTPS zorunlu
- [ ] AASA dosyası yayında ve erişilebilir
- [ ] State parameter CSRF koruması aktif
- [ ] Error handling implementasyonu tamamlanmış

### 9. Monitoring

Google Cloud Console'da OAuth kullanımını takip edin:
- APIs & Services > Metrics
- OAuth 2.0 error rate'i kontrol edin
- Başarısız authentication attempt'leri inceleyin

## Önemli Notlar

1. **Client Secret** web uygulamalarında kullanılmamalı (güvenlik riski)
2. iOS için **SFAuthenticationSession** veya **ASWebAuthenticationSession** kullanılıyor
3. Android için Expo proxy kullanılıyor
4. Web için direct redirect kullanılıyor

## Support

Sorun yaşarsanız:
1. Browser console'da hataları kontrol edin
2. Google Cloud Console'da OAuth logs'ları inceleyin
3. Network tab'da redirect flow'u takip edin