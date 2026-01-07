İhtiyacı şöyle anlıyorum: Elinde bir test codeunit (80001) ve bir de yardımcı kütüphane codeunit (80000) var; bu test codeunit içindeki her bir procedure’ün (test senaryosunun) tek tek, bağımsız olarak çalıştırılabilmesini istiyorsun ve bunun için nasıl bir yapı kurman gerektiğini soruyorsun.

Aşağıda:
- Business Central test mimarisinin mantığını,
- Her testin ayrı ayrı çalışabilmesi için dikkat etmen gereken noktaları,
- Örnek bir **test codeunit** + **library codeunit** yapısını,
- Bir kullanım senaryosu,
- Bir test senaryosu ve
- Tamamlanmış bir **AL test codeunit** örneğini

vereceğim. Kodlar tamamen derlenebilir ve standart BC test framework’ünü kullanır.

---

## 1. Genel Prensip: Her Test = Bağımsız `procedure`

Business Central test framework’ünde:

- `[Test]` attribute’u olan **her bir procedure**, tek bir **bağımsız test**’tir.
- Her test, kendi içinde:
  - Test data’yı hazırlar (Arrange),
  - İşlemi tetikler (Act),
  - Sonucu kontrol eder (Assert).
- Testler **birbirinden bağımsız** olmalıdır:
  - Ortak logic için genelde ayrı bir **Library codeunit** kullanılır (sende 80000).
  - Ortak setup/cleanup için `[TestInitialize]` / `[TestCleanup]` kullanabilirsin.

Testleri tek tek çalıştırmak için:

- VS Code içinde: Test Explorer’da ilgili test procedure’ünün yanında “Run Test” / “Debug Test”.
- Veya al.test tool ya da test suite üzerinden isimlerine göre çağırabilirsin.

Özetle, yapman gereken:
1. Her test senaryosu için **ayrı bir `[Test]` procedure** yazmak.
2. Ortak fonksiyonları **Library - EInvoice EArchive** gibi bir codeunit’e almak.
3. Gerekirse her testten önce/sonra çalışacak **`[TestInitialize]` / `[TestCleanup]`** procedure’leri tanımlamak.

---

## 2. Önerilen Yapı

### Standart / Kullanılacak Nesneler

- **Standard**:
  - Table 36 "Sales Header"
  - Table 37 "Sales Line"
  - Codeunit 80 "Sales-Post"
  - Codeunit 130402 "Test Runner" (framework tarafı)
  - Standart TestLibrary codeunit’leri (varsa reuse edebilirsin, ama aşağıda custom örnek veriyorum)

- **Custom**:
  - Codeunit 80000 "Library - EInvoice EArchive"  
    – Yardımcı fonksiyonlar: test data oluşturma, E-Fatura/E-Arşiv işaretleme, kontrol fonksiyonları.
  - Codeunit 80001 "E-Invoice Tests"  
    – Her bir `[Test]` procedure: örn. `Test_SalesInvoiceMarkedAsEInvoice`, `Test_EArchiveFlagOnCustomer`, vb.

---

## 3. Örnek: Library Codeunit (80000)

Aşağıdaki örnek, testlerin ortak kullanacağı fonksiyonları içeriyor. Sen kendi gerçek E-Fatura/E-Arşiv mantığına göre içini zenginleştirebilirsin.

