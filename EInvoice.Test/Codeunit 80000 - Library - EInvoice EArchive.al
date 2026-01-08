codeunit 80000 "Library - EInvoice EArchive"
{
    Permissions = tabledata "PRG_E-Invoice Tax Type Code" = rimd,
                  tabledata "PRG_E-Invoice Setup" = rimd,
                  tabledata "PRG_E-Invoice Integrator Setup" = rimd,
                  tabledata "PRG_E-Invoice Status Code" = rimd;

    procedure CreateEInvTestSetup_Uyumsoft()
    var
        EInvSetup: Record "PRG_E-Invoice Setup";
    begin
        CreateDefaultTaxTypeCodes();

        EInvSetup.Init();
        EInvSetup."E-Invoice Starting Date" := DMY2Date(1, 1, 2020);
        EInvSetup."E-Archive Starting Date" := DMY2Date(1, 1, 2020);
        EInvSetup."E-Invoice No. Series" := CreateEInvoiceNoSeries();
        EInvSetup."E-Archive No. Series" := CreateEArchiveNoSeries();
        EInvSetup."Supplier Tax Registration No." := '9000068418';
        EInvSetup.RegistrationNoType := 'VKN';
        EInvSetup."Success Status Code" := '1000';
        EInvSetup."Default ProfileID" := EInvSetup."Default ProfileID"::Basic;
        EInvSetup."VAT Tax Type Code" := '0015';
        EInvSetup."Sales Exemption Tax Code" := '350';
        EInvSetup.Activated := true;
        if EInvSetup.Insert() then;
    end;

    procedure CreateIntTestSetup_Uyumsoft()
    var
        IntSetup: Record "PRG_E-Invoice Integrator Setup";
    begin
        IntSetup.Init();
        IntSetup."E-Invoice Integrator" := IntSetup."E-Invoice Integrator"::Uyumsoft;
        IntSetup."E-Invoice Int. Auth. URL" := 'https://efatura-test.uyumsoft.com.tr/Services/Integration?wsdl';
        IntSetup."E-Invoice Integrator URL" := 'https://efatura-test.uyumsoft.com.tr/Services/Integration?wsdl';
        IntSetup."E-Invoice Web Service UserName" := 'Uyumsoft';
        IntSetup."E-Invoice Web Service Password" := 'Uyumsoft';

        IntSetup."E-Archive Integrator" := IntSetup."E-Archive Integrator"::Uyumsoft;
        IntSetup."E-Archive Int. Auth. URL" := 'https://efatura-test.uyumsoft.com.tr/Services/Integration?wsdl';
        IntSetup."E-Archive Integrator URL" := 'https://efatura-test.uyumsoft.com.tr/Services/Integration?wsdl';
        IntSetup."E-Archive Web Service UserName" := 'Uyumsoft';
        IntSetup."E-Archive Web Service Password" := 'Uyumsoft';
        if not IntSetup.Insert() then
            IntSetup.Modify();
    end;

    procedure CreateNoSeries(NoSeriesCode: Code[20]; Default: Boolean; Manual: Boolean; DateOrder: Boolean): Code[20]
    var
        NoSeries: Record "No. Series";
    begin
        NoSeries.Validate(Code, NoSeriesCode);
        NoSeries.Validate("Default Nos.", Default);
        NoSeries.Validate("Manual Nos.", Manual);
        NoSeries.Validate("Date Order", DateOrder);
        NoSeries.Insert();
        exit(NoSeriesCode);
    end;

    procedure CreateEInvoiceNoSeries() EInvNoSeries: Code[20]
    begin
        EInvNoSeries := CreateNoSeries('EINV-TEST', true, false, true);
    end;

    procedure CreateEArchiveNoSeries() EArchNoSeries: Code[20]
    begin
        EArchNoSeries := CreateNoSeries('EARCH-TEST', true, false, true);
    end;

    procedure CreateTaxTypeCode(Code: Code[20]; Description: Text[100]; Type: Option; TaxRate: Decimal)
    var
        TaxTypeCode: Record "PRG_E-Invoice Tax Type Code";
    begin
        TaxTypeCode.Init();
        TaxTypeCode.Code := Code;
        TaxTypeCode.Description := Description;
        TaxTypeCode.Type := Type;
        TaxTypeCode."Tax Rate" := TaxRate;
        TaxTypeCode.Insert();
    end;

    procedure CreateDefaultTaxTypeCodes()
    begin
        CreateTaxTypeCode('0015', 'KDV', 0, 18);
        CreateTaxTypeCode('0018', 'KDV', 0, 8);
        CreateTaxTypeCode('0025', 'KDV', 0, 1);
    end;

    procedure InitilazeClient(var Client: HttpClient; var Content: HttpContent; var HeaderContent: HttpHeaders; RequestText: Text; BaseAddress: Text[250])
    begin
        Content.WriteFrom(RequestText);
        Content.GetHeaders(HeaderContent);
        RemoveHeader(HeaderContent, 'Content-Type');
        InitHeaderContent(HeaderContent);
        Client.SetBaseAddress(BaseAddress);
    end;

    procedure RemoveHeader(var HeaderContent: HttpHeaders; _Name: Text)
    begin
        HeaderContent.Remove(_Name);
    end;

    procedure InitHeaderContent(var HeaderContent: HttpHeaders)
    begin
        HeaderContent.Add('Content-Type', 'text/xml;charset=UTF-8');
        HeaderContent.Add('Return-Type', 'text/xml;charset=UTF-8');
    end;
}