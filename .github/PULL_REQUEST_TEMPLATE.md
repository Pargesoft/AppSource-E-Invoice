## Azure DevOps Work Item
<!-- Zorunlu: AB#248 formatında -->
AB#

---

## Fonksiyonel Özet
<!-- Danışman ve Product Owner için -->
- 

---

## AppSource Etkisi
<!-- AppSource değerlendirmesi için -->
- [ ] Yeni özellik
- [ ] Kırıcı değişiklik (Breaking change)
- [ ] Veri yükseltmesi gerekiyor
- [ ] Yetki seti değişti

---

## Doğrulama

### CI – Deploy Öncesi (Zorunlu)
<!-- Pull Request aşamasında çalışan testler -->
- [ ] AL-Go CI başarılı (derleme + AL testleri)
- [ ] Page Scripting testleri başarılı (CI)

### QA / Sandbox – Deploy Sonrası
<!-- Ortama alındıktan sonra çalışan otomasyonlar -->
- [ ] QA deploy tamamlandı
- [ ] UI otomasyon testleri başarılı
- [ ] API / entegrasyon testleri başarılı

### Manuel / Fonksiyonel Doğrulama (varsa)
<!-- Danışman / QA -->
- [ ] Fonksiyonel doğrulama tamamlandı
- [ ] Regresyon tespit edilmedi

---

## AppSource Kontrol Listesi
<!-- Microsoft AppSource için kritik -->
- [ ] Sabit (hard-coded) firma / şirket verisi yok
- [ ] Test kodları pakete dahil değil
- [ ] Gerekliyse upgrade codeunit ele alındı
- [ ] App.json versiyonu artırıldı
- [ ] Bağımlılıklar kontrol edildi

---

## Reviewer / Danışman Notları
<!-- Opsiyonel ama çok değerli -->
-
