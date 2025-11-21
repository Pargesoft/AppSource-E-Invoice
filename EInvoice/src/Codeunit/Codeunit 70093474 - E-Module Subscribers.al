codeunit 70093474 "PRG_E-Module Subscribers"
{
    Permissions = tabledata 45 = rm;

    var
        ExportSetup: Record "PRG_E-Export Setup";
        EInvSetup: Record "PRG_E-Invoice Setup";
        CheckFunctions: Codeunit "PRG_E-Invoice Check Functions";
        EInvMgt: Codeunit "PRG_E-Invoice Management";
        ConnectorMgt: Codeunit "PRG_E-Invoice Connector Mgt.";
        EInvSetupGot: Boolean;
        GotExportSetup: Boolean;

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

    [EventSubscriber(ObjectType::Table, Database::Customer, 'OnAfterValidateEvent', 'Vat Registration No.', true, true)]
    local procedure Customer_OnAfterValidateEventVATRegistrationNo(VAR Rec: Record Customer; VAR xRec: Record Customer; CurrFieldNo: Integer)
    begin
        GetEInvSetup();
        IF not EInvSetup.Activated then
            exit;

        IF Rec.ISTEMPORARY THEN
            EXIT;

        if Rec."VAT Registration No." = xRec."VAT Registration No." then
            exit;

        ConnectorMgt.GetSingleCustomer(Rec);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterProcessPurchLines', '', false, false)]
    local procedure OnAfterProcessPurchLines_PurchPost(var PurchHeader: Record "Purchase Header")
    begin
        CheckFunctions.CheckPurchInvAmountControl(PurchHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnBeforePostPurchaseDoc', '', false, false)]
    local procedure OnBeforePostPurchaseDoc(var PurchaseHeader: Record "Purchase Header")
    var
        IsHandle: Boolean;
    begin
        GetEInvSetup();
        IF not EInvSetup.Activated then
            exit;

        IF PurchaseHeader.ISTEMPORARY THEN
            EXIT;

        if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::"Return Order" then
            if not PurchaseHeader.Invoice then
                exit;

        if (PurchaseHeader.Ship) and not (PurchaseHeader.Invoice) then
            exit;

        OnBeforeControlRelatedInvInfo(PurchaseHeader, IsHandle);
        IF not IsHandle THEN
            if PurchaseHeader."Document Type" IN [PurchaseHeader."Document Type"::"Credit Memo", PurchaseHeader."Document Type"::"Return Order"] then begin
                PurchaseHeader.TestField("PRG_Related Invoice No.");
                PurchaseHeader.TestField("PRG_Related Invoice Date");
            end;

        CheckFunctions.CheckMedicalInvoiceForPurch(PurchaseHeader);
        CheckFunctions.EInvoiceTaxCodeControl_PurchHeader(PurchaseHeader);
        CheckFunctions.CheckFieldForPurchPost(PurchaseHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforePostSalesDoc', '', false, false)]
    local procedure OnBeforePostSalesDoc(var SalesHeader: Record "Sales Header")
    begin
        GetEInvSetup();
        IF not EInvSetup.Activated then
            exit;

        IF SalesHeader.ISTEMPORARY THEN
            EXIT;

        if SalesHeader."Document Type" = SalesHeader."Document Type"::Order then
            if not SalesHeader.Invoice then
                exit;

        if (SalesHeader.Ship) and not (SalesHeader.Invoice) then
            exit;

        CheckFunctions.CheckMedicalInvoiceForSales(SalesHeader);
        CheckFunctions.EInvoiceTaxCodeControl_SalesHeader(SalesHeader);
        CheckFunctions.CheckFieldForSalesPost(SalesHeader);

    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterValidateEvent', 'PRG_E-Platform Type', false, false)]
    local procedure PurchaseHeader_OnAfterValidateEventEPlatformType(VAR Rec: Record "Purchase Header"; VAR xRec: Record "Purchase Header"; CurrFieldNo: Integer)
    var

    begin
        GetEInvSetup();
        IF not EInvSetup.Activated then
            exit;

        IF Rec.ISTEMPORARY THEN
            EXIT;

        IF FORMAT(Rec) = FORMAT(xRec) THEN
            EXIT;

        CheckFunctions.CheckFieldChangesForEPlatformTypeForPurch(Rec, xRec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterValidateEvent', 'Pay-to Vendor No.', false, false)]
    local procedure PurchaseHeader_OnAfterValidatePayToVendorNo(VAR Rec: Record "Purchase Header"; VAR xRec: Record "Purchase Header"; CurrFieldNo: Integer)
    var

    begin
        GetEInvSetup();
        IF not EInvSetup.Activated then
            exit;

        IF Rec.ISTEMPORARY THEN
            EXIT;

        IF (Rec."Pay-to Vendor No." = '') OR (Rec."Posting Date" = 0D) THEN
            EXIT;

        EInvMgt.SetPurchDoc_EPlatformType(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterValidateEvent', 'Posting Date', false, false)]
    local procedure PurchaseHeader_OnAfterValidatePostingDate(VAR Rec: Record "Purchase Header"; VAR xRec: Record "Purchase Header"; CurrFieldNo: Integer)
    var

    begin
        GetEInvSetup();
        IF not EInvSetup.Activated then
            exit;

        IF Rec.ISTEMPORARY THEN
            EXIT;

        IF (Rec."Pay-to Vendor No." = '') OR (Rec."Posting Date" = 0D) THEN
            EXIT;

        EInvMgt.SetPurchDoc_EPlatformType(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnAfterValidateEvent', 'No.', true, true)]
    local procedure PurchaseLine_OnAfterValidateEventNo(VAR Rec: Record "Purchase Line"; VAR xRec: Record "Purchase Line"; CurrFieldNo: Integer)
    var
        Item: Record Item;
    begin
        GetEInvSetup();
        IF not EInvSetup.Activated then
            exit;

        IF Rec.ISTEMPORARY THEN
            EXIT;

        Rec."PRG_Tariff Number" := '';

        IF Rec.Type <> Rec.Type::Item then
            EXIT;

        if Item.get(Rec."No.") then
            Rec."PRG_Tariff Number" := Item."Tariff No.";

    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterValidateEvent', 'Bill-to Customer No.', false, false)]
    local procedure SalesHeader_OnAfterValidateBillToCustomerNo(VAR Rec: Record "Sales Header"; VAR xRec: Record "Sales Header"; CurrFieldNo: Integer)
    begin
        GetEInvSetup();
        IF not EInvSetup.Activated then
            exit;

        IF Rec.ISTEMPORARY THEN
            EXIT;

        IF (Rec."Bill-to Customer No." = '') OR (Rec."Posting Date" = 0D) THEN
            EXIT;

        EInvMgt.SetSalesDoc_EPlatformType(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterValidateEvent', 'PRG_E-Platform Type', false, false)]
    local procedure SalesHeader_OnAfterValidateEventEPlatformType(VAR Rec: Record "Sales Header"; VAR xRec: Record "Sales Header"; CurrFieldNo: Integer)
    begin
        GetEInvSetup();
        IF not EInvSetup.Activated then
            exit;

        IF Rec.ISTEMPORARY THEN
            EXIT;

        IF FORMAT(Rec) = FORMAT(xRec) THEN
            EXIT;

        CheckFunctions.CheckFieldChangesForEPlatformTypeForSales(Rec, xRec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterValidateEvent', 'Posting Date', false, false)]
    local procedure SalesHeader_OnAfterValidatePostingDate(VAR Rec: Record "Sales Header"; VAR xRec: Record "Sales Header"; CurrFieldNo: Integer)
    begin
        GetEInvSetup();
        IF not EInvSetup.Activated then
            exit;

        IF Rec.ISTEMPORARY THEN
            EXIT;

        IF (Rec."Bill-to Customer No." = '') OR (Rec."Posting Date" = 0D) THEN
            EXIT;

        EInvMgt.SetSalesDoc_EPlatformType(Rec);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Quote to Order", 'OnAfterCreateSalesHeader', '', false, false)]
    local procedure SetEPlatformTypeAfterQuote_OnAfterCreateSalesHeader(var SalesOrderHeader: Record "Sales Header"; SalesHeader: Record "Sales Header")
    var
        EInvMgt: Codeunit "PRG_E-Invoice Management";
        Cust: Record Customer;
    begin
        if SalesOrderHeader.IsTemporary then
            exit;

        Cust.SetRange("VAT Registration No.", SalesHeader."VAT Registration No.");
        if not Cust.FindFirst() then
            exit;

        SalesOrderHeader."Bill-to Customer No." := Cust."No.";

        EInvMgt.SetSalesDoc_EPlatformType(SalesOrderHeader);
        if SalesOrderHeader.Modify() then;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterValidateEvent', 'No.', true, true)]
    local procedure SalesLine_OnAfterValidateEventNo(VAR Rec: Record "Sales Line"; VAR xRec: Record "Sales Line"; CurrFieldNo: Integer)
    var
        Item: Record Item;
    begin
        GetEInvSetup();
        IF not EInvSetup.Activated then
            exit;

        IF Rec.ISTEMPORARY THEN
            EXIT;

        Rec."PRG_Tariff Number" := '';

        IF Rec.Type <> Rec.Type::Item then
            EXIT;

        if Item.get(Rec."No.") then
            Rec."PRG_Tariff Number" := Item."Tariff No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::Vendor, 'OnAfterValidateEvent', 'Vat Registration No.', true, true)]
    local procedure Vendor_OnAfterValidateEventVATRegistrationNo(VAR Rec: Record Vendor; VAR xRec: Record Vendor; CurrFieldNo: Integer)
    begin
        GetEInvSetup();
        IF not EInvSetup.Activated then
            exit;

        IF Rec.ISTEMPORARY THEN
            EXIT;

        if Rec."VAT Registration No." = xRec."VAT Registration No." then
            exit;

        //ConnectorMgt.GetSingleUser(Rec."VAT Registration No.", 1);
        ConnectorMgt.GetSingleVendor(Rec);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnAfterGLFinishPosting', '', false, false)]
    local procedure OnAfterGLFinishPosting(var GLRegister: Record "G/L Register")
    var
        GLEntry: Record "G/L Entry";
        SalesInvHeader: Record "Sales Invoice Header";
        Queue: Record "PRG_E-Invoice Queue";
    begin
        GLEntry.SETRANGE("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        if not GLEntry.FINDFIRST() then
            exit;

        SalesInvHeader.SETRANGE("No.", GLEntry."Document No.");
        SalesInvHeader.SETRANGE("Posting Date", GLEntry."Posting Date");
        if not SalesInvHeader.FindFirst() then
            exit;

        if SalesInvHeader."PRG_Exclude in E-Invoice" then
            GLRegister."PRG_E-Invoice Status" := GLRegister."PRG_E-Invoice Status"::OutofScope;

        Queue.SetRange(GLRegisterEntryNo, GLRegister."No.");
        if not Queue.FindFirst() then
            exit;

        Queue.ERPRecordID := SalesInvHeader.RecordId;
        Queue.Modify();
    end;

    [EventSubscriber(ObjectType::Table, DATABASE::"Purchase Header", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeleteEvent_PurchaseHeader(var Rec: Record "Purchase Header"; RunTrigger: Boolean)
    var
        Queue: Record "PRG_E-Invoice Queue";
        RecID: RecordId;
    begin
        if not RunTrigger then
            exit;

        Queue.SetRange(Type, Queue.Type::Inbox);
        Queue.SetRange(ERPRecordID, Rec.RecordId);
        if not Queue.FindFirst() then
            exit;

        Queue.ERPRecordID := RecID;
        Queue."Dest. Document Status" := Queue."Dest. Document Status"::" ";
        Queue.Modify();
    end;

    [EventSubscriber(ObjectType::Table, DATABASE::"Sales Header", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeleteEvent_SalesHeader(var Rec: Record "Sales Header"; RunTrigger: Boolean)
    var
        Queue: Record "PRG_E-Invoice Queue";
        RecID: RecordId;
    begin
        if not RunTrigger then
            exit;

        Queue.SetRange(Type, Queue.Type::Inbox);
        Queue.SetRange(ERPRecordID, Rec.RecordId);
        if not Queue.FindFirst() then
            exit;

        Queue.ERPRecordID := RecID;
        Queue."Dest. Document Status" := Queue."Dest. Document Status"::" ";
        Queue.Modify();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"XML Buffer Writer", OnBeforeCanPassValue, '', false, false)]
    local procedure OnBeforeCanPassValue_XMLBufferWriter(var Value: Text; Name: Text; var IsHandled: Boolean; var ReturnValue: Boolean)
    begin
        if StrLen(Value) <= 250 then
            exit;

        IsHandled := true;
        ReturnValue := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterPostSalesDoc', '', false, false)]
    local procedure OnAfterPostSalesDoc(var SalesHeader: Record "Sales Header"; SalesCrMemoHdrNo: Code[20])
    var
        SalesCRMemoHeader: Record "Sales Cr.Memo Header";
        Queue: Record "PRG_E-Invoice Queue";
        RecID: RecordId;
    begin
        if SalesCrMemoHdrNo = '' then
            exit;

        if not SalesCRMemoHeader.Get(SalesCrMemoHdrNo) then
            exit;

        Queue.SetRange(ERPRecordID, SalesHeader.RecordId);
        if not Queue.FindFirst() then
            exit;

        Queue.ERPRecordID := SalesCRMemoHeader.RecordId;
        Queue.Modify();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterPostPurchaseDoc', '', false, false)]
    local procedure OnAfterPostPurchaseDoc(PurchInvHdrNo: Code[20]; var PurchaseHeader: Record "Purchase Header")
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        Queue: Record "PRG_E-Invoice Queue";
        RecID: RecordId;
    begin
        if PurchInvHdrNo = '' then
            exit;

        if not PurchInvHeader.Get(PurchInvHdrNo) then
            exit;

        Queue.SetRange(ERPRecordID, PurchaseHeader.RecordId);
        if not Queue.FindFirst() then
            exit;

        Queue.ERPRecordID := PurchInvHeader.RecordId;
        Queue.Modify();
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeControlRelatedInvInfo(var PurchaseHeader: Record "Purchase Header"; var IsHandle: Boolean)
    begin
    end;
}