# PersonaX (Relate Coach) - Proje Genel Bakış

## 🎯 Proje Amacı
PersonaX, kullanıcıların kişilik özelliklerini analiz eden ve ilişki koçluğu sağlayan çok dilli bir platformdur. Kullanıcılar kendileri ve başkaları hakkında değerlendirmeler yapabilir, ilişki dinamiklerini anlayabilir ve kişiselleştirilmiş koçluk alabilirler.

## 🏗️ Teknik Altyapı

### Backend (Node.js + Express)
- **Port:** 8080
- **Veritabanı:** PostgreSQL (personax_app)
- **AI Entegrasyonu:** OpenAI GPT-4 ve GPT-5-mini
- **Dil Desteği:** 15+ dil (TR, EN, ES, FR, DE, IT, PT, NL, RU, ZH, JA, KO, AR, HI)

### Frontend (Expo/React Native)
- **Port:** 8081
- **Platform:** iOS, Android, Web (tek kod tabanı)
- **Durum Yönetimi:** React Hooks
- **API İletişimi:** Fetch API

### Process Management
- **PM2:** Otomatik yeniden başlatma ve monitoring
- **Cron:** Her 5 dakikada sağlık kontrolü

## 📱 Ekranlar ve İşlevleri

### 1. Ana Ekran (HomeScreen)
**Yol:** `/`

**İçerik:**
- PersonaX logosu ve karşılama mesajı
- 5 ana test butonu:
  - S0 - Profil Bilgileri (32 soru)
  - S1 - Kendini Değerlendirme (72 soru)
  - S2 - İlişki Değerlendirmesi (20 ilişki tipi)
  - S3 - Tip Kontrolü (12 soru)
  - S4 - Değerler ve Sınırlar (4 alan)

**Kullanıcı Akışı:**
1. Kullanıcı istediği testi seçer
2. İlgili test ekranına yönlendirilir

### 2. S0 - Profil Ekranı (S0ProfileScreen)
**Yol:** `/s0-profile`

**Bölümler ve Sorular:**
- **Demographics (2 soru):** Yaş, Cinsiyet
- **EducationWork (7 soru):** İş durumu, eğitim, stres düzeyi
- **Relationship (5 soru):** Medeni durum, yaşam durumu, kronotip
- **Preferences (3 soru):** Hobiler, sevdikleri, sevmedikleri
- **Goals (3 soru):** Hayat amacı, ilişki hedefleri, sınırlar
- **Challenges (3 soru):** Zorluklar, tetikleyiciler
- **Values (3 soru):** Öncelikli değerler, para/sorumluluk rahatlığı
- **Support (2 soru):** Destek çevresi, başa çıkma stratejileri
- **Romantic (3 soru):** Sevgi dilleri, fiziksel temas, gelecek planı
- **Consent (2 soru):** Veri işleme onayı, neden ihtiyaç

**Özellikler:**
- Placeholder örnekleri ile açık uçlu sorular
- Çoklu seçim (max 3 değer seçimi)
- Likert ölçeği (1-5)
- Yerel kaydetme (AsyncStorage)
- İlerleme takibi

### 3. S1 - Kendini Değerlendirme (S1FormScreen)
**Yol:** `/s1-form`

**Bölümler:**
1. **BigFive (20 soru):** Beş faktör kişilik modeli
2. **Attachment (12 soru):** Bağlanma stilleri
3. **MBTI (12 soru):** A/B seçenekleri, düşünce tarzları
4. **DISC (7 soru):** Günlük hayat senaryoları
   - Su sızıntısı durumu
   - Ürün iade süreci
   - Komşu gürültüsü
   - Ortak mutfak kullanımı
5. **Conflict (4 soru):** Çatışma yönetimi senaryoları
6. **EmotionReg (5 soru):** Duygu düzenleme
7. **Empathy (4 soru):** Empati becerileri
8. **LifeStory (2 soru):** Hayat hikayesi
9. **OpenEnded (2 soru):** Açık uçlu sorular
10. **Quality (4 soru):** Dikkat kontrolü soruları

**Özel Özellikler:**
- MBTI sorularında sadece A/B butonları (başlık olmadan)
- Dikkat kontrolü: "4 nolu seçeneği işaretleyin"
- Gerçekçi senaryolar ve davranış bazlı cevaplar

### 4. S1 Kontrol Ekranı (S1CheckScreen)
**Yol:** `/s1-check`

**İşlevler:**
- Cevapların özeti
- Eksik soruları görme
- Gönderim öncesi kontrol
- Analiz başlatma

### 5. S2 - İlişki Değerlendirmesi
**Alt Ekranlar:** 20 farklı ilişki tipi
- Aile: Anne, Baba, Kardeş
- Romantik: Eş, Nişanlı, Partner, Flört
- Arkadaşlık: Arkadaş, En yakın arkadaş
- İş: Yönetici, Çalışma arkadaşı, Müşteri
- Diğer: Mentor, Mentee, Komşu, vb.

