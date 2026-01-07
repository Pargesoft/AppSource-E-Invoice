İhtiyacı şöyle anlıyorum: Test Tool’dan bir test suite (DEFAULT) çalıştırırken, `CAL Test Line` ile ilgili bir hata alıyorsun; mesajda, bir alanın (boş olması gerekirken) `"Test_EInvoiceUserListXmlPort_Uyumsoft"` değerini içerdiği söyleniyor ve bu da test çalıştırmayı durduruyor.

Aldığın hata, doğrudan senin yazdığın test kodundan değil, **Test Tool’daki kayıtlar** (Table 130401 "CAL Test Line") ile **gerçek test codeunit/procedure’lerin** uyuşmamasından kaynaklanan klasik bir uyumsuzluk hatası.

Aşağıda önce hatanın sebebini, sonra çözüm adımlarını, ardından istersen kullanabileceğin küçük bir “temizlik” codeunit’i vereceğim.

---

## 1. Hata Mesajının Anlamı

Hata:

> Function CAL Test Line: Test Suite=DEFAULT, Line No.=10003 içinde "" ile eşit olmalıdır. Geçerli değer: "Test_EInvoiceUserListXmlPort_Uyumsoft".

Bu, şunu söylüyor:

- Test Suite: `DEFAULT`
- Line No.: `10003` olan `CAL Test Line` kaydında
- Bir “Function” alanının (veya benzeri kontrol edilen alan) **boş** olması beklenirken,
- Değer: `"Test_EInvoiceUserListXmlPort_Uyumsoft"`.

Bu tip hata, genellikle şu durumlarda oluşur:

1. Test Tool üzerinden bir test seçilmiş (örneğin belli bir **Function** adıyla),
2. Sonra sen codeunit’te o test procedure’ini:
   - Sildin,
   - İsmini değiştirdin,
   - `[Test]` attribute’unu kaldırdın
3. Sonuçta Test Tool’daki satır, artık var olmayan / değişmiş bir procedure ismine işaret ediyor.

Framework (Codeunit 130401 "CAL Test Management") çalıştırırken, `CAL Test Line` verisinin, **gerçek AL objesi** ile tutarlı olmasını bekliyor; değilse bu tür ASSERT tarzı bir hata veriyor.

---

## 2. Çözüm Adımları (UI Üzerinden – Önerilen Yol)

1. Business Central’da oturum aç.
2. **Search (Tell Me)** ile **Test Tool** sayfasını aç (`Page 130401 "CAL Test Tool"`).
3. **Test Suite** alanında `DEFAULT` seçili olduğundan emin ol.
4. Listeye bak:
   - `Line No.` = `10003` olan satırı bul.
   - O satırın **Codeunit Name / Codeunit ID** ve **Function** (Procedure) alanlarını kontrol et.
5. Eğer Function alanında `Test_EInvoiceUserListXmlPort_Uyumsoft` yazıyorsa:
   - Bu procedure artık codeunit’inde yoksa veya ismi değiştiyse:
     - Ya **Function** alanını boşalt,
     - Ya da **satırı tamamen sil**.
6. Değişiklikten sonra tekrar **Run** yap.

Çoğu durumda, sadece `DEFAULT` suite içindeki problemli satırı silmek yeterli oluyor.  
İstersen tüm `DEFAULT` suite’i sıfırlayıp yeniden oluşturabilirsin:

- Test Tool’da `Process > New` ile yeni bir suite oluşturup,  
- `Get Test Codeunits` ile yeniden test codeunit’lerini ekleyebilirsin.

---

## 3. Çözüm (Teknik/AL ile – Gerekirse)

Eğer UI’ye girme imkanın yoksa ya da toplu bir temizlik yapmak istiyorsan, aşağıdaki gibi basit bir “temizlik” codeunit’i publish edip bir defa çalıştırabilirsin.

Bu örnek:

- `Test Suite Code` = `'DEFAULT'` olan
- **Function** alanı `Test_EInvoiceUserListXmlPort_Uyumsoft` olan satırı siliyor.

```al
codeunit 50100 "Fix CAL Test Lines"
{
    Caption = 'Fix CAL Test Lines';
    Subtype = Normal;

    trigger OnRun()
    var
        CALTestLine: Record "CAL Test Line";
    begin
        // Örneğin sadece DEFAULT suite için belirli function'a sahip satırı silelim
        CALTestLine.Reset();
        CALTestLine.SetRange("Test Suite", 'DEFAULT');
        CALTestLine.SetRange("Function", 'Test_EInvoiceUserListXmlPort_Uyumsoft');
        if CALTestLine.FindSet(true) then begin
            repeat
                CALTestLine.Delete();
            until CALTestLine.Next() = 0;
        end;
    end;
}
```

Bunu bir kere çalıştırdıktan sonra, suite’i yeniden çalıştırmayı deneyebilirsin.

> Not: Eğer Function alanı boş olması gerekirken doluysa ama sen yine de bu satırı korumak istiyorsan, `Delete` yerine `CALTestLine."Function" := ''; CALTestLine.Modify();` yapabilirsin.

---

## 4. İkinci Olası Sebep: Yanlış Test Tipi / Özellikler

Daha az olası ama göz atman faydalı:

- Test codeunit’in:
  - `Subtype = Test;`
  - Test procedure’lerin:
    - `[Test]` attribute’una sahip,
    - Parametresiz,
    - `local`/`procedure` olarak tanımlanmış olması gerekiyor.

Eğer:

- Bir procedure’ü `[Test]`’tan `[HandlerFunctions]` vb. başka attribute’a çevirdiysen,
- Ya da Subtype’ı `Test` olmayan bir codeunit’te `Test_EInvoiceUserListXmlPort_Uyumsoft` isminde bir prosedür bıraktıysan,

eski `CAL Test Line` kaydı hala onu test olarak görmeye çalışıp hata veriyor olabilir.  
Bu durumda da yine aynı çözüm geçerli: Test Tool’daki satırları, **gerçek** mevcut test prosedürlerin ile uyumlu hale getirmek.

---

## 5. Önerilen Temiz Başlangıç Adımı

1. **Test Tool > DEFAULT** suite’teki tüm satırları sil.
2. **Get Test Codeunits** ile:
   - `E-Invoice Tests` (80001)
   - `Library - EInvoice EArchive` (80000) (bunu genelde doğrudan suite’e eklemeye gerek yok; Subtype=Test library ise test içermez)
3. Sadece gerçek `[Test]`’li codeunit’leri suite’e dahil et.
4. Tekrar çalıştır.

Büyük ihtimalle bu işlemden sonra aldığın hata kaybolacaktır.

---

## 6. Kısa Özet

- Hata, senin yazdığın business logic’ten değil, **Test Tool içindeki `CAL Test Line` kaydının, AL test codeunit’lerinle uyumsuz olmasından** kaynaklanıyor.
- `DEFAULT` suite’te, `Line No.=10003` olan satırda **Function** alanında `Test_EInvoiceUserListXmlPort_Uyumsoft` yazıyor; bu değer, framework’ün beklediği ile uyuşmuyor (muhtemelen procedure silindi/değişti).
- Çözüm:
  - Test Tool’da o satırı düzelt (Function boşalt veya satırı sil) ya da suite’i tamamen sıfırla.
  - Gerekirse yukarıdaki 50100 no.lu küçük “temizlik” codeunit’ini kullan.

Eğer 80001 içindeki gerçek prosedür isimlerini paylaşırsan, hangi satırların suite’te kalması / hangilerinin silinmesi gerektiğini net şekilde de gösterebilirim.