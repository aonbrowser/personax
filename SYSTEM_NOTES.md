# PersonaX App - Sistem Notları ve Çözülen Sorunlar

## 🏗️ Sistem Mimarisi

### Backend (Node.js + Express)
- **Port:** 8080
- **Process Manager:** PM2 (backend-api)
- **Database:** PostgreSQL (personax_app)
- **API Endpoints:**
  - `/v1/analyze/self` - Kişisel analiz
  - `/v1/user/analyses` - Kullanıcı analizlerini listele
  - `/v1/user/subscription` - Abonelik kontrolü

### Frontend (Expo/React Native Web)
- **Port:** 8081  
- **Process Manager:** PM2 (expo-web)
- **Platform:** Web (iOS/Android desteği mevcut)
- **Router:** Custom App.tsx router (React Navigation kullanmıyor)

### Database
- **Name:** personax_app (DİKKAT: relate_coach değil!)
- **Tables:**
  - `items` - Assessment soruları (832 adet)
  - `analysis_results` - Analiz sonuçları
  - `users` - Kullanıcı kayıtları
  - `subscriptions` - Abonelik bilgileri

## 🔧 Karşılaşılan Sorunlar ve Çözümleri

### 1. Form Gönderimi Sonrası Analiz Görünmeme Sorunu
**Problem:** Form doldurulduktan sonra MyAnalysesScreen'e yönlendirildiğinde yeni analiz görünmüyordu.

**Sebep:** 
- React Navigation kullanmadığımız için navigation.addListener('focus') çalışmıyordu
- Ekran açıldığında otomatik veri yenileme yoktu

**Çözüm:**
```javascript
useEffect(() => {
  if (userEmail) {
    loadAnalyses();
    // Yeni oluşturulan analizi yakalamak için gecikme
    setTimeout(() => {
      loadAnalyses();
    }, 1000);
  }
}, [userEmail]);
```

### 2. Form 3 Input Tipleri Eksikliği
**Problem:** MultiSelect4, Scale5, Scale10 tipleri frontend'de tanımlı değildi.

**Çözüm:** NewFormsScreen.tsx'e eksik case'ler eklendi:
- MultiSelect4: Max 4 seçim
- Scale5: 1-5 Likert ölçeği
- Scale10: 1-10 puanlama (zaten mevcuttu)

### 3. Database Form İsimlendirme Karmaşası
**Problem:** Form isimleri karışıktı (S3_self vs Form3_Davranis)

**Gerçek Durum:**
- Form 1: Form1_Tanisalim
- Form 2: Form2_Kisilik  
- Form 3: Form3_Davranis
- Form 4: S4_* (values/boundaries)

### 4. Navigation Prop Hatası
**Problem:** `navigation.addListener is not a function` hatası

**Sebep:** Custom router kullanılıyor, React Navigation değil

**Çözüm:** Navigation listener yerine useEffect ile mount'ta veri yükleme

### 5. PM2 Process İsimleri
**Problem:** PM2 restart komutlarında yanlış isim kullanımı

**Doğru İsimler:**
- Backend: `backend-api`
- Frontend: `expo-web`

## 📝 Önemli Komutlar

### Sistem Durumu Kontrolü
```bash
cd /var/www/personax.app && \
pm2 status && \
PGPASSWORD='PersonaX2025Secure' psql -h localhost -U postgres -d personax_app -c "SELECT COUNT(*) FROM items GROUP BY form;"
```

### PM2 Yeniden Başlatma
```bash
pm2 restart backend-api  # Backend
pm2 restart expo-web     # Frontend
pm2 restart all          # Tümü
```

### Database Sorguları
```bash
# Form sorularını kontrol et
PGPASSWORD='PersonaX2025Secure' psql -h localhost -U postgres -d personax_app -c "SELECT form, COUNT(*) FROM items GROUP BY form;"

# Son analizleri göster
PGPASSWORD='PersonaX2025Secure' psql -h localhost -U postgres -d personax_app -c "SELECT id, status, created_at FROM analysis_results ORDER BY created_at DESC LIMIT 5;"
```

### CSV Import (Yeni Sorular)
```bash
cd /var/www/personax.app/server
DATABASE_URL=postgres://postgres:PersonaX2025Secure@localhost:5432/personax_app npm run seed:items /path/to/csv
```

## 🎨 UI/UX Kuralları
- **Border Radius:** Tüm elementlerde `borderRadius: 3`
- **Primary Color:** `rgb(66, 153, 225)`
- **Processing State:** Mavi arka plan (#EBF8FF) + spinner + bilgilendirme metni

## ⚠️ Kritik Uyarılar

1. **VERİTABANI ASLA YENİDEN OLUŞTURULMASIN**
   - personax_app zaten mevcut ve dolu
   - Migration dosyaları zaten çalıştırılmış

2. **Form İsimlendirmeleri**
   - Frontend'te FormX kullanılıyor
   - Backend'te bazı yerlerde S0/S1 kullanılıyor
   - Karışıklığa dikkat!

3. **Process Management**
   - PM2 ile yönetiliyor
   - Cron job her 5 dakikada health check yapıyor
   - Memory limitleri ayarlı

4. **Multi-Language Support**
   - 15+ dil desteği var
   - Dil validasyonu GPT-5-mini ile yapılıyor
   - x-user-lang header'ı kullanılıyor

## 🚀 Deployment Notları

### Ortam Değişkenleri
- Frontend URL değişkenleri localStorage'da
- Backend .env dosyasında
- PM2 ecosystem.config.js'de

### Log Dosyaları
```
~/.pm2/logs/backend-api-out.log
~/.pm2/logs/expo-web-out.log
~/.pm2/logs/expo-web-error.log
```

## 📅 Son Güncellemeler (22 Ağustos 2025)

1. **Form 3'e 14 yeni soru eklendi:**
   - Bilişsel çarpıtmalar (1)
   - Anlam ve amaç (3)
   - Gelecek perspektifi (4)
   - Bedensel farkındalık (2)
   - Günlük check-in (4)

2. **Frontend İyileştirmeleri:**
   - MultiSelect4 ve Scale5 tipleri eklendi
   - İşlemde olan analizler için bilgilendirme mesajı
   - Otomatik veri yenileme düzeltmesi

3. **Bug Fixes:**
   - Navigation listener hatası düzeltildi
   - Form submit sonrası analiz görünme sorunu çözüldü
   - Delayed loading ile yeni analizler yakalanıyor

## 🔍 Debug İpuçları

1. **Analiz oluşmuyor mu?**
   - Backend loglarını kontrol et: `pm2 logs backend-api`
   - Database'de kontrol et: analysis_results tablosu

2. **Frontend güncellenmiyor mu?**
   - Browser cache temizle
   - pm2 restart expo-web
   - Console hatalarını kontrol et

3. **Form verileri kayboluyorsa:**
   - localStorage'ı kontrol et (form1_answers, form2_answers, form3_answers)
   - Network tab'da API çağrılarını izle

---
*Bu döküman canlı sistemin çalışma mantığını ve yaygın sorunların çözümlerini içerir.*
*Son güncelleme: 22 Ağustos 2025*