**Her ilişki tipi için:**
- 34 değerlendirme sorusu
- İlişkiye özel bağlam
- Karşılaştırmalı analiz imkanı

### 6. S3 - Tip Kontrolü
**12 hızlı kontrol sorusu:**
- Temel kişilik özellikleri
- Hızlı değerlendirme
- Doğrulama amaçlı

### 7. S4 - Değerler ve Sınırlar
**4 yaşam alanı (her biri 20 soru):**
- Aile değerleri
- Arkadaşlık değerleri
- Romantik ilişki değerleri
- İş hayatı değerleri

## 🔄 Kullanıcı Akışları

### Temel Akış:
```
Ana Ekran → Test Seçimi → Sorular → Kaydet → Kontrol → Gönder → Analiz
```

### S0 Profil Akışı:
```
1. Demografik bilgiler doldurulur
2. Tercihler ve hedefler belirlenir
3. Yerel olarak kaydedilir
4. S1 testine geçiş yapılır
```

### S1 Kendini Değerlendirme Akışı:
```
1. 72 soru sırayla cevaplanır
2. MBTI'de sadece A/B seçilir
3. DISC'te günlük senaryolar değerlendirilir
4. Dikkat kontrolü soruları kontrol edilir
5. Eksik sorular işaretlenir
6. Analiz için gönderilir
```

## 🗄️ Veritabanı Yapısı

### Tablo: items
```sql
- id: Benzersiz tanımlayıcı (örn: S0_AGE)
- form: Form tipi (S0_profile, S1_self, vb.)
- section: Bölüm adı
- subscale: Alt ölçek
- text_tr: Türkçe soru metni
- type: Soru tipi (Likert5, OpenText, MultiChoice4, vb.)
- options_tr: Seçenekler
- notes: Yardımcı notlar/örnekler
- display_order: Görüntüleme sırası
```

### Toplam Soru Dağılımı:
- S0: 32 soru
- S1: 72 soru
- S2: 680 soru (20 form × 34 soru)
- S3: 12 soru
- S4: 80 soru (4 alan × 20 soru)
- **TOPLAM: 876 soru**

## 🌐 API Endpoints

### Temel Endpointler:
```
GET  /health                     - Sistem sağlık kontrolü
GET  /v1/items/by-form?form=X    - Form sorularını getir
POST /v1/analyze/self            - Kendi analizini yap
POST /v1/analyze/other           - Başkası analizini yap
POST /v1/analyze/dyad            - İlişki dinamiği analizi
POST /v1/coach                   - Koçluk önerileri
GET  /v1/admin/language-incidents - Dil hatası logları
```

### Request Headers:
```
x-user-lang: Kullanıcı dili (tr, en, vb.)
x-user-id: Kullanıcı kimliği
Content-Type: application/json
```

## 🤖 AI Entegrasyonu

### Analiz Pipeline:
1. **Veri Toplama:** Form cevapları toplanır
2. **Dil Kontrolü:** GPT-5-mini ile dil doğrulaması
3. **Analiz:** GPT-4 ile kişilik analizi
4. **Dil Validasyonu:** Çıktı dili kontrolü (2 deneme)
5. **Sonuç:** Kullanıcıya özel rapor

### Prompt Şablonları:
- `/prompts/self.md` - Kendini değerlendirme
- `/prompts/other.md` - Başkasını değerlendirme
- `/prompts/dyad.md` - İlişki dinamiği
- `/prompts/coach.md` - Koçluk önerileri

## 🔐 Güvenlik ve Gizlilik

- Tüm veriler PostgreSQL'de güvenli saklanır
- Kullanıcı onayı olmadan veri işlenmez
- Dil hatalarında otomatik loglama
- CORS koruması aktif
- Rate limiting uygulanmış

## 📊 Monitoring

### PM2 Dashboard:
```bash
pm2 status    # Process durumu
pm2 logs      # Logları görüntüle
pm2 monit     # CPU/Memory takibi
```

### Veritabanı Kontrolü:
```bash
# Soru sayıları
psql -c "SELECT form, COUNT(*) FROM items GROUP BY form"

# Sistem sağlığı
curl http://localhost:8080/health
```

## 🚀 Deployment

### Başlatma:
```bash
pm2 start ecosystem.config.js
pm2 save
pm2 startup
```

### Güncelleme:
```bash
git pull
npm install
pm2 restart all
```

### Yedekleme:
```bash
pg_dump personax_app > backup.sql
```

## 📝 Notlar

- Frontend hem mobil hem web'de çalışır
- Tüm metinler Türkçe, sistem çok dilli
- Gerçek hayat senaryoları kullanılır
- Kullanıcı deneyimi öncelikli
- Sürekli geliştirme ve iyileştirme

---
*Son güncelleme: 19 Ağustos 2025*