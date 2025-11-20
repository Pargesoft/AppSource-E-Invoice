codeunit 70093477 "PRG_E-Invoice Inc. Doc. Mgt."
{
    trigger OnRun()
    begin
    end;

    var
        GlobItemMapping: Record "PRG_E-Invoice Item Mapping";
        GlobEInvLine: Record "PRG_E-Invoice Line";
        QueueLog: Record "PRG_E-Invoice Queue Log";
        GlobRefLine: Record "PRG_E-Invoice Reference Buffer";
        EInvSetup: Record "PRG_E-Invoice Setup";
        GlobEInvTaxLine: Record "PRG_E-Invoice Tax Line";
        Library: Codeunit "PRG_E-Invoice Library";
        EInvMgt: Codeunit "PRG_E-Invoice Management";
        EInvSetupGot: Boolean;
        HeaderEntryNo: Integer;
        GlobUUID: Text[50];
        Text001: Label 'Incoming invoice files will be imported to NAV. Continue?';
        Text002: Label '%2 document created for the selected %1 record.';
        Text003: Label 'Documents will be created for the selected %1 record. Continue?';
        Text004: Label '%1 Record Added To Queue';
        Text008: Label 'Destination no. cannot be found for %1.';
        Text009: Label 'Incoming document created.';
        Text010: Label 'Record added to queue.';
        Text011: Label 'Invoice will be updated for selected %1 record. Continue?';
        Text012: Label 'Invoice Line Transferred from Purch. Rcpt. Line';
        Text018: Label 'Do you want to recapture CV information?';
        Text019: Label 'Update completed. Total Count : %1 - Updated Count : %2';
        Text020: Label 'There are mismatched lines in the E-Invoice!';
        Text021: Label 'There are mismatched lines in the E-Invoice, do you want to continue?';
        Text022: Label 'Process stopped.';
        XmlDoc: XmlDocument;
        CVNo: Code[20];
        CVName: Text[100];

    procedure ClearErpRecordID(var Queue: Record "PRG_E-Invoice Queue")
    var
        RecCount: Integer;
        RecID: RecordID;
    begin
        if GuiAllowed then begin
            RecCount := Queue.Count;
            if not Confirm(StrSubstNo(Text011, RecCount)) then
                exit;
        end;

        //Queue.FindSet(true, false);
        Queue.FindSet(true);
        repeat
            Queue.ERPRecordID := RecID;
            Queue."Dest. Document Status" := Queue."Dest. Document Status"::" ";
            Queue.Modify();
        until Queue.Next() = 0;
    end;

    procedure CreateDestinationDoc(var Queue: Record "PRG_E-Invoice Queue")
    var
        NoOfCreated: Integer;
        TotalCount: Integer;
    begin
        GetEInvSetup();

        if GuiAllowed then begin
            TotalCount := Queue.Count;
            if not Confirm(StrSubstNo(Text003, TotalCount)) then
                exit;
        end;

        EInvSetup.TestField("Incoming Inv. Mapping Type");

        //Queue.FindSet(true, false);
        Queue.FindSet(true);
        repeat
            CheckAndUpdateQueue_CVNo(Queue);
            case Queue."Dest. Document Type" of
                Queue."Dest. Document Type"::PurchInvoice:
                    if CreatePurchInvoice(Queue) then begin
                        NoOfCreated := NoOfCreated + 1;
                        EInvMgt.InsertQueueLog(Queue.EntryNo, QueueLog.Status::New, Text009);
                    end;
                Queue."Dest. Document Type"::SalesCrMemo:
                    if CreateSalesCrMemo(Queue) then begin
                        NoOfCreated := NoOfCreated + 1;
                    end;
                else
                    EInvMgt.InsertQueueLog(Queue.EntryNo, QueueLog.Status::New, Text009);
            end;
            Queue.Modify();
        until Queue.Next() = 0;

        if GuiAllowed then
            Message(Text002, NoOfCreated, TotalCount);
    end;

    procedure CreateEInvoiceDespatches()
    var
        DocID: Code[250];
        DocDate: Date;
        i: Integer;
        XmlNode: XmlNode;
        XmlNodeList: XmlNodeList;
    begin
        XmlDoc.SelectNodes('Invoice/DespatchDocumentReference', XmlNodeList);
        for i := 0 to XmlNodeList.Count - 1 do begin
            XmlNodeList.Get(i + 1, XmlNode);
            DocID := GetNodeValue(XmlNode, 'ID');
            Evaluate(DocDate, GetNodeValue(XmlNode, 'IssueDate'), 9);
            InsertRefBuffer(HeaderEntryNo, 0, GlobRefLine."Reference Type"::Despatch, DocID, DocDate);
        end;
    end;

    procedure CreateEInvoiceLines()
    var
        DiscountAmount: Decimal;
        DiscountBaseAmount: Decimal;
        DiscountRate: Decimal;
        i: Integer;
        j: Integer;
        TaxXmlNode: XmlNode;
        XmlNode: XmlNode;
        XmlNodeList: XmlNodeList;
        XmlTaxNodeList: XmlNodeList;
        LineNo: Integer;
    begin
        XmlDoc.SelectNodes('Invoice/InvoiceLine', XmlNodeList);
        for i := 0 to XmlNodeList.Count - 1 do begin
            XmlNodeList.Get(i + 1, XmlNode);

            DiscountAmount := Library.ToDecimal(GetNodeValue(XmlNode, 'AllowanceCharge/Amount'));
            DiscountBaseAmount := Library.ToDecimal(GetNodeValue(XmlNode, 'AllowanceCharge/BaseAmount'));
            DiscountRate := Library.ToDecimal(GetNodeValue(XmlNode, 'AllowanceCharge/MultiplierFactorNumeric')) * 100;
            if DiscountRate = 0 then
                if DiscountBaseAmount > 0 then
                    DiscountRate := (DiscountAmount / DiscountBaseAmount) * 100;

            LineNo := i + 1;
            InsertInvLine(HeaderEntryNo,
              LineNo,
              GetNodeValue(XmlNode, 'Item/SellersItemIdentification'),
              Library.ToDecimal(GetNodeValue(XmlNode, 'InvoicedQuantity')),
              Library.ToDecimal(GetNodeValue(XmlNode, 'LineExtensionAmount')),
              Library.ToDecimal(GetNodeValue(XmlNode, 'AllowanceCharge/Amount')),
              DiscountRate,
              GetNodeValue(XmlNode, 'Item/Name'),
              GetNodeValue(XmlNode, 'Item/Description'),
              Library.ToDecimal(GetNodeValue(XmlNode, 'Price/PriceAmount')),
              GetAttributeValue(XmlNode, 'InvoicedQuantity', 'unitCode'),
              GetNodeValue(XmlNode, 'Item/BuyersItemIdentification'),
              GetNodeValue(XmlNode, 'Item/ManufacturersItemIdentification'),
              GetNodeValue(XmlNode, 'Item/BrandName'),
              GetNodeValue(XmlNode, 'Item/ModelName'),
              Library.ToDecimal(GetNodeValue(XmlNode, 'ID')));

            XmlNode.SelectNodes('TaxTotal', XmlTaxNodeList);
            for j := 0 to XmlTaxNodeList.Count - 1 do begin
                XmlTaxNodeList.Get(j + 1, TaxXmlNode);
                GetTaxNodes(TaxXmlNode, false);
            end;

            XmlNode.SelectNodes('WithholdingTaxTotal', XmlTaxNodeList);
            for j := 0 to XmlTaxNodeList.Count - 1 do begin
                XmlTaxNodeList.Get(j + 1, TaxXmlNode);
                GetTaxNodes(TaxXmlNode, false);
            end;

        end;
    end;

    procedure CreateEInvoiceNotes()
    var
        i: Integer;
        XmlNode: XmlNode;
        XmlNodeList: XmlNodeList;
    begin
        XmlDoc.SelectNodes('Invoice/Note', XmlNodeList);
        for i := 0 to XmlNodeList.Count - 1 do begin
            XmlNodeList.Get(i + 1, XmlNode);
            InsertRefBuffer(HeaderEntryNo, 0, GlobRefLine."Reference Type"::Note, CopyStr(XmlNode.AsXmlElement().InnerText, 1, MaxStrLen(GlobRefLine."Reference Text")), 0D);
        end;
    end;

    procedure CreateEInvoicePaymentInfo()
    var
        DocID: Code[10];
        DocDate: Date;
        i: Integer;
        XmlNode: XmlNode;
        XmlNodeList: XmlNodeList;
    begin
        XmlDoc.SelectNodes('Invoice/PaymentMeans', XmlNodeList);
        for i := 0 to XmlNodeList.Count - 1 do begin
            XmlNodeList.Get(i + 1, XmlNode);
            DocID := GetNodeValue(XmlNode, 'PaymentMeansCode');
            Evaluate(DocDate, GetNodeValue(XmlNode, 'PaymentDueDate'), 9);
            InsertRefBuffer(HeaderEntryNo, 0, GlobRefLine."Reference Type"::PaymentMethod, DocID, DocDate);
        end;
    end;

    procedure CreateEInvoiceQueue(ProfileID: Option " ",Commercial,Basic,EArchive,EExport; InvType: Option " ",Sales,SalesCr,Purch,PurchCr,Withholding,Exception,SpecificBase,Exported; UUID: Guid; CVRegistrationNo: Text; TaxSchemeID: Code[10]; InvoiceID: Code[20]; IssueDate: Date; TaxExclusive: Decimal; TaxInclusive: Decimal)
    var
        Queue: Record "PRG_E-Invoice Queue";
    begin
        Queue.Init();
        Queue.EntryNo := FindQueueNextLogNo();
        Queue.Type := Queue.Type::Inbox;
        Queue."Queue Status" := Queue."Queue Status"::New;
        Queue.ProfileID := ProfileID;
        Queue.InvoiceType := InvType;
        Queue.UniqueIdentifier := UUID;
        Queue.CreationDateTime := CurrentDateTime;
        Queue.CreatedBy := UserId;
        Queue.InvoiceID := InvoiceID;
        Queue.IssueDate := IssueDate;
        Queue.CVRegistrationNo := CVRegistrationNo;
        Queue.IntegrationType := Queue.IntegrationType::EInvoice;
        Queue.TaxExclusiveAmount := TaxExclusive;
        Queue.TaxInclusiveAmount := TaxInclusive;
        Queue.CVNo := CVNo;
        Queue.CVName := CVName;
        SetIncomingDocDetails(Queue);

        Queue.Insert();

        EInvMgt.InsertQueueLog(Queue.EntryNo, QueueLog.Status::New, Text010);
    end;

    procedure CreateEInvoiceTaxLines()
    var
        i: Integer;
        XmlNode: XmlNode;
        XmlNodeList: XmlNodeList;
    begin
        XmlDoc.SelectNodes('Invoice/TaxTotal', XmlNodeList);
        for i := 0 to XmlNodeList.Count - 1 do begin
            XmlNodeList.Get(i + 1, XmlNode);
            GetTaxNodes(XmlNode, true);
        end;
    end;

    procedure CreateEInvoiceWithholdingTaxLines()
    var
        i: Integer;
        XmlNode: XmlNode;
        XmlNodeList: XmlNodeList;
    begin
        XmlDoc.SelectNodes('Invoice/WithholdingTaxTotal', XmlNodeList);
        for i := 0 to XmlNodeList.Count - 1 do begin
            XmlNodeList.Get(i + 1, XmlNode);
            GetTaxNodes(XmlNode, true);
        end;
    end;

    procedure CreateIncomingInvoice(): Boolean
    var
        Cust: Record Customer;
        Vend: Record Vendor;
        EInvoiceHeader: Record "PRG_E-Invoice Header";
        UniqueIdentifier: Guid;
    begin
        UniqueIdentifier := GetNodeValue_XmlDocument(XmlDoc, 'Invoice/UUID');

        EInvoiceHeader.SetRange(Type, EInvoiceHeader.Type::Inbox);
        EInvoiceHeader.SetRange(UUID, UniqueIdentifier);
        if not EInvoiceHeader.IsEmpty then
            exit;

        FindHeaderNextLogNo();
        EInvoiceHeader.Init();
        EInvoiceHeader."Entry No." := HeaderEntryNo;
        EInvoiceHeader.IntegrationType := EInvoiceHeader.IntegrationType::EInvoice;
        EInvoiceHeader.Type := EInvoiceHeader.Type::Inbox;

        case GetNodeValue_XmlDocument(XmlDoc, 'Invoice/ProfileID') of
            'TEMELFATURA':
                EInvoiceHeader.ProfileID := EInvoiceHeader.ProfileID::Basic;
            'TICARIFATURA':
                EInvoiceHeader.ProfileID := EInvoiceHeader.ProfileID::Commercial;
            'EARSIVFATURA':
                EInvoiceHeader.ProfileID := EInvoiceHeader.ProfileID::EArchive;
            'IHRACAT':
                EInvoiceHeader.ProfileID := EInvoiceHeader.ProfileID::EExport;
        end;

        EInvoiceHeader."Invoice ID" := GetNodeValue_XmlDocument(XmlDoc, 'Invoice/ID');
        EInvoiceHeader.CopyIndicator := GetNodeValue_XmlDocument(XmlDoc, 'Invoice/CopyIndicator');
        EInvoiceHeader.UUID := GetNodeValue_XmlDocument(XmlDoc, 'Invoice/UUID');
        Evaluate(EInvoiceHeader.IssueDate, GetNodeValue_XmlDocument(XmlDoc, 'Invoice/IssueDate'), 9);
        Evaluate(EInvoiceHeader.IssueTime, GetNodeValue_XmlDocument(XmlDoc, 'Invoice/IssueTime'), 9);

        case GetNodeValue_XmlDocument(XmlDoc, 'Invoice/InvoiceTypeCode') of
            'SATIS':
                EInvoiceHeader.InvoiceType := EInvoiceHeader.InvoiceType::Purch;
            'IADE':
                EInvoiceHeader.InvoiceType := EInvoiceHeader.InvoiceType::SalesCr;
            'ISTISNA':
                EInvoiceHeader.InvoiceType := EInvoiceHeader.InvoiceType::Exception;
            'TEVKIFAT':
                EInvoiceHeader.InvoiceType := EInvoiceHeader.InvoiceType::Withholding;
            'OZELMATRAH':
                EInvoiceHeader.InvoiceType := EInvoiceHeader.InvoiceType::SpecificBase;
            'IHRACKAYITLI':
                EInvoiceHeader.InvoiceType := EInvoiceHeader.InvoiceType::Exported;
        end;

        EInvoiceHeader.DocumentCurrencyCode := GetNodeValue_XmlDocument(XmlDoc, 'Invoice/DocumentCurrencyCode');
        if GetNodeValue_XmlDocument(XmlDoc, 'Invoice/PricingExchangeRate/CalculationRate') <> '' then begin
            Evaluate(EInvoiceHeader.DocumentCurrencyRate, GetNodeValue_XmlDocument(XmlDoc, 'Invoice/PricingExchangeRate/CalculationRate'));
        end;

        // ----- OrderReference -----
        EInvoiceHeader.OrderNo := CopyStr(GetNodeValue_XmlDocument(XmlDoc, 'Invoice/OrderReference/ID'), 1, MaxStrLen(EInvoiceHeader.OrderNo));
        Evaluate(EInvoiceHeader.OrderDate, GetNodeValue_XmlDocument(XmlDoc, 'Invoice/OrderReference/IssueDate'), 9);

        // ----- AccountingSupplierParty -----
        EInvoiceHeader.CustWebsiteURI := CopyStr(GetNodeValue_XmlDocument(XmlDoc, 'Invoice/AccountingSupplierParty/Party/WebsiteURI'), 1, MaxStrLen(EInvoiceHeader.CustWebsiteURI));

        EInvoiceHeader.CustRegistrationNo := GetPartyIdentificationID();
        if StrLen(EInvoiceHeader.CustRegistrationNo) = 10 then
            EInvoiceHeader.CustTaxSchemeID := 'VKN'
        else
            EInvoiceHeader.CustTaxSchemeID := 'TCKN';

        EInvoiceHeader.CustName := CopyStr(GetNodeValue_XmlDocument(XmlDoc, 'Invoice/AccountingSupplierParty/Party/PartyName/Name'), 1, MaxStrLen(EInvoiceHeader.CustName));
        EInvoiceHeader.CustStreetName := CopyStr(GetNodeValue_XmlDocument(XmlDoc, 'Invoice/AccountingSupplierParty/Party/PostalAddress/StreetName'), 1, MaxStrLen(EInvoiceHeader.CustStreetName));
        EInvoiceHeader.CustBuildingNumber := CopyStr(GetNodeValue_XmlDocument(XmlDoc, 'Invoice/AccountingSupplierParty/Party/PostalAddress/BuildingName'), 1, MaxStrLen(EInvoiceHeader.CustBuildingNumber));
        EInvoiceHeader.CustCitySubdivisionName := CopyStr(GetNodeValue_XmlDocument(XmlDoc, 'Invoice/AccountingSupplierParty/Party/PostalAddress/CitySubdivisionName'), 1, MaxStrLen(EInvoiceHeader.CustCitySubdivisionName));
        EInvoiceHeader.CustCityName := CopyStr(GetNodeValue_XmlDocument(XmlDoc, 'Invoice/AccountingSupplierParty/Party/PostalAddress/CityName'), 1, MaxStrLen(EInvoiceHeader.CustCityName));
        EInvoiceHeader.CustPostalZone := CopyStr(GetNodeValue_XmlDocument(XmlDoc, 'Invoice/AccountingSupplierParty/Party/PostalAddress/PostalZone'), 1, MaxStrLen(EInvoiceHeader.CustPostalZone));
        EInvoiceHeader.CustCountryName := CopyStr(GetNodeValue_XmlDocument(XmlDoc, 'Invoice/AccountingSupplierParty/Party/PostalAddress/Country/Name'), 1, MaxStrLen(EInvoiceHeader.CustCountryName));
        EInvoiceHeader.CustTaxOfficeName := CopyStr(GetNodeValue_XmlDocument(XmlDoc, 'Invoice/AccountingSupplierParty/Party/PartyTaxScheme/TaxScheme/Name'), 1, MaxStrLen(EInvoiceHeader.CustTaxOfficeName));
        EInvoiceHeader.CustTelephone := CopyStr(GetNodeValue_XmlDocument(XmlDoc, 'Invoice/AccountingSupplierParty/Party/Contact/Telephone'), 1, MaxStrLen(EInvoiceHeader.CustTelephone));
        EInvoiceHeader.CustTelefax := CopyStr(GetNodeValue_XmlDocument(XmlDoc, 'Invoice/AccountingSupplierParty/Party/Contact/Telefax'), 1, MaxStrLen(EInvoiceHeader.CustTelefax));
        EInvoiceHeader.CustElectronicMail := CopyStr(GetNodeValue_XmlDocument(XmlDoc, 'Invoice/AccountingSupplierParty/Party/Contact/ElectronicMail'), 1, MaxStrLen(EInvoiceHeader.CustElectronicMail));
        EInvoiceHeader.CustFirstName := CopyStr(GetNodeValue_XmlDocument(XmlDoc, 'Invoice/AccountingSupplierParty/Party/Person/FirstName'), 1, MaxStrLen(EInvoiceHeader.CustFirstName));
        EInvoiceHeader.CustFamilyName := CopyStr(GetNodeValue_XmlDocument(XmlDoc, 'Invoice/AccountingSupplierParty/Party/Person/FamilyName'), 1, MaxStrLen(EInvoiceHeader.CustFamilyName));

        // ----- PaymentTerms -----
        EInvoiceHeader.PaymentTermsNote := CopyStr(GetNodeValue_XmlDocument(XmlDoc, 'Invoice/PaymentTerms/Note'), 1, MaxStrLen(EInvoiceHeader.PaymentTermsNote));

        // ----- AllowanceCharge -----
        EInvoiceHeader.AllowanceChargeIndicator := CopyStr(GetNodeValue_XmlDocument(XmlDoc, 'Invoice/AllowanceCharge/ChargeIndicator'), 1, MaxStrLen(EInvoiceHeader.AllowanceChargeIndicator));
        EInvoiceHeader.AllowanceChargeReason := CopyStr(GetNodeValue_XmlDocument(XmlDoc, 'Invoice/AllowanceCharge/AllowanceChargeReason'), 1, MaxStrLen(EInvoiceHeader.AllowanceChargeReason));
        EInvoiceHeader.AllowanceChargeMultiplierFactr := Library.ToDecimal(GetNodeValue_XmlDocument(XmlDoc, 'Invoice/AllowanceCharge/MultiplierFactorNumeric'));
        EInvoiceHeader.AllowanceChargeAmtInvoice := Library.ToDecimal(GetNodeValue_XmlDocument(XmlDoc, 'Invoice/AllowanceCharge/Amount'));
        EInvoiceHeader.AllowanceChargeBase := Library.ToDecimal(GetNodeValue_XmlDocument(XmlDoc, 'Invoice/AllowanceCharge/BaseAmount'));

        // ----- LegalMonetaryTotal -----
        EInvoiceHeader.LineExtensionAmount := Library.ToDecimal(GetNodeValue_XmlDocument(XmlDoc, 'Invoice/LegalMonetaryTotal/LineExtensionAmount'));
        EInvoiceHeader.TaxExclusiveAmount := Library.ToDecimal(GetNodeValue_XmlDocument(XmlDoc, 'Invoice/LegalMonetaryTotal/TaxExclusiveAmount'));
        EInvoiceHeader.TaxInclusiveAmount := Library.ToDecimal(GetNodeValue_XmlDocument(XmlDoc, 'Invoice/LegalMonetaryTotal/TaxInclusiveAmount'));
        EInvoiceHeader.AllowanceChargeAmtLine := Library.ToDecimal(GetNodeValue_XmlDocument(XmlDoc, 'Invoice/LegalMonetaryTotal/AllowanceTotalAmount'));
        EInvoiceHeader.PayableAmount := Library.ToDecimal(GetNodeValue_XmlDocument(XmlDoc, 'Invoice/LegalMonetaryTotal/PayableAmount'));
        EInvoiceHeader.Insert();

        // ---- PaymentInfo -----
        CreateEInvoicePaymentInfo();
        // ---- Notes ----
        CreateEInvoiceNotes();
        // ---- Despatches ----
        CreateEInvoiceDespatches();
        // ----Lines ----
        CreateEInvoiceLines();
        // ---- Tax Lines ----
        CreateEInvoiceTaxLines();
        // ---- Withholding Tax Lines ----
        CreateEInvoiceWithholdingTaxLines();

        //002 ++
        Clear(CVNo);
        Clear(CVName);
        IF EInvoiceHeader.InvoiceType = EInvoiceHeader.InvoiceType::SalesCr then begin
            Cust.Reset();
            Cust.SetRange("VAT Registration No.", EInvoiceHeader.CustRegistrationNo);
            IF Cust.FindFirst() then begin
                CVNo := Cust."No.";
                CVName := Cust.Name;
            end;
        end else begin
            Vend.Reset();
            Vend.SetRange("VAT Registration No.", EInvoiceHeader.CustRegistrationNo);
            IF Vend.FindFirst() then begin
                CVNo := Vend."No.";
                CVName := Vend.Name;
            end;
        end;
        //002 --

        // ---- Queue ----
        CreateEInvoiceQueue(EInvoiceHeader.ProfileID,
          EInvoiceHeader.InvoiceType,
          EInvoiceHeader.UUID,
          EInvoiceHeader.CustRegistrationNo,
          EInvoiceHeader.CustTaxSchemeID,
          EInvoiceHeader."Invoice ID",
          EInvoiceHeader.IssueDate,
          EInvoiceHeader.TaxExclusiveAmount,
          EInvoiceHeader.TaxInclusiveAmount);

        GetEInvSetup();
        if EInvSetup."Incoming Inv. Mapping Type" = EInvSetup."Incoming Inv. Mapping Type"::HeaderLine then
            ApplyItemMappingInvoiceLines(HeaderEntryNo);

        exit(true);
    end;

    procedure CreateItemMapping(CVType: Option Cust,Vend; CVNo: Code[20]; MappingType: Option " ","Item Description","G/L Account Description","User Defined"; DestLineType: Option " ","G/L Account",Item; Priority: Integer; Enabled: Boolean)
    var
        ItemMapping: Record "PRG_E-Invoice Item Mapping";
        locItemMapping: Record "PRG_E-Invoice Item Mapping";
        LineNo: Integer;
    begin
        ItemMapping.SetRange("CV Type", CVType);
        ItemMapping.SetRange("CV No.", CVNo);
        ItemMapping.SetRange(ItemMapping."Mapping Type", MappingType);
        if not ItemMapping.FindFirst() then begin
            ItemMapping.Reset();
            ItemMapping.Init();
            ItemMapping."CV Type" := CVType;
            ItemMapping."CV No." := CVNo;

            locItemMapping.SetRange("CV Type", CVType);
            locItemMapping.SetRange("CV No.", CVNo);
            if locItemMapping.FindLast() then
                LineNo := locItemMapping."Line No." + 10000
            else
                LineNo := 10000;

            ItemMapping."Line No." := LineNo;
            ItemMapping."Mapping Type" := MappingType;
            ItemMapping."Dest. Line Type" := DestLineType;
            ItemMapping.Priority := Priority;
            ItemMapping.Enabled := Enabled;
            ItemMapping.Insert();
        end;
    end;

    procedure CreatePurchInvoice(var Queue: Record "PRG_E-Invoice Queue"): Boolean
    var
        EInvHeader: Record "PRG_E-Invoice Header";
        EInvLine: Record "PRG_E-Invoice Line";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        RecRef: RecordRef;
        OrderDocumentNo: Code[20];
        LineType: Enum "Sales Line Type";
        LineNo: Code[20];
        ItemMapping: Record "PRG_E-Invoice Item Mapping";
        ItemMapping2: Record "PRG_E-Invoice Item Mapping";
    begin
        if Queue."Dest. Document Status" <> Queue."Dest. Document Status"::" " then
            exit(false);

        GetEInvSetup();

        EInvHeader.SetRange(UUID, Queue.UniqueIdentifier);
        EInvHeader.FindFirst();

        EInvLine.SetRange("Header Entry No.", EInvHeader."Entry No.");
        if not EInvLine.FindSet() then
            exit(false);

        Queue.TestField(CVNo);

        OrderDocumentNo := FindDocumentOrder(CopyStr(EInvHeader.OrderNo, 1, 20), Queue.CVType);
        if OrderDocumentNo <> '' then begin
            PurchHeader.Get(PurchHeader."Document Type"::Order, OrderDocumentNo);
            Queue."Dest. Document Status" := Queue."Dest. Document Status"::Created;
            Queue."Dest. Document Type" := Queue."Dest. Document Type"::PurchOrder;
            RecRef.GetTable(PurchHeader);
            Queue.ERPRecordID := RecRef.RecordId;
            RecRef.Close();
            exit(true);
        end;

        PurchHeader.SetHideValidationDialog(true);

        PurchHeader.Init();
        PurchHeader."Document Type" := PurchHeader."Document Type"::Invoice;
        PurchHeader."No." := '';
        PurchHeader.Insert(true);
        PurchHeader.Validate("Buy-from Vendor No.", Queue.CVNo);

        case EInvSetup."Inc. Doc. Posting Date Type" of
            EInvSetup."Inc. Doc. Posting Date Type"::"Creation Date":
                PurchHeader.Validate("Posting Date", WorkDate());
            EInvSetup."Inc. Doc. Posting Date Type"::"Incoming Document Date":
                PurchHeader.Validate("Posting Date", Queue.IssueDate);
        end;

        PurchHeader.Validate("Document Date", Queue.IssueDate);
        PurchHeader."Vendor Invoice No." := Queue.InvoiceID;
        PurchHeader.Validate("Currency Code", GetCurrCode(EInvHeader.DocumentCurrencyCode));
        if PurchHeader."Currency Code" <> '' then
            PurchHeader.Validate("Currency Factor", ROUND(1 / EInvHeader.DocumentCurrencyRate, 0.00001));
        PurchHeader.Modify(true);

        Queue."Dest. Document Status" := Queue."Dest. Document Status"::Created;

        RecRef.GetTable(PurchHeader);
        Queue.ERPRecordID := RecRef.RecordId;
        RecRef.Close();

        if EInvSetup."Incoming Inv. Mapping Type" = EInvSetup."Incoming Inv. Mapping Type"::Header then
            exit(true);

        if CreatePurchLinesFromReceipt(EInvHeader."Entry No.", PurchHeader) then begin
            EInvMgt.InsertQueueLog(Queue.EntryNo, QueueLog.Status::New, Text012);
            exit(true);
        end;

        repeat
            Clear(LineNo);
            PurchLine.Init();
            PurchLine."Document Type" := PurchHeader."Document Type";
            PurchLine."Document No." := PurchHeader."No.";
            PurchLine."Line No." := PurchLine."Line No." + 10000;

            if (EInvLine."No." <> '') and (EInvLine.Type <> EInvLine.Type::" ") then begin
                case EInvLine.Type of
                    EInvLine.Type::Item:
                        PurchLine.Validate(Type, PurchLine.Type::Item);
                    EInvLine.Type::"G/L Account":
                        PurchLine.Validate(Type, PurchLine.Type::"G/L Account");
                    EInvLine.Type::"Charge (Item)":
                        PurchLine.Validate(Type, PurchLine.Type::"Charge (Item)");
                end;
                PurchLine.Validate("No.", EInvLine."No.");
                PurchLine.Validate(Quantity, EInvLine.Quantity);
                PurchLine.Validate("Direct Unit Cost", EInvLine."Unit Price");
                PurchLine.Validate("Line Discount Amount", Round(EInvLine."Allowance Charge Amount", 0.0001));
                PurchLine.Insert(true);

            end else

                if FindMappingInvoiceLines(EInvLine, Queue) then begin
                    case EInvLine.Type of
                        EInvLine.Type::Item:
                            PurchLine.Validate(Type, PurchLine.Type::Item);
                        EInvLine.Type::"G/L Account":
                            PurchLine.Validate(Type, PurchLine.Type::"G/L Account");
                        EInvLine.Type::"Charge (Item)":
                            PurchLine.Validate(Type, PurchLine.Type::"Charge (Item)");
                    end;
                    PurchLine.Validate("No.", EInvLine."No.");
                    PurchLine.Validate(Quantity, EInvLine.Quantity);
                    PurchLine.Validate("Direct Unit Cost", EInvLine."Unit Price");
                    PurchLine.Validate("Line Discount Amount", Round(EInvLine."Allowance Charge Amount", 0.0001));
                    PurchLine.Insert(true);
                end else begin
                    case EInvSetup."Document Mapping Control Type" of
                        EInvSetup."Document Mapping Control Type"::"Not Allow":
                            Error(Text020);
                        EInvSetup."Document Mapping Control Type"::Warning:
                            if not Confirm(Text021) then
                                Error(Text022);
                    end;

                end;

            if (EInvSetup."Mapping Adding Type" <> EInvSetup."Mapping Adding Type"::"Not Add") and (not EInvLine."Success Mapping") then begin
                ItemMapping2.SetRange("CV Type", Queue.CVType);
                ItemMapping2.SetRange("Incoming Description Text", EInvLine."Item Name");
                ItemMapping2.SetRange("Dest. Line Type", EInvLine.Type);
                ItemMapping2.SetRange("Dest. Line No.", EInvLine."No.");
                if not ItemMapping2.FindFirst() and (EInvLine."No." <> '') then begin
                    ItemMapping2.Reset();
                    ItemMapping2.SetRange("CV Type", Queue.CVType);
                    if EInvSetup."Mapping Adding Type" = EInvSetup."Mapping Adding Type"::"Related CV" then
                        ItemMapping2.SetRange("CV No.", Queue.CVNo)
                    else
                        ItemMapping2.SetRange("CV No.", '');
                    if ItemMapping2.FindLast() then;

                    ItemMapping.Init();
                    ItemMapping.Validate("CV Type", Queue.CVType);
                    if EInvSetup."Mapping Adding Type" = EInvSetup."Mapping Adding Type"::"Related CV" then
                        ItemMapping.Validate("CV No.", Queue.CVNo)
                    else
                        ItemMapping.Validate("CV No.", '');
                    ItemMapping.Validate("Line No.", ItemMapping2."Line No." + 10000);
                    ItemMapping.Validate("Mapping Type", ItemMapping."Mapping Type"::"User Defined");
                    ItemMapping.Validate("Incoming Description Text", EInvLine."Item Name");
                    ItemMapping.Validate("Dest. Line Type", EInvLine.Type);
                    ItemMapping.Validate("Dest. Line No.", EInvLine."No.");
                    ItemMapping.Validate(Priority, 1);
                    ItemMapping.Validate(Enabled, true);
                    if ItemMapping.Insert(true) then;
                end;
            end;

        until EInvLine.Next() = 0;

        exit(true);
    end;

    procedure CreatePurchLinesFromReceipt(HeaderEntryNo: Integer; var
                                                                      PurchHeader: Record "Purchase Header"): Boolean
    var
        EInvRefBuffer: Record "PRG_E-Invoice Reference Buffer";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
        Result: Boolean;
    begin
        EInvRefBuffer.SetRange("Header Entry No.", HeaderEntryNo);
        EInvRefBuffer.SetRange("Reference Type", EInvRefBuffer."Reference Type"::Despatch);
        if EInvRefBuffer.FindSet() then begin
            repeat
                PurchHeader.TestField(Status, PurchHeader.Status::Open);
                PurchRcptHeader.SetRange("Pay-to Vendor No.", PurchHeader."Pay-to Vendor No.");
                PurchRcptHeader.SetRange("Vendor Shipment No.", EInvRefBuffer."Reference Text");
                if PurchRcptHeader.FindSet() then begin

                    PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
                    PurchRcptLine.SetRange("Currency Code", PurchHeader."Currency Code");
                    PurchRcptLine.SetRange("Pay-to Vendor No.", PurchHeader."Pay-to Vendor No.");
                    PurchRcptLine.SetRange("Buy-from Vendor No.", PurchHeader."Buy-from Vendor No.");
                    PurchRcptLine.SetFilter("Qty. Rcd. Not Invoiced", '<>0');
                    if PurchRcptLine.FindSet() then
                        repeat
                            PurchGetReceipt.SetPurchHeader(PurchHeader);
                            PurchGetReceipt.CreateInvLines(PurchRcptLine);
                        until PurchRcptLine.Next() = 0;
                    Result := true;
                end;
            until EInvRefBuffer.Next() = 0;
        end;
        exit(Result);
    end;

    procedure DisplayDocument(var Queue: Record "PRG_E-Invoice Queue")
    var
        RecRef: RecordRef;
        VarRec: Variant;
    begin
        if (Queue."Dest. Document Type" <> Queue."Dest. Document Type"::" ") then
            case Queue."Dest. Document Type" of

                Queue."Dest. Document Type"::PurchInvoice:

                    begin
                        if (Queue."Dest. Document Status" = Queue."Dest. Document Status"::Created) then
                            if RecRef.Get(Queue.ERPRecordID) then begin
                                VarRec := RecRef;
                                PAGE.RunModal(PAGE::"Purchase Invoice", VarRec);
                            end
                            else
                                if (Queue."Dest. Document Status" = Queue."Dest. Document Status"::Posted) then
                                    if RecRef.Get(Queue.ERPRecordID) then begin
                                        VarRec := RecRef;
                                        PAGE.RunModal(PAGE::"Posted Purchase Invoice", VarRec);
                                    end;
                    end;

                Queue."Dest. Document Type"::SalesCrMemo:

                    begin
                        if (Queue."Dest. Document Status" = Queue."Dest. Document Status"::Created) then
                            if RecRef.Get(Queue.ERPRecordID) then begin
                                VarRec := RecRef;
                                PAGE.RunModal(PAGE::"Sales Credit Memo", VarRec);
                            end
                            else
                                if (Queue."Dest. Document Status" = Queue."Dest. Document Status"::Posted) then
                                    if RecRef.Get(Queue.ERPRecordID) then begin
                                        VarRec := RecRef;
                                        PAGE.RunModal(PAGE::"Posted Sales Credit Memo", VarRec);
                                    end;
                    end;
                Queue."Dest. Document Type"::PurchOrder:

                    begin
                        if (Queue."Dest. Document Status" = Queue."Dest. Document Status"::Created) then
                            if RecRef.Get(Queue.ERPRecordID) then begin
                                VarRec := RecRef;
                                PAGE.RunModal(PAGE::"Purchase Order", VarRec);
                            end
                    end;
                Queue."Dest. Document Type"::SalesReturnOrder:

                    begin
                        if (Queue."Dest. Document Status" = Queue."Dest. Document Status"::Created) then
                            if RecRef.Get(Queue.ERPRecordID) then begin
                                VarRec := RecRef;
                                PAGE.RunModal(PAGE::"Sales Return Order", VarRec);
                            end
                    end;

            end;
    end;

    procedure ExecuteWaitingQueue()
    var
        ImportBuffer: Record "PRG_E-Invoice Incoming Buffer";
        ImportBuffer2: Record "PRG_E-Invoice Incoming Buffer";
        Convert: Codeunit "Base64 Convert";
        TempBlob: Codeunit "Temp Blob";
        TempBlob2: Codeunit "Temp Blob";
        XmlDomMgt: Codeunit "XML DOM Management";
        IStr: InStream;
        IStr2: InStream;
        Counter: Integer;
        OStr: OutStream;
        FileText: Text;
        IntSetup: Record "PRG_E-Invoice Integrator Setup";
    begin
        IntSetup.get();
        if GuiAllowed then
            if not Confirm(Text001) then
                exit;

        GetEInvSetup();

        IF Not ImportBuffer.FindSet() then
            exit;

        repeat

            ImportBuffer.CalcFields("Invoice Value");

            if ImportBuffer."Invoice Value".HasValue then begin

                Counter := Counter + 1;

                clear(TempBlob);
                Clear(TempBlob2);
                Clear(IStr);
                Clear(OStr);
                Clear(IStr2);
                Clear(FileText);
                Clear(XmlDoc);
                Clear(FileText);
                Clear(XmlDomMgt);

                TempBlob.FromRecord(ImportBuffer, ImportBuffer.FieldNo("Invoice Value"));
                TempBlob.CreateInStream(IStr, TextEncoding::UTF8);
                TempBlob2.CreateOutStream(OStr, TextEncoding::UTF8);
                IStr.Read(FileText);
                if not (IntSetup."E-Invoice Integrator" IN [IntSetup."E-Invoice Integrator"::Efinans, IntSetup."E-Invoice Integrator"::Idea]) then begin
                    Convert.FromBase64(FileText, OStr);
                    Tempblob2.CreateInStream(IStr2, TextEncoding::UTF8);
                    XmlDocument.ReadFrom(IStr2, XmlDoc);
                end else begin
                    XmlDocument.ReadFrom(FileText, XmlDoc);
                end;

                Clear(FileText);
                XmlDoc.WriteTo(FileText);
                FileText := FileText.Replace('<?xml version="1.0" encoding="utf-16"?>', '<?xml version="1.0" encoding="utf-8"?>');
                FileText := XmlDomMgt.RemoveNamespaces(FileText);
                Clear(XmlDoc);
                XmlDocument.ReadFrom(FileText, XmlDoc);

                if CreateIncomingInvoice() then begin
                    ImportBuffer2.Get(ImportBuffer."Entry No.");
                    ImportBuffer2.Delete();
                end;

                Commit();

            end;

        until ImportBuffer.Next() = 0;

        IF (GuiAllowed) AND (Counter <> 0) then
            Message(StrSubstNo(Text004, Counter));
    end;

    procedure ApplyItemMappingInvoiceLines(HeaderEntryNo: Integer)
    var
        Queue: Record "PRG_E-Invoice Queue";
        EInvHeader: Record "PRG_E-Invoice Header";
        EInvLine: Record "PRG_E-Invoice Line";
    begin
        EInvHeader.Get(HeaderEntryNo);

        Queue.SetRange(Type, Queue.Type::Inbox);
        Queue.SetRange(UniqueIdentifier, EInvHeader.UUID);
        if not Queue.FindFirst() then
            exit;

        EInvLine.SetRange("Header Entry No.", HeaderEntryNo);
        EInvLine.SetFilter("No.", '%1', '');
        if EInvLine.FindSet() then
            repeat
                FindMappingInvoiceLines(EInvLine, Queue);
            until EInvLine.Next() = 0;
    end;

    procedure FindMappingInvoiceLines(var EInvLine: Record "PRG_E-Invoice Line"; var Queue: Record "PRG_E-Invoice Queue"): Boolean
    var
        GLAcc: Record "G/L Account";
        Item: Record Item;
        EInvItemMapping: Record "PRG_E-Invoice Item Mapping";
    begin
        EInvItemMapping.SetCurrentKey("CV Type", "CV No.", Priority);
        case Queue.CVType of
            Queue.CVType::Vend:
                EInvItemMapping.SetRange("CV Type", EInvItemMapping."CV Type"::Vendor);
            Queue.CVType::Cust:
                EInvItemMapping.SetRange("CV Type", EInvItemMapping."CV Type"::Customer);
        end;
        EInvItemMapping.SetRange("CV No.", Queue.CVNo);
        EInvItemMapping.SetRange(Enabled, true);
        if EInvItemMapping.FindSet() then
            repeat
                case EInvItemMapping."Mapping Type" of

                    EInvItemMapping."Mapping Type"::"Item Description":
                        begin
                            Item.SetCurrentKey(Description);
                            Item.SetFilter(Description, '@%1', CopyStr(EInvLine."Item Name", 1, MaxStrLen(Item.Description)));
                            if Item.FindFirst() then begin
                                EInvLine.Type := EInvLine.Type::Item;
                                EInvLine."No." := Item."No.";
                                EInvLine."Success Mapping" := true;
                                EInvLine.Modify();
                                exit(true);
                            end;
                        end;

                    EInvItemMapping."Mapping Type"::"G/L Account Description":
                        begin
                            GLAcc.SetCurrentKey(Name);
                            GLAcc.SetRange(GLAcc."Direct Posting", true);
                            GLAcc.SetRange(Name, CopyStr(EInvLine."Item Name", 1, MaxStrLen(GLAcc.Name)));
                            if GLAcc.FindFirst() then begin
                                EInvLine.Type := EInvLine.Type::"G/L Account";
                                EInvLine."No." := GLAcc."No.";
                                EInvLine."Success Mapping" := true;
                                EInvLine.Modify();
                                exit(true);
                            end;
                        end;

                    EInvItemMapping."Mapping Type"::"User Defined":
                        begin
                            if NormalizeWhitespace(UpperCase(EInvItemMapping."Incoming Description Text")) = NormalizeWhitespace(UpperCase(EInvLine."Item Name")) then begin
                                case EInvItemMapping."Dest. Line Type" of
                                    EInvItemMapping."Dest. Line Type"::"G/L Account":
                                        EInvLine.Type := EInvLine.Type::"G/L Account";
                                    EInvItemMapping."Dest. Line Type"::Item:
                                        EInvLine.Type := EInvLine.Type::Item;
                                    EInvItemMapping."Dest. Line Type"::"Charge (Item)":
                                        EInvLine.Type := EInvLine.Type::"Charge (Item)";
                                end;
                                EInvLine."No." := EInvItemMapping."Dest. Line No.";
                                EInvLine."Success Mapping" := true;
                                EInvLine.Modify();
                                exit(true);
                            end else
                                if StrPos(NormalizeWhitespace(UpperCase(EInvLine."Item Name")), NormalizeWhitespace(EInvItemMapping."Incoming Description Text")) <> 0 then begin
                                    case EInvItemMapping."Dest. Line Type" of
                                        EInvItemMapping."Dest. Line Type"::"G/L Account":
                                            EInvLine.Type := EInvLine.Type::"G/L Account";
                                        EInvItemMapping."Dest. Line Type"::Item:
                                            EInvLine.Type := EInvLine.Type::Item;
                                        EInvItemMapping."Dest. Line Type"::"Charge (Item)":
                                            EInvLine.Type := EInvLine.Type::"Charge (Item)";
                                    end;
                                    EInvLine."No." := EInvItemMapping."Dest. Line No.";
                                    EInvLine."Success Mapping" := true;
                                    EInvLine.Modify();
                                    exit(true);
                                end;
                        end;
                    EInvItemMapping."Mapping Type"::"Fixed Item":
                        begin
                            EInvLine.Type := EInvLine.Type::Item;
                            EInvLine."No." := EInvItemMapping."Dest. Line No.";
                            EInvLine."Success Mapping" := true;
                            EInvLine.Modify();
                            exit(true);
                        end;
                    EInvItemMapping."Mapping Type"::"Fixed G/L":
                        begin
                            EInvLine.Type := EInvLine.Type::"G/L Account";
                            EInvLine."No." := EInvItemMapping."Dest. Line No.";
                            EInvLine."Success Mapping" := true;
                            EInvLine.Modify();
                            exit(true);
                        end;
                end;
            until EInvItemMapping.Next() = 0;

        EInvItemMapping.SetCurrentKey(Priority);
        EInvItemMapping.SetRange("CV No.");
        if EInvItemMapping.FindSet() then
            repeat
                case EInvItemMapping."Mapping Type" of
                    EInvItemMapping."Mapping Type"::"Item Description":
                        begin
                            Item.SetCurrentKey(Description);
                            Item.SetFilter(Description, '@%1', CopyStr(EInvLine."Item Name", 1, MaxStrLen(Item.Description)));
                            if Item.FindFirst() then begin
                                EInvLine.Type := EInvLine.Type::Item;
                                EInvLine."No." := Item."No.";
                                EInvLine."Success Mapping" := true;
                                EInvLine.Modify();
                                exit(true);
                            end;
                        end;

                    EInvItemMapping."Mapping Type"::"G/L Account Description":
                        begin
                            GLAcc.SetCurrentKey(Name);
                            GLAcc.SetRange(GLAcc."Direct Posting", true);
                            GLAcc.SetRange(Name, CopyStr(EInvLine."Item Name", 1, MaxStrLen(GLAcc.Name)));
                            if GLAcc.FindFirst() then begin
                                EInvLine.Type := EInvLine.Type::"G/L Account";
                                EInvLine."No." := GLAcc."No.";
                                EInvLine."Success Mapping" := true;
                                EInvLine.Modify();
                                exit(true);
                            end;
                        end;

                    EInvItemMapping."Mapping Type"::"User Defined":
                        begin
                            if NormalizeWhitespace(UpperCase(EInvItemMapping."Incoming Description Text")) = NormalizeWhitespace(UpperCase(EInvLine."Item Name")) then begin
                                case EInvItemMapping."Dest. Line Type" of
                                    EInvItemMapping."Dest. Line Type"::"G/L Account":
                                        EInvLine.Type := EInvLine.Type::"G/L Account";
                                    EInvItemMapping."Dest. Line Type"::Item:
                                        EInvLine.Type := EInvLine.Type::Item;
                                    EInvItemMapping."Dest. Line Type"::"Charge (Item)":
                                        EInvLine.Type := EInvLine.Type::"Charge (Item)";
                                end;
                                EInvLine."No." := EInvItemMapping."Dest. Line No.";
                                EInvLine."Success Mapping" := true;
                                EInvLine.Modify();
                                exit(true);
                            end else
                                if StrPos(NormalizeWhitespace(UpperCase(EInvLine."Item Name")), NormalizeWhitespace(UpperCase(EInvItemMapping."Incoming Description Text"))) <> 0 then begin
                                    case EInvItemMapping."Dest. Line Type" of
                                        EInvItemMapping."Dest. Line Type"::"G/L Account":
                                            EInvLine.Type := EInvLine.Type::"G/L Account";
                                        EInvItemMapping."Dest. Line Type"::Item:
                                            EInvLine.Type := EInvLine.Type::Item;
                                        EInvItemMapping."Dest. Line Type"::"Charge (Item)":
                                            EInvLine.Type := EInvLine.Type::"Charge (Item)";
                                    end;
                                    EInvLine."No." := EInvItemMapping."Dest. Line No.";
                                    EInvLine."Success Mapping" := true;
                                    EInvLine.Modify();
                                    exit(true);
                                end;
                        end;
                end;
            until EInvItemMapping.Next() = 0;
    end;

    procedure NormalizeWhitespace(InputText: Text): Text
    var
        CleanedText: Text;
        CharIndex: Integer;
        PrevCharIsSpace: Boolean;
    begin
        CleanedText := '';
        PrevCharIsSpace := false;

        for CharIndex := 1 to StrLen(InputText) do begin
            if CopyStr(InputText, CharIndex, 1) = ' ' then begin
                if not PrevCharIsSpace then
                    CleanedText += ' ';
                PrevCharIsSpace := true;
            end else begin
                CleanedText += CopyStr(InputText, CharIndex, 1);
                PrevCharIsSpace := false;
            end;
        end;

        CleanedText := StrSubstNo(InputText, 'ı', 'i');
        exit(CleanedText);
    end;

    procedure FindCrossRef(CVType: Option;
        CVNo: Code[20];
        SellersItemNo: Code[20]): Text[30]
    var
        ItemCrossReference: Record "Item Reference";
        Queue: Record "PRG_E-Invoice Queue";
    begin
        case CVType of
            Queue.CVType::Cust:
                ItemCrossReference.SetRange("Reference Type", ItemCrossReference."Reference Type"::Customer);
            Queue.CVType::Vend:
                ItemCrossReference.SetRange("Reference Type", ItemCrossReference."Reference Type"::Vendor);
        end;
        ItemCrossReference.SetRange("Reference Type No.", CVNo);
        ItemCrossReference.SetRange("Reference No.", SellersItemNo);
        if ItemCrossReference.FindFirst() then
            exit(ItemCrossReference."Item No.")
    end;

    procedure FindDocumentOrder(OrderNo: Code[35]; CVType: Option " ",Cust,Vend): Code[20]
    var
        PurchHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
    begin
        case CVType of
            CVType::Vend:
                begin
                    if PurchHeader.Get(PurchHeader."Document Type"::Order, OrderNo) then
                        exit(PurchHeader."No.")
                    else
                        exit('');
                end;
            CVType::Cust:
                begin
                    if SalesHeader.Get(SalesHeader."Document Type"::"Return Order", OrderNo) then
                        exit(SalesHeader."No.")
                    else
                        exit('');
                end;
        end;
    end;

    procedure FindHeaderNextLogNo(): Integer
    var
        EInvHeader: Record "PRG_E-Invoice Header";
    begin
        EInvHeader.LockTable();
        if EInvHeader.FindLast() then
            HeaderEntryNo := EInvHeader."Entry No." + 1
        else
            HeaderEntryNo := 1;
        exit(HeaderEntryNo);
    end;

    procedure FindMapping(var EInvLine: Record "PRG_E-Invoice Line"; CVType: Option; CVNo: Code[20]; var DestLineType: Enum "Sales Line Type"; var DestLineNo: Code[20]): Boolean
    var
        GLAcc: Record "G/L Account";
        Item: Record Item;
        EInvItemMapping: Record "PRG_E-Invoice Item Mapping";
        Queue: Record "PRG_E-Invoice Queue";
        TempNo: Code[20];
    begin
        DestLineType := DestLineType::" ";
        DestLineNo := '';

        case true of
            EInvLine."Buyers Item Identification" <> '':
                if Item.Get(EInvLine."Buyers Item Identification") then begin
                    DestLineType := DestLineType::Item;
                    DestLineNo := EInvLine."Buyers Item Identification";
                end;

            EInvLine."Sellers Item Identification" <> '':
                begin
                    TempNo := FindCrossRef(CVType, CVNo, EInvLine."Sellers Item Identification");
                    if TempNo <> '' then begin
                        DestLineType := DestLineType::Item;
                        DestLineNo := TempNo;
                    end;
                end;
        end;

        if (DestLineNo <> '') and (DestLineType <> DestLineType::" ") then
            exit(true);

        EInvItemMapping.SetCurrentKey("CV Type", "CV No.", Priority);
        case CVType of
            Queue.CVType::Vend:
                EInvItemMapping.SetRange("CV Type", EInvItemMapping."CV Type"::Vendor);
            Queue.CVType::Cust:
                EInvItemMapping.SetRange("CV Type", EInvItemMapping."CV Type"::Customer);
        end;

        EInvItemMapping.SetRange("CV No.", CVNo);
        EInvItemMapping.SetRange(Enabled, true);
        if EInvItemMapping.FindSet() then
            repeat
                case EInvItemMapping."Mapping Type" of

                    EInvItemMapping."Mapping Type"::"Item Description":
                        begin
                            Item.SetCurrentKey(Description);
                            Item.SetFilter(Description, '@%1', CopyStr(EInvLine."Item Name", 1, MaxStrLen(Item.Description)));

                            if Item.FindFirst() then begin
                                DestLineType := DestLineType::Item;
                                DestLineNo := Item."No.";
                                exit(true);
                            end else begin
                                EInvMgt.InsertQueueLog(Queue.EntryNo, QueueLog.Status::Failed, StrSubstNo(Text008, EInvLine."Item Name"));
                            end;
                        end;

                    EInvItemMapping."Mapping Type"::"G/L Account Description":
                        begin
                            GLAcc.SetCurrentKey(Name);
                            GLAcc.SetRange(GLAcc."Direct Posting", true);
                            GLAcc.SetRange(Name, CopyStr(EInvLine."Item Name", 1, MaxStrLen(GLAcc.Name)));
                            if GLAcc.FindFirst() then begin
                                DestLineType := DestLineType::"G/L Account";
                                DestLineNo := GLAcc."No.";
                                exit(true);
                            end else begin
                                EInvMgt.InsertQueueLog(Queue.EntryNo, QueueLog.Status::Failed, StrSubstNo(Text008, EInvLine."Item Name"));
                            end;
                        end;

                    EInvItemMapping."Mapping Type"::"User Defined":
                        begin
                            if UpperCase(EInvItemMapping."Incoming Description Text") = UpperCase(EInvLine."Item Name") then begin
                                case EInvItemMapping."Dest. Line Type" of
                                    EInvItemMapping."Dest. Line Type"::"G/L Account":
                                        DestLineType := DestLineType::"G/L Account";
                                    EInvItemMapping."Dest. Line Type"::Item:
                                        DestLineType := DestLineType::Item;
                                end;
                                DestLineNo := EInvItemMapping."Dest. Line No.";
                                exit(true);
                            end else
                                if StrPos(UpperCase(EInvLine."Item Name"), EInvItemMapping."Incoming Description Text") <> 0 then begin
                                    case EInvItemMapping."Dest. Line Type" of
                                        EInvItemMapping."Dest. Line Type"::"G/L Account":
                                            DestLineType := DestLineType::"G/L Account";
                                        EInvItemMapping."Dest. Line Type"::Item:
                                            DestLineType := DestLineType::Item;
                                    end;
                                    DestLineNo := EInvItemMapping."Dest. Line No.";
                                    exit(true);
                                end else begin
                                    EInvMgt.InsertQueueLog(Queue.EntryNo, QueueLog.Status::Failed, StrSubstNo(Text008, EInvLine."Item Name"));
                                end;
                        end;

                end;
            until EInvItemMapping.Next() = 0;
    end;

    procedure FindQueueNextLogNo(): Integer
    var
        Queue: Record "PRG_E-Invoice Queue";
        QueueEntryNo: Integer;
    begin
        Queue.LockTable();
        if Queue.FindLast() then
            QueueEntryNo := Queue.EntryNo + 1
        else
            QueueEntryNo := 1;
        exit(QueueEntryNo);
    end;

    procedure FormatDate(pDate: Date): Text[30]
    begin
        exit(Format(pDate, 0, '<Year4>-<Month,2>-<Day,2>'))
    end;

    procedure FormatTime(pTime: Time): Text[30]
    begin
        exit(Format(pTime, 0, '<Hours24,2><Filler Character,0>:<Minutes,2>:<Seconds,2>'))
    end;

    procedure GetCurrCode(CurrCode: Code[10]) NewCurrCode: Code[10]
    var
        CodeMapping: Record "PRG_E-Invoice Code Mapping";
    begin
        CodeMapping.SetRange(CodeMapping.Type, CodeMapping.Type::Currency);
        CodeMapping.SetRange(CodeMapping."Destination Code", CurrCode);
        if CodeMapping.FindFirst() then
            exit(CodeMapping."Source Code");
    end;

    procedure GetEInvSetup()
    begin
        if not EInvSetupGot then begin
            if EInvSetup.Get() then;
            EInvSetupGot := true;
        end;
    end;

    procedure GetPartyIdentificationID(): Text[20]
    var
        i: Integer;
        PartyIdentificationID: Text;
        SchemeID: Text;
        XmlNode: XmlNode;
        XmlNodeList: XmlNodeList;
    begin
        XmlDoc.SelectNodes('Invoice/AccountingSupplierParty/Party/PartyIdentification', XmlNodeList);
        for i := 0 to XmlNodeList.Count - 1 do begin
            XmlNodeList.Get(i + 1, XmlNode);
            PartyIdentificationID := GetNodeValue(XmlNode, 'ID');
            SchemeID := GetAttributeValue(XmlNode, 'ID', 'schemeID');
            if SchemeID in ['VKN', 'TCKN'] then
                exit(PartyIdentificationID);
        end;
    end;

    procedure GetTaxNodes(var XmlNode: XmlNode; Header: Boolean)
    var
        HeaderTaxTotal: Decimal;
        i: Integer;
        j: Integer;
        HeaderTaxTotalSchemeID: Text;
        XMLNodeSubTotal: XmlNodeList;
    begin
        if Header then
            GlobEInvTaxLine.Type := GlobEInvTaxLine.Type::Header
        else
            GlobEInvTaxLine.Type := GlobEInvTaxLine.Type::Line;

        HeaderTaxTotal := Library.ToDecimal(GetNodeValue(XmlNode, 'TaxAmount'));
        HeaderTaxTotalSchemeID := GetAttributeValue(XmlNode, 'TaxAmount', 'currencyID');

        XmlNode.SelectNodes('TaxSubtotal', XMLNodeSubTotal);

        for j := 0 to XMLNodeSubTotal.Count - 1 do begin
            XMLNodeSubTotal.Get(i + 1, XmlNode);

            InsertTaxLines(HeaderEntryNo,
              GlobEInvTaxLine.Type,
              GetNodeValue(XmlNode, 'TaxCategory/TaxScheme/TaxTypeCode'),
              Library.ToDecimal(GetNodeValue(XmlNode, 'Percent')),
              Library.ToDecimal(GetNodeValue(XmlNode, 'TaxAmount')),
              Library.ToDecimal(GetNodeValue(XmlNode, 'TaxableAmount')),
              Library.ToDecimal(GetNodeValue(XmlNode, 'TaxableAmount')) + Library.ToDecimal(GetNodeValue(XmlNode, 'TaxAmount')),
              GetNodeValue(XmlNode, 'TaxCategory/TaxExemptionReason'),
              GetNodeValue(XmlNode, 'TaxCategory/TaxExemptionReasonCode'),
              Library.ToDecimal(GetNodeValue(XmlNode, 'CalculationSequenceNumeric')));
        end;
    end;

    procedure GetUOMCode(UOMCode: Code[10]): Code[10]
    var
        CodeMapping: Record "PRG_E-Invoice Code Mapping";
    begin
        if UOMCode <> '' then begin
            CodeMapping.SetRange(Type, CodeMapping.Type::UOM);
            CodeMapping.SetRange("Destination Code", UOMCode);
            CodeMapping.SetFilter("Source Code", '<>%1', '');
            if CodeMapping.FindFirst() then begin
                CodeMapping.TestField("Source Code");
                exit(CodeMapping."Source Code");
            end;
        end else begin
            GetEInvSetup();
            CodeMapping.Get(CodeMapping.Type::UOM, '');
            CodeMapping.TestField("Source Code");
            exit(CodeMapping."Source Code");
        end;
    end;

    procedure InsertInvLine(HeaderEntryNo: Integer; LineNo: Integer; ItemNo: Text; Qty: Decimal; LineExtAmt: Decimal; ChargeAmt: Decimal; DiscountRate: Decimal; ItemName: Text; Desc: Text; UnitPrice: Decimal; UOMCode: Code[20]; CrossRefNo: Text; BarcodeNo: Text; BrandName: Text; ModelName: Text; IncomingDocLineNo: Integer)
    var
        LocEInvHeader: Record "PRG_E-Invoice Header";
    begin
        GlobEInvLine.Init();
        GlobEInvLine."Header Entry No." := HeaderEntryNo;
        GlobEInvLine."Line No." := LineNo;
        GlobEInvLine."Sellers Item Identification" := CopyStr(ItemNo, 1, MaxStrLen(GlobEInvLine."Sellers Item Identification"));
        GlobEInvLine.Quantity := Round(Qty, 0.00001);
        GlobEInvLine."Line Extension Amount" := Abs(Round(LineExtAmt, 0.01));
        GlobEInvLine."Allowance Charge Indicator" := 'false';
        GlobEInvLine."Allowance Charge Amount" := Abs(Round(ChargeAmt, 0.01));
        GlobEInvLine."Allowance Charge Rate" := DiscountRate;
        GlobEInvLine."Item Name" := CopyStr(ItemName, 1, MaxStrLen(GlobEInvLine."Item Name"));
        GlobEInvLine.Description := CopyStr(Desc, 1, MaxStrLen(GlobEInvLine.Description));
        GlobEInvLine."Unit Price" := Abs(Round(UnitPrice, 0.00001));
        GlobEInvLine."Brand Name" := CopyStr(BrandName, 1, MaxStrLen(GlobEInvLine."Brand Name"));
        GlobEInvLine."Model Name" := CopyStr(ModelName, 1, MaxStrLen(GlobEInvLine."Model Name"));
        GlobEInvLine."Buyers Item Identification" := CopyStr(CrossRefNo, 1, MaxStrLen(GlobEInvLine."Buyers Item Identification"));
        GlobEInvLine."Manu. Item Identification" := CopyStr(BarcodeNo, 1, MaxStrLen(GlobEInvLine."Manu. Item Identification"));
        GlobEInvLine."Unit Of Measure Code" := GetUOMCode(UOMCode);
        GlobEInvLine."Incoming Document Line No." := IncomingDocLineNo;
        if LocEInvHeader.Get(HeaderEntryNo) then
            GlobEInvLine.UUID := LocEInvHeader.UUID;
        GlobEInvLine.Insert();
    end;

    procedure InsertTaxLines(HeaderEntryNo: Integer; Type: Option " ",Header,Line; TaxTypeCode: Code[10]; TaxPercent: Decimal; TaxAmount: Decimal; TaxExclusiveAmount: Decimal; TaxInclusiveAmount: Decimal; TaxExemptionReasonDesc: Text; TaxExemptionReasonCode: Code[10]; CalculationSequenceNumeric: Integer)
    var
        EInvTaxLine: Record "PRG_E-Invoice Tax Line";
        locEInvTaxLine: Record "PRG_E-Invoice Tax Line";
        TaxCode: Record "PRG_E-Invoice Tax Type Code";
        HeaderLineNo: Integer;
        LineNo: Integer;
    begin
        if TaxTypeCode = '' then
            TaxTypeCode := '0015';

        TaxCode.Get(TaxTypeCode);

        locEInvTaxLine.Reset();
        locEInvTaxLine.SetRange("Header Entry No.", HeaderEntryNo);
        locEInvTaxLine.SetRange(Type, Type);
        if locEInvTaxLine.FindLast() then
            LineNo := locEInvTaxLine."Line No." + 10000
        else
            LineNo := 10000;

        EInvTaxLine.Init();
        EInvTaxLine."Header Entry No." := HeaderEntryNo;

        if Type = Type::Header then
            HeaderLineNo := 0
        else
            HeaderLineNo := locEInvTaxLine."Header Line No." + 1;

        EInvTaxLine.Type := Type;
        EInvTaxLine."Header Line No." := HeaderLineNo;
        EInvTaxLine."Line No." := LineNo;
        EInvTaxLine.TaxTypeCode := TaxCode.Code;

        case TaxCode.Type of
            TaxCode.Type::VAT:
                EInvTaxLine.TaxType := EInvTaxLine.TaxType::VAT;
            TaxCode.Type::WitholdingCode:
                EInvTaxLine.TaxType := EInvTaxLine.TaxType::Witholding;
            TaxCode.Type::ExceptionCode:
                EInvTaxLine.TaxType := EInvTaxLine.TaxType::Exception;
            TaxCode.Type::PartialExceptionCode:
                EInvTaxLine.TaxType := EInvTaxLine.TaxType::PartialException;
            TaxCode.Type::SpecificBaseCode:
                EInvTaxLine.TaxType := EInvTaxLine.TaxType::SpecificBase;
            TaxCode.Type::Exported:
                EInvTaxLine.TaxType := EInvTaxLine.TaxType::Exported;
        end;

        EInvTaxLine.TaxPercent := TaxPercent;
        EInvTaxLine.TaxAmount := TaxAmount;
        EInvTaxLine.TaxExclusiveAmount := TaxExclusiveAmount;
        EInvTaxLine.TaxInclusiveAmount := TaxInclusiveAmount;
        EInvTaxLine."TaxExemption Reason Desc" := CopyStr(TaxExemptionReasonDesc, 1, MaxStrLen(EInvTaxLine."TaxExemption Reason Desc"));
        EInvTaxLine."TaxExemption Reason Code" := TaxExemptionReasonCode;
        EInvTaxLine.CalculationSequenceNumeric := CalculationSequenceNumeric;
        EInvTaxLine.Insert();
    end;


    procedure ReCaptureRelatedCVInfo()
    var
        Customer: Record Customer;
        NewQueue: Record "PRG_E-Invoice Queue";
        Queue: Record "PRG_E-Invoice Queue";
        Vendor: Record Vendor;
        Found: Boolean;
        TotalCount: Integer;
        UpdatedCount: Integer;
    begin
        if GuiAllowed then
            if not Confirm(Text018) then
                exit;

        Queue.SetRange(CVNo, '');
        Queue.SetFilter(CVRegistrationNo, '<>%1', '');
        TotalCount := Queue.Count;
        if not Queue.FindFirst() then
            exit;

        repeat

            Found := false;
            Vendor.Reset();
            Customer.Reset();

            NewQueue.Get(Queue.EntryNo);

            case Queue."Dest. Document Type" of
                Queue."Dest. Document Type"::PurchInvoice, Queue."Dest. Document Type"::PurchOrder:
                    begin
                        Vendor.SetRange("VAT Registration No.", Queue.CVRegistrationNo);
                        Found := Vendor.FindFirst();
                        ApplyReCapturedValues(NewQueue, Found, Vendor."No.", Vendor.Name + ' ' + Vendor."Name 2");
                    end;
                Queue."Dest. Document Type"::SalesCrMemo, Queue."Dest. Document Type"::SalesReturnOrder:
                    begin
                        begin
                            Customer.SetRange("VAT Registration No.", Queue.CVRegistrationNo);
                            Found := Customer.FindFirst();
                            ApplyReCapturedValues(NewQueue, Found, Customer."No.", Customer.Name + ' ' + Customer."Name 2");
                        end;
                    end;
            end;
            if Found then begin
                NewQueue.Modify();
                UpdatedCount := UpdatedCount + 1;
            end;

        until Queue.Next() = 0;

        if GuiAllowed then
            Message(StrSubstNo(Text019, TotalCount, UpdatedCount));
    end;

    procedure SetIncomingDocDetails(var Queue: Record "PRG_E-Invoice Queue")
    var
        CVInfo: Record "PRG_E-Invoice CV Info.";
    begin
        Queue.TestField(Type, Queue.Type::Inbox);
        case Queue.InvoiceType of

            Queue.InvoiceType::SalesCr:
                begin
                    Queue."Dest. Document Type" := Queue."Dest. Document Type"::SalesCrMemo;
                    Queue.CVType := Queue.CVType::Cust;
                end;

            else begin
                Queue."Dest. Document Type" := Queue."Dest. Document Type"::PurchInvoice;
                Queue.CVType := Queue.CVType::Vend;
            end;
        end;

        CVInfo.SetRange("Tax Registration No.", Queue.CVRegistrationNo);
        CVInfo.SetRange("CV Type", Queue.CVType);
        if CVInfo.FindFirst() then begin
            Queue.CVNo := CVInfo."CV No.";
            Queue.CVName := CVInfo."CV Name";
            CreateItemMapping(Queue.CVType, Queue.CVNo, GlobItemMapping."Mapping Type"::"Item Description", GlobItemMapping."Dest. Line Type"::Item, 1, true);
            CreateItemMapping(Queue.CVType, Queue.CVNo, GlobItemMapping."Mapping Type"::"G/L Account Description", GlobItemMapping."Dest. Line Type"::"G/L Account", 2, true);
        end;
    end;

    local procedure ApplyReCapturedValues(var NewQueue: Record "PRG_E-Invoice Queue"; Found: Boolean; pNo: Code[20]; pName: Text)
    begin
        if not Found then
            exit;

        NewQueue.CVNo := pNo;
        NewQueue.CVName := CopyStr(pName, 1, MaxStrLen(NewQueue.CVName));
    end;

    local procedure CreateSalesCrMemo(var Queue: Record "PRG_E-Invoice Queue"): Boolean
    var
        EInvHeader: Record "PRG_E-Invoice Header";
        EInvLine: Record "PRG_E-Invoice Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RecRef: RecordRef;
        OrderDocumentNo: Code[20];
        LineNo: Integer;
        ItemMapping: Record "PRG_E-Invoice Item Mapping";
        ItemMapping2: Record "PRG_E-Invoice Item Mapping";
    begin
        if Queue."Dest. Document Status" <> Queue."Dest. Document Status"::" " then
            exit(false);

        GetEInvSetup();

        EInvHeader.SetRange(UUID, Queue.UniqueIdentifier);
        EInvHeader.FindFirst();

        EInvLine.SetRange("Header Entry No.", EInvHeader."Entry No.");
        if not EInvLine.FindSet() then
            exit(false);

        Queue.TestField(CVNo);

        OrderDocumentNo := FindDocumentOrder(CopyStr(EInvHeader.OrderNo, 1, 20), Queue.CVType);
        if OrderDocumentNo <> '' then begin
            SalesHeader.Get(SalesHeader."Document Type"::"Return Order", OrderDocumentNo);
            Queue."Dest. Document Status" := Queue."Dest. Document Status"::Created;
            Queue."Dest. Document Type" := Queue."Dest. Document Type"::SalesReturnOrder;
            RecRef.GetTable(SalesHeader);
            Queue.ERPRecordID := RecRef.RecordId;
            RecRef.Close();
            exit(true);
        end;

        SalesHeader.SetHideValidationDialog(true);

        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::"Credit Memo";
        SalesHeader."No." := '';
        SalesHeader.Insert(true);
        SalesHeader.Validate("Sell-to Customer No.", Queue.CVNo);
        SalesHeader.Validate("Posting Date", Queue.IssueDate);
        SalesHeader.Validate("Document Date", WorkDate());
        SalesHeader."External Document No." := Queue.InvoiceID;
        SalesHeader.Validate("Currency Code", GetCurrCode(EInvHeader.DocumentCurrencyCode));
        SalesHeader.Modify(true);

        RecRef.GetTable(SalesHeader);
        Queue.ERPRecordID := RecRef.RecordId;
        RecRef.Close();

        Queue."Dest. Document Status" := Queue."Dest. Document Status"::Created;

        if EInvSetup."Incoming Inv. Mapping Type" = EInvSetup."Incoming Inv. Mapping Type"::Header then
            exit(true);

        repeat
            Clear(LineNo);
            SalesLine.Init();
            SalesLine."Document Type" := SalesHeader."Document Type";
            SalesLine."Document No." := SalesHeader."No.";
            SalesLine."Line No." := SalesLine."Line No." + 10000;
            /*
            if FindMapping(EInvLine, Queue.CVType, Queue.CVNo, SalesLine.Type, SalesLine."No.") then begin
                SalesLine.Validate("No.", SalesLine."No.");
                SalesLine.Validate(Quantity, EInvLine.Quantity);
                SalesLine.Validate("Unit Cost", EInvLine."Unit Price");
                SalesLine.Validate("Line Discount Amount", Round(EInvLine."Allowance Charge Amount", 0.0001));
                SalesLine.Insert(true);
            end else begin
                SalesLine."No." := '***';
                SalesLine.Description := CopyStr(EInvLine."Item Name", 1, MaxStrLen(SalesLine.Description));
                SalesLine.Quantity := EInvLine.Quantity;
                SalesLine."Unit Cost" := EInvLine."Unit Price";
                SalesLine.Insert(true);
            end;
            */
            if (EInvLine."No." <> '') and (EInvLine.Type <> EInvLine.Type::" ") then begin
                case EInvLine.Type of
                    EInvLine.Type::Item:
                        SalesLine.Validate(Type, SalesLine.Type::Item);
                    EInvLine.Type::"G/L Account":
                        SalesLine.Validate(Type, SalesLine.Type::"G/L Account");
                    EInvLine.Type::"Charge (Item)":
                        SalesLine.Validate(Type, SalesLine.Type::"Charge (Item)");
                end;
                SalesLine.Validate("No.", EInvLine."No.");
                SalesLine.Validate(Quantity, EInvLine.Quantity);
                SalesLine.Validate("Unit Price", EInvLine."Unit Price");
                SalesLine.Validate("Line Discount Amount", Round(EInvLine."Allowance Charge Amount", 0.0001));
                SalesLine.Insert(true);
            end else
                if FindMappingInvoiceLines(EInvLine, Queue) then begin
                    case EInvLine.Type of
                        EInvLine.Type::Item:
                            SalesLine.Validate(Type, SalesLine.Type::Item);
                        EInvLine.Type::"G/L Account":
                            SalesLine.Validate(Type, SalesLine.Type::"G/L Account");
                        EInvLine.Type::"Charge (Item)":
                            SalesLine.Validate(Type, SalesLine.Type::"Charge (Item)");
                    end;
                    SalesLine.Validate("No.", EInvLine."No.");
                    SalesLine.Validate(Quantity, EInvLine.Quantity);
                    SalesLine.Validate("Unit Price", EInvLine."Unit Price");
                    SalesLine.Validate("Line Discount Amount", Round(EInvLine."Allowance Charge Amount", 0.0001));
                    SalesLine.Insert(true);
                end else begin
                    case EInvSetup."Document Mapping Control Type" of
                        EInvSetup."Document Mapping Control Type"::"Not Allow":
                            Error(Text020);
                        EInvSetup."Document Mapping Control Type"::Warning:
                            if not Confirm(Text021) then
                                Error(Text022);
                    end;
                end;

            if (EInvSetup."Mapping Adding Type" <> EInvSetup."Mapping Adding Type"::"Not Add") and (not EInvLine."Success Mapping") then begin
                ItemMapping2.SetRange("CV Type", Queue.CVType);
                ItemMapping2.SetRange("Incoming Description Text", EInvLine."Item Name");
                ItemMapping2.SetRange("Dest. Line Type", EInvLine.Type);
                ItemMapping2.SetRange("Dest. Line No.", EInvLine."No.");
                if not ItemMapping2.FindFirst() then begin
                    ItemMapping2.Reset();
                    ItemMapping2.SetRange("CV Type", Queue.CVType);
                    if EInvSetup."Mapping Adding Type" = EInvSetup."Mapping Adding Type"::"Related CV" then
                        ItemMapping2.SetRange("CV No.", Queue.CVNo)
                    else
                        ItemMapping2.SetRange("CV No.", '');
                    if ItemMapping2.FindLast() then;

                    ItemMapping.Init();
                    ItemMapping.Validate("CV Type", Queue.CVType);
                    if EInvSetup."Mapping Adding Type" = EInvSetup."Mapping Adding Type"::"Related CV" then
                        ItemMapping.Validate("CV No.", Queue.CVNo)
                    else
                        ItemMapping.Validate("CV No.", '');
                    ItemMapping.Validate("Line No.", ItemMapping2."Line No." + 10000);
                    ItemMapping.Validate("Mapping Type", ItemMapping."Mapping Type"::"User Defined");
                    ItemMapping.Validate("Incoming Description Text", EInvLine."Item Name");
                    ItemMapping.Validate("Dest. Line Type", EInvLine.Type);
                    ItemMapping.Validate("Dest. Line No.", EInvLine."No.");
                    ItemMapping.Validate(Priority, 1);
                    ItemMapping.Validate(Enabled, true);
                    if ItemMapping.Insert(true) then;
                end;
            end;

        until EInvLine.Next() = 0;

        Queue."Dest. Document Status" := Queue."Dest. Document Status"::Created;

        exit(true);
    end;

    local procedure GetAttributeValue(XMLDoc: XmlNode; Element: Text; Attribute: Text): Text[1024]
    var
        lXMLAttribute: XmlAttribute;
        lXmlNode: XmlNode;
    begin
        if not XMLDoc.SelectSingleNode(Element, lXmlNode) then
            exit('');

        if lXmlNode.AsXmlElement().InnerText = '' then
            exit('');

        lXmlNode.AsXmlElement().Attributes().Get(Attribute, lXMLAttribute);
        exit(lXMLAttribute.Value);
    end;

    local procedure GetAttributeValue_XmlDocument(XMLDoc: XmlDocument; Element: Text; Attribute: Text): Text[1024]
    var
        lXMLAttribute: XmlAttribute;
        lXmlNode: XmlNode;
    begin
        if not XMLDoc.SelectSingleNode(Element, lXmlNode) then
            exit('');
        if lXmlNode.AsXmlElement().InnerText = '' then
            exit('');

        lXmlNode.AsXmlElement().Attributes().Get(Attribute, lXMLAttribute);
        exit(lXMLAttribute.Value);
    end;

    local procedure GetNodeValue(var XMLDoc: XmlNode; xPath: Text): Text[1024]
    var
        lXmlNode: XmlNode;
    begin
        if not XMLDoc.SelectSingleNode(xPath, lXmlNode) then
            exit('');
        exit(lXmlNode.AsXmlElement().InnerText);
    end;

    local procedure GetNodeValue_XmlDocument(var XMLDoc: XmlDocument; xPath: Text): Text[1024]
    var
        lXmlNode: XmlNode;
    begin
        if not XMLDoc.SelectSingleNode(xPath, lXmlNode) then
            exit('');

        exit(lXmlNode.AsXmlElement().InnerText);
    end;

    local procedure GetXsltName(PText: Text[100]): Text[100]
    var
        TempText: Text[100];
    begin
        TempText := CopyStr(PText, 1, StrLen(PText) - 3);
        TempText := TempText + 'xslt';
        exit(TempText);
    end;

    local procedure InsertRefBuffer(HeaderEntryNo: Integer; SourceLineNo: Integer; RefType: Option; RefText: Text[250]; RefDate: Date)
    var
        RefLine: Record "PRG_E-Invoice Reference Buffer";
    begin
        if RefText = '' then
            exit;

        RefLine.SetRange("Header Entry No.", HeaderEntryNo);
        if RefLine.FindLast() then;

        GlobRefLine.Init();
        GlobRefLine."Header Entry No." := HeaderEntryNo;
        GlobRefLine."Source Line No." := 0;
        GlobRefLine."Line No." := RefLine."Line No." + 10000;
        GlobRefLine."Reference Type" := RefType;
        GlobRefLine."Source Type" := GlobRefLine."Source Type"::Header;
        GlobRefLine."Reference Text" := RefText;
        GlobRefLine."Reference Date" := RefDate;
        GlobRefLine.Insert();

        case GlobRefLine."Reference Type" of
            GlobRefLine."Reference Type"::Despatch:
                GlobRefLine.TestField("Reference Date");
        end;
    end;

    local procedure CheckAndUpdateQueue_CVNo(var Queue: Record "PRG_E-Invoice Queue")
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        ErrInfo: ErrorInfo;
        EInvLib: Codeunit "PRG_E-Invoice Library";
    begin
        case Queue.CVType of
            Queue.CVType::Cust:
                begin
                    Customer.SetRange("VAT Registration No.", Queue.CVRegistrationNo);
                    if Customer.FindFirst() then
                        Queue.Validate(CVNo, Customer."No.")
                    else begin
                        ErrInfo.Message('Customer not found!');
                        ErrInfo.RecordId := Queue.RecordId;
                        ErrInfo.AddAction('Create Customer', Codeunit::"PRG_E-Invoice Library", 'CreateCVCard');
                        Error(ErrInfo);
                    end;
                end;
            Queue.CVType::Vend:
                begin
                    Vendor.SetRange("VAT Registration No.", Queue.CVRegistrationNo);
                    if Vendor.FindFirst() then
                        Queue.Validate(CVNo, Vendor."No.")
                    else begin
                        ErrInfo.RecordId := Queue.RecordId;
                        ErrInfo.Message('Vendor not found!');
                        ErrInfo.AddAction('Create Vendor', Codeunit::"PRG_E-Invoice Library", 'CreateCVCard');
                        Error(ErrInfo);
                    end;
                end;
        end;
    end;
}