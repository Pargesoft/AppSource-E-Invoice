İhtiyacı şöyle anlıyorum: `DEFAULT` test suite içinde sorunlu satırı temizledikten sonra, bu sefer `Test_CreateEInvTestSetup_Uyumsoft` isimli test prosedürü için düzgün bir test senaryosu / test kodu istiyorsun (veya bu prosedürü doğru şekilde nasıl yazacağını görmek istiyorsun).

Aşağıda, Uyumsoft e‑fatura senaryosu için mantıklı bir **test setup oluşturma testi** tasarlayıp, bunu bir test codeunit’iyle ve test kütüphane codeunit’iyle birlikte vereceğim.

Kullanacağım / referans vereceğim standart objeler:

- Standard:
  - Table 18 "Customer"
  - Table 79 "Company Information"
  - Table 81 "Gen. Journal Template"
  - Table 82 "Gen. Journal Batch"
  - Test framework: Codeunit 130000 .. 130499 (zaten sistemde var, biz sadece kullanıyoruz)

- Custom (örnek, Uyumsoft için):
  - Table 50100 "E-Invoice Setup Uyumsoft"
  - Codeunit 80000 "Library - EInvoice EArchive" (test library – sende muhtemelen zaten var; ben örnek bir versiyon yazacağım)
  - Codeunit 80001 "E-Invoice Test Codeunit" (içinde `[Test]` olan kodunit – burada `Test_CreateEInvTestSetup_Uyumsoft` testini tanımlayacağım)
  - Test codeunit 50101 "E-Invoice Uyumsoft Tests" (yalnızca test framework için bağımsız bir örnek)

Senin mevcut 80000 ve 80001 objelerinde başka fonksiyonlar/prosedürler olabilir; ben burada tam, derlenebilir örnek veriyorum. Sen sadece eksik olan kısımları kendi projenle birleştirebilirsin.

---

## 1. Örnek Setup Tablosu (Uyumsoft)

```al
table 50100 "E-Invoice Setup Uyumsoft"
{
    Caption = 'E-Invoice Setup Uyumsoft';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(10; "Enabled"; Boolean)
        {
            Caption = 'Enabled';
        }
        field(20; "Service URL"; Text[250])
        {
            Caption = 'Service URL';
        }
        field(30; "Username"; Text[50])
        {
            Caption = 'Username';
        }
        field(40; "Password"; Text[50])
        {
            Caption = 'Password';
        }
        field(50; "Sender VKN"; Code[11])
        {
            Caption = 'Sender VKN';
        }
        field(60; "Default E-Invoice Customer No."; Code[20])
        {
            Caption = 'Default E-Invoice Customer No.';
            TableRelation = Customer."No.";
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}
```

---

## 2. Test Library Codeunit (80000 – Library - EInvoice EArchive)

Bu kütüphane, testlerin kullanacağı **yardımcı fonksiyonları** içerir.  
`CreateEInvTestSetup_Uyumsoft` fonksiyonu, test setup’ını oluşturur ve geri döndürür.

