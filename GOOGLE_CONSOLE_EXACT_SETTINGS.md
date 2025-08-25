# Google Cloud Console - TAM AYARLAR

## ÖNEMLİ: Bu ayarları AYNEN kopyalayıp yapıştırın!

### 1. Google Cloud Console'a Giriş
https://console.cloud.google.com/

### 2. APIs & Services > Credentials

Client ID'yi bulun: `1081510942447-mpjnej5fbs9vn262m4sccp3lcufmr9du.apps.googleusercontent.com`

"Edit" (Düzenle) butonuna tıklayın.

### 3. Authorized JavaScript origins
**TAM OLARAK şu URL'leri ekleyin (her biri ayrı satırda):**

```
https://personax.app
https://www.personax.app
http://localhost:8081
http://localhost:8080
http://localhost:3000
```

### 4. Authorized redirect URIs
**TAM OLARAK şu URL'leri ekleyin (her biri ayrı satırda):**

```
https://personax.app
https://www.personax.app
http://localhost:8081
http://localhost:8080
http://localhost:3000
```

### 5. SAVE (KAYDET) butonuna tıklayın

⚠️ **ÖNEMLİ:** Kayıt sonrası 5-10 dakika beklemeniz gerekebilir. Google'ın değişiklikleri yayması zaman alıyor.

### 6. OAuth consent screen kontrol

APIs & Services > OAuth consent screen

- Publishing status: **Production** olmalı (Testing değil!)
- User type: **External**

### 7. Test Etme

1. 10 dakika bekleyin
2. Tarayıcınızda cache'i temizleyin (Cmd+Shift+R veya Ctrl+Shift+R)
3. https://personax.app açın
4. "Google ile giriş yap" tıklayın

### Hala "redirect_uri_mismatch" Hatası Alıyorsanız:

1. Browser console'u açın (F12)
2. Network tab'ına gidin
3. Google login butonuna tıklayın
4. "auth" isteğine tıklayın
5. Query parameters'da `redirect_uri` değerini kopyalayın
6. Bu EXACT değeri Google Console'da "Authorized redirect URIs" listesine ekleyin

### Örnek:
Eğer console'da `redirect_uri=https%3A%2F%2Fpersonax.app` görüyorsanız, decode edilmiş hali: `https://personax.app`

Bu URL'yi Google Console'a ekleyin.

## Yaygın Hatalar:

❌ YANLIŞ: `https://personax.app/` (sondaki slash ile)
✅ DOĞRU: `https://personax.app` (slash olmadan)

❌ YANLIŞ: `http://personax.app` (http ile)
✅ DOĞRU: `https://personax.app` (https ile)

## Support:

Eğer hala sorun yaşıyorsanız:
1. Screenshot alın (hata mesajı + browser console)
2. Network tab'dan auth request'ini screenshot'layın
3. Google Console'daki redirect URI listesinin screenshot'ını alın