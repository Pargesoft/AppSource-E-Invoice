codeunit 70093472 "PRG_E-Invoice Library"
{

    Permissions = TableData "Purch. Cr. Memo Hdr." = rm,
                  TableData "Sales Invoice Header" = rm;

    var
        Text001: Label 'Parsing Error for date format!';
        Text002: Label 'Old GUID: %1';
        Text003: Label '%1';
        Text004: Label 'Do you want to create GUID for new sending?';
        Text005: Label 'Initial Values Created.';
        Text006: Label 'All document will be scanned and updated. Do you want to continue?';

    procedure CreateEExportDocumentScopeLog(DocType: Option; DocNo: Code[20]; CVType: Option; CVNo: Code[20]; PostingDate: Date; OldValue: Text; NewValue: Text)
    var
        DocumentScopeLog: Record "PRG_E-Export Doc. Scope Log";
        IsHandled: Boolean;
    begin

        OnBeforeCreateDocumentScopeLog(DocumentScopeLog, IsHandled);
        if IsHandled then
            exit;

        IF DocumentScopeLog.FINDLAST() THEN;

        DocumentScopeLog.INIT();
        DocumentScopeLog."Entry No." := DocumentScopeLog."Entry No." + 1;
        DocumentScopeLog."Document Type" := DocType;
        DocumentScopeLog."Document No." := DocNo;
        DocumentScopeLog."CV Type" := CVType;
        DocumentScopeLog."CV No." := CVNo;
        DocumentScopeLog."Posting Date" := PostingDate;
        DocumentScopeLog."Old Value" := OldValue;
        DocumentScopeLog."New Value" := NewValue;
        DocumentScopeLog.INSERT(TRUE);

        OnAfterCreateDocumentScopeLog(DocumentScopeLog);
    end;

    procedure FormatDate(pDate: Date): Text[30]
    begin
        EXIT(FORMAT(pDate, 0, '<Year4>-<Month,2>-<Day,2>'))
    end;

    procedure FormatDateTime(pDateTime: DateTime): Text[30]
    begin
        EXIT(FORMAT(pDateTime, 0, '<Year4>-<Month,2>-<Day,2> <Hours24,2>:<Minutes,2>:<Seconds,2>'))
    end;

    procedure FormatDec2Places(pDec: Decimal): Text[50]
    begin
        EXIT(FORMAT(ROUND(ABS(pDec), 0.01), 0, '<Standard Format,2>'));
    end;

    procedure FormatDec4Places(pDec: Decimal): Text[50]
    begin
        EXIT(FORMAT(ROUND(ABS(pDec), 0.0001), 0, '<Standard Format,2>'));
    end;

    procedure FormatDec5Places(pDec: Decimal): Text[50]
    begin
        EXIT(FORMAT(ROUND(ABS(pDec), 0.00001), 0, '<Standard Format,2>'));
    end;

    procedure FormatGUID(Value: Variant): Text
    begin
        exit(DelChr(Format(Value), '=', '{}'));
    end;

    procedure FormatStr(Txt: Text[1024]): Text[1024]
    begin
        EXIT(STRSUBSTNO(Text003, Txt))
    end;

    procedure FormatTime(pTime: Time): Text[30]
    begin
        EXIT(FORMAT(pTime, 0, '<Hours24,2><Filler Character,0>:<Minutes,2>:<Seconds,2>'))
    end;

    procedure GetChildValue(var XmlBuffer: Record "XML Buffer" temporary; ParentEntryNo: Integer; _Name: Text; filtertype: Integer): Text
    begin
        XmlBuffer.reset();
        XmlBuffer.SetRange(Type, filtertype);
        XmlBuffer.SetRange("Parent Entry No.", ParentEntryNo);
        XmlBuffer.SetRange(Name, _Name);
        IF XmlBuffer.FindFirst() then;
        exit(XmlBuffer.Value);
    end;

    procedure IsAllReadyImported(UUID: Text): Boolean
    var
        ImportBuffer: Record "PRG_E-Invoice Incoming Buffer";
        Queue: Record "PRG_E-Invoice Queue";
    begin
        Queue.SetRange(Type, Queue.Type::Inbox);
        Queue.SetFilter(UniqueIdentifier, UUID);
        IF Queue.FindFirst() then
            exit(true);

        ImportBuffer.SetRange("Document ID", UUID);
        exit(NOT ImportBuffer.IsEmpty);

    end;

    procedure ParseDatetime(pText: Text[30]; DMYFormat: Text[3]): Date
    var
        DMY: array[3] of Integer;
        DatePart: Text;
        Sep: Text[1];
        IntSetup: Record "PRG_E-Invoice Integrator Setup";
    begin
        IntSetup.Get();
        IF STRPOS(pText, ' ') <> 0 THEN
            pText := COPYSTR(pText, 1, STRPOS(pText, ' ') - 1)
        ELSE
            IF STRPOS(pText, 'T') <> 0 THEN
                pText := COPYSTR(pText, 1, STRPOS(pText, 'T') - 1);

        Sep := COPYSTR(DELCHR(pText, '=', '1234567890'), 1, 1);

        if IntSetup."E-Invoice Integrator" <> IntSetup."E-Invoice Integrator"::Efinans then begin
            DatePart := COPYSTR(pText, 1, STRPOS(pText, Sep) - 1);
            EVALUATE(DMY[1], DatePart);
            pText := COPYSTR(pText, STRPOS(pText, Sep) + 1);
            DatePart := COPYSTR(pText, 1, STRPOS(pText, Sep) - 1);
            EVALUATE(DMY[2], DatePart);
            EVALUATE(DMY[3], COPYSTR(pText, STRPOS(pText, Sep) + 1));

            CASE DMYFormat OF
                'DMY':
                    EXIT(DMY2DATE(DMY[1], DMY[2], DMY[3]));
                'MDY':
                    EXIT(DMY2DATE(DMY[2], DMY[1], DMY[3]));
                'YMD':
                    EXIT(DMY2DATE(DMY[3], DMY[2], DMY[1]));
                ELSE
                    ERROR(Text001);
            end;
        end else begin
            EVALUATE(DMY[1], CopyStr(pText, 1, 4));
            EVALUATE(DMY[2], CopyStr(pText, 5, 2));
            EVALUATE(DMY[3], CopyStr(pText, 7, 2));

            CASE DMYFormat OF
                'DMY':
                    EXIT(DMY2DATE(DMY[1], DMY[2], DMY[3]));
                'MDY':
                    EXIT(DMY2DATE(DMY[2], DMY[1], DMY[3]));
                'YMD':
                    EXIT(DMY2DATE(DMY[3], DMY[2], DMY[1]));
                ELSE
                    ERROR(Text001);
            end;
        end;



    end;

    procedure RecreateGUID(Var Queue: Record "PRG_E-Invoice Queue")
    var
        EInvHeader: Record "PRG_E-Invoice Header";
        StatusCodes: Record "PRG_E-Invoice Status Code";
        EInvMgt: Codeunit "PRG_E-Invoice Management";
    begin
        StatusCodes.SetRange(Code, Queue.ResultStatusCode);
        StatusCodes.SetRange("Error Code", true);
        StatusCodes.FindFirst();

        if Not Confirm(Text004) then
            exit;

        EInvMgt.InsertQueueLog(Queue.EntryNo, 1, STRSUBSTNO(Text002, Queue.UniqueIdentifier));

        EInvHeader.SETRANGE(UUID, Queue.UniqueIdentifier);
        EInvHeader.FINDFIRST();
        EInvHeader.UUID := CREATEGUID();
        EInvHeader.MODIFY();

        Queue.UniqueIdentifier := EInvHeader.UUID;
        Queue."Queue Status" := Queue."Queue Status"::New;
        Queue.ResultStatusCode := '';
        Queue.ResultStatusDescription := '';
        Queue.MODIFY();
    end;

    procedure SetDocumentInitialValues()
    var
        EInvSetup: Record "PRG_E-Invoice Setup";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchHeader: Record "Purchase Header";
        TempPurchHeader: Record "Purchase Header" temporary;
        SalesHeader: Record "Sales Header";
        TempSalesHeader: Record "Sales Header" temporary;
        SalesInvHeader: Record "Sales Invoice Header";
        EInvMgt: Codeunit "PRG_E-Invoice Management";
    begin

        if not Confirm(Text006) then
            exit;

        if (NOT TempSalesHeader.IsTemporary) or (not TempPurchHeader.IsTemporary) then
            Error('');

        EInvSetup.Get();
        EInvSetup.TestField("E-Invoice Starting Date");

        SalesHeader.SetFilter("Document Type", '%1|%2', SalesHeader."Document Type"::Order, SalesHeader."Document Type"::Invoice);
        if SalesHeader.FindSet() then
            repeat
                EInvMgt.SetSalesDoc_EPlatformType(SalesHeader);
                SalesHeader.Modify();
            until SalesHeader.Next() = 0;

        PurchHeader.SetFilter("Document Type", '%1|%2', PurchHeader."Document Type"::"Return Order", PurchHeader."Document Type"::"Credit Memo");
        if PurchHeader.FindSet() then
            repeat
                EInvMgt.SetPurchDoc_EPlatformType(PurchHeader);
                PurchHeader.Modify();
            until PurchHeader.Next() = 0;

        SalesInvHeader.SetFilter("Posting Date", '%1..', EInvSetup."E-Invoice Starting Date");
        if SalesInvHeader.FindSet() then
            repeat
                TempSalesHeader."Posting Date" := SalesInvHeader."Posting Date";
                TempSalesHeader."Bill-to Customer No." := SalesInvHeader."Bill-to Customer No.";
                TempSalesHeader."Bill-to Country/Region Code" := SalesInvHeader."Bill-to Country/Region Code";
                EInvMgt.SetSalesDoc_EPlatformType(TempSalesHeader);
                SalesInvHeader."PRG_E-Platform Type" := TempSalesHeader."PRG_E-Platform Type";
                SalesInvHeader.Modify();
            until SalesInvHeader.Next() = 0;

        PurchCrMemoHdr.SetFilter("Posting Date", '%1..', EInvSetup."E-Invoice Starting Date");
        if PurchCrMemoHdr.FindSet() then
            repeat
                TempPurchHeader."Posting Date" := SalesInvHeader."Posting Date";
                TempPurchHeader."Pay-to Vendor No." := PurchCrMemoHdr."Pay-to Vendor No.";
                TempPurchHeader."Pay-to Country/Region Code" := PurchCrMemoHdr."Pay-to Country/Region Code";
                EInvMgt.SetPurchDoc_EPlatformType(TempPurchHeader);
                PurchCrMemoHdr."PRG_E-Platform Type" := TempPurchHeader."PRG_E-Platform Type";
                PurchCrMemoHdr.Modify();
            until PurchCrMemoHdr.Next() = 0;

        Message(Text005);
    end;

    procedure ToBool(TextValue: Text[1024]): Boolean
    var
        BoolValue: Boolean;
    begin
        if TextValue = '' then
            exit(false)
        else begin
            Evaluate(BoolValue, TextValue, 9);
            exit(BoolValue);
        end;
    end;

    procedure ToDecimal(TextValue: Text[1024]): Decimal
    var
        DecimalValue: Decimal;
    begin
        if TextValue = '' then
            exit(0)
        else begin
            Evaluate(DecimalValue, TextValue, 9);
            exit(DecimalValue);
        end;
    end;

    procedure CreateCVCard(ErrInfo: ErrorInfo)
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        PostCode: Record "Post Code";
        Queue: Record "PRG_E-Invoice Queue";
        EInvHeader: Record "PRG_E-Invoice Header";
        RecRef: RecordRef;
    begin
        RecRef.Get(ErrInfo.RecordId);
        RecRef.SETTABLE(Queue);
        EInvHeader.SetRange(UUID, Queue.UniqueIdentifier);
        EInvHeader.FindFirst();
        CASE Queue.CVType OF
            Queue.CVType::Cust:
                begin
                    Customer.Init();
                    Customer.Validate(Name, EInvHeader.CustName);
                    Customer.Validate("VAT Registration No.", Queue.CVRegistrationNo);
                    Customer.Validate("Phone No.", EInvHeader.CustTelephone);
                    Customer.Validate("Fax No.", EInvHeader.CustTelefax);

                    PostCode.SetRange(Code, EInvHeader.CustPostalZone);
                    if PostCode.FindFirst() then
                        Customer.Validate("Post Code", PostCode.Code);

                    Customer.Insert(true);

                    Page.Run(Page::"Customer Card", Customer);

                    Queue.Validate(CVNo, Customer."No.");
                    Queue.Modify(true);
                end;
            Queue.CVType::Vend:
                begin
                    Vendor.Init();
                    Vendor.Validate(Name, EInvHeader.CustName);
                    Vendor.Validate("VAT Registration No.", Queue.CVRegistrationNo);
                    Vendor.Validate("Phone No.", EInvHeader.CustTelephone);
                    Vendor.Validate("Fax No.", EInvHeader.CustTelefax);

                    PostCode.SetRange(Code, EInvHeader.CustPostalZone);
                    if PostCode.FindFirst() then
                        Vendor.Validate("Post Code", PostCode.Code);

                    Vendor.Insert(true);

                    Page.Run(Page::"Vendor Card", Vendor);

                    Queue.Validate(CVNo, Vendor."No.");
                    Queue.Modify(true);
                end;
        end;
    end;

    procedure FormatDateTimeToISO(InputDateTime: DateTime): Text
    var
        startDT: DateTime;
        startDTText: Text;
        MyTime: Time;
        TimeText: Text;
    begin
        startDTText := FORMAT(DT2Date(InputDateTime), 0, '<Year4>-<Month,2>-<Day,2>');
        MyTime := DT2Time(InputDateTime);

        TimeText := Format(MyTime, 0, '<Hours24,2>:<Minutes,2>:<Seconds,2>');
        TimeText := DelChr(TimeText, '=', ' ');
        if StrLen(TimeText) < 8 then
            TimeText := '0' + TimeText;

        exit(startDTText + 'T' + TimeText);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCreateDocumentScopeLog(var DocumentScopeLog: Record "PRG_E-Export Doc. Scope Log"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCreateDocumentScopeLog(var DocumentScopeLog: Record "PRG_E-Export Doc. Scope Log");
    begin
    end;
}