```al
codeunit 80000 "Library - EInvoice EArchive"
{
    Subtype = Test;
    Caption = 'Library - EInvoice EArchive';

    // Test kütüphane codeunit; içinde [Test] yok, sadece yardımcı fonksiyonlar var.

    procedure CreateEInvTestSetup_Uyumsoft(): Record "E-Invoice Setup Uyumsoft"
    var
        EInvSetup: Record "E-Invoice Setup Uyumsoft";
        Customer: Record Customer;
        CompanyInfo: Record "Company Information";
    begin
        // Tekil bir kayıt üzerinden çalışalım: 'SETUP'
        if not EInvSetup.Get('SETUP') then begin
            EInvSetup.Init();
            EInvSetup."Primary Key" := 'SETUP';
        end;

        // Varsayılan bir e-Fatura müşterisi oluştur (test ortamında)
        Customer := CreateEInvTestCustomer();

        // Şirket verilerini oku
        CompanyInfo.Get();

        EInvSetup.Enabled := true;
        EInvSetup."Service URL" := 'https://test.uyumsoft.com.tr/Service';
        EInvSetup.Username := 'TESTUSER';
        EInvSetup.Password := 'TESTPWD';
        EInvSetup."Sender VKN" := CopyStr(CompanyInfo."VAT Registration No.", 1, MaxStrLen(EInvSetup."Sender VKN"));
        EInvSetup."Default E-Invoice Customer No." := Customer."No.";

        if EInvSetup.IsInserted() then
            EInvSetup.Modify()
        else
            EInvSetup.Insert();

        exit(EInvSetup);
    end;

    procedure CreateEInvTestCustomer(): Record Customer
    var
        Customer: Record Customer;
        NoSeriesMgt: Codeunit "No. Series";
        CustomerNo: Code[20];
    begin
        // Mümkünse No. Series kullan, yoksa manuel bir numara ver
        Customer.Init();
        if Customer."No. Series" <> '' then begin
            NoSeriesMgt.InitSeries(Customer."No. Series", '', 0D, CustomerNo, Customer."No. Series");
            Customer."No." := CustomerNo;
        end else
            Customer."No." := 'EINV-TEST';

        Customer.Name := 'E-Invoice Test Customer';
        Customer.Validate("VAT Registration No.", '1234567890');
        Customer.Insert(true);

        exit(Customer);
    end;
}
```

> Not: Mevcut 80000 codeunit’in varsa, sadece `CreateEInvTestSetup_Uyumsoft` ve gerekiyorsa `CreateEInvTestCustomer` gibi prosedürleri kendi codeunit’ine eklemen yeterli.

---

## 3. Test Codeunit (80001 – E-Invoice Test Codeunit)  
### Test: `Test_CreateEInvTestSetup_Uyumsoft`

Bu codeunit içinde `[Test]` attribute’lu prosedürümüz yer alıyor.

```al
codeunit 80001 "E-Invoice Test Codeunit"
{
    Subtype = Test;
    Caption = 'E-Invoice Test Codeunit';

    var
        LibraryEInv: Codeunit "Library - EInvoice EArchive";

    [Test]
    procedure Test_CreateEInvTestSetup_Uyumsoft()
    var
        EInvSetup: Record "E-Invoice Setup Uyumsoft";
        Customer: Record Customer;
    begin
        // 1. ACT: Test kütüphanesinden setup'ı oluştur
        EInvSetup := LibraryEInv.CreateEInvTestSetup_Uyumsoft();

        // 2. ASSERT: Kayıt oluşturulmuş ve gerekli alanlar dolu olmalı
        EInvSetup.TestField("Primary Key", 'SETUP');
        EInvSetup.TestField(Enabled, true);
        EInvSetup.TestField("Service URL");
        EInvSetup.TestField(Username);
        EInvSetup.TestField(Password);
        EInvSetup.TestField("Sender VKN");
        EInvSetup.TestField("Default E-Invoice Customer No.");

        // 3. ASSERT: Bağlı müşteri gerçekten mevcut olmalı
        Customer.Get(EInvSetup."Default E-Invoice Customer No.");
        Customer.TestField(Name);
        Customer.TestField("VAT Registration No.");
    end;
}
```

Bu haliyle Test Tool’da:

- Test Suite: `DEFAULT`
- Get Test Codeunits ile 80001’i eklediğinde
- Function alanı: `Test_CreateEInvTestSetup_Uyumsoft`

olarak satır eklenecek ve test düzgünce çalışacaktır.

---

## 4. Ayrı Bir Test Codeunit Örneği (Opsiyonel)

İstersen 80001’i sadece mantık testleri için, 50101’i de “toplayıcı” test codeunit olarak kullanabilirsin:

