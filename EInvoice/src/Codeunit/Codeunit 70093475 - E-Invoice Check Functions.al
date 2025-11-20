codeunit 70093475 "PRG_E-Invoice Check Functions"
{
    trigger OnRun()
    begin
    end;

    var
        ExportSetup: Record "PRG_E-Export Setup";
        EInvSetup: Record "PRG_E-Invoice Setup";
        TaxType: Record "PRG_E-Invoice Tax Type Code";
        Library: Codeunit "PRG_E-Invoice Library";
        EInvSetupGot: Boolean;
        GotExportSetup: Boolean;
        Text001: Label '%1 %2 %3 is empty. Do you want to continue?';
        Text002: Label 'For E-Export invoices you can only use following options : %1 ,%2';
        Text003: Label 'You can only choose certaion options. %1,%2';

    procedure CheckFieldChangesForEPlatformTypeForPurch(Rec: Record "Purchase Header"; xRec: Record "Purchase Header")
    begin
        IF NOT (Rec."Document Type" IN [Rec."Document Type"::"Return Order", Rec."Document Type"::"Credit Memo"]) THEN
            EXIT;

        IF FORMAT(Rec) = FORMAT(xRec) THEN
            EXIT;

        IF xRec."PRG_E-Platform Type" = xRec."PRG_E-Platform Type"::" " THEN
            Rec.TESTFIELD("PRG_E-Platform Type", Rec."PRG_E-Platform Type"::" ");

        IF xRec."PRG_E-Platform Type" = xRec."PRG_E-Platform Type"::EArchive THEN
            IF NOT (Rec."PRG_E-Platform Type" IN [Rec."PRG_E-Platform Type"::EArchive, Rec."PRG_E-Platform Type"::FreeZone]) THEN
                ERROR(Text003, Rec."PRG_E-Platform Type"::EArchive, Rec."PRG_E-Platform Type"::FreeZone);

        IF xRec."PRG_E-Platform Type" = xRec."PRG_E-Platform Type"::EInvoice THEN
            IF NOT (Rec."PRG_E-Platform Type" IN [Rec."PRG_E-Platform Type"::EArchive, Rec."PRG_E-Platform Type"::FreeZone]) THEN
                ERROR(Text003, Rec."PRG_E-Platform Type"::EInvoice, Rec."PRG_E-Platform Type"::FreeZone);

        IF (xRec."PRG_E-Platform Type" = xRec."PRG_E-Platform Type"::EExport) AND
            NOT (Rec."PRG_E-Platform Type" IN [Rec."PRG_E-Platform Type"::EExport, Rec."PRG_E-Platform Type"::FreeZone, Rec."PRG_E-Platform Type"::MicroExport]) THEN
            ERROR(Text002, Rec."PRG_E-Platform Type"::EExport, Rec."PRG_E-Platform Type"::MicroExport);


        Library.CreateEExportDocumentScopeLog(2, Rec."No.", 2, Rec."Pay-to Vendor No.", Rec."Posting Date", FORMAT(xRec."PRG_E-Platform Type"), FORMAT(Rec."PRG_E-Platform Type"));
    end;

    procedure CheckFieldChangesForEPlatformTypeForSales(Rec: Record "Sales Header"; xRec: Record "Sales Header")
    begin
        IF NOT (Rec."Document Type" IN [Rec."Document Type"::Order, Rec."Document Type"::Invoice]) THEN
            EXIT;

        IF FORMAT(Rec) = FORMAT(xRec) THEN
            EXIT;

        IF xRec."PRG_E-Platform Type" = xRec."PRG_E-Platform Type"::" " THEN
            Rec.TESTFIELD("PRG_E-Platform Type", Rec."PRG_E-Platform Type"::" ");

        IF xRec."PRG_E-Platform Type" = xRec."PRG_E-Platform Type"::EArchive THEN
            IF NOT (Rec."PRG_E-Platform Type" IN [Rec."PRG_E-Platform Type"::EArchive, Rec."PRG_E-Platform Type"::FreeZone, Rec."PRG_E-Platform Type"::MicroExport]) THEN
                ERROR(Text003, Rec."PRG_E-Platform Type"::EArchive, Rec."PRG_E-Platform Type"::FreeZone);

        IF xRec."PRG_E-Platform Type" = xRec."PRG_E-Platform Type"::EInvoice THEN
            IF NOT (Rec."PRG_E-Platform Type" IN [Rec."PRG_E-Platform Type"::EArchive, Rec."PRG_E-Platform Type"::FreeZone, Rec."PRG_E-Platform Type"::MicroExport]) THEN
                ERROR(Text003, Rec."PRG_E-Platform Type"::EInvoice, Rec."PRG_E-Platform Type"::FreeZone);

        IF (xRec."PRG_E-Platform Type" = xRec."PRG_E-Platform Type"::EExport) AND
            NOT (Rec."PRG_E-Platform Type" IN [Rec."PRG_E-Platform Type"::EExport, Rec."PRG_E-Platform Type"::FreeZone, Rec."PRG_E-Platform Type"::MicroExport]) THEN
            ERROR(Text002, Rec."PRG_E-Platform Type"::EExport, Rec."PRG_E-Platform Type"::MicroExport);

        Library.CreateEExportDocumentScopeLog(1, Rec."No.", 1, Rec."Bill-to Customer No.", Rec."Posting Date", FORMAT(xRec."PRG_E-Platform Type"), FORMAT(Rec."PRG_E-Platform Type"));
    end;

    procedure CheckIfEditable()
    begin
        GetEInvSetup();
        EInvSetup.TESTFIELD("Allow E-Invoice Change");
    end;

    procedure EInvoiceTaxCodeControl_PurchHeader(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        IsHandled: Boolean;
    begin
        GetEInvSetup();
        IF NOT EInvSetupGot THEN
            EXIT;

        if not EInvSetup."Control TaxTypeCode for P&SCr." then
            IF NOT (PurchaseHeader."Document Type" IN [PurchaseHeader."Document Type"::"Credit Memo", PurchaseHeader."Document Type"::"Return Order"]) THEN
                EXIT;

        IF PurchaseHeader."PRG_E-Platform Type" IN [PurchaseHeader."PRG_E-Platform Type"::" ", PurchaseHeader."PRG_E-Platform Type"::EExport, PurchaseHeader."PRG_E-Platform Type"::FreeZone] THEN
            EXIT;


        OnBeforeCheckPurchTaxTypeCode(PurchaseHeader, PurchaseLine, IsHandled);
        if IsHandled then
            exit;

        PurchaseLine.SETRANGE("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SETRANGE("Document No.", PurchaseHeader."No.");
        PurchaseLine.SETFILTER(PurchaseLine.Type, '<>%1', PurchaseLine.Type::" ");
        IF PurchaseLine.ISEMPTY THEN
            EXIT;

        PurchaseLine.FINDSET();
        REPEAT

            CASE TRUE OF
                (PurchaseLine."Amount Including VAT" - PurchaseLine.Amount = 0) AND (PurchaseLine."PRG_E-Invoice Tax Type Code" = ''):
                    BEGIN
                        CASE EInvSetup."Exception Control in Posting" OF
                            EInvSetup."Exception Control in Posting"::Allow:
                                EXIT;
                            EInvSetup."Exception Control in Posting"::NotAllow:
                                PurchaseLine.TESTFIELD("PRG_E-Invoice Tax Type Code");
                            EInvSetup."Exception Control in Posting"::Warning:
                                BEGIN
                                    IF NOT CONFIRM(STRSUBSTNO(Text001, PurchaseLine.FIELDCAPTION("Line No."), PurchaseLine."Line No.", PurchaseLine.FIELDCAPTION("PRG_E-Invoice Tax Type Code"))) THEN
                                        ERROR('');
                                END;
                        END;
                    END;

                (PurchaseLine."Amount Including VAT" - PurchaseLine.Amount > 0) AND (PurchaseLine."PRG_E-Invoice Tax Type Code" <> ''):
                    BEGIN
                        TaxType.GET(PurchaseLine."PRG_E-Invoice Tax Type Code");
                        IF (TaxType.Type = TaxType.Type::ExceptionCode) THEN
                            PurchaseLine.TESTFIELD("PRG_E-Invoice Tax Type Code", '');
                    END;
            END;

        UNTIL PurchaseLine.NEXT() = 0;
    end;

    procedure EInvoiceTaxCodeControl_SalesHeader(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        IsHandled: Boolean;
    begin
        GetEInvSetup();
        IF NOT EInvSetupGot THEN
            EXIT;
        if not EInvSetup."Control TaxTypeCode for P&SCr." then
            IF NOT (SalesHeader."Document Type" IN [SalesHeader."Document Type"::Invoice, SalesHeader."Document Type"::Order]) THEN
                EXIT;

        IF SalesHeader."PRG_E-Platform Type" IN [SalesHeader."PRG_E-Platform Type"::" ", SalesHeader."PRG_E-Platform Type"::EExport, SalesHeader."PRG_E-Platform Type"::FreeZone] THEN
            EXIT;



        OnAfterCheckSalesTaxTypeCode(SalesHeader, SalesLine, IsHandled);
        if IsHandled then
            exit;

        SalesLine.SETRANGE("Document Type", SalesHeader."Document Type");
        SalesLine.SETRANGE("Document No.", SalesHeader."No.");
        SalesLine.SETFILTER(SalesLine.Type, '<>%1', SalesLine.Type::" ");
        IF SalesLine.ISEMPTY THEN
            EXIT;

        SalesLine.FINDSET();
        REPEAT
            CASE TRUE OF
                (SalesLine."Amount Including VAT" - SalesLine.Amount = 0) AND (SalesLine."PRG_E-Invoice Tax Type Code" = ''):
                    BEGIN
                        CASE EInvSetup."Exception Control in Posting" OF
                            EInvSetup."Exception Control in Posting"::Allow:
                                EXIT;
                            EInvSetup."Exception Control in Posting"::NotAllow:
                                SalesLine.TESTFIELD("PRG_E-Invoice Tax Type Code");
                            EInvSetup."Exception Control in Posting"::Warning:
                                BEGIN
                                    IF NOT CONFIRM(STRSUBSTNO(Text001, SalesLine.FIELDCAPTION("Line No."), SalesLine."Line No.", SalesLine.FIELDCAPTION("PRG_E-Invoice Tax Type Code"))) THEN
                                        ERROR('');
                                END;
                        END;
                    END;

                (SalesLine."Amount Including VAT" - SalesLine.Amount > 0) AND (SalesLine."PRG_E-Invoice Tax Type Code" <> ''):
                    BEGIN
                        TaxType.GET(SalesLine."PRG_E-Invoice Tax Type Code");
                        IF (TaxType.Type = TaxType.Type::ExceptionCode) THEN
                            SalesLine.TESTFIELD("PRG_E-Invoice Tax Type Code", '');
                    END;
            END;

        UNTIL SalesLine.NEXT() = 0;
    end;

    procedure CheckFieldForSalesPost(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        IsHandled: Boolean;
    begin
        IF NOT (SalesHeader."Document Type" IN [SalesHeader."Document Type"::Order,
                                                SalesHeader."Document Type"::Invoice]) THEN
            EXIT;

        GetEInvSetup();
        IF NOT EInvSetup.Activated then
            exit;

        GetExportSetup();
        IF NOT ExportSetup.Activated THEN
            EXIT;

        OnBeforeCheckFieldForSalesPost(SalesHeader, SalesLine, IsHandled);

        ExportSetup.TESTFIELD("E-Export Starting Date");
        ExportSetup.TESTFIELD("Company Country/Region Code");
        ExportSetup.TESTFIELD("Default Exemption Tax Code");

        IF SalesHeader."Posting Date" < ExportSetup."E-Export Starting Date" THEN
            EXIT;

        IF (SalesHeader."Bill-to Country/Region Code" IN [ExportSetup."Company Country/Region Code", '']) AND (SalesHeader."PRG_E-Platform Type" <> SalesHeader."PRG_E-Platform Type"::FreeZone) THEN
            EXIT;

        IF SalesHeader."PRG_E-Platform Type" = SalesHeader."PRG_E-Platform Type"::MicroExport THEN
            EXIT;

        SalesLine.SETRANGE("Document Type", SalesHeader."Document Type");
        SalesLine.SETRANGE("Document No.", SalesHeader."No.");
        SalesLine.SETFILTER(Type, '%1|%2', SalesLine.Type::Item, SalesLine.Type::"G/L Account");
        IF SalesLine.ISEMPTY THEN
            EXIT;

        SalesHeader.TestField("Shipment Method Code");
        SalesHeader.TestField("Transport Method");
        SalesHeader.TestField("Bill-to County");

        IF SalesLine.FINDSET() THEN
            REPEAT
                SalesLine.TESTFIELD("PRG_Tariff Number");
                IF SalesLine."PRG_E-Invoice Tax Type Code" = '' THEN BEGIN
                    SalesLine.VALIDATE("PRG_E-Invoice Tax Type Code", ExportSetup."Default Exemption Tax Code");
                    SalesLine.MODIFY();
                END;
            UNTIL SalesLine.NEXT() = 0;
    end;

    procedure CheckFieldForPurchPost(var PurchaseHeader: Record "Purchase Header")
    var
        PurchLine: Record "Purchase Line";
        IsHandled: Boolean;
    begin
        IF NOT (PurchaseHeader."Document Type" IN [PurchaseHeader."Document Type"::"Return Order",
                                                   PurchaseHeader."Document Type"::"Credit Memo"]) THEN
            EXIT;

        GetEInvSetup();
        IF NOT EInvSetup.Activated then
            exit;

        GetExportSetup();
        IF NOT ExportSetup.Activated THEN
            EXIT;

        OnBeforeCheckFieldForPurchPost(PurchaseHeader, PurchLine, IsHandled);

        ExportSetup.TESTFIELD("E-Export Starting Date");
        ExportSetup.TESTFIELD("Company Country/Region Code");
        ExportSetup.TESTFIELD("Default Exemption Tax Code");

        IF PurchaseHeader."Posting Date" < ExportSetup."E-Export Starting Date" THEN
            EXIT;

        IF (PurchaseHeader."Pay-to Country/Region Code" IN [ExportSetup."Company Country/Region Code", '']) AND (PurchaseHeader."PRG_E-Platform Type" <> PurchaseHeader."PRG_E-Platform Type"::FreeZone) THEN
            EXIT;

        IF PurchaseHeader."PRG_E-Platform Type" = PurchaseHeader."PRG_E-Platform Type"::MicroExport THEN
            EXIT;

        PurchLine.SETRANGE("Document Type", PurchaseHeader."Document Type");
        PurchLine.SETRANGE("Document No.", PurchaseHeader."No.");
        PurchLine.SETFILTER(Type, '%1|%2', PurchLine.Type::Item, PurchLine.Type::"G/L Account");
        IF PurchLine.ISEMPTY THEN
            EXIT;

        PurchaseHeader.TestField("Shipment Method Code");
        PurchaseHeader.TestField("Transport Method");
        PurchaseHeader.TestField("Pay-to County");

        IF PurchLine.FINDSET() THEN
            REPEAT
                PurchLine.TESTFIELD("PRG_Tariff Number");
                IF PurchLine."PRG_E-Invoice Tax Type Code" = '' THEN BEGIN
                    PurchLine.VALIDATE("PRG_E-Invoice Tax Type Code", ExportSetup."Default Exemption Tax Code");
                    PurchLine.MODIFY();
                END;
            UNTIL PurchLine.NEXT() = 0;
    end;

    procedure CheckMedicalInvoiceForSales(var SalesHeader: Record "Sales Header") IsMedical: Boolean
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
        ItemCategory: Record "Item Category";
        IsHandle: Boolean;
    begin
        GetEInvSetup();
        IF not EInvSetupGot THEN
            EXIT;

        IF not EInvSetup."Active Medical E-Invoice" then
            exit;

        OnBeforeCheckMedicalInvoiceForSales(SalesHeader, IsHandle, IsMedical);
        if IsHandle then
            exit(IsMedical);

        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetFilter("Qty. to Invoice", '>0');
        if SalesLine.FindSet() then
            repeat
                Item.Get(SalesLine."No.");

                if ItemCategory.Get(Item."Item Category Code") then
                    if ItemCategory."PRG_Medical E-Invoice Type" <> ItemCategory."PRG_Medical E-Invoice Type"::" " then begin
                        SalesHeader."PRG_Medical E-Invoice" := true;
                        exit(true);
                    end;
            until SalesLine.Next() = 0;

        exit(false);
    end;

    procedure CheckMedicalInvoiceForPurch(var PurchHeader: Record "Purchase Header") IsMedical: Boolean
    var
        PurchLine: Record "Sales Line";
        Item: Record Item;
        ItemCategory: Record "Item Category";
        IsHandle: Boolean;
    begin
        GetEInvSetup();
        IF not EInvSetupGot THEN
            EXIT;

        IF not EInvSetup."Active Medical E-Invoice" then
            exit;

        OnBeforeCheckMedicalInvoiceForPurch(PurchHeader, IsHandle, IsMedical);
        if IsHandle then
            exit(IsMedical);

        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.SetRange(Type, PurchLine.Type::Item);
        PurchLine.SetFilter("Qty. to Invoice", '>0');
        if PurchLine.FindSet() then
            repeat
                Item.Get(PurchLine."No.");

                if ItemCategory.Get(Item."Item Category Code") then
                    if ItemCategory."PRG_Medical E-Invoice Type" <> ItemCategory."PRG_Medical E-Invoice Type"::" " then begin
                        PurchHeader."PRG_Medical E-Invoice" := true;
                        exit(true);
                    end;
            until PurchLine.Next() = 0;

        exit(false);
    end;

    procedure CheckPurchInvAmountControl(var PurchaseHeader: Record "Purchase Header")
    var
        Queue: Record "PRG_E-Invoice Queue";
        EInvHeader: Record "PRG_E-Invoice Header";
        DifAmt: Decimal;
    begin

        GetEInvSetup();
        if not EInvSetup.Activated then
            exit;

        Queue.SetRange(ERPRecordID, PurchaseHeader.RecordId());
        if NOT Queue.FindFirst() then
            exit;

        EInvHeader.SetRange(UUID, Queue.UniqueIdentifier);
        if not EInvHeader.FindFirst() then
            exit;

        PurchaseHeader.CalcFields("Amount Including VAT");
        EInvHeader.CalcFields(TaxInclusiveAmount);
        DifAmt := PurchaseHeader."Amount Including VAT" - EInvHeader.TaxInclusiveAmount;
        if Abs(DifAmt) > EInvSetup."Different Amount Range" then
            case EInvSetup."Posting Amount Control" of
                EInvSetup."Posting Amount Control"::Allow:
                    exit;
                EInvSetup."Posting Amount Control"::Warning:
                    IF NOT CONFIRM('The amount difference is higher than the allowed range, do you want to continue?') THEN
                        ERROR('Proccess Stopped.');
                EInvSetup."Posting Amount Control"::Error:
                    Error('The amount difference is higher than the allowed range.');
            end;
    end;

    procedure GetEInvSetup()
    begin
        IF NOT EInvSetupGot THEN BEGIN
            IF EInvSetup.GET() THEN
                EInvSetupGot := TRUE;
        END;
    end;

    local procedure GetExportSetup()
    begin
        IF NOT GotExportSetup THEN BEGIN
            IF ExportSetup.GET() THEN
                GotExportSetup := TRUE;
        END;
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckPurchTaxTypeCode(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCheckSalesTaxTypeCode(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckFieldForSalesPost(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckFieldForPurchPost(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckMedicalInvoiceForPurch(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean; var IsMedical: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckMedicalInvoiceForSales(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean; var IsMedical: Boolean)
    begin
    end;
}