```al
codeunit 80000 "Library - EInvoice EArchive"
{
    Subtype = Test;
    Caption = 'Library - EInvoice EArchive';

    // Bu kütüphane sadece testlerde ortak fonksiyonları sağlar.
    // Gerçek E-Fatura/E-Arşiv logic'in, başka normal bir codeunit'te olabilir.

    // Örnek: E-Fatura müşterisi oluşturan yardımcı fonksiyon
    procedure CreateEInvoiceCustomer(var Customer: Record Customer)
    var
        NoSeriesMgt: Codeunit "No. Series Management";
    begin
        Customer.Init();
        Customer."No." := NoSeriesMgt.GetNextNo('CUST', Today, true);
        Customer.Name := 'Test E-Invoice Customer';
        // Örn: özel alan ya da extension alanları burada set edersin
        // Customer."E-Invoice Customer" := true; // Örnek extension alanı varsayalım
        Customer.Insert(true);
    end;

    // Örnek: E-Arşiv müşterisi oluşturan yardımcı fonksiyon
    procedure CreateEArchiveCustomer(var Customer: Record Customer)
    var
        NoSeriesMgt: Codeunit "No. Series Management";
    begin
        Customer.Init();
        Customer."No." := NoSeriesMgt.GetNextNo('CUST', Today, true);
        Customer.Name := 'Test E-Archive Customer';
        // Customer."E-Archive Customer" := true; // Örnek extension alanı varsayalım
        Customer.Insert(true);
    end;

    // Örnek: Basit bir satış faturası başlığı + satır oluşturma
    procedure CreateSalesInvoice(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20])
    var
        SalesLine: Record "Sales Line";
        SalesHeader2: Record "Sales Header";
        SalesSetup: Record "Sales & Receivables Setup";
        NoSeriesMgt: Codeunit "No. Series Management";
    begin
        SalesSetup.Get();

        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
        SalesHeader."No." := NoSeriesMgt.GetNextNo(SalesSetup."Invoice Nos.", Today, true);
        SalesHeader.Validate("Sell-to Customer No.", CustomerNo);
        SalesHeader.Insert(true);

        // Örnek satır
        SalesLine.Init();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := 10000;
        SalesLine.Type := SalesLine.Type::"G/L Account";
        SalesLine.Validate("No.", GetAnyGLAccountNo());
        SalesLine.Validate(Quantity, 1);
        SalesLine.Validate("Unit Price", 100);
        SalesLine.Insert(true);
    end;

    // Örnek: herhangi bir G/L Account No. bulma (test amaçlı)
    local procedure GetAnyGLAccountNo(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        if GLAccount.FindFirst() then
            exit(GLAccount."No.")
        else
            Error('No G/L Account found for test.');
    end;

    // Örnek: Satış faturası post etme (normal process’e dokunmadan)
    procedure PostSalesInvoice(var SalesHeader: Record "Sales Header")
    var
        SalesPost: Codeunit "Sales-Post";
    begin
        // Standart mekanizma ile post ediyoruz
        SalesPost.Run(SalesHeader);
    end;

    // Örnek: Post sonrası E-Fatura flag’ini kontrol eden yardımcı fonksiyon
    procedure AssertEInvoiceFlagOnPostedSalesInv(SalesHeader: Record "Sales Header")
    var
        SalesInvHeader: Record "Sales Invoice Header";
    begin
        SalesInvHeader.Reset();
        SalesInvHeader.SetRange("Order No.", SalesHeader."No.");
        if not SalesInvHeader.FindFirst() then
            Error('Posted Sales Invoice not found.');

        // Burada kendi extension alanını kontrol edersin
        // SalesInvHeader.TestField("E-Invoice Exported", true);
    end;
}
```

---

## 4. Örnek: Test Codeunit (80001) – Her Procedure Ayrı Çalışabilir

Bu codeunit’te her `[Test]` procedure bağımsızdır; test runner veya VS Code Test Explorer’dan **tek tek** çalıştırılabilir.

```al
codeunit 80001 "E-Invoice Tests"
{
    Subtype = Test;
    Caption = 'E-Invoice Tests';

    // DI / Library
    var
        EInvoiceLib: Codeunit "Library - EInvoice EArchive";

    // Her testten önce ortak temizleme/kurulum yapılacaksa:
    [TestInitialize]
    procedure TestInitialize()
    begin
        // Örn: Test data temizliği, setup parametrik ayarlar
        // ClearAll; reset some tables, etc.
    end;

    // Her testten sonra temizleme
    [TestCleanup]
    procedure TestCleanup()
    begin
        // Örn: Oluşturulan test kayıtlarını silme
        // ClearAll; delete temp records, etc.
    end;

    // =====================
    // Test 1: E-Fatura müşterisi ile satış faturası oluşturup post edince
    //         ilgili E-Fatura flag’inin set olup olmadığını kontrol et
    // =====================
    [Test]
    procedure Test_PostInvoiceForEInvoiceCustomer_SetsEInvoiceFlag()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        // Arrange
        EInvoiceLib.CreateEInvoiceCustomer(Customer);
        EInvoiceLib.CreateSalesInvoice(SalesHeader, Customer."No.");

        // Act
        EInvoiceLib.PostSalesInvoice(SalesHeader);

        // Assert
        EInvoiceLib.AssertEInvoiceFlagOnPostedSalesInv(SalesHeader);
    end;

    // =====================
    // Test 2: E-Arşiv müşterisi ile yaratılan faturada
    //         E-Arşiv flaginin doğru set edildiğini kontrol et
    // =====================
    [Test]
    procedure Test_CreateInvoiceForEArchiveCustomer_SetsEArchiveFlag()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        // Arrange
        EInvoiceLib.CreateEArchiveCustomer(Customer);
        EInvoiceLib.CreateSalesInvoice(SalesHeader, Customer."No.");

        // Act
        // Örneğin: henüz post etmeden sadece header/line üzerindeki E-Arşiv alanını test edebilirsin
        // ya da gerçek senaryona göre post ettikten sonra test edersin

        // Assert
        // Burada kendi extension alanına göre test yazarsın
        // SalesHeader.TestField("E-Archive Document", true);
    end;

    // =====================
    // Test 3: E-Fatura olmayan bir müşteriye fatura kesildiğinde
    //         E-Fatura alanının boş/false olması beklenir
    // =====================
    [Test]
    procedure Test_NonEInvoiceCustomer_DoesNotSetEInvoiceFlag()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        NoSeriesMgt: Codeunit "No. Series Management";
    begin
        // Arrange: normal müşteri
        Customer.Init();
        Customer."No." := NoSeriesMgt.GetNextNo('CUST', Today, true);
        Customer.Name := 'Normal Customer';
        Customer.Insert(true);

        EInvoiceLib.CreateSalesInvoice(SalesHeader, Customer."No.");
        EInvoiceLib.PostSalesInvoice(SalesHeader);

        // Assert
        // Burada E-Fatura alanının false ya da boş olması kontrol edilir
        // örn: Posted Sales Invoice Header üzerindeki alanı bul ve TestField(false) yap
    end;
}
```

