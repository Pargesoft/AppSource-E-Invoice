codeunit 70093473 "PRG_E-Invoice Management"
{
    Permissions = TableData "Bank Account Ledger Entry" = rm,
                  TableData "Cust. Ledger Entry" = rm,
                  TableData "G/L Entry" = rm,
                  TableData "G/L Register" = rm,
                  TableData "Purch. Cr. Memo Hdr." = rm,
                  TableData "Sales Invoice Header" = rm,
                  TableData "Sales Invoice Line" = rm,
                  TableData "Value Entry" = rm,
                  TableData "VAT Entry" = rm,
                  TableData "Vendor Ledger Entry" = rm,
                  TableData "Service Invoice Header" = rm,
                  TableData "Service Invoice Line" = rm;

    var
        ExportSetup: Record "PRG_E-Export Setup";
        GlobCVInfo: Record "PRG_E-Invoice CV Info.";
        GlobEInvHeader: Record "PRG_E-Invoice Header";
        IntSetup: Record "PRG_E-Invoice Integrator Setup";
        GlobEInvLine: Record "PRG_E-Invoice Line";
        QueueToPass: Record "PRG_E-Invoice Queue";
        GlobRefLine: Record "PRG_E-Invoice Reference Buffer";
        EInvSetup: Record "PRG_E-Invoice Setup";
        GlobEInvTaxLine: Record "PRG_E-Invoice Tax Line";
        TempReturnShptHeader: Record "Return Shipment Header" temporary;
        TempReturnShptLine: Record "Return Shipment Line" temporary;
        TempSalesShptHeader: Record "Sales Shipment Header" temporary;
        TempSalesShptLine: Record "Sales Shipment Line" temporary;
        TempServiceShptLine: Record "Service Shipment Line" temporary;
        TempVATEntry: Record "VAT Entry" temporary;
        Library: Codeunit "PRG_E-Invoice Library";
        NumberReader: Codeunit "PRG_E-Invoice Number Reader";
        UBLMgt: Codeunit "PRG_E-Invoice UBL Management";
        GotExportSetup: Boolean;
        GotIntSetup: Boolean;
        GotInvSetup: Boolean;
        IsManuelAmountWord: Boolean;
        SendPreview: Boolean;
        GlobRegionCode: Code[10];
        GlobTaxTypeCode: Code[20];
        HeaderEntryNo: Integer;
        Text002: Label 'Invoice Storage cant be processed\';
        Text004: Label 'Contact your system administrator';
        Text007: Label 'Record added to queue';
        Text010: Label 'Invoice sent.';
        Text019: Label 'Branch E-Invoice address is empty. Address will be copied from cv. Do you want to continue';
        Text020: Label 'Process stopped because of selection.';
        Text022: Label 'Tax Type empty!';
        Text023: Label 'length must be %1 or %2 character!';
        Text024: Label '%1 lines have not been created! Transaction stopped. Source G/L Register No: %2';
        Text025: Label 'Cannot find the source table information used in external document no. control!';
        Text026: Label '%1 Invoice has been sent to integrator';
        Text027: Label 'No invoice sent because selection does not include New or Failed invoices!';
        Text032: Label 'Invoice number %1 is already used before! Check number series and run the process again.';
        Text033: Label 'length is not correct! Length must be 10 or 11 character.';
        Text034: Label 'Tax Type missing!';
        Text045: Label 'Before using preview functionality, e-invoice must be created!';
        Text046: Label 'This sales type is not supported! E-Invoice %1: %2';
        Text047: Label 'This integration type is not supported! E-Invoice %1: %2';
        Text048: Label 'Product is not activated! Activate the product and run the process again.';
        Text056: Label 'ERP Document No. : %1';
        Text057: Label 'Gönderim Şekli:ELEKTRONIK', Locked = true;

    procedure ArchiveQueue(VAR Queue: Record "PRG_E-Invoice Queue")
    var
        EInvEntry: Record "PRG_E-Invoice Archive";
        EInvLogEntry: Record "PRG_E-Invoice Log Archive";
        LclQueue: Record "PRG_E-Invoice Queue";
        LclQueueLog: Record "PRG_E-Invoice Queue Log";
        QueueLog: Record "PRG_E-Invoice Queue Log";
    begin
        IF Queue.FINDSET() THEN
            REPEAT
                IF EInvEntry.FINDLAST() THEN;
                EInvEntry.TRANSFERFIELDS(Queue, FALSE);
                EInvEntry."Queue Status" := EInvEntry."Queue Status"::Completed;
                EInvEntry.EntryNo := EInvEntry.EntryNo + 1;
                EInvEntry.INSERT(TRUE);

                QueueLog.SETRANGE("Header Entry No.", Queue.EntryNo);
                IF QueueLog.FINDSET() THEN
                    REPEAT
                        EInvLogEntry.TRANSFERFIELDS(QueueLog, FALSE);
                        EInvLogEntry."Header Entry No." := EInvEntry.EntryNo;
                        EInvLogEntry."Line No." := QueueLog."Line No.";
                        EInvLogEntry.INSERT();
                        LclQueueLog.GET(QueueLog."Header Entry No.", QueueLog."Line No.");
                        LclQueueLog.DELETE(TRUE);
                    UNTIL QueueLog.NEXT() = 0;

                LclQueue.GET(Queue.EntryNo);
                LclQueue.DELETE(TRUE);

            UNTIL Queue.NEXT() = 0;
    end;

    procedure ArchiveQueue(VAR Queue: Record "PRG_E-Invoice Queue"; FromCancellation: Boolean)
    var
        EInvEntry: Record "PRG_E-Invoice Archive";
        EInvHeader: Record "PRG_E-Invoice Header";
        EInvLogEntry: Record "PRG_E-Invoice Log Archive";
        LocEInvLogEntry: Record "PRG_E-Invoice Log Archive";
        LclQueue: Record "PRG_E-Invoice Queue";
        LclQueueLog: Record "PRG_E-Invoice Queue Log";
        QueueLog: record "PRG_E-Invoice Queue Log";
    begin
        IF Queue.FINDSET() THEN
            REPEAT

                IF EInvEntry.FINDLAST() THEN;

                EInvEntry.TRANSFERFIELDS(Queue, FALSE);
                EInvEntry."Queue Status" := EInvEntry."Queue Status"::Completed;
                EInvEntry.EntryNo := EInvEntry.EntryNo + 1;
                EInvEntry.INSERT(TRUE);

                IF FromCancellation THEN BEGIN
                    EInvHeader.SETFILTER(UUID, Queue.UniqueIdentifier);
                    IF EInvHeader.FINDFIRST() THEN BEGIN
                        EInvHeader."Invoice ID" := '';
                        EInvHeader.MODIFY();
                    END;
                END;

                QueueLog.SETRANGE("Header Entry No.", Queue.EntryNo);
                IF QueueLog.FINDSET() THEN
                    REPEAT
                        LocEInvLogEntry.SetRange("Header Entry No.", Queue.EntryNo);
                        if LocEInvLogEntry.FindLast() then;

                        EInvLogEntry.TRANSFERFIELDS(QueueLog, FALSE);
                        EInvLogEntry."Header Entry No." := EInvEntry.EntryNo;
                        EInvLogEntry."Line No." := QueueLog."Line No.";
                        EInvLogEntry.INSERT();
                        LclQueueLog.GET(QueueLog."Header Entry No.", QueueLog."Line No.");
                        LclQueueLog.DELETE(TRUE);
                    UNTIL QueueLog.NEXT() = 0;

                LclQueue.GET(Queue.EntryNo);
                LclQueue.DELETE(TRUE);

            UNTIL Queue.NEXT() = 0;

    end;

    procedure MoveArchiveToQueue(var ArchiveEntry: Record "PRG_E-Invoice Archive")
    var
        LocArchiveEntry: Record "PRG_E-Invoice Archive";
        ArchiveLogEntry: Record "PRG_E-Invoice Log Archive";
        LocArchiveLogEntry: Record "PRG_E-Invoice Log Archive";
        Queue: Record "PRG_E-Invoice Queue";
        LclQueueLog: Record "PRG_E-Invoice Queue Log";
        QueueLog: Record "PRG_E-Invoice Queue Log";
    begin
        IF ArchiveEntry.FINDSET() THEN
            REPEAT
                IF Queue.FINDLAST() THEN;
                Queue.TRANSFERFIELDS(ArchiveEntry, FALSE);
                Queue."Queue Status" := ArchiveEntry."Queue Status"::Completed;
                Queue.EntryNo := Queue.EntryNo + 1;
                Queue.INSERT(TRUE);

                ArchiveLogEntry.SETRANGE("Header Entry No.", ArchiveEntry.EntryNo);
                IF ArchiveLogEntry.FINDSET() THEN
                    REPEAT
                        QueueLog.SetRange("Header Entry No.", Queue.EntryNo);
                        if QueueLog.FindLast() then;

                        QueueLog.TRANSFERFIELDS(ArchiveLogEntry, FALSE);
                        QueueLog."Header Entry No." := Queue.EntryNo;
                        QueueLog."Line No." := ArchiveLogEntry."Line No.";
                        QueueLog.INSERT();
                        LocArchiveLogEntry.GET(ArchiveLogEntry."Header Entry No.", ArchiveLogEntry."Line No.");
                        LocArchiveLogEntry.DELETE(TRUE);
                    UNTIL ArchiveLogEntry.NEXT() = 0;

                LocArchiveEntry.GET(ArchiveEntry.EntryNo);
                LocArchiveEntry.DELETE(TRUE);
            UNTIL ArchiveEntry.NEXT() = 0;
    end;

    procedure CalcTaxSeqNumber(pTaxLine: Record "PRG_E-Invoice Tax Line"): Integer
    var
        TaxLine: Record "PRG_E-Invoice Tax Line";
        TaxTypeCode: Record "PRG_E-Invoice Tax Type Code";
        TempTaxTypeCode: Record "PRG_E-Invoice Tax Type Code" temporary;
        SeqNo: Integer;
    begin
        TaxLine.RESET();
        TaxLine.SETRANGE("Header Entry No.", pTaxLine."Header Entry No.");
        TaxLine.SETRANGE("Header Line No.", pTaxLine."Header Line No.");
        TaxLine.FINDFIRST();
        REPEAT
            IF NOT TempTaxTypeCode.GET(TaxLine.TaxTypeCode) THEN BEGIN
                TaxTypeCode.GET(TaxLine.TaxTypeCode);
                TempTaxTypeCode := TaxTypeCode;
                TempTaxTypeCode.INSERT();
            END;
        UNTIL TaxLine.NEXT() = 0;

        TempTaxTypeCode.SETCURRENTKEY("Calculation Sequence Number");
        TempTaxTypeCode.FINDFIRST();
        SeqNo := 0;
        REPEAT
            SeqNo := SeqNo + 1;
            TaxLine.SETRANGE(TaxTypeCode, TempTaxTypeCode.Code);
            TaxLine.FINDFIRST();
            TaxLine.CalculationSequenceNumeric := SeqNo;
            TaxLine.MODIFY();
        UNTIL TempTaxTypeCode.NEXT() = 0;
    end;

    procedure CreateCommInvoice(var Queue: Record "PRG_E-Invoice Queue"; PreviewOnly: Boolean)
    var
        Cust: Record "Customer";
        EInvoiceFixNotes: Record "PRG_E-Invoice Fix Notes";
        TaxType: Record "PRG_E-Invoice Tax Type Code";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        TempPurchCrMemoLine: Record "Purch. Cr. Memo Line" temporary;
        SalesCommLine: Record "Sales Comment Line";
        PurchCommLine: Record "Purch. Comment Line";
        ServiceCommLine: Record "Service Comment Line";
        SalesInvHeader: Record "Sales Invoice Header";
        SalesInvLine: Record "Sales Invoice Line";
        TempSalesInvLine: Record "Sales Invoice Line" temporary;
        ServiceInvHeader: Record "Service Invoice Header";
        ServiceInvLine: Record "Service Invoice Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
        NoteCustLedgEntry: Record "Cust. Ledger Entry";
        IssuedFinChargeMemoLine: Record "Issued Fin. Charge Memo Line";
        ServiceInvAmount: Decimal;
        ServiceInvAmountVAT: Decimal;
        ShipToAddr: Record "Ship-to Address";
        ShippingAgent: Record "Shipping Agent";
        TaxArea: Record "Tax Area";
        Vend: Record "Vendor";
        RecRef: RecordRef;
        IsHandle: Boolean;
        DiscAmt: Decimal;
        LineExtAmt: Decimal;
        LineCount: Integer;
        LineNo: Integer;
        Text001: Label 'Only: ';
        OutputType: Option ,Standard,Customized;
        Desc: Text[250];
        ItemName: Text[250];
        TRWord: Text[250];
        TaxExclAmt: Decimal;
        TaxAmt: Decimal;
        RecordID: RecordId;
    begin
        IF NOT GetInvSetup() THEN
            ERROR(Text048);

        IF NOT GotIntSetup then
            GetIntSetup();

        GlobEInvHeader.SETRANGE(UUID, Queue.UniqueIdentifier);
        IF GlobEInvHeader.FINDFIRST() THEN BEGIN
            GlobEInvHeader."Invoice ID" := Queue.InvoiceID;
            GlobEInvHeader.MODIFY();

            case Queue.IntegrationType of
                Queue.IntegrationType::EInvoice:
                    OutputType := IntSetup."E-Invoice Output Type";
                Queue.IntegrationType::EArchive:
                    OutputType := IntSetup."E-Archive Output Type";
            END;

            IF OutputType = OutputType::Standard then begin
                IF GlobEInvHeader.SalesType = GlobEInvHeader.SalesType::Internet THEN BEGIN
                    GlobEInvHeader.TESTFIELD(PaymentMethodNote);
                    IF GlobEInvHeader.PaymentMethodNote = 'ODEMEARACISI' THEN
                        GlobEInvHeader.TESTFIELD(PaymentChannelCode);
                    GlobEInvHeader.TESTFIELD(CustWebsiteURI);
                END;

            END;

            EXIT;

        END ELSE
            IF PreviewOnly THEN
                ERROR(Text045);

        EInvSetup.TESTFIELD("VAT Tax Type Code");
        EInvSetup.TESTFIELD("Sales Exemption Tax Code");

        TempSalesShptLine.RESET();
        TempSalesShptLine.DELETEALL();
        TempReturnShptLine.RESET();
        TempReturnShptLine.DELETEALL();

        TempServiceShptLine.RESET;
        TempServiceShptLine.DELETEALL;

        RecRef.GET(Queue.ERPRecordID);

        GlobCVInfo.TESTFIELD("Profile ID");

        GlobEInvHeader.INIT();

        OnBeforeStartCreateCommInvoice(Queue, GlobEInvHeader);

        GlobEInvHeader.UUID := Queue.UniqueIdentifier;
        GlobEInvHeader."Invoice ID" := Queue.InvoiceID;
        GlobEInvHeader."G/L Register Entry No." := Queue.GLRegisterEntryNo;
        GlobEInvHeader.CopyIndicator := 'false';
        GlobEInvHeader.ProfileID := Queue.ProfileID;

        IF Queue.ProfileID = Queue.ProfileID::EExport THEN BEGIN
            GlobEInvHeader."Country/Region Code" := GlobRegionCode;
            GlobEInvHeader."Company ID" := Cust."VAT Registration No.";
        END;

        GlobEInvHeader.IssueTime := TIME;
        GlobEInvHeader.CustNo := GlobCVInfo."CV No.";
        GlobEInvHeader.CustRegistrationNo := GlobCVInfo."Tax Registration No.";
        GlobEInvHeader.CustTaxSchemeID := GlobCVInfo."TaxSchemeID Buffer";
        GlobEInvHeader.CustName := GlobCVInfo."CV Name";
        GlobEInvHeader.CustFirstName := GlobCVInfo."First Name";
        GlobEInvHeader.CustFamilyName := GlobCVInfo."Family Name";
        GlobEInvHeader.AllowanceChargeIndicator := 'false';
        GlobEInvHeader.IntegrationType := GlobCVInfo."Integration Type";
        GlobEInvHeader.CustBuildingNumber := '';
        GlobEInvHeader.Type := GlobEInvHeader.Type::Outbox;

        CASE RecRef.NUMBER OF

            DATABASE::"Sales Invoice Header":
                BEGIN

                    RecRef.SETTABLE(SalesInvHeader);
                    SalesInvLine.SETRANGE("Document No.", SalesInvHeader."No.");
                    LineCount := SalesInvLine.COUNT;
                    IF LineCount = 0 THEN
                        EXIT;

                    Cust.GET(GlobCVInfo."CV No.");

                    SalesInvHeader.CALCFIELDS(Amount, "Amount Including VAT");
                    DiscAmt := ROUND(CalcSalesInvDiscAmt(SalesInvHeader), 0.01);

                    GlobEInvHeader.IssueDate := SalesInvHeader."Posting Date";

                    GlobEInvHeader.InvoiceType := Queue.InvoiceType;
                    GlobEInvHeader.DocumentCurrencyCode := GetCurrCode(SalesInvHeader."Currency Code");
                    IF (SalesInvHeader."Currency Factor" <> 0) AND (SalesInvHeader."Currency Factor" <> 1) THEN
                        GlobEInvHeader.DocumentCurrencyRate := ROUND(1 / SalesInvHeader."Currency Factor", 0.00001)
                    ELSE
                        GlobEInvHeader.DocumentCurrencyRate := 1;

                    GlobEInvHeader.OrderNo := SalesInvHeader."Order No.";
                    IF SalesInvHeader."Order No." <> '' THEN
                        GlobEInvHeader.OrderDate := SalesInvHeader."Order Date";

                    IF SalesInvHeader."Ship-to Code" <> '' THEN
                        IF ShipToAddr.GET(Cust."No.", SalesInvHeader."Ship-to Code") THEN
                            GlobEInvHeader.CustBranchCode := ShipToAddr.Code;
#pragma warning disable AL0432
                    GlobEInvHeader.CustWebsiteURI := CopyStr(Cust."Home Page", 1, MaxStrLen(GlobEInvHeader.CustWebsiteURI));
#pragma warning restore AL0432
                    IF (EInvSetup."E-Invoice Addres" = EInvSetup."E-Invoice Addres"::"Fatura Adresi") OR
                       (SalesInvHeader."Ship-to Code" = '') THEN BEGIN
                        GlobEInvHeader.CustName := SalesInvHeader."Bill-to Name" + ' ' + SalesInvHeader."Bill-to Name 2";
                        IF SalesInvHeader."Bill-to County" <> '' THEN
                            GlobEInvHeader.CustCitySubdivisionName := SalesInvHeader."Bill-to County"
                        ELSE BEGIN
                            Cust.TESTFIELD(County);
                            GlobEInvHeader.CustCitySubdivisionName := Cust.County;
                        END;
                        IF SalesInvHeader."Bill-to City" <> '' THEN
                            GlobEInvHeader.CustCityName := SalesInvHeader."Bill-to City"
                        ELSE BEGIN
                            Cust.TESTFIELD(City);
                            GlobEInvHeader.CustCityName := Cust.City
                        END;
                        GlobEInvHeader.CustPostalZone := SalesInvHeader."Bill-to Post Code";
                        IF SalesInvHeader."Bill-to Country/Region Code" <> '' THEN
                            GlobEInvHeader.CustCountryName := GetCountryCode(SalesInvHeader."Bill-to Country/Region Code")
                        ELSE
                            GlobEInvHeader.CustCountryName := GetCountryCode(Cust."Country/Region Code");
                        GlobEInvHeader.CustStreetName := SalesInvHeader."Bill-to Address" + ' ' + SalesInvHeader."Bill-to Address 2";
                    END ELSE BEGIN
                        GlobEInvHeader.CustName := SalesInvHeader."Ship-to Name" + ' ' + SalesInvHeader."Ship-to Name 2";
                        IF SalesInvHeader."Ship-to County" <> '' THEN
                            GlobEInvHeader.CustCitySubdivisionName := SalesInvHeader."Ship-to County"
                        ELSE BEGIN
                            Cust.TESTFIELD(County);
                            GlobEInvHeader.CustCitySubdivisionName := Cust.County;
                        END;
                        IF SalesInvHeader."Ship-to City" <> '' THEN
                            GlobEInvHeader.CustCityName := SalesInvHeader."Ship-to City"
                        ELSE BEGIN
                            Cust.TESTFIELD(City);
                            GlobEInvHeader.CustCityName := Cust.City
                        END;
                        GlobEInvHeader.CustPostalZone := SalesInvHeader."Ship-to Post Code";
                        IF SalesInvHeader."Ship-to Country/Region Code" <> '' THEN
                            GlobEInvHeader.CustCountryName := GetCountryCode(SalesInvHeader."Ship-to Country/Region Code")
                        ELSE
                            GlobEInvHeader.CustCountryName := GetCountryCode(Cust."Country/Region Code");
                        GlobEInvHeader.CustStreetName := SalesInvHeader."Ship-to Address" + ' ' + SalesInvHeader."Ship-to Address 2";
                    END;
                    if TaxArea.Get(SalesInvHeader."Tax Area Code") then
                        GlobEInvHeader.CustTaxOfficeName := CopyStr(SalesInvHeader."Tax Area Code" + ' - ' + TaxArea.Description, 1, MaxStrLen(GlobEInvHeader.CustTaxOfficeName));
                    GlobEInvHeader.CustTelephone := Cust."Phone No.";
                    GlobEInvHeader.CustTelefax := Cust."Fax No.";

                    IF GlobCVInfo."Integration Type" = GlobCVInfo."Integration Type"::EInvoice THEN BEGIN
                        GlobEInvHeader.CustIdentifier := FindIdentifier(GlobCVInfo."E-mail Address", SalesInvHeader."Ship-to Code");
                        GlobEInvHeader.CustElectronicMail := Cust."E-Mail";
                    END ELSE BEGIN
                        GlobEInvHeader.CustElectronicMail := GlobCVInfo."E-mail Address";
                        GlobEInvHeader.CustIdentifier := '';
                        GlobEInvHeader.PaymentMethodNote := GetEArchPaymentMethod(SalesInvHeader."Payment Method Code");
                    END;
                    GlobEInvHeader.PaymentDueDate := SalesInvHeader."Due Date";
                    GlobEInvHeader.PayableAmount := SalesInvHeader."Amount Including VAT";
                    IF SalesInvHeader."Amount Including VAT" <> 0 THEN
                        GlobEInvHeader.AllowanceChargeRate := ROUND((DiscAmt / (SalesInvHeader.Amount + DiscAmt)), 0.0001)
                    ELSE
                        GlobEInvHeader.AllowanceChargeRate := 1;

                    GlobEInvHeader.AllowanceChargeAmtInvoice := DiscAmt;

                    IF GlobEInvHeader.SalesType = GlobEInvHeader.SalesType::Internet THEN
                        IF SalesInvHeader."Shipping Agent Code" <> '' THEN BEGIN
                            ShippingAgent.GET(SalesInvHeader."Shipping Agent Code");
                            IF (ShippingAgent."Account No." <> '') AND (ShippingAgent.Name <> '') THEN BEGIN
                                GlobEInvHeader."Carrier RegistrationNo" := ShippingAgent."Account No.";
                                GlobEInvHeader."Carrier Name" := ShippingAgent.Name;
                            END;
                        END;

                    IF Cust."PRG_Payee Firm" THEN BEGIN
                        GetInvSetup();
                        GlobEInvHeader.PaymentBankAccNo := EInvSetup."Payee Financial Account";
                        GlobEInvHeader.PaymentBankCurrCode := EInvSetup."Payee Currency Code";
                        GlobEInvHeader.PaymentInstructionNote := EInvSetup."Payee Payment Note";
                    END;

                    HeaderEntryNo := FindNextHeaderEntryNo();

                    IF HeaderEntryNo <> 0 THEN BEGIN

                        GlobEInvHeader."Entry No." := HeaderEntryNo;
                        OnBeforeInsertGlobEInvHeader(GlobEInvHeader);
                        GlobEInvHeader.INSERT();
                        OnAfterInsertGlobEInvHeader(GlobEInvHeader);

                        SalesInvHeader.CALCFIELDS(SalesInvHeader."Amount Including VAT");
                        TRWord := '';
                        IF SalesInvHeader."Amount Including VAT" <> 0 THEN
                            TRWord := NumberReader.GetWords('', SalesInvHeader."Amount Including VAT", SalesInvHeader."Currency Code");

                        OnBeforeTRWordReference(Queue, IsHandle);
                        IF NOT IsHandle then
                            InsertRefBuffer(HeaderEntryNo, 0, GlobRefLine."Reference Type"::Note, Text001 + TRWord, 0D);

                        GetInvSetup();
                        IF EInvSetup."Send ERP Doc. Number As Note" THEN
                            InsertRefBuffer(HeaderEntryNo, 0, GlobRefLine."Reference Type"::Note, STRSUBSTNO(Text056, SalesInvHeader."No."), 0D);

                        IF (IntSetup."E-Archive Integrator" = IntSetup."E-Archive Integrator"::Efinans) then
                            InsertRefBuffer(HeaderEntryNo, 0, GlobRefLine."Reference Type"::Note, STRSUBSTNO(Text057), 0D);

                        OnBeforeInsertSalesComment(SalesInvHeader, SalesCommLine, HeaderEntryNo);
                        IF EInvSetup."Note Info. Source" IN [EInvSetup."Note Info. Source"::"Comment Line", EInvSetup."Note Info. Source"::"Comment Line Plus Inv. Line"] THEN BEGIN
                            SalesCommLine.SETRANGE("Document Type", SalesCommLine."Document Type"::"Posted Invoice");
                            SalesCommLine.SETRANGE("No.", SalesInvHeader."No.");
                            IF SalesCommLine.FINDSET() THEN
                                REPEAT
                                    InsertRefBuffer(HeaderEntryNo, 0, GlobRefLine."Reference Type"::Note, SalesCommLine.Comment, 0D);
                                UNTIL SalesCommLine.NEXT() = 0;
                        end;

                        if not TempSalesInvLine.IsTemporary then
                            Error('');
                        TempSalesInvLine.reset;
                        TempSalesInvLine.DeleteAll();

                        OnBeforeCreateInvoiceLineForSales(SalesInvLine, TempSalesInvLine);
                        CreateTempSalesInvoiceLines(SalesInvLine, TempSalesInvLine);
                        OnAfterCreateInvoiceLineForSales(SalesInvLine, TempSalesInvLine);

                        TempSalesInvLine.FINDSET();
                        LineNo := 0;
                        REPEAT
                            IF (TempSalesInvLine.Type.AsInteger() > 0) AND (TempSalesInvLine."No." <> '') AND (TempSalesInvLine.Quantity <> 0) THEN BEGIN

                                LineNo += 1;
                                ItemName := '';
                                Desc := '';

                                CASE EInvSetup."Item Name Source" OF
                                    EInvSetup."Item Name Source"::LineDescription:
                                        begIN
                                            ItemName := TempSalesInvLine.Description;
                                            Desc := TempSalesInvLine.Description;
                                        end;
                                    EInvSetup."Item Name Source"::AccName:
                                        BEGIN
                                            ItemName := GetSourceDesc(TempSalesInvLine.Type.AsInteger(), TempSalesInvLine."No.");
                                            Desc := TempSalesInvLine.Description;
                                        END;
                                END;

                                OnAfterCreateSalesLineDescription(TempSalesInvLine.Type, TempSalesInvLine."No.", ItemName, Desc);

                                IF SalesInvHeader."Prices Including VAT" THEN
                                    CalcAmtInclVAT(SalesInvLine);

                                LineExtAmt := (TempSalesInvLine.Quantity * TempSalesInvLine."Unit Price") -
                                    (TempSalesInvLine."Line Discount Amount"); //+ TempSalesInvLine."Inv. Discount Amount");

                                OnBeforeInsertInvLineSales(TempSalesInvLine, LineExtAmt);

                                InsertInvLine(HeaderEntryNo,
                                  LineNo,
                                  TempSalesInvLine."No.",
                                  TempSalesInvLine.Quantity,
                                  LineExtAmt,
                                  TempSalesInvLine."Line Discount Amount", //+ TempSalesInvLine."Inv. Discount Amount"
                                  TempSalesInvLine.Amount,
                                  TempSalesInvLine."Amount Including VAT" - TempSalesInvLine.Amount,
                                  ItemName,
                                  Desc,
                                  TempSalesInvLine."Unit Price",
                                  TempSalesInvLine."Unit of Measure Code",
                                  FindSalesCrossRef_New(TempSalesInvLine),
                                  FindSalesBarcode_New(TempSalesInvLine),
                                  SalesInvHeader."Shipment Method Code",
                                  SalesInvHeader."Transport Method",
                                  TempSalesInvLine."PRG_Tariff Number",
                                  GlobEInvHeader.CustCountryName,
                                  GlobEInvHeader.CustCityName,
                                  TempSalesInvLine."PRG_Package Brand",
                                  TempSalesInvLine."PRG_Packagin Type Code",
                                  TempSalesInvLine."PRG_Actual Package Quantity",
                                  TempSalesInvLine."PRG_Carriage Amount",
                                  TempSalesInvLine."PRG_Insurance Amount",
                                  TempSalesInvLine."Item Category Code",
                                  TempSalesInvLine.RecordId);

                                TaxType.INIT();
                                IF TempSalesInvLine."PRG_E-Invoice Tax Type Code" <> '' THEN
                                    TaxType.GET(TempSalesInvLine."PRG_E-Invoice Tax Type Code");

                                IF TaxType.Type <> TaxType.Type::Exported THEN BEGIN
                                    SetTaxLine(HeaderEntryNo, EInvSetup."VAT Tax Type Code",
                                      TempSalesInvLine."Amount Including VAT" - TempSalesInvLine.Amount + TempSalesInvLine."Unit Volume",//Used As VAT Deduction Field On Temp Record
                                      TempSalesInvLine.Amount, TempSalesInvLine."VAT %");
                                    IF TempSalesInvLine."PRG_E-Invoice Tax Type Code" <> '' THEN
                                        SetTaxLine(HeaderEntryNo, TempSalesInvLine."PRG_E-Invoice Tax Type Code",
                                          TempSalesInvLine."Amount Including VAT" - TempSalesInvLine.Amount + TempSalesInvLine."Unit Volume",//Used As VAT Deduction Field On Temp Record
                                          TempSalesInvLine.Amount, 0);

                                END ELSE
                                    SetTaxLine(HeaderEntryNo, TempSalesInvLine."PRG_E-Invoice Tax Type Code",
                                      TempSalesInvLine."Amount Including VAT" - TempSalesInvLine.Amount + TempSalesInvLine."Unit Volume",//Used As VAT Deduction Field On Temp Record
                                      TempSalesInvLine.Amount, TempSalesInvLine."VAT %");


                                OnAfterCreateGlobEInvoiceLine(GlobEInvLine);

                            END ELSE
                                IF (TempSalesInvLine.Type = TempSalesInvLine.Type::" ") then
                                    IF EInvSetup."Note Info. Source" IN [EInvSetup."Note Info. Source"::"Invoice Line", EInvSetup."Note Info. Source"::"Comment Line Plus Inv. Line"] THEN
                                        InsertRefBuffer(HeaderEntryNo, LineNo, GlobRefLine."Reference Type"::Note, TempSalesInvLine.Description, 0D);

                        UNTIL TempSalesInvLine.NEXT() = 0;

                        OnAfterCreateInvoiceLines(HeaderEntryNo);

                        OnBeforeCreateShipmentReference(HeaderEntryNo, TempSalesShptLine, TempReturnShptLine);
                        CreateShipRef();

                        InsertPaymentMethodRef(SalesInvHeader."Payment Method Code", SalesInvHeader."Due Date");

                        OnAfterInsertPaymentMethodReference(Queue, HeaderEntryNo);

                        GlobEInvHeader.CALCFIELDS(TaxExclusiveAmount, TaxInclusiveAmount);
                        UpdateQueueForInvInfo(Queue, GlobEInvHeader.IssueDate, GlobEInvHeader.TaxExclusiveAmount, GlobEInvHeader.TaxInclusiveAmount, Cust."No.");

                        IF GlobEInvHeader.InvoiceType = GlobEInvHeader.InvoiceType::Exported THEN BEGIN
                            SalesInvHeader.CALCFIELDS(Amount);
                            GlobEInvHeader.PayableAmount := SalesInvHeader.Amount;
                            GlobEInvHeader.MODIFY();
                        END;

                        EInvoiceFixNotes.reset;
                        EInvoiceFixNotes.SetFilter("Fix Note", '<>%1');
                        EInvoiceFixNotes.SetRange("For Sales", true);
                        if EInvoiceFixNotes.FindSet() then
                            repeat
                                InsertRefBuffer(HeaderEntryNo, 0, GlobRefLine."Reference Type"::Note, EInvoiceFixNotes."Fix Note", 0D);
                            until EInvoiceFixNotes.Next() = 0;

                    END ELSE BEGIN
                        Queue."Queue Status" := Queue."Queue Status"::Failed;
                        Queue.Description := Text002 + Text004;
                        EXIT;
                    END;

                END;

            DATABASE::"Purch. Cr. Memo Hdr.":
                BEGIN
                    RecRef.SETTABLE(PurchCrMemoHeader);
                    PurchCrMemoLine.SETRANGE("Document No.", PurchCrMemoHeader."No.");
                    LineCount := PurchCrMemoLine.COUNT;
                    IF LineCount = 0 THEN
                        EXIT;

                    Vend.GET(PurchCrMemoHeader."Pay-to Vendor No.");

                    GlobCVInfo.TESTFIELD("Profile ID");

                    PurchCrMemoHeader.CALCFIELDS(Amount, "Amount Including VAT");
                    DiscAmt := ROUND(CalcPurchInvDiscAmt(PurchCrMemoHeader), 0.01);

                    GlobEInvHeader.IssueDate := PurchCrMemoHeader."Posting Date";
                    GlobEInvHeader.InvoiceType := GlobEInvHeader.InvoiceType::PurchCr;
                    GlobEInvHeader.DocumentCurrencyCode := GetCurrCode(PurchCrMemoHeader."Currency Code");
                    IF (PurchCrMemoHeader."Currency Factor" <> 0) AND (PurchCrMemoHeader."Currency Factor" <> 1) THEN
                        GlobEInvHeader.DocumentCurrencyRate := ROUND(1 / PurchCrMemoHeader."Currency Factor", 0.00001)
                    ELSE
                        GlobEInvHeader.DocumentCurrencyRate := 1;
#pragma warning disable AL0432
                    GlobEInvHeader.CustWebsiteURI := CopyStr(Vend."Home Page", 1, MaxStrLen(GlobEInvHeader.CustWebsiteURI));
#pragma warning restore AL0432
                    IF PurchCrMemoHeader."Pay-to County" <> '' THEN
                        GlobEInvHeader.CustCitySubdivisionName := PurchCrMemoHeader."Pay-to County"
                    ELSE BEGIN
                        Vend.TESTFIELD(County);
                        GlobEInvHeader.CustCitySubdivisionName := Vend.County;
                    END;
                    IF PurchCrMemoHeader."Pay-to City" <> '' THEN
                        GlobEInvHeader.CustCityName := PurchCrMemoHeader."Pay-to City"
                    ELSE BEGIN
                        Vend.TESTFIELD(City);
                        GlobEInvHeader.CustCityName := Vend.City
                    END;
                    GlobEInvHeader.CustPostalZone := PurchCrMemoHeader."Pay-to Post Code";
                    IF PurchCrMemoHeader."Pay-to Country/Region Code" <> '' THEN
                        GlobEInvHeader.CustCountryName := GetCountryCode(PurchCrMemoHeader."Pay-to Country/Region Code")
                    ELSE BEGIN
                        Vend.TESTFIELD("Country/Region Code");
                        GlobEInvHeader.CustCountryName := GetCountryCode(Vend."Country/Region Code")
                    END;
                    GlobEInvHeader.CustStreetName := PurchCrMemoHeader."Pay-to Address" + ' ' + PurchCrMemoHeader."Pay-to Address 2";
                    GlobEInvHeader.CustTaxOfficeName := PurchCrMemoHeader."Tax Area Code";
                    GlobEInvHeader.CustTelephone := Vend."Phone No.";
                    GlobEInvHeader.CustTelefax := Vend."Fax No.";

                    IF GlobCVInfo."Integration Type" = GlobCVInfo."Integration Type"::EInvoice THEN BEGIN
                        GlobEInvHeader.CustIdentifier := FindIdentifier(GlobCVInfo."E-mail Address", '');
                        GlobEInvHeader.CustElectronicMail := Vend."E-Mail";
                    END ELSE BEGIN
                        GlobEInvHeader.CustElectronicMail := GlobCVInfo."E-mail Address";
                        GlobEInvHeader.CustIdentifier := '';
                    END;

                    GlobEInvHeader.PaymentDueDate := PurchCrMemoHeader."Due Date";
                    GlobEInvHeader.AllowanceChargeIndicator := 'false';
                    GlobEInvHeader.PayableAmount := ROUND(PurchCrMemoHeader."Amount Including VAT", 0.01);
                    IF PurchCrMemoHeader."Amount Including VAT" <> 0 THEN
                        GlobEInvHeader.AllowanceChargeRate := ROUND(DiscAmt / (PurchCrMemoHeader.Amount + DiscAmt) * 100, 0.0001)
                    ELSE
                        GlobEInvHeader.AllowanceChargeRate := 1;
                    GlobEInvHeader.AllowanceChargeAmtInvoice := DiscAmt;

                    IF Cust."PRG_Payee Firm" THEN BEGIN
                        GetInvSetup();
                        GlobEInvHeader.PaymentBankAccNo := EInvSetup."Payee Financial Account";
                        GlobEInvHeader.PaymentBankCurrCode := EInvSetup."Payee Currency Code";
                        GlobEInvHeader.PaymentInstructionNote := EInvSetup."Payee Payment Note";
                    END;

                    GlobEInvHeader.IntegrationType := GlobCVInfo."Integration Type";
                    HeaderEntryNo := FindNextHeaderEntryNo();

                    IF Queue.ProfileID = Queue.ProfileID::EExport THEN BEGIN
                        GlobEInvHeader."Country/Region Code" := GlobRegionCode;
                        GlobEInvHeader."Company ID" := Vend."VAT Registration No.";
                    END;

                    GlobEInvHeader."Related Invoice No." := PurchCrMemoHeader."PRG_Related Invoice No.";
                    GlobEInvHeader."Related Invoice Date" := PurchCrMemoHeader."PRG_Related Invoice Date";

                    IF HeaderEntryNo <> 0 THEN BEGIN

                        GlobEInvHeader."Entry No." := HeaderEntryNo;
                        OnBeforeInsertGlobEInvHeader(GlobEInvHeader);
                        GlobEInvHeader.INSERT();
                        OnAfterInsertGlobEInvHeader(GlobEInvHeader);

                        OnBeforeInsertPurchCrMemoComment(PurchCrMemoHeader, PurchCommLine, HeaderEntryNo);
                        PurchCommLine.SETRANGE("Document Type", PurchCommLine."Document Type"::"Posted Credit Memo");
                        PurchCommLine.SETRANGE("No.", PurchCrMemoHeader."No.");
                        IF PurchCommLine.FINDSET() THEN
                            REPEAT
                                InsertRefBuffer(HeaderEntryNo, 0, GlobRefLine."Reference Type"::Note, PurchCommLine.Comment, 0D);
                            UNTIL PurchCommLine.NEXT() = 0;

                        if not TempPurchCrMemoLine.IsTemporary then
                            Error('');
                        TempPurchCrMemoLine.reset;
                        TempPurchCrMemoLine.DeleteAll();

                        OnBeforeCreateInvoiceLineForPurch(PurchCrMemoLine, TempPurchCrMemoLine);
                        CreateTempPurchCrMemoLines(PurchCrMemoLine, TempPurchCrMemoLine);
                        OnAfterCreateInvoiceLineForPurch(PurchCrMemoLine, TempPurchCrMemoLine);

                        TempPurchCrMemoLine.FINDSET();
                        LineNo := 0;
                        REPEAT
                            IF (TempPurchCrMemoLine.Type.AsInteger() > 0) AND (TempPurchCrMemoLine."No." <> '') AND (TempPurchCrMemoLine.Quantity <> 0) THEN BEGIN
                                LineNo += 1;
                                ItemName := '';
                                Desc := '';
                                CASE EInvSetup."Item Name Source" OF
                                    EInvSetup."Item Name Source"::LineDescription:
                                        BegIN
                                            ItemName := TempPurchCrMemoLine.Description;
                                            Desc := TempPurchCrMemoLine.Description;
                                        end;
                                    EInvSetup."Item Name Source"::AccName:
                                        BEGIN
                                            ItemName := GetSourceDesc(TempPurchCrMemoLine.Type.AsInteger(), TempPurchCrMemoLine."No.");
                                            Desc := TempPurchCrMemoLine.Description;
                                        END;
                                END;

                                OnAfterCreatePurchLineDescription(TempPurchCrMemoLine.Type, TempPurchCrMemoLine."No.", ItemName, Desc);

                                LineExtAmt := (TempPurchCrMemoLine.Quantity * TempPurchCrMemoLine."Direct Unit Cost") -
                                    (TempPurchCrMemoLine."Line Discount Amount"); //+ TempPurchCrMemoLine."Inv. Discount Amount"


                                OnBeforeInsertInvLinePurch(TempPurchCrMemoLine, LineExtAmt);

                                InsertInvLine(HeaderEntryNo,
                                  LineNo,
                                  TempPurchCrMemoLine."No.",
                                  TempPurchCrMemoLine.Quantity,
                                  LineExtAmt,
                                  TempPurchCrMemoLine."Line Discount Amount", // + TempPurchCrMemoLine."Inv. Discount Amount"
                                  TempPurchCrMemoLine.Amount,
                                  TempPurchCrMemoLine."Amount Including VAT" - TempPurchCrMemoLine.Amount,
                                  ItemName,
                                  Desc,
                                  TempPurchCrMemoLine."Direct Unit Cost",
                                  TempPurchCrMemoLine."Unit of Measure Code",
                                  FindPurchReturnCrossRef(TempPurchCrMemoLine),
                                  FindPurchReturnBarcode(TempPurchCrMemoLine),
                                  PurchCrMemoHeader."Shipment Method Code",
                                  PurchCrMemoHeader."Transport Method",
                                  TempPurchCrMemoLine."PRG_Tariff Number",
                                  GlobEInvHeader.CustCountryName,
                                  GlobEInvHeader.CustCityName,
                                  TempPurchCrMemoLine."PRG_Package Brand",
                                  TempPurchCrMemoLine."PRG_Packagin Type Code",
                                  TempPurchCrMemoLine."PRG_Actual Package Quantity",
                                  TempPurchCrMemoLine."PRG_Carriage Amount",
                                  TempPurchCrMemoLine."PRG_Insurance Amount",
                                  TempPurchCrMemoLine."Item Category Code",
                                  TempPurchCrMemoLine.RecordId);

                                TaxType.INIT();
                                IF TempPurchCrMemoLine."PRG_E-Invoice Tax Type Code" <> '' THEN
                                    TaxType.GET(TempPurchCrMemoLine."PRG_E-Invoice Tax Type Code");

                                IF TaxType.Type <> TaxType.Type::Exported THEN BEGIN
                                    SetTaxLine(HeaderEntryNo, EInvSetup."VAT Tax Type Code",
                                      TempPurchCrMemoLine."Amount Including VAT" - TempPurchCrMemoLine.Amount + TempPurchCrMemoLine."Unit Volume",//Used As VAT Deduction Field On Temp Record
                                      TempPurchCrMemoLine.Amount, TempPurchCrMemoLine."VAT %");
                                    IF TempPurchCrMemoLine."PRG_E-Invoice Tax Type Code" <> '' THEN
                                        SetTaxLine(HeaderEntryNo, TempPurchCrMemoLine."PRG_E-Invoice Tax Type Code",
                                          TempPurchCrMemoLine."Amount Including VAT" - TempPurchCrMemoLine.Amount + TempPurchCrMemoLine."Unit Volume",//Used As VAT Deduction Field On Temp Record
                                          TempPurchCrMemoLine.Amount, 0);

                                END ELSE
                                    SetTaxLine(HeaderEntryNo, PurchCrMemoLine."PRG_E-Invoice Tax Type Code",
                                      TempPurchCrMemoLine."Amount Including VAT" - TempPurchCrMemoLine.Amount + TempPurchCrMemoLine."Unit Volume",//Used As VAT Deduction Field On Temp Record
                                      TempPurchCrMemoLine.Amount, TempPurchCrMemoLine."VAT %");

                                OnAfterCreateGlobEInvoiceLine(GlobEInvLine);

                            END else
                                IF (TempPurchCrMemoLine.Type = TempPurchCrMemoLine.Type::" ") then
                                    IF EInvSetup."Note Info. Source" IN [EInvSetup."Note Info. Source"::"Invoice Line", EInvSetup."Note Info. Source"::"Comment Line Plus Inv. Line"] THEN
                                        InsertRefBuffer(HeaderEntryNo, LineNo, GlobRefLine."Reference Type"::Note, TempPurchCrMemoLine.Description, 0D);

                        UNTIL TempPurchCrMemoLine.NEXT() = 0;

                        OnAfterCreateInvoiceLines(HeaderEntryNo);

                        OnBeforeCreateShipmentReference(HeaderEntryNo, TempSalesShptLine, TempReturnShptLine);
                        CreateShipRef();

                        InsertPaymentMethodRef(PurchCrMemoHeader."Payment Method Code", PurchCrMemoHeader."Due Date");

                        OnAfterInsertPaymentMethodReference(Queue, HeaderEntryNo);

                        PurchCrMemoHeader.CALCFIELDS(PurchCrMemoHeader."Amount Including VAT");
                        TRWord := '';
                        IF PurchCrMemoHeader."Amount Including VAT" <> 0 THEN
                            TRWord := NumberReader.GetWords('', PurchCrMemoHeader."Amount Including VAT", PurchCrMemoHeader."Currency Code");

                        InsertRefBuffer(HeaderEntryNo, 0, GlobRefLine."Reference Type"::Note, Text001 + TRWord, 0D);

                        GetInvSetup();
                        IF EInvSetup."Send ERP Doc. Number As Note" THEN
                            InsertRefBuffer(HeaderEntryNo, 0, GlobRefLine."Reference Type"::Note, STRSUBSTNO(Text056, PurchCrMemoHeader."No."), 0D);

                        IF (IntSetup."E-Archive Integrator" = IntSetup."E-Archive Integrator"::Efinans) and (PurchCrMemoHeader."PRG_E-Platform Type" = PurchCrMemoHeader."PRG_E-Platform Type"::EArchive) then
                            InsertRefBuffer(HeaderEntryNo, 0, GlobRefLine."Reference Type"::Note, STRSUBSTNO(Text057), 0D);

                        IF EInvSetup."Note Info. Source" IN [EInvSetup."Note Info. Source"::"Comment Line", EInvSetup."Note Info. Source"::"Comment Line Plus Inv. Line"] THEN BEGIN
                            PurchCommLine.SETRANGE("Document Type", PurchCommLine."Document Type"::"Posted Invoice");
                            PurchCommLine.SETRANGE("No.", PurchCrMemoHeader."No.");
                            IF PurchCommLine.FINDSET() THEN
                                REPEAT
                                    InsertRefBuffer(HeaderEntryNo, 0, GlobRefLine."Reference Type"::Note, PurchCommLine.Comment, 0D);
                                UNTIL PurchCommLine.NEXT() = 0;
                        end;

                        GlobEInvHeader.CALCFIELDS(TaxExclusiveAmount, TaxInclusiveAmount);
                        UpdateQueueForInvInfo(Queue, GlobEInvHeader.IssueDate, GlobEInvHeader.TaxExclusiveAmount, GlobEInvHeader.TaxInclusiveAmount, Vend."No.");

                        IF GlobEInvHeader.InvoiceType = GlobEInvHeader.InvoiceType::Exported THEN BEGIN
                            PurchCrMemoHeader.CALCFIELDS(Amount);
                            GlobEInvHeader.PayableAmount := PurchCrMemoHeader.Amount;
                            GlobEInvHeader.MODIFY();
                        END;

                        EInvoiceFixNotes.reset;
                        EInvoiceFixNotes.SetFilter("Fix Note", '<>%1');
                        EInvoiceFixNotes.SetRange("For Purchase", true);
                        if EInvoiceFixNotes.FindSet() then
                            repeat
                                InsertRefBuffer(HeaderEntryNo, 0, GlobRefLine."Reference Type"::Note, EInvoiceFixNotes."Fix Note", 0D);
                            until EInvoiceFixNotes.Next() = 0;

                    END ELSE BEGIN
                        Queue."Queue Status" := Queue."Queue Status"::Failed;
                        Queue.Description := Text002 + Text004;
                        EXIT;
                    END;

                END;

            DATABASE::"Cust. Ledger Entry":
                begin
                    RecRef.SETTABLE(CustLedgEntry);
                    Cust.GET(CustLedgEntry."Customer No.");

                    GlobCVInfo.TESTFIELD("Profile ID");
                    Cust.TESTFIELD("Country/Region Code");
                    Cust.TESTFIELD(City);
                    Cust.TESTFIELD(County);

                    CustLedgEntry.CALCFIELDS("Original Amount");
                    TaxAmt := GetTaxAmtInLCY(CustLedgEntry."Transaction No.") * CustLedgEntry."Original Currency Factor";
                    TaxExclAmt := ROUND(CustLedgEntry."Original Amount" - TaxAmt, 0.01);

                    GlobEInvHeader.IssueDate := CustLedgEntry."Posting Date";
                    GlobEInvHeader.InvoiceType := GlobEInvHeader.InvoiceType::Sales;
                    GlobEInvHeader.DocumentCurrencyCode := GetCurrCode(CustLedgEntry."Currency Code");
                    IF (CustLedgEntry."Original Currency Factor" <> 0) AND (CustLedgEntry."Original Currency Factor" <> 1) THEN
                        GlobEInvHeader.DocumentCurrencyRate := ROUND(1 / CustLedgEntry."Original Currency Factor", 0.00001)
                    ELSE
                        GlobEInvHeader.DocumentCurrencyRate := 1;
#pragma warning disable AL0432
                    GlobEInvHeader.CustWebsiteURI := Cust."Home Page";
#pragma warning restore AL0432
                    GlobEInvHeader.CustCitySubdivisionName := Cust.County;
                    GlobEInvHeader.CustCityName := Cust.City;
                    GlobEInvHeader.CustPostalZone := Cust."Post Code";
                    GlobEInvHeader.CustCountryName := GetCountryCode(Cust."Country/Region Code");
                    GlobEInvHeader.CustStreetName := Cust.Address + ' ' + Cust."Address 2";
                    GlobEInvHeader.CustTaxOfficeName := Cust."Tax Area Code";
                    GlobEInvHeader.CustTelephone := Cust."Phone No.";
                    GlobEInvHeader.CustTelefax := Cust."Fax No.";

                    IF GlobCVInfo."Integration Type" = GlobCVInfo."Integration Type"::EInvoice THEN BEGIN
                        GlobEInvHeader.CustIdentifier := FindIdentifier(GlobCVInfo."E-mail Address", '');
                        GlobEInvHeader.CustElectronicMail := Cust."E-Mail";
                    END ELSE BEGIN
                        GlobEInvHeader.CustElectronicMail := GlobCVInfo."E-mail Address";
                        GlobEInvHeader.CustIdentifier := '';
                    END;

                    GlobEInvHeader.PaymentDueDate := CustLedgEntry."Due Date";
                    GlobEInvHeader.PayableAmount := ROUND(CustLedgEntry."Original Amount", 0.01);
                    GlobEInvHeader.IntegrationType := GlobCVInfo."Integration Type";
                    HeaderEntryNo := FindNextHeaderEntryNo;
                    IF HeaderEntryNo <> 0 THEN BEGIN

                        GlobEInvHeader."Entry No." := HeaderEntryNo;
                        GlobEInvHeader.INSERT;

                        CASE EInvSetup."Line Grp.Type For Jnl. Entry" OF

                            EInvSetup."Line Grp.Type For Jnl. Entry"::VATPostingGroup:
                                BEGIN
                                    InsertTempVATEntry(CustLedgEntry."Transaction No.");
                                    LineNo := 0;
                                    IF TempVATEntry.FINDSET THEN
                                        REPEAT
                                            LineNo += 1;

                                            ItemName := '';
                                            Desc := '';
                                            CASE EInvSetup."Item Name Source" OF
                                                EInvSetup."Item Name Source"::LineDescription:
                                                    ItemName := CustLedgEntry.Description;
                                                EInvSetup."Item Name Source"::AccName:
                                                    BEGIN
                                                        ItemName := EInvSetup."Default Item Name";
                                                        Desc := CustLedgEntry.Description;
                                                    END;
                                            END;

                                            InsertInvLine(HeaderEntryNo,
                                              LineNo,
                                              EInvSetup."Default Item No.",
                                              1,
                                              TempVATEntry.Base * CustLedgEntry."Original Currency Factor",
                                              0,
                                              TempVATEntry.Base * CustLedgEntry."Original Currency Factor",
                                              TempVATEntry.Amount * CustLedgEntry."Original Currency Factor",
                                              ItemName,
                                              Desc,
                                              TempVATEntry.Base * CustLedgEntry."Original Currency Factor",
                                              EInvSetup."Default Unit of Measure Code",
                                              '', '', '', '', '', '', '', '', '', 0, 0, 0, '', RecordID);

                                            SetTaxLine(HeaderEntryNo,
                                              EInvSetup."VAT Tax Type Code",
                                              TempVATEntry.Amount * CustLedgEntry."Original Currency Factor",
                                              TempVATEntry.Base * CustLedgEntry."Original Currency Factor",
                                              GetTaxRate(TempVATEntry."Gen. Bus. Posting Group", TempVATEntry."Gen. Prod. Posting Group"));

                                        UNTIL TempVATEntry.NEXT = 0;

                                    GlobEInvHeader."Line Count" := LineNo;
                                    GlobEInvHeader.MODIFY;

                                    InsertPaymentMethodRef('', CustLedgEntry."Due Date");

                                    IF (IntSetup."E-Archive Integrator" = IntSetup."E-Archive Integrator"::Efinans) and (Queue.IntegrationType = Queue.IntegrationType::EArchive) THEN
                                        InsertRefBuffer(HeaderEntryNo, 0, GlobRefLine."Reference Type"::Note, Text057, 0D);

                                    IF CustLedgEntry."Document Type" = CustLedgEntry."Document Type"::"Finance Charge Memo" THEN BEGIN
                                        IssuedFinChargeMemoLine.SETRANGE("Finance Charge Memo No.", CustLedgEntry."Document No.");
                                        IssuedFinChargeMemoLine.SETRANGE(Type, IssuedFinChargeMemoLine.Type::"Customer Ledger Entry");
                                        IssuedFinChargeMemoLine.SETRANGE("Detailed Interest Rates Entry", FALSE);
                                        IssuedFinChargeMemoLine.SETFILTER("Document No.", '<>%1', '');
                                        IF IssuedFinChargeMemoLine.FINDFIRST THEN
                                            REPEAT
                                                IF NoteCustLedgEntry.GET(IssuedFinChargeMemoLine."Entry No.") THEN
                                                    IF NoteCustLedgEntry."External Document No." <> '' THEN
                                                        InsertRefBuffer(HeaderEntryNo, 0, GlobRefLine."Reference Type"::Note, NoteCustLedgEntry."External Document No.", 0D);
                                            UNTIL IssuedFinChargeMemoLine.NEXT = 0;
                                    END;

                                END;
                        END;

                        GlobEInvHeader.CALCFIELDS(TaxExclusiveAmount, TaxInclusiveAmount);
                        UpdateQueueForInvInfo(Queue, GlobEInvHeader.IssueDate,
                          GlobEInvHeader.TaxExclusiveAmount, GlobEInvHeader.TaxInclusiveAmount, Cust."No.");

                    END ELSE BEGIN
                        Queue."Queue Status" := Queue."Queue Status"::Failed;
                        Queue.Description := Text002 + Text004;
                        EXIT;
                    end;
                end;

            Database::"Service Invoice Header":
                begin

                    RecRef.SETTABLE(ServiceInvHeader);
                    ServiceInvLine.SETRANGE("Document No.", ServiceInvHeader."No.");
                    LineCount := ServiceInvLine.COUNT;
                    IF LineCount = 0 THEN
                        EXIT;

                    Cust.GET(GlobCVInfo."CV No.");

                    GlobCVInfo.TESTFIELD("Profile ID");

                    DiscAmt := ROUND(CalcServiceInvDiscAmt(ServiceInvHeader), 0.01);
                    GlobEInvHeader.IssueDate := ServiceInvHeader."Posting Date";
                    GlobEInvHeader.InvoiceType := GlobEInvHeader.InvoiceType::Sales;
                    GlobEInvHeader.DocumentCurrencyCode := GetCurrCode(ServiceInvHeader."Currency Code");
                    IF (ServiceInvHeader."Currency Factor" <> 0) AND (ServiceInvHeader."Currency Factor" <> 1) THEN
                        GlobEInvHeader.DocumentCurrencyRate := ROUND(1 / ServiceInvHeader."Currency Factor", 0.00001)
                    ELSE
                        GlobEInvHeader.DocumentCurrencyRate := 1;

                    GlobEInvHeader."Line Count" := LineCount;
                    GlobEInvHeader.OrderNo := ServiceInvHeader."Order No.";
                    IF ServiceInvHeader."Order No." <> '' THEN
                        GlobEInvHeader.OrderDate := ServiceInvHeader."Order Date";

                    GlobEInvHeader.CustNo := GlobCVInfo."CV No.";
                    IF ServiceInvHeader."Ship-to Code" <> '' THEN
                        IF ShipToAddr.GET(Cust."No.", ServiceInvHeader."Ship-to Code") THEN
                            GlobEInvHeader.CustBranchCode := ShipToAddr.Code;
#pragma warning disable AL0432
                    GlobEInvHeader.CustWebsiteURI := Cust."Home Page";
#pragma warning restore AL0432
                    GlobEInvHeader.CustRegistrationNo := GlobCVInfo."Tax Registration No.";
                    GlobEInvHeader.CustTaxSchemeID := GlobCVInfo."TaxSchemeID Buffer";
                    GlobEInvHeader.CustFirstName := GlobCVInfo."First Name";
                    GlobEInvHeader.CustFamilyName := GlobCVInfo."Family Name";

                    IF (EInvSetup."E-Invoice Addres" = EInvSetup."E-Invoice Addres"::"Fatura Adresi") OR (ServiceInvHeader."Ship-to Code" = '') THEN BEGIN
                        GlobEInvHeader.CustName := ServiceInvHeader."Bill-to Name";
                        GlobEInvHeader.CustBuildingNumber := '';
                        IF ServiceInvHeader."Bill-to County" <> '' THEN
                            GlobEInvHeader.CustCitySubdivisionName := ServiceInvHeader."Bill-to County"
                        ELSE BEGIN
                            Cust.TESTFIELD(County);
                            GlobEInvHeader.CustCitySubdivisionName := Cust.County;
                        END;

                        IF ServiceInvHeader."Bill-to City" <> '' THEN
                            GlobEInvHeader.CustCityName := ServiceInvHeader."Bill-to City"
                        ELSE BEGIN
                            Cust.TESTFIELD(City);
                            GlobEInvHeader.CustCityName := Cust.City
                        END;

                        GlobEInvHeader.CustPostalZone := ServiceInvHeader."Bill-to Post Code";
                        IF ServiceInvHeader."Bill-to Country/Region Code" <> '' THEN
                            GlobEInvHeader.CustCountryName := GetCountryCode(ServiceInvHeader."Bill-to Country/Region Code")
                        ELSE
                            GlobEInvHeader.CustCountryName := GetCountryCode(Cust."Country/Region Code");
                        GlobEInvHeader.CustStreetName := ServiceInvHeader."Bill-to Address" + ' ' + ServiceInvHeader."Bill-to Address 2";
                    END ELSE BEGIN
                        GlobEInvHeader.CustName := ServiceInvHeader."Ship-to Name";
                        GlobEInvHeader.CustBuildingNumber := '';
                        IF ServiceInvHeader."Ship-to County" <> '' THEN
                            GlobEInvHeader.CustCitySubdivisionName := ServiceInvHeader."Ship-to County"
                        ELSE BEGIN
                            Cust.TESTFIELD(County);
                            GlobEInvHeader.CustCitySubdivisionName := Cust.County;
                        END;

                        IF ServiceInvHeader."Ship-to City" <> '' THEN
                            GlobEInvHeader.CustCityName := ServiceInvHeader."Ship-to City"
                        ELSE BEGIN
                            Cust.TESTFIELD(City);
                            GlobEInvHeader.CustCityName := Cust.City
                        END;

                        GlobEInvHeader.CustPostalZone := ServiceInvHeader."Ship-to Post Code";
                        IF ServiceInvHeader."Ship-to Country/Region Code" <> '' THEN
                            GlobEInvHeader.CustCountryName := GetCountryCode(ServiceInvHeader."Ship-to Country/Region Code")
                        ELSE
                            GlobEInvHeader.CustCountryName := GetCountryCode(Cust."Country/Region Code");
                        GlobEInvHeader.CustStreetName := ServiceInvHeader."Ship-to Address" + ' ' + ServiceInvHeader."Ship-to Address 2";

                        GlobEInvHeader.CustTaxOfficeName := ServiceInvHeader."Tax Area Code";
                        GlobEInvHeader.CustTelephone := Cust."Phone No.";
                        GlobEInvHeader.CustTelefax := Cust."Fax No.";
                        IF GlobCVInfo."Integration Type" = GlobCVInfo."Integration Type"::EInvoice THEN BEGIN
                            GlobEInvHeader.CustIdentifier := FindIdentifier(GlobCVInfo."E-mail Address", ServiceInvHeader."Ship-to Code");
                            GlobEInvHeader.CustElectronicMail := Cust."E-Mail";
                        END ELSE BEGIN
                            GlobEInvHeader.CustElectronicMail := GlobCVInfo."E-mail Address";
                            GlobEInvHeader.CustIdentifier := '';
                            GlobEInvHeader.PaymentMethodNote := GetEArchPaymentMethod(ServiceInvHeader."Payment Method Code");
                        END;
                    end;

                    GlobEInvHeader.PaymentDueDate := ServiceInvHeader."Due Date";
                    GlobEInvHeader.AllowanceChargeIndicator := 'false';
                    ServiceInvAmount := GetAmountServiceInv(ServiceInvHeader."No.");
                    ServiceInvAmountVAT := GetAmountIncVATServiceInv(ServiceInvHeader."No.");
                    GlobEInvHeader.PayableAmount := ServiceInvAmountVAT;
                    IF ServiceInvAmountVAT <> 0 THEN
                        GlobEInvHeader.AllowanceChargeRate := ROUND((DiscAmt / (ServiceInvAmount + DiscAmt)) * 100, 0.0001)
                    ELSE
                        GlobEInvHeader.AllowanceChargeRate := 1;

                    GlobEInvHeader.AllowanceChargeAmtInvoice := DiscAmt;
                    GlobEInvHeader.IntegrationType := GlobCVInfo."Integration Type";


                    HeaderEntryNo := FindNextHeaderEntryNo;

                    IF HeaderEntryNo <> 0 THEN BEGIN

                        GlobEInvHeader."Entry No." := HeaderEntryNo;
                        GlobEInvHeader.INSERT;

                        ServiceInvHeader.CALCFIELDS("Amount Including VAT");
                        TRWord := '';
                        IF ServiceInvHeader."Amount Including VAT" <> 0 THEN
                            TRWord := NumberReader.GetWords('', ServiceInvHeader."Amount Including VAT", ServiceInvHeader."Currency Code");

                        OnBeforeTRWordReference(Queue, IsHandle);
                        IF NOT IsHandle THEN
                            InsertRefBuffer(HeaderEntryNo, 0, GlobRefLine."Reference Type"::Note, Text001 + TRWord, 0D);

                        IF EInvSetup."Note Info. Source" IN [EInvSetup."Note Info. Source"::"Comment Line", EInvSetup."Note Info. Source"::"Comment Line Plus Inv. Line"] THEN BEGIN
                            ServiceCommLine.SETRANGE(Type, ServiceCommLine.Type::General);
                            ServiceCommLine.SETRANGE("No.", SalesInvHeader."No.");
                            IF ServiceCommLine.FINDSET() THEN
                                REPEAT
                                    InsertRefBuffer(HeaderEntryNo, 0, GlobRefLine."Reference Type"::Note, ServiceCommLine.Comment, 0D);
                                UNTIL ServiceCommLine.NEXT() = 0;
                        end;

                        ServiceInvLine.FINDSET;
                        LineNo := 0;

                        REPEAT
                            IF (ServiceInvLine.Type.AsInteger() > 0) AND (ServiceInvLine."No." <> '') AND (ServiceInvLine.Quantity <> 0) THEN BEGIN
                                LineNo := LineNo + 1;
                                ItemName := '';
                                Desc := '';

                                CASE EInvSetup."Item Name Source" OF
                                    EInvSetup."Item Name Source"::LineDescription:
                                        ItemName := ServiceInvLine.Description;

                                    EInvSetup."Item Name Source"::AccName:
                                        BEGIN
                                            ItemName := GetSourceDesc(ServiceInvLine.Type.AsInteger(), ServiceInvLine."No.");
                                            Desc := ServiceInvLine.Description;
                                        END;
                                END;

                                LineExtAmt := (ServiceInvLine.Quantity * ServiceInvLine."Unit Price") -
                                    (ServiceInvLine."Line Discount Amount");

                                InsertInvLine(HeaderEntryNo,
                                LineNo,
                                ServiceInvLine."No.",
                                ServiceInvLine.Quantity,
                                LineExtAmt,
                                ServiceInvLine."Line Discount Amount",
                                ServiceInvLine.Amount,
                                ServiceInvLine."Amount Including VAT" - ServiceInvLine.Amount,
                                ItemName,
                                Desc,
                                ServiceInvLine."Unit Price",
                                ServiceInvLine."Unit of Measure Code",
                                ServiceInvLine."Item Reference No.",
                                ServiceInvLine."Item Reference Type No.",
                                ServiceInvLine."Transport Method",
                                '',
                                GlobEInvHeader.CustCountryName,
                                GlobEInvHeader.CustCityName,
                                '',
                                '',
                                '',
                                0,
                                0,
                                0,
                                ServiceInvLine."Item Category Code",
                                ServiceInvLine.RecordId);

                                TaxType.INIT();

                                IF ServiceInvLine."PRG_E-Invoice Tax Type Code" <> '' THEN
                                    TaxType.GET(ServiceInvLine."PRG_E-Invoice Tax Type Code");


                                IF TaxType.Type <> TaxType.Type::Exported THEN BEGIN
                                    SetTaxLine(
                                    HeaderEntryNo, EInvSetup."VAT Tax Type Code",
                                    ServiceInvLine."Amount Including VAT" - ServiceInvLine.Amount,
                                    ServiceInvLine.Amount, ServiceInvLine."VAT %");

                                    IF ServiceInvLine."PRG_E-Invoice Tax Type Code" <> '' THEN
                                        SetTaxLine(
                                        HeaderEntryNo, ServiceInvLine."PRG_E-Invoice Tax Type Code",
                                        ServiceInvLine."Amount Including VAT" - ServiceInvLine.Amount,
                                        ServiceInvLine.Amount,
                                        0);

                                END ELSE
                                    SetTaxLine(
                                    HeaderEntryNo, ServiceInvLine."PRG_E-Invoice Tax Type Code",
                                    ServiceInvLine."Amount Including VAT" - ServiceInvLine.Amount, ServiceInvLine.Amount, ServiceInvLine."VAT %");


                            END ELSE
                                IF (ServiceInvLine.Type = ServiceInvLine.Type::" ") then
                                    IF EInvSetup."Note Info. Source" IN [EInvSetup."Note Info. Source"::"Invoice Line", EInvSetup."Note Info. Source"::"Comment Line Plus Inv. Line"] THEN
                                        InsertRefBuffer(HeaderEntryNo, LineNo, GlobRefLine."Reference Type"::Note, ServiceInvLine.Description, 0D);

                            FindServiceShipments(ServiceInvLine);

                        UNTIL ServiceInvLine.NEXT = 0;

                        CreateShipRef();


                        InsertPaymentMethodRef(ServiceInvHeader."Payment Method Code", ServiceInvHeader."Due Date");

                        IF (IntSetup."E-Invoice Integrator" = IntSetup."E-Invoice Integrator"::Efinans) AND (Queue.IntegrationType = Queue.IntegrationType::EArchive) THEN
                            InsertRefBuffer(HeaderEntryNo, 0, GlobRefLine."Reference Type"::Note, Text057, 0D);

                        GlobEInvHeader.CALCFIELDS(TaxExclusiveAmount, TaxInclusiveAmount);
                        UpdateQueueForInvInfo(Queue, GlobEInvHeader.IssueDate, GlobEInvHeader.TaxExclusiveAmount, GlobEInvHeader.TaxInclusiveAmount, Cust."No.");
                        EInvoiceFixNotes.reset;
                        EInvoiceFixNotes.SetFilter("Fix Note", '<>%1');
                        EInvoiceFixNotes.SetRange("For Service", true);
                        if EInvoiceFixNotes.FindSet() then
                            repeat
                                InsertRefBuffer(HeaderEntryNo, 0, GlobRefLine."Reference Type"::Note, EInvoiceFixNotes."Fix Note", 0D);
                            until EInvoiceFixNotes.Next() = 0;

                    END ELSE BEGIN
                        Queue."Queue Status" := Queue."Queue Status"::Failed;
                        Queue.Description := Text002 + Text004;
                        EXIT;
                    END;
                END;
        END;
    end;

    local procedure FindServiceShipments(VAR ServiceInvLine: Record "Service Invoice Line"): Code[30]
    var
        TempServiceShptLine2: Record "Service Shipment Line";
    begin
        IF ServiceInvLine.Type = ServiceInvLine.Type::Item THEN BEGIN
            ServiceInvLine.GetServShptLines(TempServiceShptLine2);
            IF TempServiceShptLine2.FINDSET THEN
                REPEAT
                    TempServiceShptLine := TempServiceShptLine2;
                    IF TempServiceShptLine.INSERT THEN;
                UNTIL TempServiceShptLine2.NEXT = 0;
        END;
    end;

    local procedure GetAmountIncVATServiceInv(pNo: Code[20]): Decimal
    var
        ServiceInvLine: Record "Service Invoice Line";
        locAmountVAT: Decimal;
    begin
        ServiceInvLine.SETRANGE("Document No.", pNo);
        IF ServiceInvLine.FINDSET THEN
            REPEAT
                locAmountVAT := locAmountVAT + ServiceInvLine."Amount Including VAT";
            UNTIL ServiceInvLine.NEXT = 0;

        EXIT(locAmountVAT);
    end;

    local procedure GetAmountServiceInv(pNo: Code[20]): Decimal
    var
        ServiceInvLine: Record "Service Invoice Line";
        locAmount: Decimal;
    begin
        ServiceInvLine.SETRANGE("Document No.", pNo);
        IF ServiceInvLine.FINDSET THEN
            REPEAT
                locAmount := locAmount + ServiceInvLine.Amount;
            UNTIL ServiceInvLine.NEXT = 0;

        EXIT(locAmount);
    end;

    local procedure CalcServiceInvDiscAmt(ServiceInvHeader: Record "Service Invoice Header") InvDiscAmount: Decimal
    var
        ServiceInvLine: Record "Service Invoice Line";
    begin
        ServiceInvLine.SETRANGE("Document No.", ServiceInvHeader."No.");
        IF ServiceInvLine.FINDSET THEN
            REPEAT
                IF ServiceInvHeader."Prices Including VAT" THEN
                    InvDiscAmount := InvDiscAmount + (ServiceInvLine."Inv. Discount Amount" + ServiceInvLine."Line Discount Amount")
                        / (1 + ServiceInvLine."VAT %" / 100)
                ELSE
                    InvDiscAmount := InvDiscAmount + (ServiceInvLine."Inv. Discount Amount" + ServiceInvLine."Line Discount Amount");
            UNTIL ServiceInvLine.NEXT = 0;

        EXIT(InvDiscAmount);
    end;

    procedure CreateInvoiceID(EInvHeader: Record "PRG_E-Invoice Header"): Text[30]
    var
        UserSetup: Record "User Setup";
        NoSeriesMgt: Codeunit "No. Series";
        IsHandle: Boolean;
        UseSetupNo: Boolean;
        InvoiceID: Text[30];
    begin

        IF EInvHeader.IssueDate = 0D THEN
            EInvHeader.IssueDate := WORKDATE();

        OnBeforeAssignInvoiceID(EInvHeader, IsHandle, InvoiceID);
        if IsHandle then
            exit(InvoiceID);

        CASE EInvHeader.IntegrationType OF

            EInvHeader.IntegrationType::EInvoice:
                BEGIN
                    UseSetupNo := FALSE;
                    IF UserSetup.GET(USERID) THEN BEGIN
                        IF UserSetup."PRG_E-Invoice No. Series" <> '' THEN
                            EXIT(NoSeriesMgt.GetNextNo(UserSetup."PRG_E-Invoice No. Series", EInvHeader.IssueDate, TRUE))
                        ELSE
                            UseSetupNo := TRUE;
                    END ELSE
                        UseSetupNo := TRUE;

                    IF UseSetupNo THEN BEGIN
                        IF NOT GetInvSetup() THEN
                            ERROR(Text048);
                        EInvSetup.TESTFIELD("E-Invoice No. Series");
                        InvoiceID := NoSeriesMgt.GetNextNo(EInvSetup."E-Invoice No. Series", EInvHeader.IssueDate, TRUE);
                        EXIT(InvoiceID);
                    END;
                END;

            EInvHeader.IntegrationType::EArchive:
                BEGIN
                    CASE EInvHeader.SalesType OF

                        EInvHeader.SalesType::" ":
                            BEGIN
                                UseSetupNo := FALSE;
                                IF UserSetup.GET(USERID) THEN BEGIN
                                    IF UserSetup."PRG_E-Archive No. Series" <> '' THEN
                                        EXIT(NoSeriesMgt.GetNextNo(UserSetup."PRG_E-Archive No. Series", EInvHeader.IssueDate, TRUE))
                                    ELSE
                                        UseSetupNo := TRUE;
                                END ELSE
                                    UseSetupNo := TRUE;

                                IF UseSetupNo THEN BEGIN
                                    IF NOT GetInvSetup() THEN
                                        ERROR(Text048);
                                    EInvSetup.TESTFIELD("E-Archive No. Series");
                                    InvoiceID := NoSeriesMgt.GetNextNo(EInvSetup."E-Archive No. Series", EInvHeader.IssueDate, TRUE);
                                    EXIT(InvoiceID);
                                END;
                            END;

                        EInvHeader.SalesType::Internet:
                            BEGIN
                                EInvSetup.TESTFIELD("Internet Sales No. Series");
                                EXIT(NoSeriesMgt.GetNextNo(EInvSetup."Internet Sales No. Series", EInvHeader.IssueDate, TRUE));
                            END;

                        ELSE
                            ERROR(Text046, EInvHeader.FIELDCAPTION("Entry No."), EInvHeader."Entry No.");
                    END;
                END;

            ELSE
                ERROR(Text047, EInvHeader.FIELDCAPTION("Entry No."), EInvHeader."Entry No.");
        END;
    end;

    procedure DownloadXml(EntryNo: Integer)
    var
        Queue: Record "PRG_E-Invoice Queue";
        FileMgt: Codeunit "File Management";
        TempBlob: Codeunit "Temp Blob";
        Outstr: OutStream;
        ToFile: Text;
        XmlDoc: XmlDocument;
    begin
        Queue.GET(EntryNo);
        Clear(UBLMgt);
        if Queue.InvoiceID = '' then
            Queue.InvoiceID := 'Preview';

        XMLdoc := UBLMgt.CreateOutgoingXML(Queue, true);

        TempBlob.CreateOutStream(Outstr, TextEncoding::UTF8);
        XmlDoc.WriteTo(Outstr);

        ToFile := Queue.CVNo + '-' + Queue.CVName + '.xml';

        FileMgt.BLOBExportWithEncoding(TempBlob, ToFile, true, TextEncoding::UTF8);

    end;

    procedure ExecExportControls()
    begin
        GetExportSetup();
        ExportSetup.TESTFIELD(ExportSetup."Ministry VKN");
        ExportSetup.TESTFIELD(ExportSetup."Ministry Party Name");
        ExportSetup.TESTFIELD(ExportSetup."Ministry Adress");
        ExportSetup.TESTFIELD(ExportSetup."Ministry City Subdivision Name");
        ExportSetup.TESTFIELD(ExportSetup."Ministry CityName");
        ExportSetup.TESTFIELD(ExportSetup."Ministry PostalZone");
        ExportSetup.TESTFIELD(ExportSetup."Ministry CountryName");
        ExportSetup.TESTFIELD(ExportSetup."Ministry Party Tax Scheme");
        ExportSetup.TESTFIELD(ExportSetup."E-Export Starting Date");
        ExportSetup.TESTFIELD(ExportSetup."Ministry Web Adress");
        ExportSetup.TESTFIELD(ExportSetup."Ministry Building Number");
        ExportSetup.TESTFIELD(ExportSetup."Ministry TaxScheme");
        ExportSetup.TESTFIELD(ExportSetup."Ministry Mail Adress");
        ExportSetup.TESTFIELD(ExportSetup."Ministry Telephone");
        ExportSetup.TESTFIELD(ExportSetup."Ministry Telefax");
        ExportSetup.TESTFIELD(ExportSetup."Ministry URN");
        ExportSetup.TESTFIELD(ExportSetup."Company Country/Region Code");
        ExportSetup.TESTFIELD("Default Delivery Terms ID");
    end;

    procedure ExecPostControls()
    begin
        GlobEInvLine.RESET();
        GlobEInvLine.SETRANGE("Header Entry No.", GlobEInvHeader."Entry No.");
        IF GlobEInvLine.ISEMPTY THEN
            ERROR(Text024, GlobEInvLine.TABLECAPTION, GlobEInvHeader."G/L Register Entry No.");

        GlobEInvTaxLine.RESET();
        GlobEInvTaxLine.SETRANGE("Header Entry No.", GlobEInvHeader."Entry No.");
        IF GlobEInvTaxLine.ISEMPTY THEN
            ERROR(Text024, GlobEInvTaxLine.TABLECAPTION, GlobEInvHeader."G/L Register Entry No.");
    end;

    procedure FillCVInfoForExport(CVType: Option; CVNo: Code[20]): Boolean
    var
        Cust: Record Customer;
        Vend: Record Vendor;
    begin
        GetExportSetup();

        GlobCVInfo.INIT();
        GlobCVInfo."CV Type" := CVType;
        GlobCVInfo."CV No." := CVNo;

        CASE CVType OF
            GlobCVInfo."CV Type"::Customer:
                BEGIN
                    Cust.GET(CVNo);
                    GlobCVInfo."CV Name" := Cust.Name;
                    SplitCVName(GlobCVInfo);

                    GlobCVInfo."Integration Type" := GlobCVInfo."Integration Type"::EInvoice;
                    GlobCVInfo."Profile ID" := GlobCVInfo."Profile ID"::IHRACAT;
                    GlobCVInfo."E-mail Address" := Cust."E-Mail";
                    GlobCVInfo."E-Invoice Starting Date" := ExportSetup."E-Export Starting Date";
                    GlobCVInfo."Tax Registration No." := Cust."VAT Registration No.";
                    IF (Cust."Country/Region Code" = ExportSetup."Company Country/Region Code") OR (Cust."Country/Region Code" = '') THEN
                        GlobCVInfo."Tax Registration No." := '11111111111';
                END;

            GlobCVInfo."CV Type"::Vendor:
                BEGIN
                    Vend.GET(CVNo);
                    GlobCVInfo."CV Name" := Vend.Name;
                    SplitCVName(GlobCVInfo);

                    GlobCVInfo."Integration Type" := GlobCVInfo."Integration Type"::EInvoice;
                    GlobCVInfo."Profile ID" := GlobCVInfo."Profile ID"::IHRACAT;
                    GlobCVInfo."E-mail Address" := Vend."E-Mail";
                    GlobCVInfo."E-Invoice Starting Date" := ExportSetup."E-Export Starting Date";
                    GlobCVInfo."Tax Registration No." := Vend."VAT Registration No.";
                    IF (Vend."Country/Region Code" = ExportSetup."Company Country/Region Code") OR (Vend."Country/Region Code" = '') THEN
                        GlobCVInfo."Tax Registration No." := '11111111111';
                END;

        END;

        EXIT(TRUE);
    end;


    procedure FindCVInfo(CVType: Option; CVNo: Code[20]; PostingDate: Date): Boolean
    var
        Cust: Record "Customer";
        LiableCompanies: Record "PRG_E-Invoice Liable Companies";
        lLiableCompanies: Record "PRG_E-Invoice Liable Companies";
        Vend: Record "Vendor";
        IsHandled: Boolean;
        RegistrationNo: Text;
    begin

        OnBeforeFindCVInfo(CVType, CVNo, PostingDate, GlobCVInfo, IsHandled);
        if IsHandled then
            exit;

        GetInvSetup();
        GetExportSetup();

        CASE CVType OF
            GlobCVInfo."CV Type"::Customer:
                begin
                    Cust.GET(CVNo);
                    RegistrationNo := Cust."VAT Registration No.";
                end;
            GlobCVInfo."CV Type"::Vendor:
                begin
                    Vend.GET(CVNo);
                    RegistrationNo := Vend."VAT Registration No.";
                end;
        END;

        GlobCVInfo.INIT();
        GlobCVInfo."CV Type" := CVType;
        GlobCVInfo."CV No." := CVNo;

        LiableCompanies.SetCurrentKey(Identifier);
        LiableCompanies.SetRange(Identifier, RegistrationNo);
        IF NOT LiableCompanies.FindFirst() THEN BEGIN

            IF EInvSetup."E-Archive Starting Date" = 0D THEN
                EXIT(FALSE);

            IF PostingDate < EInvSetup."E-Archive Starting Date" THEN
                EXIT(FALSE);

            CASE CVType OF

                GlobCVInfo."CV Type"::Customer:
                    BEGIN
                        GlobCVInfo."CV Name" := Cust.Name + ' ' + Cust."Name 2";
                        GlobCVInfo."Integration Type" := GlobCVInfo."Integration Type"::EArchive;
                        GlobCVInfo."Profile ID" := GlobCVInfo."Profile ID"::EARSIVFATURA;
                        GlobCVInfo."E-Invoice Starting Date" := EInvSetup."E-Archive Starting Date";
                    END;

                GlobCVInfo."CV Type"::Vendor:
                    BEGIN
                        GlobCVInfo."CV Name" := Vend.Name + ' ' + Vend."Name 2";
                        GlobCVInfo."Integration Type" := GlobCVInfo."Integration Type"::EArchive;
                        GlobCVInfo."Profile ID" := GlobCVInfo."Profile ID"::EARSIVFATURA;
                        GlobCVInfo."E-Invoice Starting Date" := EInvSetup."E-Archive Starting Date";
                    END;
            END;
        END Else begin
            GlobCVInfo."Integration Type" := GlobCVInfo."Integration Type"::EInvoice;

            CASE CVType OF

                GlobCVInfo."CV Type"::Customer:
                    BEGIN
                        Cust.TestField(PRG_Alias);
                        lLiableCompanies.SetCurrentKey(Identifier);
                        lLiableCompanies.SetRange(Identifier, RegistrationNo);
                        LiableCompanies.SetRange(Alias, Cust.PRG_Alias);
                        lLiableCompanies.FindFirst();
                        GlobCVInfo."CV Name" := Cust.Name + ' ' + Cust."Name 2";
                        GlobCVInfo."Profile ID" := Cust."PRG_Profile ID";
                        GlobCVInfo."E-Invoice Starting Date" := Library.ParseDatetime(lLiableCompanies.FirstCreationTime, 'YMD');
                        //GlobCVInfo."E-mail Address" := lLiableCompanies.Alias; //
                        GlobCVInfo."E-mail Address" := Cust.PRG_Alias;
                        GlobCVInfo."Tax Registration No." := Cust."VAT Registration No.";
                    END;

                GlobCVInfo."CV Type"::Vendor:
                    BEGIN
                        Vend.TestField(PRG_Alias);
                        lLiableCompanies.SetCurrentKey(Identifier);
                        lLiableCompanies.SetRange(Identifier, RegistrationNo);
                        LiableCompanies.SetRange(Alias, Cust.PRG_Alias);
                        lLiableCompanies.FindFirst();
                        GlobCVInfo."CV Name" := Vend.Name + ' ' + Vend."Name 2";
                        GlobCVInfo."Profile ID" := Vend."PRG_Profile ID";
                        GlobCVInfo."E-Invoice Starting Date" := Library.ParseDatetime(lLiableCompanies.FirstCreationTime, 'YMD');
                        //GlobCVInfo."E-mail Address" := lLiableCompanies.Alias; //
                        GlobCVInfo."E-mail Address" := Vend.PRG_Alias;
                        GlobCVInfo."Tax Registration No." := Vend."VAT Registration No.";
                    END;
            END;
        end;

        IF GlobCVInfo."E-Invoice Starting Date" = 0D THEN
            EXIT(FALSE);

        CASE CVType OF
            GlobCVInfo."CV Type"::Customer:
                IF GlobCVInfo."E-mail Address" = '' THEN
                    GlobCVInfo."E-mail Address" := Cust."E-Mail";
            GlobCVInfo."CV Type"::Vendor:
                IF GlobCVInfo."E-mail Address" = '' THEN
                    GlobCVInfo."E-mail Address" := Vend."E-Mail";
        END;

        CASE GlobCVInfo."Integration Type" OF

            GlobCVInfo."Integration Type"::EInvoice:
                IF PostingDate < GlobCVInfo."E-Invoice Starting Date" THEN BEGIN
                    IF (PostingDate >= EInvSetup."E-Archive Starting Date") AND (EInvSetup."E-Archive Starting Date" <> 0D) THEN BEGIN
                        GlobCVInfo."Integration Type" := GlobCVInfo."Integration Type"::EArchive;
                        GlobCVInfo."Profile ID" := GlobCVInfo."Profile ID"::EARSIVFATURA;
                        GlobCVInfo."E-Invoice Starting Date" := EInvSetup."E-Archive Starting Date";
                    END ELSE
                        EXIT(FALSE);
                END;

            GlobCVInfo."Integration Type"::EArchive:
                IF PostingDate < GlobCVInfo."E-Invoice Starting Date" THEN
                    EXIT(FALSE);
        END;

        GlobCVInfo.TESTFIELD("Profile ID");

        OnBeforeControlVATRegistrationNo(CVType, Cust, Vend, GlobCVInfo);

        IF GlobCVInfo."Integration Type" = GlobCVInfo."Integration Type"::EArchive THEN BEGIN
            CASE CVType OF

                GlobCVInfo."CV Type"::Customer:
                    BEGIN
                        CASE Cust."Country/Region Code" OF
                            '', EInvSetup."Company Country/Region Code":
                                begin
                                    IF NOT (StrLen(Cust."VAT Registration No.") IN [10, 11]) then
                                        Cust.FIELDERROR("VAT Registration No.", STRSUBSTNO(Text023, 10));
                                    GlobCVInfo."Tax Registration No." := Cust."VAT Registration No.";
                                end;
                            else begin
                                if Cust."VAT Registration No." = '' then
                                    GlobCVInfo."Tax Registration No." := '11111111111'
                                else
                                    GlobCVInfo."Tax Registration No." := Cust."VAT Registration No.";
                            end;
                        END
                    END;

                GlobCVInfo."CV Type"::Vendor:
                    BEGIN

                        CASE Vend."Country/Region Code" OF
                            '', EInvSetup."Company Country/Region Code":
                                begin
                                    IF NOT (StrLen(Vend."VAT Registration No.") IN [10, 11]) then
                                        Vend.FIELDERROR("VAT Registration No.", STRSUBSTNO(Text023, 10));
                                    GlobCVInfo."Tax Registration No." := Vend."VAT Registration No.";
                                end;
                            else begin
                                if Vend."VAT Registration No." = '' then
                                    GlobCVInfo."Tax Registration No." := '11111111111'
                                else
                                    GlobCVInfo."Tax Registration No." := Vend."VAT Registration No.";
                            end;

                        END

                    END;

            END;
        END;

        GlobCVInfo.TESTFIELD("Tax Registration No.");

        OnBeforeCheckVATLengthv2(GlobCVInfo, IsHandled);
        if IsHandled then
            exit(true);

        CASE STRLEN(GlobCVInfo."Tax Registration No.") OF
            10:
                BEGIN
                    GlobCVInfo.TESTFIELD("CV Name");
                    GlobCVInfo."TaxSchemeID Buffer" := 'VKN';
                END;
            11:
                BEGIN
                    IF (GlobCVInfo."First Name" = '') OR (GlobCVInfo."Family Name" = '') THEN
                        SplitCVName(GlobCVInfo);
                    GlobCVInfo.TESTFIELD("First Name");
                    GlobCVInfo.TESTFIELD("Family Name");
                    GlobCVInfo."TaxSchemeID Buffer" := 'TCKN';
                END;
            ELSE
                GlobCVInfo.FIELDERROR("Tax Registration No.", Text033);
        END;

        GlobCVInfo.TESTFIELD("E-mail Address");

        OnAfterFindCVInfo(GlobCVInfo);

        EXIT(TRUE);
    end;

    procedure FindInvoiceLineExport(PrmRecRef: RecordRef): Boolean
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        SalesInvHeader: Record "Sales Invoice Header";
        SalesInvLine: Record "Sales Invoice Line";
    begin
        if not ExportSetup.Activated then
            exit(false);

        ExportSetup.TESTFIELD("Company Country/Region Code");
        ExportSetup.TESTFIELD("E-Export Starting Date");

        Clear(GlobRegionCode);

        case PrmRecRef.NUMBER of
            DATABASE::"Sales Invoice Header":
                begin
                    PrmRecRef.SETTABLE(SalesInvHeader);
                    SalesInvLine.SETRANGE("Document No.", SalesInvHeader."No.");
                    SalesInvLine.SETFILTER(Type, '%1|%2', SalesInvLine.Type::Item, SalesInvLine.Type::"G/L Account");
                    if SalesInvLine.FindFirst() then begin
                        GlobTaxTypeCode := SalesInvLine."PRG_E-Invoice Tax Type Code";
                        exit(TRUE);
                    end;
                end;
            DATABASE::"Purch. Cr. Memo Hdr.":
                begin
                    PrmRecRef.SETTABLE(PurchCrMemoHdr);
                    PurchCrMemoLine.SETRANGE("Document No.", PurchCrMemoHdr."No.");
                    PurchCrMemoLine.SETFILTER(Type, '%1|%2', PurchCrMemoLine.Type::Item, PurchCrMemoLine.Type::"G/L Account");
                    if PurchCrMemoLine.FindFirst() then begin
                        GlobTaxTypeCode := PurchCrMemoLine."PRG_E-Invoice Tax Type Code";
                        exit(TRUE);
                    end;
                end;
        end;
    end;

    procedure FindNextHeaderEntryNo(): Integer
    var
        EInvHeader: Record "PRG_E-Invoice Header";
    begin
        IF EInvHeader.FINDLAST() THEN;
        EXIT(EInvHeader."Entry No." + 1)
    end;

    procedure FindSalesBarcode(VAR SalesInvLine: Record "Sales Invoice Line"): Text[30]
    var
        ItemCrossReference: Record "Item Reference";
    begin

        IF SalesInvLine.Type <> SalesInvLine.Type::Item THEN
            exit('');
        ItemCrossReference.RESET();
        ItemCrossReference.SETRANGE("Item No.", SalesInvLine."No.");
        ItemCrossReference.SETRANGE("Variant Code", SalesInvLine."Variant Code");
        ItemCrossReference.SETRANGE("Unit of Measure", SalesInvLine."Unit of Measure Code");
        ItemCrossReference.SETRANGE("Reference Type", ItemCrossReference."Reference Type"::"Bar Code");
        ItemCrossReference.SETRANGE("Reference Type No.", SalesInvLine."Sell-to Customer No.");
        IF ItemCrossReference.FINDFIRST() THEN;
        EXIT(ItemCrossReference."Reference No.");
    end;

    procedure FindSalesBarcode_New(SalesInvLine: Record "Sales Invoice Line" temporary): Text[30]
    var
        ItemCrossReference: Record "Item Reference";
    begin

        IF SalesInvLine.Type <> SalesInvLine.Type::Item THEN
            exit('');
        ItemCrossReference.RESET();
        ItemCrossReference.SETRANGE("Item No.", SalesInvLine."No.");
        ItemCrossReference.SETRANGE("Variant Code", SalesInvLine."Variant Code");
        ItemCrossReference.SETRANGE("Unit of Measure", SalesInvLine."Unit of Measure Code");
        ItemCrossReference.SETRANGE("Reference Type", ItemCrossReference."Reference Type"::"Bar Code");
        ItemCrossReference.SETRANGE("Reference Type No.", SalesInvLine."Sell-to Customer No.");
        IF ItemCrossReference.FINDFIRST() THEN;
        EXIT(ItemCrossReference."Reference No.");
    end;

    procedure FindSalesCrossRef(VAR SalesInvLine: Record "Sales Invoice Line"): Text[30]
    var
        ItemCrossReference: Record "Item Reference";
    begin

        IF SalesInvLine.Type <> SalesInvLine.Type::Item THEN
            EXIT('');
        ItemCrossReference.RESET();
        ItemCrossReference.SETRANGE("Item No.", SalesInvLine."No.");
        ItemCrossReference.SETRANGE("Variant Code", SalesInvLine."Variant Code");
        ItemCrossReference.SETRANGE("Unit of Measure", SalesInvLine."Unit of Measure Code");
        ItemCrossReference.SETRANGE("Reference Type", ItemCrossReference."Reference Type"::Customer);
        ItemCrossReference.SETRANGE("Reference Type No.", SalesInvLine."Sell-to Customer No.");
        IF ItemCrossReference.FINDFIRST() THEN;
        EXIT(ItemCrossReference."Reference No.");
    end;

    procedure FindSalesCrossRef_New(SalesInvLine: Record "Sales Invoice Line" temporary): Text[30]
    var
        ItemCrossReference: Record "Item Reference";
    begin

        IF SalesInvLine.Type <> SalesInvLine.Type::Item THEN
            EXIT('');
        ItemCrossReference.RESET();
        ItemCrossReference.SETRANGE("Item No.", SalesInvLine."No.");
        ItemCrossReference.SETRANGE("Variant Code", SalesInvLine."Variant Code");
        ItemCrossReference.SETRANGE("Unit of Measure", SalesInvLine."Unit of Measure Code");
        ItemCrossReference.SETRANGE("Reference Type", ItemCrossReference."Reference Type"::Customer);
        ItemCrossReference.SETRANGE("Reference Type No.", SalesInvLine."Sell-to Customer No.");
        IF ItemCrossReference.FINDFIRST() THEN;
        OnBeforeFindSalesCrossRefValue(ItemCrossReference, SalesInvLine);
        EXIT(ItemCrossReference."Reference No.");
    end;

    procedure GetCountryCode(CountryCode: Code[10]): Code[10]
    var
        CodeMapping: Record "PRG_E-Invoice Code Mapping";
    begin
        IF CountryCode <> '' THEN BEGIN
            CodeMapping.GET(CodeMapping.Type::Country, CountryCode);
            CodeMapping.TESTFIELD(CodeMapping."Destination Code");
            EXIT(CodeMapping."Destination Code");
        END ELSE BEGIN
            CodeMapping.GET(CodeMapping.Type::Country, '');
            CodeMapping.TESTFIELD("Destination Code");
            EXIT(CodeMapping."Destination Code");
        END;
    end;

    procedure GetCurrCode(CurrCode: Code[10]) NewCurrCode: Code[10]
    var
        CodeMapping: Record "PRG_E-Invoice Code Mapping";
    begin
        CodeMapping.GET(CodeMapping.Type::Currency, CurrCode);
        CodeMapping.TESTFIELD(CodeMapping."Destination Code");
        EXIT(CodeMapping."Destination Code");
    end;

    procedure GetExportSetup(): Boolean
    begin
        IF NOT GotExportSetup then begin
            if ExportSetup.get() then;
            GotExportSetup := true;
        end;
    end;

    procedure GetIntSetup()
    begin
        IF NOT GotIntSetup then begin
            IF IntSetup.get() THEN
                GotIntSetup := true;
        end;
    end;

    procedure GetInvSetup(): Boolean
    begin
        IF NOT GotInvSetup then begin
            IF NOT EInvSetup.get() then
                exit(false);
            GotInvSetup := true;
        end;
        exit(true);
    end;

    procedure GetSourceDesc(pType: Option; pNo: Code[20]): Text[30]
    var
        FA: Record "Fixed Asset";
        GLAcc: Record "G/L Account";
        Item: Record "Item";
        Res: Record "Resource";
        SalesInvLine: Record "Sales Invoice Line";
    begin
        CASE pType OF
            SalesInvLine.Type::Item.AsInteger():
                BEGIN
                    Item.GET(pNo);
                    EXIT(Item.Description);
                END;
            SalesInvLine.Type::"G/L Account".AsInteger():
                BEGIN
                    GLAcc.GET(pNo);
                    EXIT(GLAcc.Name);
                END;
            SalesInvLine.Type::Resource.AsInteger():
                BEGIN
                    Res.GET(pNo);
                    EXIT(Res.Name);
                END;
            SalesInvLine.Type::"Fixed Asset".AsInteger():
                BEGIN
                    FA.GET(pNo);
                    EXIT(FA.Description);
                END;

        END;

        EXIT('');
    end;

    procedure GetTaxAmtInLCY(TransactionNo: Integer) ReturnVal: Decimal
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SETCURRENTKEY("Transaction No.");
        VATEntry.SETRANGE("Transaction No.", TransactionNo);
        IF VATEntry.FINDSET() THEN
            REPEAT
                ReturnVal += VATEntry.Amount;
            UNTIL VATEntry.NEXT() = 0;

        EXIT(ABS(ROUND(ReturnVal, 0.01)));
    end;

    procedure GetTaxRate(BusPostGrp: Code[10]; ProdPostGrp: Code[10]): Decimal
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        IF VATPostingSetup.GET(BusPostGrp, ProdPostGrp) THEN
            EXIT(VATPostingSetup."VAT %")
        ELSE
            EXIT(0);
    end;

    procedure GetUOMCode(UOMCode: Code[10]): Code[10]
    var
        CodeMapping: Record "PRG_E-Invoice Code Mapping";
    begin
        IF UOMCode <> '' THEN BEGIN
            CodeMapping.GET(CodeMapping.Type::UOM, UOMCode);
            CodeMapping.TESTFIELD("Destination Code");
            EXIT(CodeMapping."Destination Code");
        END ELSE BEGIN
            IF NOT GetInvSetup() THEN
                ERROR(Text048);
            CodeMapping.GET(CodeMapping.Type::UOM, '');
            CodeMapping.TESTFIELD("Destination Code");
            EXIT(CodeMapping."Destination Code");
        END;
    end;

    procedure InsertInvLine(HeaderEntryNo: Integer; LineNo: Integer; ItemNo: Code[20]; Qty: Decimal; LineExtAmt: Decimal; ChargeAmt: Decimal; TaxableAmt: Decimal; TaxAmt: Decimal; ItemName: Text[250]; Desc: Text[250]; UnitPrice: Decimal; UOMCode: Code[20]; CrossRefNo: Text[30]; BarcodeNo: Text[30]; ShipmentMethod: Code[10]; TransMethod: Code[10]; TariffNumber: Code[20]; CountryName: Text[30]; CityName: Text[30]; PackageBrand: Code[20]; PackageType: Code[20]; PackageQty: Decimal; CarriageAmt: Decimal; InsuranceAmt: Decimal; ItemCategoryCode: Code[20]; LineRecID: RecordId)
    begin
        GlobEInvLine.INIT();
        GlobEInvLine."Header Entry No." := HeaderEntryNo;
        GlobEInvLine."Line No." := LineNo;
        GlobEInvLine."Sellers Item Identification" := ItemNo;
        GlobEInvLine.Quantity := ROUND(Qty, 0.00001);
        GlobEInvLine."Line Extension Amount" := ABS(ROUND(LineExtAmt, 0.01));
        GlobEInvLine."Allowance Charge Indicator" := 'false';
        GlobEInvLine."Allowance Charge Amount" := ABS(ROUND(ChargeAmt, 0.01));
        IF ChargeAmt <> 0 THEN
            GlobEInvLine."Allowance Charge Rate" := ABS(ROUND((ChargeAmt / (TaxableAmt + ChargeAmt)), 0.0001));
        GlobEInvLine."Item Name" := ItemName;
        GlobEInvLine.Description := Desc;
        GlobEInvLine."Unit Price" := ABS(ROUND(UnitPrice, 0.00001));
        GlobEInvLine."Buyers Item Identification" := CrossRefNo;
        GlobEInvLine."Manu. Item Identification" := BarcodeNo;
        GlobEInvLine."Unit Of Measure Code" := GetUOMCode(UOMCode);
        GlobEInvLine."Delivery Terms" := ShipmentMethod;
        GlobEInvLine."Transport Mode Code" := TransMethod;
        GlobEInvLine."GTIP No." := TariffNumber;
        GlobEInvLine."Delivery Country Name" := CountryName;
        GlobEInvLine."Delivery City Name" := CityName;
        GlobEInvLine."Package Brand" := PackageBrand;
        GlobEInvLine."Packagin Type Code" := PackageType;
        GlobEInvLine."Actual Package Quantity" := PackageQty;
        GlobEInvLine."Carriage Amount" := CarriageAmt;
        GlobEInvLine."Insurance Amount" := InsuranceAmt;
        GlobEInvLine.UUID := GlobEInvHeader.UUID;
        GlobEInvLine.LineRecordId := LineRecID;
        GlobEInvLine.INSERT();
    end;

    /*
    [Obsolete('Pending remove', '25.0')]
    procedure InsertInvLine(HeaderEntryNo: Integer; LineNo: Integer; ItemNo: Code[20]; Qty: Decimal; LineExtAmt: Decimal; ChargeAmt: Decimal; TaxableAmt: Decimal; TaxAmt: Decimal; ItemName: Text[250]; Desc: Text[250]; UnitPrice: Decimal; UOMCode: Code[20]; CrossRefNo: Text[30]; BarcodeNo: Text[30]; ShipmentMethod: Code[10]; TransMethod: Code[10]; TariffNumber: Code[20]; CountryName: Text[30]; CityName: Text[30]; PackageBrand: Code[20]; PackageType: Code[20]; PackageQty: Decimal; CarriageAmt: Decimal; InsuranceAmt: Decimal)
    begin
        GlobEInvLine.INIT();
        GlobEInvLine."Header Entry No." := HeaderEntryNo;
        GlobEInvLine."Line No." := LineNo;
        GlobEInvLine."Sellers Item Identification" := ItemNo;
        GlobEInvLine.Quantity := ROUND(Qty, 0.00001);
        GlobEInvLine."Line Extension Amount" := ABS(ROUND(LineExtAmt, 0.01));
        GlobEInvLine."Allowance Charge Indicator" := 'false';
        GlobEInvLine."Allowance Charge Amount" := ABS(ROUND(ChargeAmt, 0.01));
        IF ChargeAmt <> 0 THEN
            GlobEInvLine."Allowance Charge Rate" := ABS(ROUND((ChargeAmt / (TaxableAmt + ChargeAmt)), 0.0001));
        GlobEInvLine."Item Name" := ItemName;
        GlobEInvLine.Description := Desc;
        GlobEInvLine."Unit Price" := ABS(ROUND(UnitPrice, 0.00001));
        GlobEInvLine."Buyers Item Identification" := CrossRefNo;
        GlobEInvLine."Manu. Item Identification" := BarcodeNo;
        GlobEInvLine."Unit Of Measure Code" := GetUOMCode(UOMCode);
        GlobEInvLine."Delivery Terms" := ShipmentMethod;
        GlobEInvLine."Transport Mode Code" := TransMethod;
        GlobEInvLine."GTIP No." := TariffNumber;
        GlobEInvLine."Delivery Country Name" := CountryName;
        GlobEInvLine."Delivery City Name" := CityName;
        GlobEInvLine."Package Brand" := PackageBrand;
        GlobEInvLine."Packagin Type Code" := PackageType;
        GlobEInvLine."Actual Package Quantity" := PackageQty;
        GlobEInvLine."Carriage Amount" := CarriageAmt;
        GlobEInvLine."Insurance Amount" := InsuranceAmt;
        GlobEInvLine.UUID := GlobEInvHeader.UUID; //new
        GlobEInvLine.INSERT();
    end;
    
    [Obsolete('Pending remove', '25.6')]

    procedure InsertInvLine(HeaderEntryNo: Integer; LineNo: Integer; ItemNo: Code[20]; Qty: Decimal; LineExtAmt: Decimal; ChargeAmt: Decimal; TaxableAmt: Decimal; TaxAmt: Decimal; ItemName: Text[250]; Desc: Text[250]; UnitPrice: Decimal; UOMCode: Code[20]; CrossRefNo: Text[30]; BarcodeNo: Text[30]; ShipmentMethod: Code[10]; TransMethod: Code[10]; TariffNumber: Code[20]; CountryName: Text[30]; CityName: Text[30]; PackageBrand: Code[20]; PackageType: Code[20]; PackageQty: Decimal)
    begin
        GlobEInvLine.INIT();
        GlobEInvLine."Header Entry No." := HeaderEntryNo;
        GlobEInvLine."Line No." := LineNo;
        GlobEInvLine."Sellers Item Identification" := ItemNo;
        GlobEInvLine.Quantity := ROUND(Qty, 0.00001);
        GlobEInvLine."Line Extension Amount" := ABS(ROUND(LineExtAmt, 0.01));
        GlobEInvLine."Allowance Charge Indicator" := 'false';
        GlobEInvLine."Allowance Charge Amount" := ABS(ROUND(ChargeAmt, 0.01));
        IF ChargeAmt <> 0 THEN
            GlobEInvLine."Allowance Charge Rate" := ABS(ROUND((ChargeAmt / (TaxableAmt + ChargeAmt)), 0.0001));
        GlobEInvLine."Item Name" := ItemName;
        GlobEInvLine.Description := Desc;
        GlobEInvLine."Unit Price" := ABS(ROUND(UnitPrice, 0.00001));
        GlobEInvLine."Buyers Item Identification" := CrossRefNo;
        GlobEInvLine."Manu. Item Identification" := BarcodeNo;
        GlobEInvLine."Unit Of Measure Code" := GetUOMCode(UOMCode);
        GlobEInvLine."Delivery Terms" := ShipmentMethod;
        GlobEInvLine."Transport Mode Code" := TransMethod;
        GlobEInvLine."GTIP No." := TariffNumber;
        GlobEInvLine."Delivery Country Name" := CountryName;
        GlobEInvLine."Delivery City Name" := CityName;
        GlobEInvLine."Package Brand" := PackageBrand;
        GlobEInvLine."Packagin Type Code" := PackageType;
        GlobEInvLine."Actual Package Quantity" := PackageQty;
        GlobEInvLine.INSERT();
    end;
    */

    procedure InsertQueue(var GLReg: Record "G/L Register"; RecreateExisting: Boolean; IncludeCancelledInv: Boolean; IncludeOutOfScope: Boolean)
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        Queue: Record "PRG_E-Invoice Queue";
        QueueLog: Record "PRG_E-Invoice Queue Log";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        SalesInvHeader: Record "Sales Invoice Header";
        VendLedgEntry: Record "Vendor Ledger Entry";
        ServiceInvHeader: Record "Service Invoice Header";
        RecRef: RecordRef;
        Continue: Boolean;
        CreateEInv: Boolean;
        InvType: Option;
        ProfileID: Option;
    begin
        IF NOT IsEInvActivated(FindPostingDate(GLReg)) THEN
            EXIT;

        GetExportSetup();

        InvType := Queue.InvoiceType::" ";
        ProfileID := Queue.ProfileID::" ";
        CreateEInv := FALSE;
        CLEAR(RecRef);

        Continue := TRUE;

        IF NOT RecreateExisting THEN BEGIN
            IF IncludeCancelledInv THEN
                Continue := (GLReg."PRG_E-Invoice Status" = GLReg."PRG_E-Invoice Status"::" ") OR (GLReg."PRG_E-Invoice Status" = GLReg."PRG_E-Invoice Status"::Cancelled)
            ELSE
                Continue := (GLReg."PRG_E-Invoice Status" = GLReg."PRG_E-Invoice Status"::" ");
        END ELSE
            Continue := true;

        IF (NOT Continue) AND (IncludeOutOfScope) THEN
            Continue := GLReg."PRG_E-Invoice Status" = GLReg."PRG_E-Invoice Status"::OutofScope;

        OnBeforeSetContinueForQueue(GLReg, Continue);

        IF Continue THEN BEGIN
            CustLedgEntry.RESET();
            CustLedgEntry.SETRANGE("Entry No.", GLReg."From Entry No.", GLReg."To Entry No.");
            CustLedgEntry.SETFILTER("Document Type", '%1|%2', CustLedgEntry."Document Type"::Invoice,
              CustLedgEntry."Document Type"::"Finance Charge Memo");
            IF CustLedgEntry.FINDFIRST() THEN BEGIN
                CreateEInv := IsEInvCV(DATABASE::"Cust. Ledger Entry",
                  CustLedgEntry."Customer No.", CustLedgEntry."Posting Date", CustLedgEntry."Document Type".AsInteger());

                IF NOT CreateEInv THEN BEGIN
                    RecRef.GETTABLE(CustLedgEntry);
                    CreateEInv := SetScopeForExport(RecRef);
                END;

                IF CreateEInv THEN BEGIN
                    SalesInvHeader.SETRANGE("No.", CustLedgEntry."Document No.");
                    SalesInvHeader.SETRANGE("Posting Date", CustLedgEntry."Posting Date");
                    IF SalesInvHeader.FINDFIRST() THEN BEGIN
                        RecRef.GETTABLE(SalesInvHeader);
                        SetCVInfoForExport(RecRef);
                        IF NOT IncludeOutOfScope THEN begin
                            CASE SalesInvHeader."PRG_E-Platform Type" OF
                                SalesInvHeader."PRG_E-Platform Type"::" ":
                                    CreateEInv := FALSE;
                                SalesInvHeader."PRG_E-Platform Type"::MicroExport:
                                    IF GlobCVInfo."Integration Type" <> GlobCVInfo."Integration Type"::EArchive THEN
                                        CreateEInv := FALSE;
                            END;
                        end;
                    END else begin
                        ServiceInvHeader.SETRANGE("No.", CustLedgEntry."Document No.");
                        ServiceInvHeader.SETRANGE("Posting Date", CustLedgEntry."Posting Date");
                        IF ServiceInvHeader.FINDFIRST THEN
                            RecRef.GETTABLE(ServiceInvHeader)

                        ELSE
                            RecRef.GETTABLE(CustLedgEntry)
                    end;


                    InvType := Queue.InvoiceType::Sales;

                    if SalesInvHeader."PRG_Medical E-Invoice" then
                        ProfileID := GlobCVInfo."Profile ID"::MEDICAL
                    else
                        ProfileID := GlobCVInfo."Profile ID";
                END;

            END ELSE BEGIN

                VendLedgEntry.RESET();
                VendLedgEntry.SETRANGE("Entry No.", GLReg."From Entry No.", GLReg."To Entry No.");
                VendLedgEntry.SETRANGE("Document Type", VendLedgEntry."Document Type"::"Credit Memo");
                IF VendLedgEntry.FINDFIRST() THEN BEGIN
                    CreateEInv := IsEInvCV(DATABASE::"Vendor Ledger Entry",
                      VendLedgEntry."Vendor No.", VendLedgEntry."Posting Date", VendLedgEntry."Document Type".AsInteger());

                    IF NOT CreateEInv THEN BEGIN
                        RecRef.GETTABLE(VendLedgEntry);
                        CreateEInv := SetScopeForExport(RecRef);
                    END;

                    IF CreateEInv THEN BEGIN
                        PurchCrMemoHeader.SETRANGE("No.", VendLedgEntry."Document No.");
                        PurchCrMemoHeader.SETRANGE("Posting Date", VendLedgEntry."Posting Date");
                        IF PurchCrMemoHeader.FINDFIRST() THEN BEGIN
                            RecRef.GETTABLE(PurchCrMemoHeader);
                            SetCVInfoForExport(RecRef);
                            IF NOT IncludeOutOfScope THEN begin
                                CASE PurchCrMemoHeader."PRG_E-Platform Type" OF
                                    PurchCrMemoHeader."PRG_E-Platform Type"::" ":
                                        CreateEInv := FALSE;
                                    PurchCrMemoHeader."PRG_E-Platform Type"::MicroExport:
                                        IF GlobCVInfo."Integration Type" <> GlobCVInfo."Integration Type"::EArchive THEN
                                            CreateEInv := FALSE;
                                END;
                            END;
                        END ELSE
                            RecRef.GETTABLE(VendLedgEntry);

                        InvType := Queue.InvoiceType::PurchCr;

                        IF GlobCVInfo."Profile ID" = GlobCVInfo."Profile ID"::TICARIFATURA THEN
                            GlobCVInfo."Profile ID" := GlobCVInfo."Profile ID"::TEMELFATURA;

                        if PurchCrMemoHeader."PRG_Medical E-Invoice" then
                            ProfileID := GlobCVInfo."Profile ID"::MEDICAL
                        else
                            ProfileID := GlobCVInfo."Profile ID";
                        //ProfileID := GlobCVInfo."Profile ID";

                    END;
                END;
            END;

            OnBeforeCreateEInv(GLReg, SalesInvHeader, PurchCrMemoHeader, CreateEInv);

            IF CreateEInv THEN BEGIN

                CLEAR(Queue);
                IF Queue.FINDLAST() THEN;
                Queue.INIT();
                Queue.EntryNo := Queue.EntryNo + 1;
                CASE TRUE OF
                    InvType IN [Queue.InvoiceType::Sales, Queue.InvoiceType::PurchCr]:
                        Queue.Type := Queue.Type::Outbox;
                    InvType IN [Queue.InvoiceType::Purch, Queue.InvoiceType::SalesCr]:
                        Queue.Type := Queue.Type::Inbox;
                END;
                Queue."Queue Status" := Queue."Queue Status"::New;
                Queue.ProfileID := ProfileID;
                Queue.InvoiceType := InvType;
                Queue.ERPRecordID := RecRef.RECORDID;
                Queue.GLRegisterEntryNo := GLReg."No.";
                Queue.UniqueIdentifier := CREATEGUID();
                Queue.CreationDateTime := CURRENTDATETIME;
                Queue.CreatedBy := USERID;
                Queue.CVNo := GlobCVInfo."CV No.";
                Queue.CVName := GlobCVInfo."CV Name";
                Queue.IntegrationType := GlobCVInfo."Integration Type";
                Queue.CVRegistrationNo := GlobCVInfo."Tax Registration No.";
                IF SalesInvHeader."Responsibility Center" <> '' THEN
                    Queue.DepartmentCode := SalesInvHeader."Responsibility Center"
                ELSE
                    Queue.DepartmentCode := PurchCrMemoHeader."Responsibility Center";

                OnBeforeInsertEInvoiceQueue(Queue);

                Queue.INSERT();

                OnAfterInsertEInvoiceQueue(Queue);

                InsertQueueLog(Queue.EntryNo, QueueLog.Status::New, Text007);

                CreateCommInvoice(Queue, FALSE);

                ExecPostControls();
                Queue.MODIFY();

                OnBeforeModifyEInvoiceStatus(GLReg, Queue);
                GLReg."PRG_E-Invoice Status" := GLReg."PRG_E-Invoice Status"::SentToQueue;
                GLReg.MODIFY();
                OnAfterModifyEInvoiceStatus(GLReg, Queue);

                IF SendPreview THEN
                    SetQueueToPass(Queue);

            END ELSE BEGIN

                OnBeforeModifyEInvoiceStatus(GLReg, Queue);
                GLReg."PRG_E-Invoice Status" := GLReg."PRG_E-Invoice Status"::OutofScope;
                GLReg.MODIFY();
                OnAfterModifyEInvoiceStatus(GLReg, Queue);

            END;
        END;
    end;

    [TryFunction]
    procedure TryFindEInvoice(var GLReg: Record "G/L Register")
    begin
        if NOT IsEInvActivated(FindPostingDate(GLReg)) then
            exit;

        FindEInvoices(GLReg);

    end;

    [TryFunction]
    local procedure FindEInvoices(VAR GLReg: Record "G/L Register")
    var
        Queue: Record "PRG_E-Invoice Queue";
        Counter: Integer;
    begin
        if not IsEInvActivated(FindPostingDate(GLReg)) then
            exit;

        InsertQueue(GLReg, false, false, false);

        if EInvSetup."Export to Service Type" = EInvSetup."Export to Service Type"::Automatic then begin
            Queue.RESET();
            Queue.SetRange(Type, Queue.Type::Outbox);
            Queue.SetRange(GLRegisterEntryNo, GLReg."No.");
            Queue.SetRange("Queue Status", Queue."Queue Status"::New);
            if Queue.FindFirst() then
                SendInvoice(Queue, false);
        end;
    end;

    procedure InsertQueueLog(QueueEntryNo: Integer; pStatus: Option; pDesc: Text[250])
    var
        QueueLog: Record "PRG_E-Invoice Queue Log";
    begin
        QueueLog.RESET();
        QueueLog.SETRANGE("Header Entry No.", QueueEntryNo);
        IF QueueLog.FINDLAST() THEN;
        QueueLog.INIT();
        QueueLog."Header Entry No." := QueueEntryNo;
        QueueLog."Line No." := QueueLog."Line No." + 10000;
        QueueLog.Status := pStatus;
        QueueLog.Description := pDesc;
        QueueLog.INSERT(TRUE);
    end;

    procedure InsertTaxLine(HeaderEntryNo: Integer; TaxTypeCode: Code[20]; TaxAmt: Decimal; BaseAmt: Decimal; TaxPercent: Decimal; IsHeader: Boolean)
    var
        TaxType: Record "PRG_E-Invoice Tax Type Code";
    begin

        IF TaxTypeCode = '' THEN
            ERROR(Text022);

        TaxType.GET(TaxTypeCode);
        CLEAR(GlobEInvTaxLine);

        CASE TRUE OF

            TaxTypeCode = EInvSetup."VAT Tax Type Code", TaxType.Type = TaxType.Type::Exported:
                BEGIN
                    IF TaxAmt = 0 THEN
                        EXIT;
                    IF TaxPercent = 0 THEN
                        IF BaseAmt <> 0 THEN
                            TaxPercent := ROUND(TaxAmt / BaseAmt * 100, 1);
                END;

            ELSE BEGIN
                IF TaxPercent = 0 THEN
                    TaxPercent := TaxType."Tax Rate";
                IF TaxType.Type = TaxType.Type::WitholdingCode THEN
                    BaseAmt := TaxAmt;
                TaxAmt := BaseAmt * TaxPercent / 100
            END;
        END;

        CASE TRUE OF
            TaxType.Code = EInvSetup."Sales Exemption Tax Code":
                TaxTypeCode := EInvSetup."VAT Tax Type Code";
            TaxType.Type = TaxType.Type::ExceptionCode:
                TaxTypeCode := EInvSetup."VAT Tax Type Code";
            TaxType.Type = TaxType.Type::PartialExceptionCode:
                TaxTypeCode := EInvSetup."VAT Tax Type Code";
        END;

        OnBeforeCreateGlobalTaxLine(HeaderEntryNo, GlobEInvTaxLine, IsHeader);

        GlobEInvTaxLine.SETRANGE("Header Entry No.", HeaderEntryNo);
        IF IsHeader THEN
            GlobEInvTaxLine.SETRANGE("Header Line No.", 0)
        ELSE
            GlobEInvTaxLine.SETRANGE("Header Line No.", GlobEInvLine."Line No.");

        IF (IsHeader) AND (TaxType.Type = TaxType.Type::Exported) THEN
            GlobEInvTaxLine.SETRANGE(TaxTypeCode, EInvSetup."VAT Tax Type Code")
        ELSE
            GlobEInvTaxLine.SETRANGE(TaxTypeCode, TaxTypeCode);

        GlobEInvTaxLine.SETRANGE(TaxPercent, TaxPercent);
        IF NOT GlobEInvTaxLine.FINDLAST() THEN BEGIN

            GlobEInvTaxLine.SETRANGE(TaxTypeCode);
            GlobEInvTaxLine.SETRANGE(TaxPercent);
            IF NOT GlobEInvTaxLine.FINDLAST() THEN
                GlobEInvTaxLine."Line No." := 10000
            ELSE
                GlobEInvTaxLine."Line No." := GlobEInvTaxLine."Line No." + 10000;

            GlobEInvTaxLine.INIT();
            GlobEInvTaxLine."Header Entry No." := HeaderEntryNo;
            IF IsHeader THEN BEGIN
                GlobEInvTaxLine.Type := GlobEInvTaxLine.Type::Header;
                GlobEInvTaxLine."Header Line No." := 0;
            END ELSE BEGIN
                GlobEInvTaxLine.Type := GlobEInvTaxLine.Type::Line;
                GlobEInvTaxLine."Header Line No." := GlobEInvLine."Line No.";
            END;

            GlobEInvTaxLine.TaxTypeCode := TaxTypeCode;

            CASE TaxType.Type OF
                TaxType.Type::VAT:
                    GlobEInvTaxLine.TaxTypeName := 'KDV';
                TaxType.Type::WitholdingCode:
                    GlobEInvTaxLine.TaxTypeName := 'TEVKIFAT';
                TaxType.Type::ExceptionCode:
                    GlobEInvTaxLine.TaxTypeName := 'ISTISNA';
                TaxType.Type::PartialExceptionCode:
                    GlobEInvTaxLine.TaxTypeName := 'ISTISNA';
                TaxType.Type::SpecificBaseCode:
                    GlobEInvTaxLine.TaxTypeName := 'OZELMATRAH';
                TaxType.Type::Exported:
                    BEGIN
                        GlobEInvTaxLine.TaxTypeName := 'KDV';
                        GlobEInvTaxLine.TaxTypeCode := EInvSetup."VAT Tax Type Code";
                    END
                ELSE
                    GlobEInvTaxLine.FIELDERROR(TaxTypeName, Text034);
            END;

            IF TaxType.Type <> TaxType.Type::Exported THEN
                GlobEInvTaxLine.TaxTypeName := TaxType.Description;

            CASE TRUE OF
                TaxType.Code = EInvSetup."Sales Exemption Tax Code":
                    GlobEInvTaxLine.TaxTypeCode := EInvSetup."VAT Tax Type Code";
                TaxType.Type = TaxType.Type::ExceptionCode:
                    GlobEInvTaxLine.TaxTypeCode := EInvSetup."VAT Tax Type Code";
                TaxType.Type = TaxType.Type::PartialExceptionCode:
                    GlobEInvTaxLine.TaxTypeCode := EInvSetup."VAT Tax Type Code";
                TaxType.Type = TaxType.Type::Exported:
                    GlobEInvTaxLine.TaxTypeCode := EInvSetup."VAT Tax Type Code";
                ELSE
                    GlobEInvTaxLine.TaxTypeCode := TaxTypeCode;
            END;

            CASE TaxType.Type OF

                TaxType.Type::VAT:
                    IF (TaxTypeCode = EInvSetup."VAT Tax Type Code") OR
                       (TaxTypeCode = EInvSetup."Sales Exemption Tax Code") THEN
                        GlobEInvTaxLine.TaxType := GlobEInvTaxLine.TaxType::VAT
                    ELSE
                        GlobEInvTaxLine.TaxType := GlobEInvTaxLine.TaxType::Other;
                TaxType.Type::WitholdingCode:
                    BEGIN
                        GlobEInvTaxLine.TaxType := GlobEInvTaxLine.TaxType::Witholding;
                        GlobEInvHeader.InvoiceType := GlobEInvHeader.InvoiceType::Withholding;
                    END;

                TaxType.Type::ExceptionCode:
                    BEGIN
                        GlobEInvTaxLine.TaxType := GlobEInvTaxLine.TaxType::Exception;
                        GlobEInvHeader.InvoiceType := GlobEInvHeader.InvoiceType::Exception;
                    END;

                TaxType.Type::PartialExceptionCode:
                    BEGIN
                        GlobEInvTaxLine.TaxType := GlobEInvTaxLine.TaxType::PartialException;
                        GlobEInvHeader.InvoiceType := GlobEInvHeader.InvoiceType::Exception;
                    END;

                TaxType.Type::SpecificBaseCode:
                    BEGIN
                        GlobEInvTaxLine.TaxType := GlobEInvTaxLine.TaxType::SpecificBase;
                        GlobEInvHeader.InvoiceType := GlobEInvHeader.InvoiceType::SpecificBase;
                    END;

                TaxType.Type::Exported:
                    BEGIN
                        GlobEInvHeader.InvoiceType := GlobEInvHeader.InvoiceType::Exported;
                    END;

            END;

            GlobEInvTaxLine.TaxPercent := ABS(TaxPercent);
            GlobEInvTaxLine.TaxAmount := ABS(TaxAmt);
            GlobEInvTaxLine.TaxExclusiveAmount := ABS(BaseAmt);
            GlobEInvTaxLine.TaxInclusiveAmount := GlobEInvTaxLine.TaxExclusiveAmount + GlobEInvTaxLine.TaxAmount;

            IF (TaxType.Type = TaxType.Type::ExceptionCode) OR
               (TaxType.Type = TaxType.Type::PartialExceptionCode) OR (TaxType.Code = EInvSetup."Sales Exemption Tax Code") OR (TaxType.Type = TaxType.Type::Exported) THEN BEGIN
                GlobEInvTaxLine."TaxExemption Reason Code" := TaxType.Code;
                GlobEInvTaxLine."TaxExemption Reason Desc" := TaxType.Description;
            END;

            IF GlobEInvHeader.ProfileID = GlobEInvHeader.ProfileID::EExport THEN BEGIN
                GlobEInvHeader.InvoiceType := GlobEInvHeader.InvoiceType::Exception;
                if GlobTaxTypeCode = '' then begin
                    GetExportSetup();
                    ExportSetup.TESTFIELD("Default Exemption Tax Code");
                    GlobEInvTaxLine."TaxExemption Reason Code" := ExportSetup."Default Exemption Tax Code";
                    GlobEInvTaxLine."TaxExemption Reason Desc" := ExportSetup."Default Exemption Tax Desc";
                end else
                    if TaxType.Get(GlobTaxTypeCode) then begin
                        GlobEInvTaxLine."TaxExemption Reason Code" := GlobTaxTypeCode;
                        GlobEInvTaxLine."TaxExemption Reason Desc" := TaxType.Description;
                    end;
            END;

            GlobEInvTaxLine.INSERT();
            CalcTaxSeqNumber(GlobEInvTaxLine);
        END ELSE BEGIN
            GlobEInvTaxLine.TaxAmount := GlobEInvTaxLine.TaxAmount + ABS(TaxAmt);
            GlobEInvTaxLine.TaxExclusiveAmount := GlobEInvTaxLine.TaxExclusiveAmount + ABS(BaseAmt);
            GlobEInvTaxLine.TaxInclusiveAmount := GlobEInvTaxLine.TaxExclusiveAmount + GlobEInvTaxLine.TaxAmount;
            GlobEInvTaxLine.MODIFY();
        END;

        OnAfterCreateGlobalTaxLine(HeaderEntryNo, GlobEInvTaxLine);
    end;

    procedure InsertTempVATEntry(TransactionNo: Integer)
    var
        VATEntry: Record "VAT Entry";
    begin
        TempVATEntry.RESET();
        TempVATEntry.DELETEALL();

        VATEntry.SETCURRENTKEY("Transaction No.");
        VATEntry.SETRANGE("Transaction No.", TransactionNo);
        IF VATEntry.FINDSET() THEN
            REPEAT
                TempVATEntry.SETRANGE("Gen. Bus. Posting Group", VATEntry."Gen. Bus. Posting Group");
                TempVATEntry.SETRANGE("Gen. Bus. Posting Group", VATEntry."Gen. Bus. Posting Group");
                IF TempVATEntry.FINDFIRST() THEN BEGIN
                    TempVATEntry.Base := TempVATEntry.Base + VATEntry.Base;
                    TempVATEntry.Amount := TempVATEntry.Amount + VATEntry.Amount;
                    TempVATEntry.MODIFY();
                END ELSE BEGIN
                    TempVATEntry."Entry No." := VATEntry."Entry No.";
                    TempVATEntry.Base := VATEntry.Base;
                    TempVATEntry.Amount := VATEntry.Amount;
                    TempVATEntry."Gen. Bus. Posting Group" := VATEntry."Gen. Bus. Posting Group";
                    TempVATEntry."Gen. Bus. Posting Group" := VATEntry."Gen. Bus. Posting Group";
                    TempVATEntry.INSERT();
                END;
            UNTIL VATEntry.NEXT() = 0;
    end;

    procedure IsEInvActivated(PostingDate: Date): Boolean
    var

    begin
        GetInvSetup();
        GetExportSetup();

        IF NOT EInvSetup.Activated THEN
            EXIT(FALSE);

        IF PostingDate <> 0D THEN BEGIN
            EInvSetup.TESTFIELD("E-Invoice Starting Date");
            EXIT(PostingDate >= EInvSetup."E-Invoice Starting Date");
        END;
    end;

    procedure IsEInvCV(TableNo: Integer; CVNo: Code[20]; PostingDate: Date; DocType: Option " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund): Boolean
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        GenJnlLine: Record "Gen. Journal Line";
        PurchHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        IF NOT IsEInvActivated(PostingDate) THEN
            EXIT(FALSE);

        CASE TableNo OF
            DATABASE::"Cust. Ledger Entry":
                BEGIN
                    IF NOT (DocType IN [CustLedgEntry."Document Type"::Invoice.AsInteger(), CustLedgEntry."Document Type"::"Finance Charge Memo".AsInteger()]) THEN
                        EXIT(FALSE);
                    IF NOT FindCVInfo(GlobCVInfo."CV Type"::Customer, CVNo, PostingDate) THEN
                        EXIT(FALSE);
                END;
            DATABASE::"Sales Header":
                BEGIN
                    IF NOT (DocType IN [SalesHeader."Document Type"::Order.AsInteger(), SalesHeader."Document Type"::Invoice.AsInteger()]) THEN
                        EXIT(FALSE);
                    IF NOT FindCVInfo(GlobCVInfo."CV Type"::Customer, CVNo, PostingDate) THEN
                        EXIT(FALSE);
                END;
            DATABASE::"Vendor Ledger Entry":
                BEGIN
                    IF NOT (DocType IN [VendLedgEntry."Document Type"::"Credit Memo".AsInteger()]) THEN
                        EXIT(FALSE);
                    IF NOT FindCVInfo(GlobCVInfo."CV Type"::Vendor, CVNo, PostingDate) THEN
                        EXIT(FALSE);
                END;
            DATABASE::"Purchase Header":
                BEGIN
                    IF NOT (DocType IN [PurchHeader."Document Type"::"Return Order".AsInteger(), PurchHeader."Document Type"::"Credit Memo".AsInteger()]) THEN
                        EXIT(FALSE);
                    IF NOT FindCVInfo(GlobCVInfo."CV Type"::Vendor, CVNo, PostingDate) THEN
                        EXIT(FALSE);
                END;
            DATABASE::"Gen. Journal Line":
                BEGIN
                    IF NOT (DocType IN [GenJnlLine."Document Type"::Invoice.AsInteger(), GenJnlLine."Document Type"::"Credit Memo".AsInteger(),
                                        GenJnlLine."Document Type"::"Finance Charge Memo".AsInteger()]) THEN
                        EXIT(FALSE);

                    CASE DocType OF
                        GenJnlLine."Document Type"::Invoice.AsInteger(), GenJnlLine."Document Type"::"Finance Charge Memo".AsInteger():
                            IF NOT FindCVInfo(GlobCVInfo."CV Type"::Customer, CVNo, PostingDate) THEN
                                EXIT(FALSE);
                        GenJnlLine."Document Type"::"Credit Memo".AsInteger():
                            IF NOT FindCVInfo(GlobCVInfo."CV Type"::Vendor, CVNo, PostingDate) THEN
                                EXIT(FALSE);
                    END;
                END;

            ELSE
                ERROR(Text025);
        END;

        IF PostingDate < GlobCVInfo."E-Invoice Starting Date" THEN
            EXIT(FALSE)
        ELSE
            CASE GlobCVInfo."Integration Type" OF
                GlobCVInfo."Integration Type"::EInvoice:
                    EXIT(PostingDate >= EInvSetup."E-Invoice Starting Date");
                GlobCVInfo."Integration Type"::EArchive:
                    EXIT(PostingDate >= EInvSetup."E-Archive Starting Date");
            END;

    end;

    procedure ModfiyGlobCVInfoForExport()
    begin
        GlobCVInfo."Integration Type" := GlobCVInfo."Integration Type"::EInvoice;
        GlobCVInfo."Profile ID" := GlobCVInfo."Profile ID"::IHRACAT;
        GlobCVInfo."E-Invoice Starting Date" := ExportSetup."E-Export Starting Date";
    end;

    procedure Navigate(GLRegNo: Integer)
    var
        GLEntry: Record "G/L Entry";
        GLReg: Record "G/L Register";
        NavigatePage: Page Navigate;
    begin
        IF GLRegNo <> 0 THEN BEGIN
            GLReg.GET(GLRegNo);
            GLEntry.GET(GLReg."From Entry No.");
            NavigatePage.SetDoc(GLEntry."Posting Date", GLEntry."Document No.");
            NavigatePage.RUN();
        END;
    end;

    procedure ReplaceDescription(OriginalText: Text[100]; FindText: Text[30]; ReplaceText: Text[30]): Text[100]
    var
        FindLength: Integer;
        FirstPos: Integer;
    begin

        FirstPos := STRPOS(OriginalText, FindText);
        FindLength := STRLEN(FindText);
        IF FirstPos = 0 THEN
            EXIT(OriginalText);

        OriginalText := DELSTR(OriginalText, FirstPos, FindLength);
        OriginalText := INSSTR(OriginalText, ReplaceText, FirstPos);

        EXIT(OriginalText);
    end;

    procedure SendInvoice(var Queue: Record "PRG_E-Invoice Queue"; PreviewOnly: Boolean)
    var
        GLReg: Record "G/L Register";
        EInvHeader: Record "PRG_E-Invoice Header";
        Queue2: Record "PRG_E-Invoice Queue";
        QueueLog: Record "PRG_E-Invoice Queue Log";
        ConnectorMgt: Codeunit "PRG_E-Invoice Connector Mgt.";

        RecRef: RecordRef;
        NoOfInvoiceSent: Integer;
        XMLdoc: XmlDocument;
    begin
        IF PreviewOnly THEN BEGIN
            Queue2.SETFILTER(EntryNo, Queue.GETFILTER(EntryNo));
            Queue.SETRANGE(EntryNo, Queue.EntryNo);
        END ELSE
            Queue.SETFILTER("Queue Status", '%1|%2', Queue."Queue Status"::New, Queue."Queue Status"::Failed);

        Queue.SetCurrentKey(EntryNo);
        Queue.SetAscending(EntryNo, true);

        IF Queue.FINDFIRST() THEN BEGIN

            REPEAT

                EInvHeader.SETRANGE(UUID, Queue.UniqueIdentifier);
                EInvHeader.FindFirst();

                RecRef.GET(Queue.ERPRecordID);
                CASE RecRef.NUMBER OF
                    DATABASE::"Cust. Ledger Entry", DATABASE::"Sales Invoice Header":
                        FindCVInfo(GlobCVInfo."CV Type"::Customer, Queue.CVNo, EInvHeader.IssueDate);
                    DATABASE::"Vendor Ledger Entry", DATABASE::"Purch. Cr. Memo Hdr.":
                        FindCVInfo(GlobCVInfo."CV Type"::Vendor, Queue.CVNo, EInvHeader.IssueDate);
                END;

                IF NOT PreviewOnly THEN BEGIN
                    IF GLReg.GET(Queue.GLRegisterEntryNo) then;

                    CheckPayeeInformation(Queue);

                    IF Queue.InvoiceID = '' THEN BEGIN
                        Queue.InvoiceID := CreateInvoiceID(EInvHeader);
                        Queue.MODIFY();
                        COMMIT();
                    END;

                    UpdateExtDocNo(Queue, GLReg);
                END ELSE BEGIN
                    IF Queue.InvoiceID = '' THEN
                        Queue.InvoiceID := '1';
                END;

                CreateCommInvoice(Queue, PreviewOnly);

                OnBeforeCreateXmlDocument(Queue, PreviewOnly);
                XMLdoc := UBLMgt.CreateOutgoingXML(Queue, PreviewOnly);
                OnAfterCreateXmlDocument(Queue, PreviewOnly, XMLdoc);

                IF NOT PreviewOnly THEN BEGIN

                    InsertQueueLog(Queue.EntryNo, QueueLog.Status::SentToService, Text010);

                    GLReg."PRG_E-Invoice Status" := GLReg."PRG_E-Invoice Status"::SentToSrvQueue;
                    IF GLReg.MODIFY() then;

                    Queue."Queue Status" := Queue."Queue Status"::SentToService;
                    Queue.MODIFY();

                    OnBeforeSendInvoiceToWB(XMLdoc, Queue);
                    Clear(ConnectorMgt);
                    ConnectorMgt.SendInvoice(XMLdoc, Queue.UniqueIdentifier);
                    OnAfterSendInvoiceToWB(XMLdoc, Queue);

                    COMMIT();

                    NoOfInvoiceSent := NoOfInvoiceSent + 1;
                END;

            UNTIL Queue.NEXT() = 0;

            IF PreviewOnly THEN
                IF Queue2.GETFILTER(EntryNo) <> '' THEN
                    Queue.SETFILTER(EntryNo, Queue2.GETFILTER(EntryNo))
                ELSE
                    Queue.SETRANGE(EntryNo);

            Queue.SETRANGE("Queue Status");

            IF NOT PreviewOnly THEN
                IF GUIALLOWED THEN
                    MESSAGE(Text026, NoOfInvoiceSent);

        END ELSE
            IF NOT PreviewOnly THEN
                IF GUIALLOWED THEN
                    MESSAGE(Text027);
    end;

    procedure SetCVInfoForExport(PrmRecRef: RecordRef)
    var
        TaxTypeCode: Record "PRG_E-Invoice Tax Type Code";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        SalesInvHeader: Record "Sales Invoice Header";
        ServiceInvHeader: Record "Service Invoice Header";
    begin

        GetExportSetup();

        IF NOT ExportSetup.Activated THEN
            EXIT;

        ExportSetup.TESTFIELD("Company Country/Region Code");
        ExportSetup.TESTFIELD("E-Export Starting Date");

        CLEAR(GlobRegionCode);

        CASE PrmRecRef.NUMBER OF
            DATABASE::"Sales Invoice Header":
                BEGIN
                    PrmRecRef.SETTABLE(SalesInvHeader);
                    IF SalesInvHeader."PRG_E-Platform Type" IN [SalesInvHeader."PRG_E-Platform Type"::EExport, SalesInvHeader."PRG_E-Platform Type"::FreeZone] THEN
                        IF FindInvoiceLineExport(PrmRecRef) THEN BEGIN
                            ExecExportControls();
                            GlobRegionCode := SalesInvHeader."Bill-to Country/Region Code";
                            IF EInvSetup."E-Archive Starting Date" <> 0D THEN
                                ModfiyGlobCVInfoForExport()
                            ELSE
                                FillCVInfoForExport(GlobCVInfo."CV Type"::Customer, SalesInvHeader."Bill-to Customer No.");
                        END;
                END;
            DATABASE::"Purch. Cr. Memo Hdr.":
                BEGIN
                    PrmRecRef.SETTABLE(PurchCrMemoHdr);
                    IF PurchCrMemoHdr."PRG_E-Platform Type" IN [PurchCrMemoHdr."PRG_E-Platform Type"::EExport, PurchCrMemoHdr."PRG_E-Platform Type"::FreeZone] THEN
                        IF FindInvoiceLineExport(PrmRecRef) THEN BEGIN
                            ExecExportControls();
                            GlobRegionCode := PurchCrMemoHdr."Pay-to Country/Region Code";
                            IF EInvSetup."E-Archive Starting Date" <> 0D THEN
                                ModfiyGlobCVInfoForExport()
                            ELSE
                                FillCVInfoForExport(GlobCVInfo."CV Type"::Vendor, PurchCrMemoHdr."Pay-to Vendor No.");
                        END;
                END;

            Database::"Service Invoice Header":
                begin
                    PrmRecRef.SETTABLE(ServiceInvHeader);
                    IF ServiceInvHeader."PRG_E-Platform Type" IN [ServiceInvHeader."PRG_E-Platform Type"::EExport, ServiceInvHeader."PRG_E-Platform Type"::FreeZone] THEN
                        IF FindInvoiceLineExport(PrmRecRef) THEN BEGIN
                            ExecExportControls();
                            GlobRegionCode := ServiceInvHeader."Bill-to Country/Region Code";
                            IF EInvSetup."E-Archive Starting Date" <> 0D THEN
                                ModfiyGlobCVInfoForExport()
                            ELSE
                                FillCVInfoForExport(GlobCVInfo."CV Type"::Vendor, ServiceInvHeader."Bill-to Customer No.");
                        END;
                end;
        END;

    end;

    procedure SetPurchDoc_EPlatformType(var PurchaseHeader: Record "Purchase Header")
    var
        LiableCompany: Record "PRG_E-Invoice Liable Companies";
        Vend: Record Vendor;
        StartDate: Date;
    begin
        IF NOT GetInvSetup() then
            exit;

        GetExportSetup();

        IF NOT GotInvSetup THEN
            EXIT;

        IF NOT EInvSetup.Activated THEN
            EXIT;

        Vend.get(PurchaseHeader."Pay-to Vendor No.");
        Vend.TestField("VAT Registration No.");

        LiableCompany.SetCurrentKey(Identifier);
        LiableCompany.SetRange(Identifier, Vend."VAT Registration No.");
        if Vend.PRG_Alias <> '' then
            LiableCompany.SetRange(Alias, Vend.PRG_Alias);
        if LiableCompany.FindFirst() then begin
            StartDate := Library.ParseDatetime(LiableCompany.FirstCreationTime, 'YMD');
            IF (PurchaseHeader."Posting Date" >= EInvSetup."E-Invoice Starting Date") AND (PurchaseHeader."Posting Date" >= StartDate) THEN
                PurchaseHeader."PRG_E-Platform Type" := PurchaseHeader."PRG_E-Platform Type"::EInvoice
            ELSE BEGIN
                IF (EInvSetup."E-Archive Starting Date" <> 0D) AND (PurchaseHeader."Posting Date" >= EInvSetup."E-Archive Starting Date") THEN
                    PurchaseHeader."PRG_E-Platform Type" := PurchaseHeader."PRG_E-Platform Type"::EArchive
                ELSE
                    PurchaseHeader."PRG_E-Platform Type" := PurchaseHeader."PRG_E-Platform Type"::" ";
            END;
        END ELSE BEGIN
            IF (GotExportSetup) AND (ExportSetup.Activated) THEN BEGIN
                IF (NOT (PurchaseHeader."Pay-to Country/Region Code" IN [ExportSetup."Company Country/Region Code", ''])) AND (PurchaseHeader."Posting Date" >= ExportSetup."E-Export Starting Date") THEN
                    PurchaseHeader."PRG_E-Platform Type" := PurchaseHeader."PRG_E-Platform Type"::EExport
                ELSE BEGIN
                    IF (EInvSetup."E-Archive Starting Date" <> 0D) AND (PurchaseHeader."Posting Date" >= EInvSetup."E-Archive Starting Date") THEN
                        PurchaseHeader."PRG_E-Platform Type" := PurchaseHeader."PRG_E-Platform Type"::EArchive
                    ELSE
                        PurchaseHeader."PRG_E-Platform Type" := PurchaseHeader."PRG_E-Platform Type"::" ";
                END;
            END ELSE BEGIN
                IF (EInvSetup."E-Archive Starting Date" <> 0D) AND (PurchaseHeader."Posting Date" >= EInvSetup."E-Archive Starting Date") THEN
                    PurchaseHeader."PRG_E-Platform Type" := PurchaseHeader."PRG_E-Platform Type"::EArchive
            END;
        END;
    end;

    procedure SetSalesDoc_EPlatformType(var SalesHeader: Record "Sales Header")
    var
        Cust: Record Customer;
        LiableCompany: Record "PRG_E-Invoice Liable Companies";
        StartDate: Date;
        IsHandle: Boolean;
    begin
        OnBeforeSetSalesDocEPlatformType(SalesHeader, IsHandle);
        IF IsHandle then
            exit;

        IF NOT GetInvSetup() then
            exit;

        GetExportSetup();

        IF NOT GotInvSetup THEN
            EXIT;

        IF NOT EInvSetup.Activated THEN
            EXIT;

        Cust.get(SalesHeader."Bill-to Customer No.");
        Cust.TestField("VAT Registration No.");
        SalesHeader."PRG_Exclude in E-Invoice" := Cust."PRG_Exclude in E-Invoice";
        LiableCompany.SetCurrentKey(Identifier);
        LiableCompany.SetRange(Identifier, Cust."VAT Registration No.");
        if Cust.PRG_Alias <> '' then
            LiableCompany.SetRange(Alias, Cust.PRG_Alias);
        if LiableCompany.FindFirst() then begin
            StartDate := Library.ParseDatetime(LiableCompany.FirstCreationTime, 'YMD');
            IF (SalesHeader."Posting Date" >= EInvSetup."E-Invoice Starting Date") AND (SalesHeader."Posting Date" >= StartDate) THEN
                SalesHeader."PRG_E-Platform Type" := SalesHeader."PRG_E-Platform Type"::EInvoice
            ELSE BEGIN
                IF (EInvSetup."E-Archive Starting Date" <> 0D) AND (SalesHeader."Posting Date" >= EInvSetup."E-Archive Starting Date") THEN
                    SalesHeader."PRG_E-Platform Type" := SalesHeader."PRG_E-Platform Type"::EArchive
                ELSE
                    SalesHeader."PRG_E-Platform Type" := SalesHeader."PRG_E-Platform Type"::" ";
            END;
        END ELSE BEGIN
            IF (GotExportSetup) AND (ExportSetup.Activated) THEN BEGIN
                IF (NOT (SalesHeader."Bill-to Country/Region Code" IN [ExportSetup."Company Country/Region Code", ''])) AND (SalesHeader."Posting Date" >= ExportSetup."E-Export Starting Date") THEN
                    SalesHeader."PRG_E-Platform Type" := SalesHeader."PRG_E-Platform Type"::EExport
                ELSE BEGIN
                    IF (EInvSetup."E-Archive Starting Date" <> 0D) AND (SalesHeader."Posting Date" >= EInvSetup."E-Archive Starting Date") THEN
                        SalesHeader."PRG_E-Platform Type" := SalesHeader."PRG_E-Platform Type"::EArchive
                    ELSE
                        SalesHeader."PRG_E-Platform Type" := SalesHeader."PRG_E-Platform Type"::" ";
                END;
            END ELSE BEGIN
                IF (EInvSetup."E-Archive Starting Date" <> 0D) AND (SalesHeader."Posting Date" >= EInvSetup."E-Archive Starting Date") THEN
                    SalesHeader."PRG_E-Platform Type" := SalesHeader."PRG_E-Platform Type"::EArchive
            END;
        END;
    end;

    procedure SetScopeForExport(RecRef: RecordRef): Boolean
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        PurcCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        SalesInvHeader: Record "Sales Invoice Header";
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        IF NOT ExportSetup.GET() THEN
            EXIT(FALSE);

        IF NOT ExportSetup.Activated THEN
            EXIT(FALSE);

        CASE RecRef.NUMBER OF
            DATABASE::"Cust. Ledger Entry":
                BEGIN
                    RecRef.SETTABLE(CustLedgEntry);
                    SalesInvHeader.SETRANGE("No.", CustLedgEntry."Document No.");
                    SalesInvHeader.SETRANGE("Posting Date", CustLedgEntry."Posting Date");
                    IF SalesInvHeader.FINDFIRST() THEN
                        IF SalesInvHeader."PRG_E-Platform Type" IN [SalesInvHeader."PRG_E-Platform Type"::EExport, SalesInvHeader."PRG_E-Platform Type"::FreeZone] THEN
                            EXIT(TRUE);

                END;
            DATABASE::"Vendor Ledger Entry":
                BEGIN
                    RecRef.SETTABLE(VendLedgEntry);
                    PurcCrMemoHdr.SETRANGE("No.", VendLedgEntry."Document No.");
                    PurcCrMemoHdr.SETRANGE("Posting Date", VendLedgEntry."Posting Date");
                    IF PurcCrMemoHdr.FINDFIRST() THEN
                        IF PurcCrMemoHdr."PRG_E-Platform Type" IN [PurcCrMemoHdr."PRG_E-Platform Type"::EExport, SalesInvHeader."PRG_E-Platform Type"::FreeZone] THEN
                            EXIT(TRUE);
                END;
        END;
    end;

    procedure SetTaxLine(HeaderEntryNo: Integer; TaxTypeCode: Code[20]; TaxAmt: Decimal; BaseAmt: Decimal; TaxPercent: Decimal)
    begin
        InsertTaxLine(HeaderEntryNo, TaxTypeCode, ROUND(TaxAmt, 0.01), ROUND(BaseAmt, 0.01), ROUND(TaxPercent, 0.01), FALSE);
        InsertTaxLine(HeaderEntryNo, TaxTypeCode, ROUND(TaxAmt, 0.01), ROUND(BaseAmt, 0.01), ROUND(TaxPercent, 0.01), TRUE);
    end;

    procedure UpdateCVInfoForRegChange(TableNo: Integer; CVNo: Code[20]; RegNo: Code[20])
    var
        LocCVInfo: Record "PRG_E-Invoice CV Info.";
        LiableCompanies: Record "PRG_E-Invoice Liable Companies";
    begin
        CASE TableNo OF
            DATABASE::Customer:
                BEGIN
                    IF LocCVInfo.GET(LocCVInfo."CV Type"::Customer, CVNo) THEN BEGIN
                        IF LocCVInfo."Tax Registration No." <> RegNo THEN BEGIN
                            LocCVInfo."Tax Registration No." := RegNo;
                            LocCVInfo.MODIFY();
                        END;
                        EXIT;
                    END;
                END;
            DATABASE::Vendor:
                BEGIN
                    IF LocCVInfo.GET(LocCVInfo."CV Type"::Vendor, CVNo) THEN BEGIN
                        IF LocCVInfo."Tax Registration No." <> RegNo THEN BEGIN
                            LocCVInfo."Tax Registration No." := RegNo;
                            LocCVInfo.MODIFY();
                        END;
                        EXIT;
                    END;
                END;
        END;

        IF NOT GetInvSetup() THEN
            EXIT;

        LiableCompanies.SETRANGE(Identifier, RegNo);
        IF LiableCompanies.FINDFIRST() THEN BEGIN

            LocCVInfo.INIT();
            CASE TableNo OF
                DATABASE::Customer:
                    LocCVInfo."CV Type" := LocCVInfo."CV Type"::Customer;
                DATABASE::Vendor:
                    LocCVInfo."CV Type" := LocCVInfo."CV Type"::Vendor;
            END;
            LocCVInfo.VALIDATE("CV No.", CVNo);
            LocCVInfo."Integration Type" := LocCVInfo."Integration Type"::EInvoice;
            LocCVInfo."E-mail Address" := LiableCompanies.Alias;
            LocCVInfo."E-Invoice Starting Date" := Library.ParseDatetime(LiableCompanies.FirstCreationTime, 'YMD');
            LocCVInfo."Creation Datetime" := CURRENTDATETIME;
            LocCVInfo."Tax Registration No." := RegNo;
            LocCVInfo."Profile ID" := EInvSetup."Default ProfileID";
            IF LocCVInfo.INSERT(TRUE) THEN;
        END;
    end;

    procedure UpdateExtDocNo(PrmQueue: Record "PRG_E-Invoice Queue"; var GLReg: Record "G/L Register")
    var
        BankAccLedgEntry: Record "Bank Account Ledger Entry";
        CustLedgEntry: Record "Cust. Ledger Entry";
        GLEntry: Record "G/L Entry";
        LocEInvHeader: Record "PRg_E-Invoice Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        SalesInvHeader: Record "Sales Invoice Header";
        ValueEntry: Record "Value Entry";
        VATEntry: Record "VAT Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        IsHandled: Boolean;
        ModifyPostingDesc: Boolean;
        ExtDocNo: Code[50];
        NewPostingDesc: Text[50];
    begin
        OnBeforeUpdateExDocNo(PrmQueue, GLReg, IsHandled);
        if IsHandled then
            EXIT;

        LocEInvHeader.SETFILTER(UUID, '<>%1', PrmQueue.UniqueIdentifier);
        LocEInvHeader.SETRANGE("Invoice ID", PrmQueue.InvoiceID);
        LocEInvHeader.SETRANGE(Type, LocEInvHeader.Type::Outbox);
        IF NOT LocEInvHeader.ISEMPTY THEN
            ERROR(Text032, PrmQueue.InvoiceID);

        GLReg.GET(PrmQueue.GLRegisterEntryNo);

        GLEntry.SETRANGE("Entry No.", GLReg."From Entry No.", GLReg."To Entry No.");
        GLEntry.FINDFIRST();

        IF GLEntry."External Document No." <> '' THEN
            ExtDocNo := GLEntry."External Document No."
        ELSE BEGIN
            ExtDocNo := '[]';
        END;

        NewPostingDesc := COPYSTR(ReplaceDescription(GLEntry.Description, ExtDocNo, PrmQueue.InvoiceID), 1, 50);

        OnAfterCreateNewPostingDescription(GLEntry, NewPostingDesc);

        ModifyPostingDesc := GLEntry.Description <> NewPostingDesc;
        IF ModifyPostingDesc THEN
            GLEntry.MODIFYALL(Description, NewPostingDesc);
        GLEntry.MODIFYALL("External Document No.", PrmQueue.InvoiceID);

        CustLedgEntry.SETRANGE("Entry No.", GLReg."From Entry No.", GLReg."To Entry No.");
        IF NOT CustLedgEntry.ISEMPTY THEN
            CustLedgEntry.MODIFYALL("External Document No.", PrmQueue.InvoiceID);
        IF ModifyPostingDesc THEN
            CustLedgEntry.MODIFYALL(Description, NewPostingDesc);

        VendLedgEntry.SETRANGE("Entry No.", GLReg."From Entry No.", GLReg."To Entry No.");
        IF NOT VendLedgEntry.ISEMPTY THEN
            VendLedgEntry.MODIFYALL("External Document No.", PrmQueue.InvoiceID);
        IF ModifyPostingDesc THEN
            VendLedgEntry.MODIFYALL(Description, NewPostingDesc);

        VATEntry.SETRANGE("Entry No.", GLReg."From VAT Entry No.", GLReg."To VAT Entry No.");
        IF NOT VATEntry.ISEMPTY THEN
            VATEntry.MODIFYALL("External Document No.", PrmQueue.InvoiceID);

        SalesInvHeader.SETRANGE("No.", GLEntry."Document No.");
        SalesInvHeader.SETRANGE("Posting Date", GLEntry."Posting Date");
        IF SalesInvHeader.FindSet() THEN
            repeat
                SalesInvHeader.Validate("External Document No.", PrmQueue.InvoiceID);
                IF ModifyPostingDesc THEN
                    SalesInvHeader.Validate("Posting Description", NewPostingDesc);
                SalesInvHeader.Modify(true);
            until SalesInvHeader.Next() = 0;

        //SalesInvHeader.MODIFYALL("External Document No.", PrmQueue.InvoiceID);        
        //IF ModifyPostingDesc THEN
        //SalesInvHeader.MODIFYALL("Posting Description", NewPostingDesc);

        PurchCrMemoHeader.SETRANGE("No.", GLEntry."Document No.");
        PurchCrMemoHeader.SETRANGE("Posting Date", GLEntry."Posting Date");
        IF PurchCrMemoHeader.FindSet() then
            repeat
                PurchCrMemoHeader.Validate("Vendor Cr. Memo No.", PrmQueue.InvoiceID);
                if ModifyPostingDesc then
                    PurchCrMemoHeader.Validate("Posting Description", NewPostingDesc);
                PurchCrMemoHeader.Modify(true);
            until PurchCrMemoHeader.Next() = 0;

        //IF NOT PurchCrMemoHeader.ISEMPTY THEN
        //    PurchCrMemoHeader.MODIFYALL("Vendor Cr. Memo No.", PrmQueue.InvoiceID);
        //IF ModifyPostingDesc THEN
        //    PurchCrMemoHeader.MODIFYALL("Posting Description", NewPostingDesc);

        BankAccLedgEntry.SETCURRENTKEY("Document No.", "Posting Date");
        BankAccLedgEntry.SETRANGE("Document No.", GLEntry."Document No.");
        BankAccLedgEntry.SETRANGE("Posting Date", GLEntry."Posting Date");
        BankAccLedgEntry.MODIFYALL("External Document No.", PrmQueue.InvoiceID);

        ValueEntry.RESET();
        ValueEntry.SETCURRENTKEY("Document No.");
        ValueEntry.SETRANGE("Document No.", GLEntry."Document No.");
        ValueEntry.SETRANGE("Document Type", ValueEntry."Document Type"::"Sales Invoice");
        ValueEntry.SETRANGE("Posting Date", GLEntry."Posting Date");
        ValueEntry.MODIFYALL("External Document No.", PrmQueue.InvoiceID);
    end;

    procedure UpdateQueueForInvInfo(var Queue: Record "PRG_E-Invoice Queue"; pInvDate: Date; pAmtExclVAT: Decimal; pAmtInclVAT: Decimal; pCVNo: Code[20])
    begin
        Queue.IssueDate := pInvDate;
        Queue.TaxExclusiveAmount := ROUND(pAmtExclVAT, 0.01);
        Queue.TaxInclusiveAmount := ROUND(pAmtInclVAT, 0.01);
        Queue.VALIDATE(CVNo, pCVNo);
        Queue.InvoiceType := GlobEInvHeader.InvoiceType;
        GlobEInvHeader.MODIFY();
    end;

    procedure UpdateTaxCodeFromExcel()
    var
        ExcellBuffer: Record "Excel Buffer" temporary;
        SalesInvLine: Record "Sales Invoice Line";
        FileMgt: Codeunit "File Management";
        TempBlob: Codeunit "Temp Blob";
        TempDocNo: Code[20];
        IStr: InStream;
        i: Integer;
        LastCol: Integer;
        LastRow: Integer;
        TempInt: Integer;
        ExcelFileExtensionTok: Label '.xlsx';
        Text001: Label 'Upload Excel';
        Text002: Label 'Process Completed';
        FromFile: Text;
        NewValue: Text;
        SheetName: Text;
    begin
        TempBlob.CreateInStream(IStr, TextEncoding::UTF8);
        if not File.UploadIntoStream(Text001, '', FileMgt.GetToFilterText('', ExcelFileExtensionTok), FromFile, IStr) then
            exit;

        SheetName := ExcellBuffer.SelectSheetsNameStream(IStr);
        if SheetName = '' then
            exit;

        ExcellBuffer.OpenBookStream(IStr, SheetName);
        ExcellBuffer.ReadSheet();

        ExcellBuffer.FindLast();
        LastCol := ExcellBuffer."Column No.";
        LastRow := ExcellBuffer."Row No.";

        for i := 1 to LastRow do begin
            Clear(TempDocNo);
            Clear(TempDocNo);
            Clear(NewValue);

            ExcellBuffer.Get(i, 1);
            TempDocNo := ExcellBuffer."Cell Value as Text";
            ExcellBuffer.Get(i, 2);
            Evaluate(TempInt, ExcellBuffer."Cell Value as Text");
            ExcellBuffer.Get(i, 3);
            Evaluate(NewValue, ExcellBuffer."Cell Value as Text");
            if SalesInvLine.Get(TempDocNo, TempInt) then begin
                SalesInvLine."PRG_E-Invoice Tax Type Code" := NewValue;
                SalesInvLine.Modify();
            end;
        end;

        if GuiAllowed then
            Message(Text002);

    end;

    local procedure ApplyAllowanceInformation(var EInvLine: Record "PRG_E-Invoice Line"; TrueIndicator: Text; NewAmount: Decimal; NewRate: Decimal; NewDesc: Text)
    begin

        EInvLine.CALCFIELDS("Taxable Amount");
        EInvLine."Allowance Charge Indicator" := TrueIndicator;
        EInvLine."Allowance Charge Amount" := NewAmount;
        EInvLine."Allowance Charge Rate" := ROUND((100 * EInvLine."Allowance Charge Amount" / EInvLine."Taxable Amount"), 0.0001);
        EInvLine."Allowance Charge Reason" := NewDesc;
        EInvLine.MODIFY();

    end;

    local procedure CalcAmtInclVAT(var pSalesInvLine: Record "Sales Invoice Line")
    begin
        pSalesInvLine."Unit Price" := pSalesInvLine."Unit Price" / (1 + (pSalesInvLine."VAT %" / 100));
        pSalesInvLine."Line Discount Amount" := pSalesInvLine.Quantity * pSalesInvLine."Unit Price" * pSalesInvLine."Line Discount %" / 100;
        pSalesInvLine."Inv. Discount Amount" := pSalesInvLine."Inv. Discount Amount" / (1 + (pSalesInvLine."VAT %" / 100));
    end;

    local procedure CalcPurchInvDiscAmt(PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.") InvDiscAmount: Decimal
    var
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        PurchCrMemoLine.SETRANGE("Document No.", PurchCrMemoHeader."No.");
        IF PurchCrMemoLine.FINDSET() THEN
            REPEAT
                IF PurchCrMemoHeader."Prices Including VAT" THEN
                    InvDiscAmount := InvDiscAmount + (PurchCrMemoLine."Inv. Discount Amount" + PurchCrMemoLine."Line Discount Amount")
                      / (1 + PurchCrMemoLine."VAT %" / 100)
                ELSE
                    InvDiscAmount := InvDiscAmount + (PurchCrMemoLine."Inv. Discount Amount" + PurchCrMemoLine."Line Discount Amount");
            UNTIL PurchCrMemoLine.NEXT() = 0;

        EXIT(InvDiscAmount);
    end;

    local procedure CalcSalesInvDiscAmt(SalesInvHeader: Record "Sales Invoice Header") InvDiscAmount: Decimal
    var
        SalesInvLine: Record "Sales Invoice Line";
    begin
        SalesInvLine.SETRANGE("Document No.", SalesInvHeader."No.");
        IF SalesInvLine.FINDSET() THEN
            REPEAT
                IF SalesInvHeader."Prices Including VAT" THEN
                    InvDiscAmount := InvDiscAmount + (SalesInvLine."Inv. Discount Amount" + SalesInvLine."Line Discount Amount")
                      / (1 + SalesInvLine."VAT %" / 100)
                ELSE
                    InvDiscAmount := InvDiscAmount + (SalesInvLine."Inv. Discount Amount" + SalesInvLine."Line Discount Amount");
            UNTIL SalesInvLine.NEXT() = 0;

        EXIT(InvDiscAmount);
    end;

    local procedure CalculateAmountIndicator(LineAmt: Decimal; DocAmt: Decimal; TotalAmt: Decimal; var AmtToApply: Decimal): Decimal
    var
        Indicator: Decimal;
    begin
        IF LineAmt = 0 THEN
            EXIT;

        Indicator := (100 * LineAmt) / DocAmt;
        AmtToApply := ROUND(((TotalAmt * Indicator) / 100), 0.01);

        EXIT(AmtToApply);
    end;

    local procedure CreateShipRef()
    var
        ReturnShipHeader: Record "Return Shipment Header";
        SalesShipHeader: Record "Sales Shipment Header";
    begin
        TempSalesShptHeader.RESET();
        TempSalesShptHeader.DELETEALL();
        TempSalesShptLine.RESET();
        IF TempSalesShptLine.FINDSET() THEN
            REPEAT
                IF NOT TempSalesShptHeader.GET(TempSalesShptLine."Document No.") THEN BEGIN
                    TempSalesShptHeader."No." := TempSalesShptLine."Document No.";
                    TempSalesShptHeader.INSERT();
                    SalesShipHeader.GET(TempSalesShptLine."Document No.");
                    InsertRefBuffer(GlobEInvHeader."Entry No.", 0,
                      GlobRefLine."Reference Type"::Despatch,
                      SalesShipHeader."External Document No.", SalesShipHeader."Posting Date");
                END;
            UNTIL TempSalesShptLine.NEXT() = 0;

        TempReturnShptHeader.RESET();
        TempReturnShptHeader.DELETEALL();
        TempReturnShptLine.RESET();
        IF TempReturnShptLine.FINDSET() THEN
            REPEAT
                IF NOT TempReturnShptHeader.GET(TempReturnShptLine."Document No.") THEN BEGIN
                    TempReturnShptHeader."No." := TempReturnShptLine."Document No.";
                    TempReturnShptHeader.INSERT();
                    ReturnShipHeader.GET(TempReturnShptLine."Document No.");
                    InsertRefBuffer(GlobEInvHeader."Entry No.", 0,
                      GlobRefLine."Reference Type"::Despatch,
                      ReturnShipHeader."Vendor Authorization No.", ReturnShipHeader."Posting Date");
                END;
            UNTIL TempReturnShptLine.NEXT() = 0;
    end;

    local procedure CreateTempPurchCrMemoLines(var PurchCrMemoLine: Record "Purch. Cr. Memo Line"; var TempPurchCrMemoLine: Record "Purch. Cr. Memo Line" temporary)
    var
        LineRecordRef: RecordRef;
    begin
        PurchCrMemoLine.FindSet();
        repeat

            LineRecordRef.Open(Database::"Purch. Cr. Memo Line");
            LineRecordRef.GetTable(PurchCrMemoLine);

            TempPurchCrMemoLine := PurchCrMemoLine;
            TempPurchCrMemoLine."Unit Volume" := GetDeductionValue(LineRecordRef);//Used As Grouping Purpose
            TempPurchCrMemoLine.Insert();

            FindReturnShipments(PurchCrMemoLine);
            LineRecordRef.Close();
        until PurchCrMemoLine.Next() = 0;
    end;

    local procedure CreateTempSalesInvoiceLines(var SalesInvLine: Record "Sales Invoice Line"; var TempSalesInvLine: Record "Sales Invoice Line" temporary)
    var
        LineRecordRef: RecordRef;
    begin
        SalesInvLine.FindSet();
        repeat

            LineRecordRef.Open(Database::"Sales Invoice Line");
            LineRecordRef.GetTable(SalesInvLine);

            TempSalesInvLine := SalesInvLine;
            TempSalesInvLine."Unit Volume" := GetDeductionValue(LineRecordRef);//Used As Grouping Purpose
            TempSalesInvLine.Insert();

            FindSalesShipments(SalesInvLine);
            LineRecordRef.Close();
        until SalesInvLine.Next() = 0;
    end;

    local procedure FindIdentifier(CVIdentifier: Text[250]; AddrCode: Code[10]): Text[250]
    var
        OrderAddr: Record "Order Address";
        ShipToAddr: Record "Ship-to Address";
        AddrIdentifier: Text[250];
    begin
        IF AddrCode = '' THEN
            EXIT(CVIdentifier)
        ELSE BEGIN

            CASE GlobEInvHeader.InvoiceType OF
                GlobEInvHeader.InvoiceType::Sales:
                    IF ShipToAddr.GET(GlobEInvHeader.CustNo, AddrCode) THEN
                        AddrIdentifier := ShipToAddr."PRG_E-Invoice E-mail Address";
                GlobEInvHeader.InvoiceType::PurchCr:
                    IF OrderAddr.GET(GlobEInvHeader.CustNo, AddrCode) THEN
                        AddrIdentifier := OrderAddr."PRG_E-Invoice E-mail Address";
            END;

            IF AddrIdentifier <> '' THEN
                EXIT(AddrIdentifier)
            ELSE BEGIN
                IF NOT GetInvSetup() THEN
                    ERROR(Text048);
                CASE EInvSetup."Branch Empty E-Mail Control" OF

                    EInvSetup."Branch Empty E-Mail Control"::CopyFromCV:
                        EXIT(CVIdentifier);

                    EInvSetup."Branch Empty E-Mail Control"::Warn:
                        IF CONFIRM(Text019) THEN
                            EXIT(CVIdentifier)
                        ELSE
                            ERROR(Text020);

                    EInvSetup."Branch Empty E-Mail Control"::Block:
                        CASE GlobEInvHeader.InvoiceType OF
                            GlobEInvHeader.InvoiceType::Sales:
                                ShipToAddr.TESTFIELD("PRG_E-Invoice E-mail Address");
                            GlobEInvHeader.InvoiceType::PurchCr:
                                OrderAddr.TESTFIELD("PRG_E-Invoice E-mail Address");
                        END;
                END;
            END;
        END;
    end;

    local procedure FindPostingDate(GLReg: Record "G/L Register"): Date
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.Get(GLReg."From Entry No.");
        exit(GLEntry."Posting Date");
    end;

    local procedure FindPurchReturnBarcode(PurchCrMemoLine: Record "Purch. Cr. Memo Line" temporary): Text[30]
    var
        ItemCrossReference: Record "Item Reference";
    begin
        IF PurchCrMemoLine.Type <> PurchCrMemoLine.Type::Item THEN
            exit('');
        ItemCrossReference.RESET();
        ItemCrossReference.SETRANGE("Item No.", PurchCrMemoLine."No.");
        ItemCrossReference.SETRANGE("Variant Code", PurchCrMemoLine."Variant Code");
        ItemCrossReference.SETRANGE("Unit of Measure", PurchCrMemoLine."Unit of Measure Code");
        ItemCrossReference.SETRANGE("Reference Type", ItemCrossReference."Reference Type"::"Bar Code");
        ItemCrossReference.SETRANGE("Reference Type No.", PurchCrMemoLine."Buy-from Vendor No.");
        IF ItemCrossReference.FINDFIRST() THEN;
        EXIT(ItemCrossReference."Reference No.");
    end;

    local procedure FindPurchReturnCrossRef(PurchCrMemoLine: Record "Purch. Cr. Memo Line" temporary): Text[30]
    var
        ItemCrossReference: Record "Item Reference";
    begin

        IF PurchCrMemoLine.Type <> PurchCrMemoLine.Type::Item THEN
            exit('');
        ItemCrossReference.RESET();
        ItemCrossReference.SETRANGE("Item No.", PurchCrMemoLine."No.");
        ItemCrossReference.SETRANGE("Variant Code", PurchCrMemoLine."Variant Code");
        ItemCrossReference.SETRANGE("Unit of Measure", PurchCrMemoLine."Unit of Measure Code");
        ItemCrossReference.SETRANGE("Reference Type", ItemCrossReference."Reference Type"::Vendor);
        ItemCrossReference.SETRANGE("Reference Type No.", PurchCrMemoLine."Buy-from Vendor No.");
        IF ItemCrossReference.FINDFIRST() THEN;
        EXIT(ItemCrossReference."Reference No.");
    end;

    local procedure FindReturnShipments(PurchCrMemoLine: Record "Purch. Cr. Memo Line"): Code[30]
    var
        TempReturnShptLine2: Record "Return Shipment Line" temporary;
    begin
        IF PurchCrMemoLine.Type = PurchCrMemoLine.Type::Item THEN BEGIN
            PurchCrMemoLine.GetReturnShptLines(TempReturnShptLine2);
            IF TempReturnShptLine2.FINDSET() THEN
                REPEAT
                    TempReturnShptLine := TempReturnShptLine2;
                    IF TempReturnShptLine.INSERT() THEN;
                UNTIL TempReturnShptLine2.NEXT() = 0;
        END;
    end;

    local procedure FindSalesShipments(var SalesInvLine: Record "Sales Invoice Line"): Code[30]
    var
        TempSalesShptLine2: Record "Sales Shipment Line" temporary;
    begin
        IF SalesInvLine.Type = SalesInvLine.Type::Item THEN BEGIN
            SalesInvLine.GetSalesShptLines(TempSalesShptLine2);
            IF TempSalesShptLine2.FINDSET() THEN
                REPEAT
                    TempSalesShptLine := TempSalesShptLine2;
                    IF TempSalesShptLine.INSERT() THEN;
                UNTIL TempSalesShptLine2.NEXT() = 0;
        END;
    end;

    local procedure GetDeductionValue(RecRef: RecordRef): Decimal
    var
        FldRef: FieldRef;
    begin
        //Localication VAT Dedcution Amount Field Number is 70093119
        if not RecRef.FieldExist(70093119) then
            exit(0);
        FldRef := RecRef.Field(70093119);
        exit(FldRef.Value);
    end;

    procedure GetEArchPaymentMethod(PMCode: Code[30]): Code[30]
    var
        CodeMapping: Record "PRG_E-Invoice Code Mapping";
    begin
        IF PMCode <> '' THEN BEGIN
            IF NOT GetInvSetup() THEN
                ERROR(Text048);
            CodeMapping.GET(CodeMapping.Type::EArchPayMethod, PMCode);
            CodeMapping.TESTFIELD("Destination Code");
            EXIT(CodeMapping."Destination Code");
        END;
    end;

    procedure GetEInvPaymentMethod(PMCode: Code[10]): Code[10]
    var
        CodeMapping: Record "PRG_E-Invoice Code Mapping";
    begin
        IF PMCode <> '' THEN BEGIN
            CodeMapping.GET(CodeMapping.Type::EInvPayMethod, PMCode);
            CodeMapping.TESTFIELD("Destination Code");
            EXIT(CodeMapping."Destination Code");
        END ELSE BEGIN
            IF NOT GetInvSetup() THEN
                ERROR(Text048);
            CodeMapping.GET(CodeMapping.Type::EInvPayMethod, '');
            CodeMapping.TESTFIELD("Destination Code");
            EXIT(CodeMapping."Destination Code");
        END;
    end;

    local procedure InsertPaymentMethodRef(PrmPaymentMethodCode: Code[10]; PrmDueDate: Date)
    begin
        InsertRefBuffer(HeaderEntryNo, 0, GlobRefLine."Reference Type"::PaymentMethod, GetEInvPaymentMethod(PrmPaymentMethodCode), PrmDueDate);
    end;

    procedure InsertRefBuffer(HeaderEntryNo: Integer; SourceLineNo: Integer; RefType: Option; RefText: Text[250]; RefDate: Date)
    var
        RefLine: Record "PRG_E-Invoice Reference Buffer";
    begin
        IF RefText = '' THEN
            EXIT;

        RefLine.SETRANGE("Header Entry No.", HeaderEntryNo);
        IF RefLine.FINDLAST() THEN;

        GlobRefLine.INIT();
        GlobRefLine."Header Entry No." := HeaderEntryNo;
        GlobRefLine."Source Line No." := 0;
        GlobRefLine."Line No." := RefLine."Line No." + 10000;
        GlobRefLine."Reference Type" := RefType;
        GlobRefLine."Source Type" := GlobRefLine."Source Type"::Header;
        GlobRefLine."Reference Text" := RefText;
        GlobRefLine."Reference Date" := RefDate;
        GlobRefLine.INSERT();

        OnAfterInsertGlobRefLine(GlobRefLine);

        CASE GlobRefLine."Reference Type" OF
            GlobRefLine."Reference Type"::Despatch:
                GlobRefLine.TESTFIELD("Reference Date");
            GlobRefLine."Reference Type"::PaymentMethod:
                GlobRefLine.TESTFIELD("Reference Date");
        END;
    end;

    local procedure SetQueueToPass(var Queue: Record "PRG_E-Invoice Queue")
    begin
        QueueToPass := Queue;
    end;

    local procedure SplitCVName(var TempCVInfo: Record "PRG_E-Invoice CV Info.")
    var
        i: Integer;
        Pos: Integer;
    begin
        IF TempCVInfo."CV Name" = '' THEN
            EXIT;

        TempCVInfo."CV Name" := DELCHR(TempCVInfo."CV Name", '><');

        IF STRPOS(TempCVInfo."CV Name", ' ') = 0 THEN
            EXIT;

        FOR i := 1 TO STRLEN(TempCVInfo."CV Name") DO
            IF COPYSTR(TempCVInfo."CV Name", i, 1) = ' ' THEN
                Pos := i;

        TempCVInfo."First Name" := COPYSTR(TempCVInfo."CV Name", 1, Pos - 1);
        TempCVInfo."Family Name" := COPYSTR(TempCVInfo."CV Name", Pos + 1);
    end;

    local procedure CheckPayeeInformation(var Queue: Record "PRG_E-Invoice Queue")
    var
        Customer: Record "Customer";
        EInvHeader: Record "PRG_E-Invoice Header";
        Vendor: Record "Vendor";
    begin
        //IF NOT Queue.FINDFIRST THEN
        //    EXIT;

        //REPEAT
        CASE TRUE OF
            Customer.GET(Queue.CVNo):
                BEGIN
                    IF Customer."PRG_Payee Firm" THEN BEGIN
                        EInvHeader.SETFILTER(UUID, Queue.UniqueIdentifier);
                        EInvHeader.FINDFIRST;
                        EInvHeader.TESTFIELD(PaymentBankAccNo);
                        EInvHeader.TESTFIELD(PaymentBankCurrCode);
                    END;
                END;
            Vendor.GET(Queue.CVNo):
                BEGIN
                    IF Vendor."PRG_Payee Firm" THEN BEGIN
                        EInvHeader.SETFILTER(UUID, Queue.UniqueIdentifier);
                        EInvHeader.FINDFIRST;
                        EInvHeader.TESTFIELD(PaymentBankAccNo);
                        EInvHeader.TESTFIELD(PaymentBankCurrCode);
                    END;
                END;
        END;
        //UNTIL Queue.NEXT = 0;
    end;

    procedure GetOutboxInvoice()
    var
        GLReg: Record "G/L Register";
    begin
        GLReg.SetRange(SystemCreatedAt, CreateDateTime(Today - 3, Time), CurrentDateTime);
        GLReg.SetRange("PRG_E-Invoice Status", GLReg."PRG_E-Invoice Status"::" ");
        if not GLReg.FindSet() then
            exit;

        repeat
            FindEInvoices(GLReg);
        until GLReg.Next() = 0;
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCreateGlobalTaxLine(HeaderEntryNo: Integer; var GlobEInvTaxLine: Record "PRG_E-Invoice Tax Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCreateGlobEInvoiceLine(var GlobEInvLine: Record "PRG_E-Invoice Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCreateInvoiceLineForPurch(var PurchCrMemoLine: Record "Purch. Cr. Memo Line"; var TempPurchCrMemoLine: Record "Purch. Cr. Memo Line" temporary)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCreateInvoiceLineForSales(var SalesInvLine: Record "Sales Invoice Line"; var TempSalesInvLine: Record "Sales Invoice Line" temporary)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCreateInvoiceLines(HeaderEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCreateNewPostingDescription(GLEntry: Record "G/L Entry"; var NewPostingDesc: Text)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCreatePurchLineDescription(LineType: Enum "Purchase Line Type"; LineNo: Code[20]; var ItemName: Text; var Desc: Text)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCreateSalesLineDescription(LineType: Enum "Sales Line Type"; LineNo: Code[20]; var ItemName: Text; var Desc: Text)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCreateXmlDocument(Queue: Record "PRG_E-Invoice Queue"; PreviewOnly: Boolean; var XMLdoc: XmlDocument)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterFindCVInfo(var GlobCVInfo: Record "PRG_E-Invoice CV Info.")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterInsertEInvoiceQueue(var Queue: Record "PRG_E-Invoice Queue")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterInsertGlobEInvHeader(var GlobEInvHeader: Record "PRG_E-Invoice Header")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterInsertGlobRefLine(var GlobRefLine: Record "PRG_E-Invoice Reference Buffer")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterModifyEInvoiceStatus(GLReg: Record "G/L Register"; Queue: Record "PRG_E-Invoice Queue")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterSendInvoiceToWB(XMLdoc: XmlDocument; var Queue: Record "PRG_E-Invoice Queue")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeAssignInvoiceID(var EInvHeader: Record "PRG_E-Invoice Header"; var IsHandle: Boolean; var InvoiceID: Text[30])
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCreateEInv(GLReg: Record "G/L Register"; SalesInvHeader: Record "Sales Invoice Header"; PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr."; var CreateEInv: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCreateGlobalTaxLine(HeaderEntryNo: Integer; var GlobEInvTaxLine: Record "PRG_E-Invoice Tax Line"; var IsHeader: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCreateInvoiceLineForSales(var SalesInvLine: Record "Sales Invoice Line"; var TempSalesInvLine: Record "Sales Invoice Line" temporary)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCreateShipmentReference(HeaderEntryNo: Integer; var TempSalesShptLine: Record "Sales Shipment Line" temporary; var TempReturnShptLine: Record "Return Shipment Line" temporary)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCreateXmlDocument(var Queue: Record "PRG_E-Invoice Queue"; var PreviewOnly: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeFindCVInfo(CVType: Option; CVNo: Code[20]; PostingDate: Date; var GlobCVInfo: Record "PRG_E-Invoice CV Info."; IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeInsertEInvoiceQueue(var Queue: Record "PRG_E-Invoice Queue")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeInsertGlobEInvHeader(var GlobEInvHeader: Record "PRG_E-Invoice Header")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeModifyEInvoiceStatus(GLReg: Record "G/L Register"; Queue: Record "PRG_E-Invoice Queue")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeSendInvoiceToWB(var XMLdoc: XmlDocument; Queue: Record "PRG_E-Invoice Queue")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeSetContinueForQueue(GLReg: Record "G/L Register"; var Continue: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeStartCreateCommInvoice(Queue: Record "PRG_E-Invoice Queue"; GlobEInvHeader: Record "PRG_E-Invoice Header")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeUpdateExDocNo(PrmQueue: Record "PRG_E-Invoice Queue"; GLReg: Record "G/L Register"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeTRWordReference(PrmQueue: Record "PRG_E-Invoice Queue"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterInsertPaymentMethodReference(PrmQueue: Record "PRG_E-Invoice Queue"; HeaderEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeInsertInvLinePurch(var TmpPurchCrMemoLine: Record "Purch. Cr. Memo Line"; var LineExtAmt: Decimal)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeInsertInvLineSales(var TmpSalesInvLine: Record "Sales Invoice Line"; var LineExtAmt: Decimal)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCreateInvoiceLineForPurch(var PurchCrMemoLine: Record "Purch. Cr. Memo Line"; var TempPurchCrMemoLine: Record "Purch. Cr. Memo Line" temporary)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeFindSalesCrossRefValue(var ItemCrossReference: Record "Item Reference"; SalesInvLine: Record "Sales Invoice Line" temporary)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeControlVATRegistrationNo(var CVType: Option; var Cust: Record Customer; var Vend: Record Vendor; var GlobCVInfo: Record "PRG_E-Invoice CV Info.")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckVATLength(var GlobCVInfo: Record "PRG_E-Invoice CV Info."; IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckVATLengthv2(var GlobCVInfo: Record "PRG_E-Invoice CV Info."; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeInsertSalesComment(SalesInvHeader: Record "Sales Invoice Header"; var SalesCommLine: Record "Sales Comment Line"; HeaderEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeInsertPurchCrMemoComment(PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr."; var PurchCommLine: Record "Purch. Comment Line"; HeaderEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeSetSalesDocEPlatformType(SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

}