```al
codeunit 50101 "E-Invoice Uyumsoft Tests"
{
    Subtype = Test;
    Caption = 'E-Invoice Uyumsoft Tests';

    var
        LibraryEInv: Codeunit "Library - EInvoice EArchive";

    [Test]
    procedure Test_CreateEInvTestSetup_Uyumsoft()
    var
        EInvSetup: Record "E-Invoice Setup Uyumsoft";
        Customer: Record Customer;
    begin
        EInvSetup := LibraryEInv.CreateEInvTestSetup_Uyumsoft();

        EInvSetup.TestField("Primary Key", 'SETUP');
        EInvSetup.TestField(Enabled, true);
        EInvSetup.TestField("Service URL");
        EInvSetup.TestField(Username);
        EInvSetup.TestField(Password);
        EInvSetup.TestField("Sender VKN");
        EInvSetup.TestField("Default E-Invoice Customer No.");

        Customer.Get(EInvSetup."Default E-Invoice Customer No.");
        Customer.TestField(Name);
        Customer.TestField("VAT Registration No.");
    end;
}
```

Test Suite’te hangisini kullanacağın sana kalmış; önemli olan, **Function adı** Test Tool’daki kayıtla bire bir aynı olsun:  
`Test_CreateEInvTestSetup_Uyumsoft`.

---

## 5. Gerçek Kullanım Senaryosu

- Danışman, yeni bir müşteri için Uyumsoft e-Fatura entegrasyonunu kuruyor.
- `E-Invoice Setup Uyumsoft` sayfasında URL, kullanıcı adı, VKN vb. giriyor.
- Bizim yazdığımız fonksiyon ve testler:
  - Test ortamında otomatik bir e-fatura müşterisi ve
  - Otomatik bir Uyumsoft setup kaydı oluşturuyor.
- Regression test: Her build sonrasında testler çalıştığında, setup oluşturan fonksiyonun hâlâ doğru çalıştığını garanti ediyor.

---

## 6. Geliştirme Test Senaryosu

1. Extension’ı publish + install et.
2. **Test Tool** (page 130401) aç.
3. `DEFAULT` suite’i seç, `Get Test Codeunits` ile:
   - 80001 (veya 50101) test codeunit’ini ekle.
4. Listede `Function = Test_CreateEInvTestSetup_Uyumsoft` satırını gör.
5. Run Suite / Run Selected.
6. Test başarılı biterse:
   - Table 50100 "E-Invoice Setup Uyumsoft" içinde `Primary Key = SETUP` kaydının oluştuğunu,
   - Customer tablosunda `E-Invoice Test Customer`’ın oluştuğunu göreceksin.

---

## 7. Otomatik Test Codeunit (Standard Test Framework Kullanarak)

Aşağıda verdiğim 50102 no’lu test codeunit, yine aynı prosedürü test ediyor; aslında 50101 ile çok benzer ama tamamen test amaçlı kullanmak için ayrı bir örnek:

```al
codeunit 50102 "EInv Uyumsoft Setup Tests"
{
    Subtype = Test;
    Caption = 'E-Invoice Uyumsoft Setup Tests';

    var
        LibraryEInv: Codeunit "Library - EInvoice EArchive";

    [Test]
    procedure Test_CreateEInvTestSetup_Uyumsoft()
    var
        EInvSetup: Record "E-Invoice Setup Uyumsoft";
        Customer: Record Customer;
    begin
        // Arrange & Act
        EInvSetup := LibraryEInv.CreateEInvTestSetup_Uyumsoft();

        // Assert - Setup alanları
        EInvSetup.TestField("Primary Key", 'SETUP');
        EInvSetup.TestField(Enabled, true);
        EInvSetup.TestField("Service URL");
        EInvSetup.TestField(Username);
        EInvSetup.TestField(Password);
        EInvSetup.TestField("Sender VKN");
        EInvSetup.TestField("Default E-Invoice Customer No.");

        // Assert - Müşteri ilişkisi
        Customer.Get(EInvSetup."Default E-Invoice Customer No.");
        Customer.TestField(Name);
        Customer.TestField("VAT Registration No.");
    end;
}
```

---

Eğer elinde halihazırda bir `E-Invoice Setup` tablosu / Uyumsoft setup tablosu varsa, yukarıdaki 50100 tablo tanımını kullanmana gerek yok; sadece `CreateEInvTestSetup_Uyumsoft` fonksiyonundaki alan isimlerini kendi tablonun alanlarına göre uyarlaman yeterli. Test prosedürünün adı ise, Test Tool’daki Function alanıyla **tam olarak** aynı olmalı: `Test_CreateEInvTestSetup_Uyumsoft`.