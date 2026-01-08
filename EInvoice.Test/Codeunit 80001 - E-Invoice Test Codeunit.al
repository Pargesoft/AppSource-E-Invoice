codeunit 80001 "E-Invoice Test Codeunit"
{
    Subtype = Test;
    TestType = UnitTest;
    Permissions = tabledata "PRG_E-Invoice Tax Type Code" = rimd,
                  tabledata "PRG_E-Invoice Setup" = rimd,
                  tabledata "PRG_E-Invoice Integrator Setup" = rimd,
                  tabledata "PRG_E-Invoice Status Code" = rimd;

    [Test]
    procedure Test_CreateEInvTestSetup_Uyumsoft()
    var
        EInvEArchLib: Codeunit "Library - EInvoice EArchive";
        EInvSetup: Record "PRG_E-Invoice Setup";
        Assert: Codeunit "Library Assert";
    begin
        EInvEArchLib.CreateEInvTestSetup_Uyumsoft();
        EInvSetup.Get();
        Assert.AreEqual(DMY2Date(1, 1, 2020), EInvSetup."E-Invoice Starting Date", 'E-Invoice Starting Date is not set correctly.');
        Assert.AreEqual(DMY2Date(1, 1, 2020), EInvSetup."E-Archive Starting Date", 'E-Archive Starting Date is not set correctly.');
        Assert.AreEqual('EINV-TEST', EInvSetup."E-Invoice No. Series", 'E-Invoice No. Series is not set correctly.');
        Assert.AreEqual('EARCH-TEST', EInvSetup."E-Archive No. Series", 'E-Archive No. Series is not set correctly.');
        Assert.AreEqual('9000068418', EInvSetup."Supplier Tax Registration No.", 'Supplier Tax Registration No. is not set correctly.');
        Assert.AreEqual('VKN', EInvSetup.RegistrationNoType, 'Registration No Type is not set correctly.');
        Assert.AreEqual('1000', EInvSetup."Success Status Code", 'Success Status Code is not set correctly.');
        Assert.AreEqual(EInvSetup."Default ProfileID"::Basic, EInvSetup."Default ProfileID", 'Default ProfileID is not set correctly.');
        Assert.AreEqual('0015', EInvSetup."VAT Tax Type Code", 'VAT Tax Type Code is not set correctly.');
        Assert.AreEqual('350', EInvSetup."Sales Exemption Tax Code", 'Sales Exemption Tax Code is not set correctly.');
        Assert.AreEqual(true, EInvSetup.Activated, 'E-Invoice Setup is not activated.');
    end;

    [Test]
    procedure Test_CreateIntTestSetup_Uyumsoft()
    var
        EInvEArchLib: Codeunit "Library - EInvoice EArchive";
        IntSetup: Record "PRG_E-Invoice Integrator Setup";
        Assert: Codeunit "Library Assert";
    begin
        EInvEArchLib.CreateIntTestSetup_Uyumsoft();
        IntSetup.Get();
        Assert.AreEqual(IntSetup."E-Invoice Integrator"::Uyumsoft, IntSetup."E-Invoice Integrator", 'E-Invoice Integrator is not set correctly.');
        Assert.AreEqual('https://efatura-test.uyumsoft.com.tr/Services/Integration?wsdl', IntSetup."E-Invoice Int. Auth. URL", 'E-Invoice Int. Auth. URL is not set correctly.');
        Assert.AreEqual('https://efatura-test.uyumsoft.com.tr/Services/Integration?wsdl', IntSetup."E-Invoice Integrator URL", 'E-Invoice Integrator URL is not set correctly.');
        Assert.AreEqual('Uyumsoft', IntSetup."E-Invoice Web Service UserName", 'E-Invoice Web Service UserName is not set correctly.');
        Assert.AreEqual('Uyumsoft', IntSetup."E-Invoice Web Service Password", 'E-Invoice Web Service Password is not set correctly.');
        Assert.AreEqual(IntSetup."E-Archive Integrator"::Uyumsoft, IntSetup."E-Archive Integrator", 'E-Archive Integrator is not set correctly.');
        Assert.AreEqual('https://efatura-test.uyumsoft.com.tr/Services/Integration?wsdl', IntSetup."E-Archive Int. Auth. URL", 'E-Archive Int. Auth. URL is not set correctly.');
        Assert.AreEqual('https://efatura-test.uyumsoft.com.tr/Services/Integration?wsdl', IntSetup."E-Archive Integrator URL", 'E-Archive Integrator URL is not set correctly.');
        Assert.AreEqual('Uyumsoft', IntSetup."E-Archive Web Service UserName", 'E-Archive Web Service UserName is not set correctly.');
        Assert.AreEqual('Uyumsoft', IntSetup."E-Archive Web Service Password", 'E-Archive Web Service Password is not set correctly.');
    end;

    [Test]
    procedure Test_EInvoiceUserListXmlPort_Uyumsoft()
    var
        LiableComp: Record "PRG_E-Invoice Liable Companies";
        Connector: Codeunit "PRG_E-Invoice WB Connector";
        Assert: Codeunit "Library Assert";
        EInvEArchLib: Codeunit "Library - EInvoice EArchive";
    begin
        Connector.QueryUpdateEInvoiceListXmlPort();
        LiableComp.SetRange(Identifier, '90000684181111');
        if not LiableComp.FindFirst() then
            Assert.Fail('E-Invoice Liable Company with Identifier 90000684181111 not found after XML Port execution.');
    end;

    [Test]
    procedure Test_TestConnection_Uyumsoft()
    var
        Cust: Record Customer;
        Vend: Record Vendor;
        InvSetup: Record "PRG_E-Invoice Setup";
        IntSetup: Record "PRG_E-Invoice Integrator Setup";
        CVInfo: Record "PRG_E-Invoice CV Info.";
        Xmlbuffer: Record "XML Buffer" temporary;
        LiableComp: Record "PRG_E-Invoice Liable Companies";
        Assert: Codeunit "Library Assert";
        EInvEArchLib: Codeunit "Library - EInvoice EArchive";
        Client: HttpClient;
        Content: HttpContent;
        HeaderContent: HttpHeaders;
        Response: HttpResponseMessage;
        EntryNo: Integer;
        ResponseText, varSoapTxt, ResponseTxt, SystemCreateDateTxt, TitleTxt, TypeTxt : Text;
    begin
        InvSetup.Get();
        IntSetup.Get();

        varSoapTxt := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/">'
                    + ' <soapenv:Header>'
                    + '      <wsse:Security soapenv:mustUnderstand="1" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">'
                    + '          <wsse:UsernameToken>'
                    + '              <wsse:Username>' + IntSetup."E-Invoice Web Service UserName" + '</wsse:Username>'
                    + '               <wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText">' + IntSetup."E-Invoice Web Service Password" + '</wsse:Password>'
                    + '            </wsse:UsernameToken>'
                    + '        </wsse:Security>'
                    + '    </soapenv:Header>'
                    + '<soapenv:Body>'
                    + '<tem:TestConnection/>'
                    + '</soapenv:Body>'
                    + '</soapenv:Envelope>';

        EInvEArchLib.InitilazeClient(Client, Content, HeaderContent, varSoapTxt, IntSetup."E-Invoice Integrator URL");
        HeaderContent.Add('SOAPAction', 'http://tempuri.org/IIntegration/TestConnection');
        IF not Client.Post(IntSetup."E-Invoice Integrator URL", Content, Response) then
            Assert.Fail('Test Connection Fail!');
    end;

}