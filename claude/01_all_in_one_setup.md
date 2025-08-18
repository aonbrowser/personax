## 01 — Tüm Kurulum (Parça Parça Verin)

### A) Sunucu: Postgres Migrasyon + Seed
**Komut 1:**
```
cd server
npm i
```
**Komut 2:**
`.env` dosyanızı köke kopyalayın ve düzenleyin (bkz. `.env.example`).

**Komut 3:**
```
npm run migrate
```
**Komut 4:**
```
npm run seed:items ../data/testbank.csv
```

### B) Sunucu: Çalıştırma
**Komut 5:**
```
npm run dev
```
Tarayıcıda: `http://localhost:8080/health`

### C) Expo (Web/Mobil)
**Komut 6:**
```
cd ../apps/expo
npm i
```
**Komut 7 (Web):**
```
npm run web
```
**Komut 8 (Mobil):**
```
npm run ios
# veya
npm run android
```

### D) Analiz API Testleri
**Komut 9: Self Analizi**
```
curl -X POST http://localhost:8080/v1/analyze/self   -H "Content-Type: application/json"   -H "x-user-lang: tr"   -H "x-user-id: demo"   -d '{"bigfive":{"E":62,"A":55,"C":68,"N":41,"O":72},"mbti":{"E":0.61,"S":0.48,"T":0.52,"J":0.66},"attachment":{"anxiety":58,"avoidance":35},"conflict":{"COMPETE":40,"COLLAB":70,"COMPROM":60,"AVOID":35,"ACCOM":45},"quality":{"consistency":0.82,"speedQuality":0.77,"axisMarginAvg":0.64,"sampleSize":0.9}}'
```

**Komut 10: Other Analizi**
```
curl -X POST http://localhost:8080/v1/analyze/other   -H "Content-Type: application/json"   -H "x-user-lang: tr"   -H "x-user-id: demo"   -d '{"observations":[{"id":"S2_E1","value":4}], "confidence":0.7}'
```

**Komut 11: Dyad Raporu**
```
curl -X POST http://localhost:8080/v1/analyze/dyad   -H "Content-Type: application/json"   -H "x-user-lang: tr"   -H "x-user-id: demo"   -d '{"a":{"bigfive":{"E":60,"A":55,"C":70,"N":40,"O":65},"attachment":{"anxiety":50,"avoidance":30},"mbti":{"E":0.6,"S":0.45,"T":0.55,"J":0.7},"conflict":{"COMPETE":45,"COLLAB":65,"COMPROM":55,"AVOID":30,"ACCOM":40}}, "b":{"bigfive":{"E":35,"A":62,"C":58,"N":55,"O":72},"attachment":{"anxiety":40,"avoidance":60},"mbti":{"E":0.35,"S":0.55,"T":0.4,"J":0.5},"conflict":{"COMPETE":35,"COLLAB":62,"COMPROM":50,"AVOID":40,"ACCOM":55}}}'
```

**Komut 12: Coach**
```
curl -X POST http://localhost:8080/v1/coach   -H "Content-Type: application/json"   -H "x-user-lang: tr"   -H "x-user-id: demo"   -d '{"context":"Son konuşmada planlar çakıştı.","goal":"Barışçıl çözüm ve ortak plan"}'
```

### E) Admin — Dil Olayları
**Komut 13:**
```
curl "http://localhost:8080/v1/admin/language-incidents?limit=20"
```

> Not: Çıktı diliniz **kullanıcı dilini** (header `x-user-lang`) izler. Eşleşmezse sunucu 2 kez yeniden dener; olmazsa **banner** mesajı döner ve `language_incidents` tablosuna kayıt atılır.