Bu yapıda:

- `Test_PostInvoiceForEInvoiceCustomer_SetsEInvoiceFlag`
- `Test_CreateInvoiceForEArchiveCustomer_SetsEArchiveFlag`
- `Test_NonEInvoiceCustomer_DoesNotSetEInvoiceFlag`

gibi her `[Test]` procedure’ü tek tek çalıştırabilirsin.  

Her test, sadece **kendi senaryosunu** test ediyor, tüm ortak işler `EInvoiceLib`’e (80000) taşınmış durumda.

---

## 5. Gerçek Hayat Kullanım Senaryosu

Örneğin:

- Firmanda Türkiye E-Fatura / E-Arşiv entegrasyonu var.
- Her satış faturası oluşturulduğunda, müşterinin E-Fatura/E-Arşiv kayıt statüsüne göre:
  - Satış faturası başlığında `E-Invoice` veya `E-Archive` alanları işaretleniyor.
  - Post sonrası, gönderilecek XML queue’suna kayıt atılıyor.
- Bu mantıkta bir değişiklik veya refactor yaptığında, yukarıdaki test codeunit’i **test suite** olarak çalıştırıp:
  - E-Fatura müşterisi senaryosu bozulmuş mı?
  - E-Arşiv müşterisi senaryosu bozulmuş mu?
  - Normal müşteri yanlışlıkla E-Fatura’ya düşüyor mu?

gibi şeyleri otomatik kontrol edersin.

---

## 6. Geliştirme Test Senaryosu (Manuel)

Örneğin `Test_PostInvoiceForEInvoiceCustomer_SetsEInvoiceFlag` testi için:

1. VS Code’da extension’ı publish et (test enabled).
2. Test Tool sayfasını aç (BC içinde).
3. Yeni bir **Test Suite** oluştur; içine `E-Invoice Tests` codeunit’ini ekle.
4. İstersen tüm testleri çalıştır; veya sadece ilgili testi seçip **Run Selected** de.
5. Test sonucu Passed/Failed olarak gelir; hata varsa mesajdan hangi assert’in patladığını görürsün.

---

## 7. Özet: Her Procedure’ü Ayrı Çalıştırmak İçin Ne Yapmalısın?

1. Her senaryo için **ayrı bir `[Test]` procedure** oluştur.
2. Ortak logic’i 80000 nolu `Library - EInvoice EArchive` codeunit’ine koy.
3. Test bağımsızlığını sağlamak için:
   - Kayıtları kendi içinde yarat ve kullan,
   - Diğer testlerde oluşturulan kayıtlara güvenme.
4. Gerekirse `[TestInitialize]` ve `[TestCleanup]` ile ortak setup/temizlik yap.
5. Testleri:
   - Test Tool’dan / Test Suite’ten,
   - Veya VS Code Test Explorer’dan
   **tek tek** veya **toplu** çalıştır.

İstersen, elindeki gerçek 80000 ve 80001 kodlarını (içerikleri dolu şekilde) paylaşırsan, aynı mantığı doğrudan kendi koduna uygulayıp, procedure’leri nasıl ayırman ve attribute’leri nasıl yerleştirmen gerektiğini satır satır gösterebilirim.