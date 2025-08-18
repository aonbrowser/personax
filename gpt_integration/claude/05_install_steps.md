# Kurulum – Genişletilmiş S0 + Geliştirilmiş S1 (DISC + Senaryo + Açık uçlu)

## 1) Sunucu: bağımlılıklar ve veritabanı
```bash
cd server
npm i
cp ../.env.example ../.env  # DATABASE_URL ve OPENAI_API_KEY gir
npm run migrate
```

## 2) Test maddelerini içe aktar (seed)
```bash
npm run seed:items ../data/s0_profile.csv
npm run seed:items ../data/s1_self.csv
```

## 3) Sunucuyu başlat
```bash
npm run dev
# Sağlık: http://localhost:8080/health
# Form kontrol: http://localhost:8080/v1/items/by-form?form=S0_profile
# Form kontrol: http://localhost:8080/v1/items/by-form?form=S1_self
```

## 4) Expo (web/mobil)
```bash
cd ../apps/expo
npm i
npm run web
```
- **Home → Kendi Analizim (S0 → S1)** akışı aktif.
- S0: `OpenText`, `SingleChoice`, `Number`, `MultiSelect`, `RankedMulti` destekli.
- S1: `Likert5`, `MultiChoice5` (senaryo), `OpenText` destekli.

## 5) Skorlama ve rapor (sonraya bağlamak için)
- DISC: `section=DISC`, `subscale=D|I|S|C` → ortalama skorla hesaplayın.
- Senaryoların `scoring_key` alanı çatışma eğilimlerine ipucu verir (`COMPETE|COLLAB|ANX|AVOID|ACCOM`).
- Açık uçlular rapor prompt’unda özetlenerek kullanılmalı (`prompts/context.md`).

> Not: İstersen S2/S3/S4 dosyalarını da aynı `seed:items` ile içeri alıp ekleyebiliriz.
