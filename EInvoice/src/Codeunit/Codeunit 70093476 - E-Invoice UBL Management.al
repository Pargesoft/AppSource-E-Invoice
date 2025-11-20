codeunit 70093476 "PRG_E-Invoice UBL Management"
{
    var
        EExportSetup: Record "PRG_E-Export Setup";
        EInvIntSetup: Record "PRG_E-Invoice Integrator Setup";
        EInvSetup: Record "PRG_E-Invoice Setup";
        Library: Codeunit "PRG_E-Invoice Library";
        EIntGot: Boolean;
        EInvGot: Boolean;
        GotExportSetup: Boolean;
        NamespaceURI_CAC: Label 'cac', Locked = true;
        NamespaceURI_CAC2: Label 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2', Locked = true;
        NamespaceURI_CBC: Label 'cbc', Locked = true;
        NamespaceURI_CBC2: Label 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2', Locked = true;
        Text001: Label 'Package Brand : %1';
        Text002: Label 'Function number cannot be found!';
        Text005: Label 'Cannot find value for function no. %1!';
        XMLdoc: XmlDocument;
        RootNode: XmlElement;
        ActiveNode: XmlNode;
        ChildNode: XmlNode;
        CurrNode: XmlNode;

    procedure AddAttribute(var ParentXmlNode: XmlNode; Name: Text; NodeValue: Text)
    begin
        ParentXmlNode.AsXmlElement().SetAttribute(Name, NodeValue);
    end;

    procedure AddElement(var ParentXmlNode: XmlNode; NodeName: Text; NodeText: Text; NameSpace: Text; var CreatedXmlNode: XmlNode): Boolean
    begin
        case NameSpace of
            'cac':
                begin
                    CreatedXmlNode := XmlElement.Create(NodeName, NamespaceURI_CAC2, NodeText).AsXmlNode();
                    AddPrefix(CreatedXmlNode, NameSpace, NamespaceURI_CAC2);
                end;
            'cbc':
                begin
                    CreatedXmlNode := XmlElement.Create(NodeName, NamespaceURI_CBC2, NodeText).AsXmlNode();
                    AddPrefix(CreatedXmlNode, NameSpace, NamespaceURI_CBC2);
                end;
            '':
                CreatedXmlNode := XmlElement.Create(NodeName, '', NodeText).AsXmlNode();
        end;

        exit(ParentXmlNode.AsXmlElement().Add(CreatedXmlNode));
    end;

    procedure AddPrefix(var pXMLNode: XmlNode; pPrefix: Text; pNameSpace: text): Boolean
    begin
        pXMLNode.AsXmlElement().Add(XmlAttribute.CreateNamespaceDeclaration(pPrefix, pNameSpace));
        exit(true);
    end;

    procedure GetSetup()
    begin
        IF NOT EIntGot then begin
            EInvIntSetup.get();
            EIntGot := true;
        end;
    end;

    procedure CreateOutgoingXML(var Queue: Record "PRG_E-Invoice Queue"; Preview: Boolean): XmlDocument;
    var
        EInvHeader: Record "PRG_E-Invoice Header";
    begin
        OnBeforeCreateOutgoingXML(Queue);

        GetSetup();

        if EInvIntSetup."E-Invoice Output Type" <> EInvIntSetup."E-Invoice Output Type"::Customized then begin
            CreateXMLDoc(Queue.IntegrationType, Queue.ProfileID, Queue.InvoiceType, Queue.UniqueIdentifier, Preview);
            CreateRootNode();
            GetEInvSetup();
            GetExportSetup();

            EInvHeader.SETRANGE(Type, EInvHeader.Type::Outbox);
            EInvHeader.SETRANGE(UUID, Queue.UniqueIdentifier);
            EInvHeader.FINDFIRST();
            XmlPhase1(Queue, EInvHeader);//İnitial Nodes,Orders,Despatches,Xslt
            XmlPhase2(Queue, EInvHeader);//Signature
            XmlPhase3(Queue, EInvHeader);//AccountingSupplierParty
            CASE Queue.ProfileID OF
                EExportSetup."E-Export ProfileID":
                    XmlPhase4_Export(Queue, EInvHeader);//AccountingCustomerParty,BuyerCustomerParty
                ELSE
                    XmlPhase4_Standard(Queue, EInvHeader);//AccountingCustomerParty
            END;
            XmlPhase5(Queue, EInvHeader);//PaymentMeans,PricingExchangeRate,TaxTotal,WitholdingTaxTotal,LegalMonetaryTotal
            XmlPhase6(Queue, EInvHeader);//InvoiceLine
        end else
            CreateCustomizedXml(Queue, Preview);

        OnAfterCreateOutgoingXML(Queue);

        exit(XMLdoc);
    end;

    local procedure CreateCustomizedXml(var Queue: Record "PRG_E-Invoice Queue"; Preview: Boolean)
    var
        EInvHeader: Record "PRG_E-Invoice Header";
        EInvLine: Record "PRG_E-Invoice Line";
        EInvTaxLine: Record "PRG_E-Invoice Tax Line";
        TaxTypeCode: Record "PRG_E-Invoice Tax Type Code";
        RefLine: Record "PRG_E-Invoice Reference Buffer";
        LineCounter: Integer;
        RootAsNode: XmlNode;
        PricingExchangeRateNode: XmlNode;
        BillingReferenceNode: XmlNode;
        InvoiceDocumentReferenceNode: XmlNode;
        SupplierPartyNode: XmlNode;
        CustomerPartyNode: XmlNode;
        LinesNode: XmlNode;
        InvLineNode: XmlNode;
        ShipmentNode: XmlNode;
        DeliveryAddressNode: XmlNode;
        TaxesNode: XmlNode;
        TaxLineNode: XmlNode;
        WithholdingTaxNode: XmlNode;
        WithholdingTaxLinesNode: XmlNode;
        TaxSubTotalNode: XmlNode;
        TaxSchemeNode: XmlNode;
        PaymentsNode: XmlNode;
        PaymentNode: XmlNode;
        DispatchesNode: XmlNode;
        DispatchNode: XmlNode;
        ReferenceInvoicesNode: XmlNode;
        ReferenceInvoiceNode: XmlNode;
        NotesNode: XmlNode;
        InfoTxt: Text;
        DespatchDate: Date;
    begin

        GetEInvSetup();
        GetExportSetup();

        EInvHeader.SETRANGE(UUID, Queue.UniqueIdentifier);
        EInvHeader.FINDLAST;
        EInvHeader.CALCFIELDS(AllowanceChargeAmtLine, AllowanceChargeBase, TaxableAmount, TaxAmount, TaxExclusiveAmount, TaxInclusiveAmount);

        Queue.TestField(ProfileID);

        EInvHeader.TESTFIELD(DocumentCurrencyCode);
        EInvHeader.TESTFIELD(InvoiceType);
        EInvHeader.TESTFIELD(IssueDate);
        Queue.TestField(CVRegistrationNo);
        if STRLEN(Queue.CVRegistrationNo) = 10 then begin
            EInvHeader.TESTFIELD(CustName);
            EInvHeader.TESTFIELD(CustTaxOfficeName);
            EInvHeader.CustFirstName := '';
            EInvHeader.CustFamilyName := '';
        end else begin
            EInvHeader.TESTFIELD(CustFirstName);
            EInvHeader.TESTFIELD(CustFamilyName);
            EInvHeader.CustName := '';
            EInvHeader.CustTaxOfficeName := '';
        end;
        EInvHeader.TESTFIELD(CustCountryName);
        EInvHeader.TESTFIELD(CustCityName);
        EInvHeader.TESTFIELD(CustCitySubdivisionName);

        XmlDocument.ReadFrom('<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Invoice></Invoice>', XMLdoc);
        XMLdoc.GetRoot(RootNode);
        RootAsNode := RootNode.AsXmlNode();
        AddElement(RootAsNode, 'InvoiceNumber', Queue.InvoiceID, '', ChildNode);
        case EInvHeader.InvoiceType of
            EInvHeader.InvoiceType::Sales:
                AddElement(RootAsNode, 'InvoiceTypeCode', 'SATIS', '', ChildNode);
            EInvHeader.InvoiceType::PurchCr:
                AddElement(RootAsNode, 'InvoiceTypeCode', 'IADE', '', ChildNode);
            EInvHeader.InvoiceType::Withholding:
                AddElement(RootAsNode, 'InvoiceTypeCode', 'TEVKIFAT', '', ChildNode);
            EInvHeader.InvoiceType::Exception:
                AddElement(RootAsNode, 'InvoiceTypeCode', 'ISTISNA', '', ChildNode);
            ELSE
                ERROR('');
        end;

        case EInvHeader.ProfileID of
            EInvHeader.ProfileID::Commercial:
                AddElement(RootAsNode, 'ScenarioType', 'TICARIFATURA', '', ChildNode);
            EInvHeader.ProfileID::Basic:
                AddElement(RootAsNode, 'ScenarioType', 'TEMELFATURA', '', ChildNode);
            EInvHeader.ProfileID::EArchive:
                AddElement(RootAsNode, 'ScenarioType', 'EARSIVFATURA', '', ChildNode);
            EInvHeader.ProfileID::EExport:
                AddElement(RootAsNode, 'ScenarioType', 'IHRACAT', '', ChildNode);
        end;
        AddElement(RootAsNode, 'DocumentCurrencyCode', EInvHeader.DocumentCurrencyCode, '', ChildNode);

        if EInvHeader.DocumentCurrencyCode <> 'TRY' then begin
            AddElement(RootAsNode, 'PricingExchangeRate', '', '', PricingExchangeRateNode);
            AddElement(PricingExchangeRateNode, 'SourceCurrencyCode', EInvHeader.DocumentCurrencyCode, '', ChildNode);
            AddElement(PricingExchangeRateNode, 'TargetCurrencyCode', 'TRY', '', ChildNode);
            AddElement(PricingExchangeRateNode, 'CalculationRate', Library.FormatDec5Places(EInvHeader.DocumentCurrencyRate), '', ChildNode);
        end;

        AddElement(RootAsNode, 'IssueDate', Library.FormatDate(EInvHeader.IssueDate), '', ChildNode);
        AddElement(RootAsNode, 'IssueTime', Library.FormatTime(EInvHeader.IssueTime), '', ChildNode);
        AddElement(RootAsNode, 'PayableAmount', Library.FormatDec2Places(EInvHeader.PayableAmount), '', ChildNode);
        AddElement(RootAsNode, 'TaxExclusiveAmount', Library.FormatDec2Places(EInvHeader.TaxExclusiveAmount), '', ChildNode);
        AddElement(RootAsNode, 'TaxInclusiveAmount', Library.FormatDec2Places(EInvHeader.TaxInclusiveAmount), '', ChildNode);
        AddElement(RootAsNode, 'DiscountRate', Library.FormatDec2Places(EInvHeader.AllowanceChargeRate), '', ChildNode);
        AddElement(RootAsNode, 'DiscountTotal', Library.FormatDec2Places(EInvHeader.AllowanceChargeAmtInvoice), '', ChildNode);
        if (EInvHeader.OrderNo <> '') AND (EInvHeader.OrderDate <> 0D) then begin
            AddElement(RootAsNode, 'OrderNumber', EInvHeader.OrderNo, '', ChildNode);
            AddElement(RootAsNode, 'OrderDate', Library.FormatDate(EInvHeader.OrderDate), '', ChildNode);
        end;
        if EInvHeader.InvoiceType = EInvHeader.InvoiceType::PurchCr then begin
            AddElement(RootAsNode, 'BillingReference', '', '', BillingReferenceNode);
            AddElement(BillingReferenceNode, 'InvoiceDocumentReference', '', '', InvoiceDocumentReferenceNode);
            AddElement(InvoiceDocumentReferenceNode, 'ID', EInvHeader."Related Invoice No.", '', ChildNode);
            AddElement(InvoiceDocumentReferenceNode, 'IssueDate', Library.FormatDate(EInvHeader."Related Invoice Date"), '', ChildNode);
            AddElement(InvoiceDocumentReferenceNode, 'DocumentTypeCode', 'İADE', '', ChildNode);
            AddElement(InvoiceDocumentReferenceNode, 'DocumentType', 'İade Edilen Fatura', '', ChildNode);
        end;

        OnBeforeSupplierParty_CreateCustomizedXml(RootAsNode, ChildNode, Queue);

        AddElement(RootAsNode, 'SupplierParty', '', '', SupplierPartyNode);
        AddElement(SupplierPartyNode, 'SupplierTaxNo', EInvSetup."Supplier Tax Registration No.", '', ChildNode);
        AddElement(SupplierPartyNode, 'SupplierPartyTaxScheme', EInvSetup."Supplier Party Tax Scheme", '', ChildNode);
        AddElement(SupplierPartyNode, 'SupplierTradeRegisterNo', EInvSetup."Supplier Trade Register No.", '', ChildNode);
        AddElement(SupplierPartyNode, 'SupplierPartyName', EInvSetup."Supplier Party Name", '', ChildNode);
        AddElement(SupplierPartyNode, 'SupplierCountry', EInvSetup."Supplier Country", '', ChildNode);
        AddElement(SupplierPartyNode, 'SupplierCityName', EInvSetup."Supplier City Name", '', ChildNode);
        AddElement(SupplierPartyNode, 'SupplierCitySubdivisionName', EInvSetup."Supplier City Subdivision Name", '', ChildNode);
        AddElement(SupplierPartyNode, 'SupplierAddressDetail', EInvSetup."Supplier Address", '', ChildNode);
        AddElement(SupplierPartyNode, 'SupplierTelephone', EInvSetup."Supplier Phone", '', ChildNode);
        AddElement(SupplierPartyNode, 'SupplierFax', EInvSetup."Supplier Fax No.", '', ChildNode);
        AddElement(SupplierPartyNode, 'SupplierMail', EInvSetup."Supplier E-mail", '', ChildNode);
        AddElement(SupplierPartyNode, 'SupplierWeb', EInvSetup."Supplier Web Address", '', ChildNode);
        AddElement(SupplierPartyNode, 'SupplierMersisNumber', EInvSetup."Supplier Mersis No.", '', ChildNode);


        AddElement(RootAsNode, 'CustomerParty', '', '', CustomerPartyNode);
        AddElement(CustomerPartyNode, 'CustomerTaxNo', Queue.CVRegistrationNo, '', ChildNode);
        if STRLEN(Queue.CVRegistrationNo) = 10 then begin
            AddElement(CustomerPartyNode, 'CustomerPartyTaxScheme', EInvHeader.CustTaxOfficeName, '', ChildNode);
            AddElement(CustomerPartyNode, 'CustomerPartyName', EInvHeader.CustName, '', ChildNode);
        end else begin
            AddElement(CustomerPartyNode, 'CustomerFirstName', EInvHeader.CustFirstName, '', ChildNode);
            AddElement(CustomerPartyNode, 'CustomerFamilyName', EInvHeader.CustFamilyName, '', ChildNode);
        end;
        AddElement(CustomerPartyNode, 'CustomerCountry', EInvHeader.CustCountryName, '', ChildNode);
        AddElement(CustomerPartyNode, 'CustomerCityName', EInvHeader.CustCityName, '', ChildNode);
        AddElement(CustomerPartyNode, 'CustomerCitySubdivisionName', EInvHeader.CustCitySubdivisionName, '', ChildNode);
        AddElement(CustomerPartyNode, 'CustomerAddressDetail', EInvHeader.CustStreetName, '', ChildNode);
        AddElement(CustomerPartyNode, 'CustomerEmailAddress', EInvHeader.CustElectronicMail, '', ChildNode);

        EInvTaxLine.RESET;
        EInvTaxLine.SETRANGE("Header Entry No.", EInvHeader."Entry No.");
        EInvTaxLine.SETRANGE(Type, EInvTaxLine.Type::Line);
        EInvTaxLine.SETRANGE("Header Line No.", EInvLine."Line No.");
        EInvTaxLine.SETFILTER("TaxExemption Reason Code", '<>%1', '');
        if EInvTaxLine.FINDFIRST then begin
            AddElement(InvLineNode, 'VatExemptionReasonCode', EInvTaxLine."TaxExemption Reason Code", '', ChildNode);
            AddElement(InvLineNode, 'VatExemptionReason', EInvTaxLine."TaxExemption Reason Desc", '', ChildNode);
        end;

        //Lines
        AddElement(RootAsNode, 'InvoiceLines', '', '', LinesNode);
        EInvLine.SETRANGE("Header Entry No.", EInvHeader."Entry No.");
        LineCounter := 0;
        if EInvLine.FindSet() then
            repeat
                EInvLine.CALCFIELDS("Taxable Amount", "Tax Amount", "Tax Inclusive Amount", "VAT Amount", "VAT Percent");

                EInvLine.TESTFIELD("Item Name");
                EInvLine.TESTFIELD(Quantity);
                EInvLine.TESTFIELD("Unit Of Measure Code");

                LineCounter += 1;
                AddElement(LinesNode, 'InvoiceLine', '', '', InvLineNode);
                AddElement(InvLineNode, 'ItemLineUniqueId', FORMAT(LineCounter), '', ChildNode);
                AddElement(InvLineNode, 'ItemCode', EInvLine."Sellers Item Identification", '', ChildNode);
                AddElement(InvLineNode, 'ItemName', EInvLine."Item Name", '', ChildNode);
                AddElement(InvLineNode, 'PriceAmount', Library.FormatDec2Places(EInvLine."Unit Price"), '', ChildNode);
                AddElement(InvLineNode, 'ItemQuantity', Library.FormatDec2Places(EInvLine.Quantity), '', ChildNode);
                AddElement(InvLineNode, 'ItemUnitCode', EInvLine."Unit Of Measure Code", '', ChildNode);
                AddElement(InvLineNode, 'DiscountRate', Library.FormatDec2Places(EInvLine."Allowance Charge Rate"), '', ChildNode);
                AddElement(InvLineNode, 'DiscountTotal', Library.FormatDec2Places(EInvLine."Allowance Charge Amount"), '', ChildNode);
                AddElement(InvLineNode, 'VatAmount', Library.FormatDec2Places(EInvLine."VAT Amount"), '', ChildNode);
                if EInvLine."Taxable Amount" <> 0 then
                    AddElement(InvLineNode, 'VatPercent', Library.FormatDec2Places(ROUND(EInvLine."VAT Percent", 1)), '', ChildNode);
                AddElement(InvLineNode, 'VatExclusiveAmount', Library.FormatDec5Places(EInvLine."Taxable Amount"), '', ChildNode);
                AddElement(InvLineNode, 'VatInclusiveAmount', Library.FormatDec5Places(EInvLine."Tax Inclusive Amount"), '', ChildNode);

                EInvTaxLine.SETRANGE(Type, EInvTaxLine.Type::Line);
                EInvTaxLine.SETRANGE("Header Line No.", EInvLine."Line No.");
                EInvTaxLine.SETFILTER("TaxExemption Reason Code", '<>%1', '');
                if EInvTaxLine.FINDFIRST then begin
                    AddElement(InvLineNode, 'VatExemptionReasonCode', EInvTaxLine."TaxExemption Reason Code", '', ChildNode);
                    AddElement(InvLineNode, 'VatExemptionReason', EInvTaxLine."TaxExemption Reason Desc", '', ChildNode);
                end;

                if EInvHeader.ProfileID = EInvHeader.ProfileID::EExport then begin
                    AddElement(InvLineNode, 'RequiredCustomsID', EInvLine."GTIP No.", '', ChildNode);
                    AddElement(InvLineNode, 'Incoterms', EInvLine."Delivery Terms", '', ChildNode);
                    AddElement(InvLineNode, 'Shipment', '', '', ShipmentNode);
                    AddElement(ShipmentNode, 'TransportModeCode', EInvLine."Transport Mode Code", '', ChildNode);
                    AddElement(InvLineNode, 'DeliveryAddress', '', '', DeliveryAddressNode);
                    if EInvLine."Delivery City Name" = '' then
                        EInvLine."Delivery City Name" := '-';
                    AddElement(DeliveryAddressNode, 'City', EInvLine."Delivery City Name", '', ChildNode);
                    if EInvLine."Delivery Country Name" = '' then
                        EInvLine."Delivery Country Name" := '-';
                    AddElement(DeliveryAddressNode, 'Country', EInvLine."Delivery Country Name", '', ChildNode);
                    AddElement(InvLineNode, 'DeliveryAddress', '', '', DeliveryAddressNode);
                    AddElement(DeliveryAddressNode, 'PackagingTypeCode', EInvLine."Packagin Type Code", '', ChildNode);
                    AddElement(DeliveryAddressNode, 'ActualPackageId', '-', '', ChildNode);
                    AddElement(DeliveryAddressNode, 'ActualPackageQuantity', Library.FormatDec2Places(EInvLine."Actual Package Quantity"), '', ChildNode);
                    if EInvLine."Package Brand" = '' then
                        EInvLine."Package Brand" := '-';
                    AddElement(DeliveryAddressNode, 'PackageBrand', EInvLine."Package Brand", '', ChildNode);
                end;

                EInvTaxLine.RESET;
                EInvTaxLine.SETRANGE("Header Entry No.", EInvHeader."Entry No.");
                EInvTaxLine.SetRange("Header Line No.", EInvLine."Line No.");
                EInvTaxLine.SetRange(Type, EInvTaxLine.Type::Line);
                EInvTaxLine.SetRange(TaxType, EInvTaxLine.TaxType::Witholding);
                if EInvTaxLine.FindFirst() then begin
                    AddElement(InvLineNode, 'WithholdingTax', '', '', WithholdingTaxNode);
                    EInvTaxLine.TESTFIELD(TaxTypeCode);
                    TaxTypeCode.GET(EInvTaxLine.TaxTypeCode);

                    AddElement(WithholdingTaxNode, 'Tax', '', '', WithholdingTaxLinesNode);
                    AddElement(WithholdingTaxLinesNode, 'TaxAmount', Library.FormatDec2Places(EInvTaxLine.TaxAmount), '', ChildNode);
                    AddElement(WithholdingTaxLinesNode, 'TaxExclusiveAmount', Library.FormatDec2Places(EInvTaxLine.TaxExclusiveAmount), '', ChildNode);
                    AddElement(WithholdingTaxLinesNode, 'TaxInclusiveAmount', Library.FormatDec2Places(EInvTaxLine.TaxInclusiveAmount), '', ChildNode);
                    AddElement(WithholdingTaxLinesNode, 'TaxSubTotal', '', '', TaxSubTotalNode);
                    AddElement(TaxSubTotalNode, 'TaxableAmount', Library.FormatDec2Places(EInvLine."Taxable Amount"), '', ChildNode);
                    AddElement(TaxSubTotalNode, 'TaxAmount', Library.FormatDec2Places(EInvTaxLine.TaxAmount), '', ChildNode);
                    AddElement(TaxSubTotalNode, 'TaxPercent', Library.FormatDec2Places(EInvTaxLine.TaxPercent), '', ChildNode);
                    AddElement(TaxSubTotalNode, 'TaxScheme', '', '', TaxSchemeNode);
                    AddElement(TaxSchemeNode, 'Name', EInvTaxLine."TaxExemption Reason Desc", '', ChildNode);
                    AddElement(TaxSchemeNode, 'TaxTypeCode', EInvTaxLine.TaxTypeCode, '', ChildNode);
                end;

            until EInvLine.Next() = 0;

        //Taxes
        AddElement(RootAsNode, 'Taxes', '', '', TaxesNode);
        EInvTaxLine.RESET;
        EInvTaxLine.SETRANGE("Header Entry No.", EInvHeader."Entry No.");
        EInvTaxLine.SETRANGE(Type, EInvTaxLine.Type::Header);
        //if EInvHeader.ProfileID <> EInvHeader.ProfileID::EExport then
        //    EInvTaxLine.SetRange(TaxType, EInvTaxLine.TaxType::VAT)
        //else
        //    EInvTaxLine.SetRange(TaxType, EInvTaxLine.TaxType::Exception);
        if EInvTaxLine.FINDSET then
            repeat
                EInvTaxLine.TESTFIELD(TaxTypeCode);
                TaxTypeCode.GET(EInvTaxLine.TaxTypeCode);
                if TaxTypeCode.Type <> TaxTypeCode.Type::VAT THEN
                    EInvTaxLine.TaxTypeCode := EInvSetup."VAT Tax Type Code";

                if EInvTaxLine.TaxAmount = 0 THEN
                    EInvTaxLine.TESTFIELD("TaxExemption Reason Code");

                if EInvTaxLine."TaxExemption Reason Code" <> '' then
                    EInvTaxLine.TESTFIELD("TaxExemption Reason Desc")
                else begin
                    EInvTaxLine.TESTFIELD(TaxExclusiveAmount);
                    EInvTaxLine.TESTFIELD(TaxInclusiveAmount);
                end;
                AddElement(TaxesNode, 'Tax', '', '', TaxLineNode);
                AddElement(TaxLineNode, 'TaxTypeCode', EInvTaxLine.TaxTypeCode, '', ChildNode);
                AddElement(TaxLineNode, 'TaxPercent', Library.FormatDec2Places(EInvTaxLine.TaxPercent), '', ChildNode);
                AddElement(TaxLineNode, 'TaxAmount', Library.FormatDec2Places(EInvTaxLine.TaxAmount), '', ChildNode);
                AddElement(TaxLineNode, 'TaxExclusiveAmount', Library.FormatDec2Places(EInvTaxLine.TaxExclusiveAmount), '', ChildNode);
                AddElement(TaxLineNode, 'TaxInclusiveAmount', Library.FormatDec2Places(EInvTaxLine.TaxInclusiveAmount), '', ChildNode);
                if EInvTaxLine."TaxExemption Reason Code" <> '' then begin
                    AddElement(TaxLineNode, 'TaxExemptionReasonCode', EInvTaxLine."TaxExemption Reason Code", '', ChildNode);
                    AddElement(TaxLineNode, 'TaxExemptionReason', EInvTaxLine."TaxExemption Reason Desc", '', ChildNode);
                end;
                AddElement(TaxLineNode, 'CalculationSequenceNumeric', Library.FormatDec2Places(EInvTaxLine.CalculationSequenceNumeric), '', ChildNode);
            until EInvTaxLine.Next() = 0;

        //Withholding Taxes
        AddElement(RootAsNode, 'WithholdingTax', '', '', WithholdingTaxNode);
        EInvTaxLine.RESET;
        EInvTaxLine.SETRANGE("Header Entry No.", EInvHeader."Entry No.");
        EInvTaxLine.SETRANGE(Type, EInvTaxLine.Type::Header);
        EInvTaxLine.SetRange(TaxType, EInvTaxLine.TaxType::Witholding);
        if EInvTaxLine.FINDSET then
            repeat
                EInvTaxLine.TESTFIELD(TaxTypeCode);
                TaxTypeCode.GET(EInvTaxLine.TaxTypeCode);

                AddElement(WithholdingTaxNode, 'Tax', '', '', WithholdingTaxLinesNode);
                AddElement(WithholdingTaxLinesNode, 'TaxAmount', Library.FormatDec2Places(EInvTaxLine.TaxAmount), '', ChildNode);
                AddElement(WithholdingTaxLinesNode, 'TaxExclusiveAmount', Library.FormatDec2Places(EInvTaxLine.TaxExclusiveAmount), '', ChildNode);
                AddElement(WithholdingTaxLinesNode, 'TaxInclusiveAmount', Library.FormatDec2Places(EInvTaxLine.TaxInclusiveAmount), '', ChildNode);
                AddElement(WithholdingTaxLinesNode, 'TaxSubTotal', '', '', TaxSubTotalNode);
                AddElement(TaxSubTotalNode, 'TaxableAmount', Library.FormatDec2Places(EInvTaxLine.TaxExclusiveAmount), '', ChildNode);
                AddElement(TaxSubTotalNode, 'TaxAmount', Library.FormatDec2Places(EInvTaxLine.TaxAmount), '', ChildNode);
                AddElement(TaxSubTotalNode, 'TaxPercent', Library.FormatDec2Places(EInvTaxLine.TaxPercent), '', ChildNode);
                AddElement(TaxSubTotalNode, 'TaxScheme', '', '', TaxSchemeNode);
                AddElement(TaxSchemeNode, 'Name', EInvTaxLine."TaxExemption Reason Desc", '', ChildNode);
                AddElement(TaxSchemeNode, 'TaxTypeCode', EInvTaxLine.TaxTypeCode, '', ChildNode);
            until EInvTaxLine.Next() = 0;

        //Payments
        RefLine.RESET;
        RefLine.SETRANGE("Header Entry No.", EInvHeader."Entry No.");
        RefLine.SETRANGE("Reference Type", RefLine."Reference Type"::PaymentMethod);
        if RefLine.FINDSET then begin
            AddElement(RootAsNode, 'Payments', '', '', PaymentsNode);
            repeat
                EInvHeader.CALCFIELDS(TaxInclusiveAmount, EInvHeader.PaymentMethodCode);

                AddElement(PaymentsNode, 'Payment', '', '', PaymentNode);
                AddElement(PaymentNode, 'PaymentTypeCode', RefLine."Reference Text", '', ChildNode);
                AddElement(PaymentNode, 'DueDate', Library.FormatDate(RefLine."Reference Date"), '', ChildNode);
                AddElement(PaymentNode, 'PaymentAmount', Library.FormatDec2Places(EInvHeader.TaxInclusiveAmount), '', ChildNode);

            until RefLine.NEXT = 0;
        end;

        //Dispatches 
        RefLine.RESET;
        RefLine.SETRANGE("Header Entry No.", EInvHeader."Entry No.");
        RefLine.SETRANGE("Reference Type", RefLine."Reference Type"::Despatch);
        if RefLine.FINDSET then begin
            AddElement(RootAsNode, 'Dispatches', '', '', DispatchesNode);
            repeat
                AddElement(DispatchesNode, 'Dispatch', '', '', DispatchNode);
                AddElement(DispatchNode, 'DispatchNumber', RefLine."Reference Text", '', ChildNode);
                AddElement(DispatchNode, 'DispatchDate', Library.FormatDate(RefLine."Reference Date"), '', ChildNode);
                DespatchDate := RefLine."Reference Date";
            until RefLine.NEXT = 0;
        end;
        if EInvHeader.InvoiceType = EInvHeader.InvoiceType::PurchCr then begin
            AddElement(RootAsNode, 'ReferenceInvoices', '', '', ReferenceInvoicesNode);
            AddElement(ReferenceInvoicesNode, 'ReferenceInvoice', '', '', ReferenceInvoiceNode);
            AddElement(ReferenceInvoiceNode, 'InvoiceNumber', EInvHeader."Related Invoice No.", '', ChildNode);
            AddElement(ReferenceInvoiceNode, 'InvoiceDate', Library.FormatDate(EInvHeader."Related Invoice Date"), '', ChildNode);
            AddElement(ReferenceInvoiceNode, 'DocumentTypeCode', 'İADE', '', ChildNode);
            AddElement(ReferenceInvoiceNode, 'DocumentType', 'İade Edilen Fatura', '', ChildNode);
        end;
        //Notes
        //AddElement(RootAsNode, 'Notes', '', '', NotesNode);
        RefLine.RESET;
        RefLine.SETRANGE("Header Entry No.", EInvHeader."Entry No.");
        RefLine.SETRANGE("Reference Type", RefLine."Reference Type"::Note);
        if RefLine.FINDSET then
            repeat
                AddElement(RootAsNode, 'Note', RefLine."Reference Text", '', ChildNode);
            until RefLine.NEXT = 0;

        if Queue.IntegrationType = Queue.IntegrationType::EArchive then
            AddElement(RootAsNode, 'Note', '!#ELEKTRONIK#', '', ChildNode);

        if EInvHeader.SalesType = EInvHeader.SalesType::Internet then begin
            EInvHeader.TESTFIELD(CustWebsiteURI);
            EInvHeader.TESTFIELD(PaymentMethodNote);
            IF EInvHeader.PaymentMethodNote = 'ODEMEARACISI' THEN
                EInvHeader.TESTFIELD(PaymentChannelCode);
            IF EInvHeader.PaymentMethodNote IN ['KREDIKARTI/BANKAKARTI', 'EFT/HAVALE', 'ODEMEARACISI'] THEN
                EInvHeader.TESTFIELD(PaymentDueDate);
            InfoTxt := '!#INTERNET#';
            InfoTxt := InfoTxt + '|' + EInvHeader.CustWebsiteURI;
            InfoTxt := InfoTxt + '|' + EInvHeader.PaymentMethodNote;
            IF EInvHeader.PaymentMethodNote = 'ODEMEARACISI' THEN
                InfoTxt := InfoTxt + '|' + EInvHeader.PaymentChannelCode
            ELSE
                InfoTxt := InfoTxt + '|';
            InfoTxt := InfoTxt + '|' + FORMAT(EInvHeader.PaymentDueDate, 0, '<Day,2>.<Month,2>.<Year4>');
            InfoTxt := InfoTxt + '|' + FORMAT(Library.ParseDatetime(Format(DespatchDate), 'YMD'), 0, '<Day,2>.<Month,2>.<Year4>');
            IF EInvHeader.IssueTime <> 0T THEN
                InfoTxt := InfoTxt + '|' + FORMAT(EInvHeader.IssueTime)
            ELSE
                InfoTxt := InfoTxt + '|' + '12:00:00';
            InfoTxt := InfoTxt + '|' + EInvHeader."Carrier RegistrationNo";
            InfoTxt := InfoTxt + '|' + EInvHeader."Carrier Name";
            InfoTxt := InfoTxt + '|';
            AddElement(RootAsNode, 'Note', InfoTxt, '', ChildNode);
        end;
    end;

    procedure CreateXMLDoc(IntegrationType: Option EInvoice,EArchive; ProfileID: Option " ",Commercial,Basic,EArchive,EExport; InvType: Option " ",Sales,SalesCr,Purch,PurchCr,Withholding,Exception,SpecificBase,Exported; _UUID: GUID; Preview: Boolean)
    var
        EInvHeader: Record "PRG_E-Invoice Header";
        EArch: Boolean;
    begin
        CLEAR(XMLdoc);

        EInvHeader.SETRANGE(Type, EInvHeader.Type::Outbox);
        EInvHeader.SETRANGE(UUID, _UUID);
        EInvHeader.FINDFIRST();
        EArch := IntegrationType = IntegrationType::EArchive;


        IF Preview then begin
            XmlDocument.ReadFrom('<?xml version="1.0" encoding="UTF-8"?>' +
            '<?xml-stylesheet type="text/xsl" href="general.xslt"?>' +
            '<Invoice xmlns="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2" ' +
            'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" ' +
            'xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2" ' +
            'xmlns:ext="urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2" ' +
            'xmlns:ds="http://www.w3.org/2000/09/xmldsig#" ' +
            'xmlns:xades="http://uri.etsi.org/01903/v1.3.2#" ' +
            'xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2" ' +
            'xsi:schemaLocation="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2 ..\xsdrt\maindoc\UBL-Invoice-2.1.xsd" ' +
            'xmlns:n4="http://www.altova.com/samplexml/other-namespace">' +
            '</Invoice>', XMLdoc);
        end else begin
            XmlDocument.ReadFrom('<?xml version="1.0" encoding="UTF-8"?>' +
            '<?xml-stylesheet type="text/xsl" href="' + Library.FormatGUID(_UUID) + '.xslt"?>' +
            '<Invoice xmlns="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2" ' +
            'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" ' +
            'xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2" ' +
            'xmlns:ext="urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2" ' +
            'xmlns:ds="http://www.w3.org/2000/09/xmldsig#" ' +
            'xmlns:xades="http://uri.etsi.org/01903/v1.3.2#" ' +
            'xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2" ' +
            'xsi:schemaLocation="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2 ..\xsdrt\maindoc\UBL-Invoice-2.1.xsd" ' +
            'xmlns:n4="http://www.altova.com/samplexml/other-namespace">' +
            '</Invoice>', XMLdoc);
        end;

        OnAfterCreateXmlDoc(XMLdoc);

    END;

    local procedure CreateOrderNodes(OrderNo: Text[30]; OrderDate: Date)
    var
        OrderReference: XmlNode;
    begin
        if (OrderNo <> '') and (OrderDate <> 0D) then begin
            ActiveNode := RootNode.AsXmlNode();
            AddElement(ActiveNode, 'OrderReference', '', NamespaceURI_CAC, OrderReference);
            AddElement(OrderReference, 'ID', OrderNo, NamespaceURI_CBC, CurrNode);
            AddElement(OrderReference, 'IssueDate', Library.FormatDate(OrderDate), NamespaceURI_CBC, CurrNode);
        end;
    end;

    local procedure CreateDespatchNodes(EntryNo: Integer)
    var
        ReferenceBuffer: Record "PRG_E-Invoice Reference Buffer";
        DespatchDocumentReference: XmlNode;
    begin

        ActiveNode := RootNode.AsXmlNode();

        ReferenceBuffer.SETRANGE("Header Entry No.", EntryNo);
        ReferenceBuffer.SETRANGE("Reference Type", ReferenceBuffer."Reference Type"::Despatch);
        ReferenceBuffer.SETFILTER("Reference Text", '<>%1', '');
        ReferenceBuffer.SETFILTER("Reference Date", '<>%1', 0D);
        IF NOT ReferenceBuffer.FINDFIRST() THEN
            EXIT;

        REPEAT

            AddElement(ActiveNode, 'DespatchDocumentReference', '', NamespaceURI_CAC, DespatchDocumentReference);
            AddElement(DespatchDocumentReference, 'ID', ReferenceBuffer."Reference Text", NamespaceURI_CBC, CurrNode);
            AddElement(DespatchDocumentReference, 'IssueDate', Library.FormatDate(ReferenceBuffer."Reference Date"), NamespaceURI_CBC, CurrNode);

        UNTIL ReferenceBuffer.NEXT() = 0;
    end;

    local procedure CreateInvoiceNotes(EntryNo: Integer)
    var
        ReferenceBuffer: Record "PRG_E-Invoice Reference Buffer";
    begin

        ActiveNode := RootNode.AsXmlNode();

        ReferenceBuffer.SETRANGE("Header Entry No.", EntryNo);
        ReferenceBuffer.SETRANGE("Reference Type", ReferenceBuffer."Reference Type"::Note);
        ReferenceBuffer.SETRANGE("Source Type", ReferenceBuffer."Source Type"::Header);
        ReferenceBuffer.SETRANGE("Source Line No.", 0);
        ReferenceBuffer.SETFILTER("Reference Text", '<>%1', '');
        IF NOT ReferenceBuffer.FINDFIRST() THEN
            EXIT;

        REPEAT

            AddElement(ActiveNode, 'Note', ReferenceBuffer."Reference Text", NamespaceURI_CBC, CurrNode);

        UNTIL ReferenceBuffer.NEXT() = 0;
    end;

    local procedure CreateInvoiceTaxNodes(var Queue: Record "PRG_E-Invoice Queue"; var EInvHeader: Record "PRG_E-Invoice Header")
    var
        TaxLine: Record "PRG_E-Invoice Tax Line";
        TotalTaxLine: Record "PRG_E-Invoice Tax Line";
        TotalTaxAmt: Decimal;
        TaxCategory: XmlNode;
        TaxScheme: XmlNode;
        TaxSubtotal: XmlNode;
        TaxTotal: XmlNode;
    begin
        TaxLine.SETRANGE("Header Entry No.", EInvHeader."Entry No.");
        TaxLine.SETRANGE(Type, TaxLine.Type::Header);
        TaxLine.SETFILTER(TaxType, '<>%1', TaxLine.TaxType::Witholding);
        IF NOT TaxLine.FINDFIRST() THEN
            EXIT;

        TotalTaxLine.SETRANGE("Header Entry No.", EInvHeader."Entry No.");
        TotalTaxLine.SETRANGE(Type, TotalTaxLine.Type::Header);
        TotalTaxLine.SETFILTER(TaxType, '<>%1', TotalTaxLine.TaxType::Witholding);
        TotalTaxLine.CALCSUMS(TaxAmount);
        TotalTaxAmt := TotalTaxLine.TaxAmount;

        ActiveNode := RootNode.AsXmlNode();

        //Tax Total
        AddElement(ActiveNode, 'TaxTotal', '', NamespaceURI_CAC, TaxTotal);

        AddElement(TaxTotal, 'TaxAmount', Library.FormatDec2Places(TotalTaxAmt), NamespaceURI_CBC, CurrNode);
        AddAttribute(CurrNode, 'currencyID', GetFunctionValue(4, Queue));

        //Sub Tax Totals
        REPEAT

            AddElement(TaxTotal, 'TaxSubtotal', '', NamespaceURI_CAC, TaxSubtotal);
            AddElement(TaxSubtotal, 'TaxableAmount', Library.FormatDec2Places(TaxLine.TaxExclusiveAmount), NamespaceURI_CBC, CurrNode);
            AddAttribute(CurrNode, 'currencyID', GetFunctionValue(4, Queue));
            AddElement(TaxSubtotal, 'TaxAmount', Library.FormatDec2Places(TaxLine.TaxAmount), NamespaceURI_CBC, CurrNode);
            AddAttribute(CurrNode, 'currencyID', GetFunctionValue(4, Queue));
            AddElement(TaxSubtotal, 'CalculationSequenceNumeric', FORMAT(TaxLine.CalculationSequenceNumeric), NamespaceURI_CBC, CurrNode);
            AddElement(TaxSubtotal, 'Percent', Library.FormatDec2Places(TaxLine.TaxPercent), NamespaceURI_CBC, CurrNode);
            AddElement(TaxSubtotal, 'TaxCategory', '', NamespaceURI_CAC, TaxCategory);

            IF (TaxLine."TaxExemption Reason Code" <> '') AND (TaxLine."TaxExemption Reason Desc" <> '') THEN BEGIN
                AddElement(TaxCategory, 'TaxExemptionReasonCode', TaxLine."TaxExemption Reason Code", NamespaceURI_CBC, CurrNode);
                AddElement(TaxCategory, 'TaxExemptionReason', TaxLine."TaxExemption Reason Desc", NamespaceURI_CBC, CurrNode);
            END;

            AddElement(TaxCategory, 'TaxScheme', '', NamespaceURI_CAC, TaxScheme);
            AddElement(TaxScheme, 'Name', TaxLine.TaxTypeName, NamespaceURI_CBC, CurrNode);
            AddElement(TaxScheme, 'TaxTypeCode', TaxLine.TaxTypeCode, NamespaceURI_CBC, CurrNode);

            OnAfterCreateHeaderTaxNode(TaxTotal, TaxSubtotal, TaxScheme, TaxCategory);

        UNTIL TaxLine.NEXT() = 0;
    end;

    local procedure CreateInvoiceWitholdingTaxNodes(var Queue: Record "PRG_E-Invoice Queue"; var EInvHeader: Record "PRG_E-Invoice Header")
    var
        TaxLine: Record "PRG_E-Invoice Tax Line";
        TotalTaxLine: Record "PRG_E-Invoice Tax Line";
        TotalTaxAmt: Decimal;
        RootaAsNode: XmlNode;
        TaxCategory: XmlNode;
        TaxScheme: XmlNode;
        TaxSubtotal: XmlNode;
        WithholdingTaxTotal: XmlNode;
    begin
        TaxLine.SETRANGE("Header Entry No.", EInvHeader."Entry No.");
        TaxLine.SETRANGE(Type, TaxLine.Type::Header);
        TaxLine.SETRANGE(TaxType, TaxLine.TaxType::Witholding);
        IF NOT TaxLine.FINDFIRST() THEN
            EXIT;

        TotalTaxLine.SETRANGE("Header Entry No.", EInvHeader."Entry No.");
        TotalTaxLine.SETRANGE(Type, TotalTaxLine.Type::Header);
        TotalTaxLine.SETRANGE(TaxType, TotalTaxLine.TaxType::Witholding);
        TotalTaxLine.CALCSUMS(TaxAmount);
        TotalTaxAmt := TotalTaxLine.TaxAmount;

        RootaAsNode := RootNode.AsXmlNode();

        //Tax Total
        AddElement(RootaAsNode, 'WithholdingTaxTotal', '', NamespaceURI_CAC, WithholdingTaxTotal);

        AddElement(WithholdingTaxTotal, 'TaxAmount', Library.FormatDec2Places(TotalTaxAmt), NamespaceURI_CBC, CurrNode);
        AddAttribute(CurrNode, 'currencyID', GetFunctionValue(4, Queue));

        //Sub Tax Totals
        REPEAT

            AddElement(WithholdingTaxTotal, 'TaxSubtotal', '', NamespaceURI_CAC, TaxSubtotal);

            AddElement(TaxSubtotal, 'TaxableAmount', Library.FormatDec2Places(TaxLine.TaxExclusiveAmount), NamespaceURI_CBC, CurrNode);
            AddAttribute(CurrNode, 'currencyID', GetFunctionValue(4, Queue));

            AddElement(TaxSubtotal, 'TaxAmount', Library.FormatDec2Places(TaxLine.TaxAmount), NamespaceURI_CBC, CurrNode);
            AddAttribute(CurrNode, 'currencyID', GetFunctionValue(4, Queue));

            AddElement(TaxSubtotal, 'Percent', Library.FormatDec2Places(TaxLine.TaxPercent), NamespaceURI_CBC, CurrNode);

            AddElement(TaxSubtotal, 'TaxCategory', '', NamespaceURI_CAC, TaxCategory);

            AddElement(TaxCategory, 'TaxScheme', '', NamespaceURI_CAC, TaxScheme);

            AddElement(TaxScheme, 'Name', TaxLine.TaxTypeName, NamespaceURI_CBC, CurrNode);

            AddElement(TaxScheme, 'TaxTypeCode', TaxLine.TaxTypeCode, NamespaceURI_CBC, CurrNode);

            OnAfterCreateHeaderWitholdingTaxNode(WithholdingTaxTotal, TaxSubtotal, TaxScheme, TaxCategory);

        UNTIL TaxLine.NEXT() = 0;
    end;

    local procedure CreateLegalMonetaryTotalNodes(var Queue: Record "PRG_E-Invoice Queue"; var EInvHeader: Record "PRG_E-Invoice Header")
    var
        LegalMonetaryTotal: XmlNode;
    begin

        EInvHeader.CALCFIELDS(LineExtensionAmount, TaxExclusiveAmount, TaxInclusiveAmount);

        ActiveNode := RootNode.AsXmlNode();
        AddElement(ActiveNode, 'LegalMonetaryTotal', '', NamespaceURI_CAC, LegalMonetaryTotal);
        AddElement(LegalMonetaryTotal, 'LineExtensionAmount', Library.FormatDec2Places(EInvHeader.LineExtensionAmount), NamespaceURI_CBC, CurrNode);
        AddAttribute(CurrNode, 'currencyID', GetFunctionValue(4, Queue));
        AddElement(LegalMonetaryTotal, 'TaxExclusiveAmount', Library.FormatDec2Places(EInvHeader.TaxExclusiveAmount), NamespaceURI_CBC, CurrNode);
        AddAttribute(CurrNode, 'currencyID', GetFunctionValue(4, Queue));
        AddElement(LegalMonetaryTotal, 'TaxInclusiveAmount', Library.FormatDec2Places(EInvHeader.TaxInclusiveAmount), NamespaceURI_CBC, CurrNode);
        AddAttribute(CurrNode, 'currencyID', GetFunctionValue(4, Queue));
        AddElement(LegalMonetaryTotal, 'AllowanceTotalAmount', Library.FormatDec2Places(EInvHeader.AllowanceChargeAmtInvoice), NamespaceURI_CBC, CurrNode);
        AddAttribute(CurrNode, 'currencyID', GetFunctionValue(4, Queue));
        AddElement(LegalMonetaryTotal, 'PayableAmount', Library.FormatDec2Places(EInvHeader.PayableAmount), NamespaceURI_CBC, CurrNode);
        AddAttribute(CurrNode, 'currencyID', GetFunctionValue(4, Queue));

        OnAfterCreateLegalMonetaryTotalNode(LegalMonetaryTotal);

    end;

    local procedure CreateRootNode()
    begin
        XMLdoc.GetRoot(RootNode);
    end;

    local procedure GetEInvSetup(): Boolean
    begin
        if not EInvGot then begin
            if not EInvSetup.Get() then
                exit(false);
            EInvGot := true;
        end;

        exit(true);
    end;

    local procedure GetExportSetup()
    begin
        IF NOT GotExportSetup THEN BEGIN
            if EExportSetup.GET() then
                GotExportSetup := TRUE;
        END;
    end;

    local procedure GetFunctionValue(FunctionNo: Integer; var Queue: Record "PRG_E-Invoice Queue"): Text
    var
        EInvHeader: Record "PRG_E-Invoice Header";
        IsHandled: Boolean;
        CustomValue: Text;
    begin

        OnBeforeGetFunctionValue(FunctionNo, Queue, CustomValue, IsHandled);
        if IsHandled then
            exit(CustomValue);

        CASE FunctionNo OF

            1:
                EXIT('#Signature_' + Queue.InvoiceID);

            2:
                CASE Queue.ProfileID OF
                    Queue.ProfileID::Basic:
                        EXIT('TEMELFATURA');
                    Queue.ProfileID::Commercial:
                        EXIT('TICARIFATURA');
                    Queue.ProfileID::EArchive:
                        EXIT('EARSIVFATURA');
                    Queue.ProfileID::EExport:
                        EXIT('IHRACAT');
                    Queue.ProfileID::Medical:
                        EXIT('ILAC_TIBBICIHAZ');
                END;

            3:
                CASE Queue.InvoiceType OF
                    Queue.InvoiceType::Sales:
                        EXIT('SATIS');
                    Queue.InvoiceType::PurchCr:
                        EXIT('IADE');
                    Queue.InvoiceType::Withholding:
                        EXIT('TEVKIFAT');
                    Queue.InvoiceType::Exception:
                        EXIT('ISTISNA');
                    Queue.InvoiceType::SpecificBase:
                        EXIT('OZELMATRAH');
                    Queue.InvoiceType::Exported:
                        EXIT('IHRACKAYITLI');
                    ELSE
                        ERROR(Text005, 3);
                END;

            4:
                BEGIN
                    EInvHeader.SETRANGE(UUID, Queue.UniqueIdentifier);
                    EInvHeader.FINDFIRST();
                    EXIT(EInvHeader.DocumentCurrencyCode);
                END;

            7:
                EXIT(Library.FormatGUID(CREATEGUID()));

            8:
                EXIT(Library.FormatDate(Queue.IssueDate));

            ELSE
                EXIT(Text002);
        END;
    end;

    local procedure XmlPhase1(var Queue: Record "PRG_E-Invoice Queue"; var EInvHeader: Record "PRG_E-Invoice Header")
    var
        OrderReferenceNode: XmlNode;
        RootAsNode: Xmlnode;
        BillingReferenceNode: XmlNode;
        InvoiceDocumentReferenceNode: XmlNode;
        OrderNo: Text[30];
        OrderDate: Date;
        Customer: Record "Customer";
    begin

        EInvHeader.CalcFields("Line Count");

        RootAsNode := RootNode.AsXmlNode();
        AddElement(RootAsNode, 'UBLVersionID', EInvSetup."UBL Version ID", NamespaceURI_CBC, ChildNode);
        AddElement(RootAsNode, 'CustomizationID', EInvSetup."Customisation ID", NamespaceURI_CBC, ChildNode);
        IF Customer.get(EInvHeader.CustNo) then;
        IF Customer."PRG_Payee Firm" then
            AddElement(RootAsNode, 'ProfileID', 'KAMU', NamespaceURI_CBC, ChildNode)
        else
            AddElement(RootAsNode, 'ProfileID', GetFunctionValue(2, Queue), NamespaceURI_CBC, ChildNode);
        AddElement(RootAsNode, 'ID', Queue."InvoiceID", NamespaceURI_CBC, ChildNode);
        AddElement(RootAsNode, 'CopyIndicator', 'false', NamespaceURI_CBC, ChildNode);
        AddElement(RootAsNode, 'UUID', Library.FormatGUID(Queue.UniqueIdentifier), NamespaceURI_CBC, ChildNode);
        AddElement(RootAsNode, 'IssueDate', Library.FormatDate(EInvHeader.IssueDate), NamespaceURI_CBC, ChildNode);
        AddElement(RootAsNode, 'IssueTime', Library.FormatTime(EInvHeader.IssueTime), NamespaceURI_CBC, ChildNode);
        AddElement(RootAsNode, 'InvoiceTypeCode', GetFunctionValue(3, Queue), NamespaceURI_CBC, ChildNode);

        OnBeforeCreateInvoiceNotes(RootAsNode);

        CreateInvoiceNotes(EInvHeader."Entry No.");

        AddElement(RootAsNode, 'DocumentCurrencyCode', Format(EInvHeader.DocumentCurrencyCode), NamespaceURI_CBC, ChildNode);
        AddElement(RootAsNode, 'LineCountNumeric', Format(EInvHeader."Line Count"), NamespaceURI_CBC, ChildNode);

        //RootAsNode := ChildNode;

        if EInvHeader.InvoiceType = EInvHeader.InvoiceType::PurchCr then begin
            AddElement(RootAsNode, 'BillingReference', '', NamespaceURI_CAC, BillingReferenceNode);
            AddElement(BillingReferenceNode, 'InvoiceDocumentReference', '', NamespaceURI_CAC, InvoiceDocumentReferenceNode);

            AddElement(InvoiceDocumentReferenceNode, 'ID', EInvHeader."Related Invoice No.", NamespaceURI_CBC, ChildNode);
            AddElement(InvoiceDocumentReferenceNode, 'IssueDate', Library.FormatDate(EInvHeader."Related Invoice Date"), NamespaceURI_CBC, ChildNode);
            AddElement(InvoiceDocumentReferenceNode, 'DocumentTypeCode', 'IADE', NamespaceURI_CBC, ChildNode);
            AddElement(InvoiceDocumentReferenceNode, 'DocumentType', 'Fatura', NamespaceURI_CBC, ChildNode);
        end;

        //RootAsNode := BillingReferenceNode;

        OrderNo := EInvHeader.OrderNo;
        OrderDate := EInvHeader.OrderDate;

        OnBeforeInsertOrderReferenceXML(OrderNo, OrderDate, EInvHeader);

        CreateOrderNodes(OrderNo, OrderDate);

        OnBeforeCreateDespatchNodes(RootAsNode);

        CreateDespatchNodes(EInvHeader."Entry No.");

        OnAfterCreateDespatchNodes(RootAsNode);
    end;

    local procedure XmlPhase2(var Queue: Record "PRG_E-Invoice Queue"; var EInvHeader: Record "PRG_E-Invoice Header")
    var
        Country: XmlNode;
        DigitalSignatureAttachment: XmlNode;
        ExternalReference: XmlNode;
        PartyIdentification: XmlNode;
        PostalAddress: XmlNode;
        SignatoryParty: XmlNode;
        SignatureNode: XmlNode;
    begin

        ActiveNode := RootNode.AsXmlNode();
        AddElement(ActiveNode, 'Signature', '', NamespaceURI_CAC, SignatureNode);
        AddElement(SignatureNode, 'ID', EInvSetup."Supplier Tax Registration No.", NamespaceURI_CBC, ChildNode);
        AddAttribute(ChildNode, 'schemeID', 'VKN_TCKN');
        AddElement(SignatureNode, 'SignatoryParty', '', NamespaceURI_CAC, SignatoryParty);
        AddElement(SignatoryParty, 'PartyIdentification', '', NamespaceURI_CAC, PartyIdentification);
        AddElement(PartyIdentification, 'ID', EInvSetup."Supplier Tax Registration No.", NamespaceURI_CBC, ChildNode);
        AddAttribute(ChildNode, 'schemeID', EInvSetup.RegistrationNoType);
        AddElement(SignatoryParty, 'PostalAddress', '', NamespaceURI_CAC, PostalAddress);
        AddElement(PostalAddress, 'StreetName', EInvSetup."Supplier Address", NamespaceURI_CBC, ChildNode);
        AddElement(PostalAddress, 'CitySubdivisionName', EInvSetup."Supplier City Subdivision Name", NamespaceURI_CBC, ChildNode);
        AddElement(PostalAddress, 'CityName', EInvSetup."Supplier City Name", NamespaceURI_CBC, ChildNode);
        AddElement(PostalAddress, 'Country', '', NamespaceURI_CAC, Country);
        AddElement(Country, 'Name', EInvSetup."Supplier Country", NamespaceURI_CBC, ChildNode);
        AddElement(SignatureNode, 'DigitalSignatureAttachment', '', NamespaceURI_CAC, DigitalSignatureAttachment);
        AddElement(DigitalSignatureAttachment, 'ExternalReference', '', NamespaceURI_CAC, ExternalReference);
        AddElement(ExternalReference, 'URI', '#Signature_' + Queue.InvoiceID, NamespaceURI_CBC, ChildNode);

        OnAfterXmlPhase2(ActiveNode);

    end;

    local procedure XmlPhase3(var Queue: Record "PRG_E-Invoice Queue"; var EInvHeader: Record "PRG_E-Invoice Header")
    var
        AccountingSupplierParty: XmlNode;
        Contact: XmlNode;
        Country: XmlNode;
        MERSISPartyIdentification: XmlNode;
        Party: XmlNode;
        PartyName: XmlNode;
        PartyTaxScheme: XmlNode;
        PostalAddress: XmlNode;
        TaxScheme: XmlNode;
        TICARETSICILNOPartyIdentification: XmlNode;
        VKNPartyIdentification: XmlNode;
    begin
        ActiveNode := RootNode.AsXmlNode();

        AddElement(ActiveNode, 'AccountingSupplierParty', '', NamespaceURI_CAC, AccountingSupplierParty);
        AddElement(AccountingSupplierParty, 'Party', '', NamespaceURI_CAC, Party);
        IF EInvSetup."Supplier Web Address" <> '' THEN
            AddElement(Party, 'WebsiteURI', EInvSetup."Supplier Web Address", NamespaceURI_CBC, ChildNode);

        AddElement(Party, 'PartyIdentification', '', NamespaceURI_CAC, VKNPartyIdentification);
        AddElement(VKNPartyIdentification, 'ID', EInvSetup."Supplier Tax Registration No.", NamespaceURI_CBC, CurrNode);
        AddAttribute(CurrNode, 'schemeID', EInvSetup.RegistrationNoType);

        IF EInvSetup."Supplier Trade Register No." <> '' then begin
            AddElement(Party, 'PartyIdentification', '', NamespaceURI_CAC, TICARETSICILNOPartyIdentification);
            AddElement(TICARETSICILNOPartyIdentification, 'ID', EInvSetup."Supplier Trade Register No.", NamespaceURI_CBC, CurrNode);
            AddAttribute(CurrNode, 'schemeID', 'TICARETSICILNO');
        end;

        IF EInvSetup."Supplier Mersis No." <> '' then begin
            AddElement(Party, 'PartyIdentification', '', NamespaceURI_CAC, MERSISPartyIdentification);
            AddElement(MERSISPartyIdentification, 'ID', EInvSetup."Supplier Mersis No.", NamespaceURI_CBC, CurrNode);
            AddAttribute(CurrNode, 'schemeID', 'MERSISNO');
        end;

        OnAfterPartyIdentification_AccountingSupplierParty(Party, AccountingSupplierParty, Queue, EInvHeader);

        AddElement(Party, 'PartyName', '', NamespaceURI_CAC, PartyName);
        AddElement(PartyName, 'Name', EInvSetup."Supplier Party Name", NamespaceURI_CBC, CurrNode);
        AddElement(Party, 'PostalAddress', '', NamespaceURI_CAC, PostalAddress);
        IF EInvSetup."Supplier Address" <> '' THEN BEGIN
            AddElement(PostalAddress, 'StreetName', EInvSetup."Supplier Address", NamespaceURI_CBC, CurrNode);
        END;
        AddElement(PostalAddress, 'CitySubdivisionName', EInvSetup."Supplier City Subdivision Name", NamespaceURI_CBC, CurrNode);
        AddElement(PostalAddress, 'CityName', EInvSetup."Supplier City Name", NamespaceURI_CBC, CurrNode);
        AddElement(PostalAddress, 'Country', '', NamespaceURI_CAC, Country);
        AddElement(Country, 'Name', EInvSetup."Supplier Country", NamespaceURI_CBC, CurrNode);
        AddElement(Party, 'PartyTaxScheme', '', NamespaceURI_CAC, PartyTaxScheme);
        AddElement(PartyTaxScheme, 'TaxScheme', '', NamespaceURI_CAC, TaxScheme);
        AddElement(TaxScheme, 'Name', EInvSetup."Supplier Party Tax Scheme", NamespaceURI_CBC, CurrNode);
        IF (EInvSetup."Supplier Phone" <> '') OR (EInvSetup."Supplier Fax No." <> '') OR (EInvSetup."Supplier E-mail" <> '') THEN BEGIN
            AddElement(Party, 'Contact', '', NamespaceURI_CAC, Contact);
            IF EInvSetup."Supplier Phone" <> '' THEN BEGIN
                AddElement(Contact, 'Telephone', EInvSetup."Supplier Phone", NamespaceURI_CBC, CurrNode);
            END;
            IF EInvSetup."Supplier Fax No." <> '' THEN BEGIN
                AddElement(Contact, 'Telefax', EInvSetup."Supplier Fax No.", NamespaceURI_CBC, CurrNode);
            END;
            IF EInvSetup."Supplier E-mail" <> '' THEN BEGIN
                AddElement(Contact, 'ElectronicMail', EInvSetup."Supplier E-mail", NamespaceURI_CBC, CurrNode);
            END;
        END;

        OnAfterXmlPhase3(ActiveNode, AccountingSupplierParty);
    end;

    local procedure XmlPhase4_Export(var Queue: Record "PRG_E-Invoice Queue"; var EInvHeader: Record "PRG_E-Invoice Header")
    var
        AccountingCustomerParty: XmlNode;
        BuyerCustomerParty: XmlNode;
        Contact: XmlNode;
        Country: XmlNode;
        CustomerContact: XmlNode;
        CustomerCountry: XmlNode;
        CustomerParty: XmlNode;
        CustomerPartyIdentification: XmlNode;
        CustomerPartyLegalEntity: XmlNode;
        CustomerPartyName: XmlNode;
        CustomerPartyTaxScheme: XmlNode;
        CustomerPerson: XmlNode;
        CustomerPostalAddress: XmlNode;
        CustomerTaxScheme: XmlNode;
        Party: XmlNode;
        PartyIdentification: XmlNode;
        PartyName: XmlNode;
        PostalAddress: XmlNode;
    begin

        ActiveNode := RootNode.AsXmlNode();

        //Ministry Information
        AddElement(ActiveNode, 'AccountingCustomerParty', '', NamespaceURI_CAC, AccountingCustomerParty);

        AddElement(AccountingCustomerParty, 'Party', '', NamespaceURI_CAC, Party);

        IF EExportSetup."Ministry Web Adress" <> '' THEN
            AddElement(Party, 'WebsiteURI', EExportSetup."Ministry Web Adress", NamespaceURI_CBC, CurrNode);

        AddElement(Party, 'PartyIdentification', '', NamespaceURI_CAC, PartyIdentification);

        AddElement(PartyIdentification, 'ID', EExportSetup."Ministry VKN", NamespaceURI_CBC, CurrNode);
        AddAttribute(CurrNode, 'schemeID', EExportSetup."Ministry Party Tax Scheme");

        AddElement(Party, 'PartyName', '', NamespaceURI_CAC, PartyName);
        AddElement(PartyName, 'Name', EExportSetup."Ministry Party Name", NamespaceURI_CBC, CurrNode);

        AddElement(Party, 'PostalAddress', '', NamespaceURI_CAC, PostalAddress);

        IF EExportSetup."Ministry Adress" <> '' THEN
            AddElement(PostalAddress, 'StreetName', EExportSetup."Ministry Adress", NamespaceURI_CBC, CurrNode);

        IF EExportSetup."Ministry Building Number" <> '' THEN
            AddElement(PostalAddress, 'BuildingName', EExportSetup."Ministry Building Number", NamespaceURI_CBC, CurrNode);

        IF EExportSetup."Ministry Building Number" <> '' THEN
            AddElement(PostalAddress, 'BuildingNumber', EExportSetup."Ministry Building Number", NamespaceURI_CBC, CurrNode);

        AddElement(PostalAddress, 'CitySubdivisionName', EExportSetup."Ministry City Subdivision Name", NamespaceURI_CBC, CurrNode);

        AddElement(PostalAddress, 'CityName', EExportSetup."Ministry CityName", NamespaceURI_CBC, CurrNode);
        //PostalAddress := CurrNode;

        IF EExportSetup."Ministry PostalZone" <> '' THEN
            AddElement(PostalAddress, 'PostalZone', EExportSetup."Ministry PostalZone", NamespaceURI_CBC, CurrNode);

        AddElement(PostalAddress, 'Country', '', NamespaceURI_CAC, Country);
        AddElement(Country, 'Name', EExportSetup."Ministry CountryName", NamespaceURI_CBC, CurrNode);

        IF (EExportSetup."Ministry Telephone" <> '') OR (EExportSetup."Ministry Telefax" <> '') OR (EExportSetup."Ministry Mail Adress" <> '') THEN BEGIN
            AddElement(Party, 'Contact', '', NamespaceURI_CAC, Contact);

            IF EExportSetup."Ministry Telephone" <> '' THEN
                AddElement(Contact, 'Telephone', EExportSetup."Ministry Telephone", NamespaceURI_CBC, CurrNode);

            IF EExportSetup."Ministry Telefax" <> '' THEN
                AddElement(Contact, 'Telefax', EExportSetup."Ministry Telefax", NamespaceURI_CBC, CurrNode);

            IF EExportSetup."Ministry Mail Adress" <> '' THEN
                AddElement(Contact, 'ElectronicMail', EExportSetup."Ministry Mail Adress", NamespaceURI_CBC, CurrNode);
        END;

        OnAfterPartyIdentification_AccountingCustomerParty(Party, AccountingCustomerParty, Queue, EInvHeader);

        //Customer Information
        ActiveNode := RootNode.AsXmlNode();
        AddElement(ActiveNode, 'BuyerCustomerParty', '', NamespaceURI_CAC, BuyerCustomerParty);

        AddElement(BuyerCustomerParty, 'Party', '', NamespaceURI_CAC, CustomerParty);

        IF EInvHeader.CustWebsiteURI <> '' THEN
            AddElement(CustomerParty, 'WebsiteURI', EInvHeader.CustWebsiteURI, NamespaceURI_CBC, CurrNode);

        AddElement(CustomerParty, 'PartyIdentification', '', NamespaceURI_CAC, CustomerPartyIdentification);
        AddElement(CustomerPartyIdentification, 'ID', 'EXPORT', NamespaceURI_CBC, CurrNode);
        AddAttribute(CurrNode, 'schemeID', 'PARTYTYPE');

        AddElement(CustomerParty, 'PartyName', '', NamespaceURI_CAC, CustomerPartyName);
        AddElement(CustomerPartyName, 'Name', EInvHeader.CustName, NamespaceURI_CBC, CurrNode);

        AddElement(CustomerParty, 'PostalAddress', '', NamespaceURI_CAC, CustomerPostalAddress);

        IF EInvHeader.CustStreetName <> '' THEN
            AddElement(CustomerPostalAddress, 'StreetName', EInvHeader.CustStreetName, NamespaceURI_CBC, CurrNode);

        IF EInvHeader.CustBuildingNumber <> '' THEN
            AddElement(CustomerPostalAddress, 'BuildingNumber', EInvHeader.CustBuildingNumber, NamespaceURI_CBC, CurrNode);

        AddElement(CustomerPostalAddress, 'CitySubdivisionName', EInvHeader.CustCitySubdivisionName, NamespaceURI_CBC, CurrNode);
        AddElement(CustomerPostalAddress, 'CityName', EInvHeader.CustCityName, NamespaceURI_CBC, CurrNode);

        IF EInvHeader.CustPostalZone <> '' THEN
            AddElement(CustomerPostalAddress, 'PostalZone', EInvHeader.CustPostalZone, NamespaceURI_CBC, CurrNode);

        AddElement(CustomerPostalAddress, 'Country', '', NamespaceURI_CAC, CustomerCountry);
        AddElement(CustomerCountry, 'Name', EInvHeader.CustCountryName, NamespaceURI_CBC, CurrNode);

        AddElement(CustomerParty, 'PartyTaxScheme', '', NamespaceURI_CAC, CustomerPartyTaxScheme);
        AddElement(CustomerPartyTaxScheme, 'TaxScheme', '', NamespaceURI_CAC, CustomerTaxScheme);
        AddElement(CustomerTaxScheme, 'Name', EInvHeader.CustTaxOfficeName, NamespaceURI_CBC, CurrNode);

        AddElement(CustomerParty, 'PartyLegalEntity', '', NamespaceURI_CAC, CustomerPartyLegalEntity);
        AddElement(CustomerPartyLegalEntity, 'RegistrationName', EInvHeader.CustName, NamespaceURI_CBC, CurrNode);

        IF EInvHeader."Company ID" <> '' THEN
            AddElement(CustomerPartyLegalEntity, 'CompanyID', EInvHeader."Company ID", NamespaceURI_CBC, CurrNode);

        IF (EInvHeader.CustTelephone <> '') OR (EInvHeader.CustTelefax <> '') OR (EInvHeader.CustElectronicMail <> '') THEN BEGIN

            AddElement(CustomerParty, 'Contact', '', NamespaceURI_CAC, CustomerContact);

            IF EInvHeader.CustTelephone <> '' THEN
                AddElement(CustomerContact, 'Telephone', EInvHeader.CustTelephone, NamespaceURI_CBC, CurrNode);

            IF EInvHeader.CustTelefax <> '' THEN
                AddElement(CustomerContact, 'Telefax', EInvHeader.CustTelefax, NamespaceURI_CBC, CurrNode);

            IF EInvHeader.CustElectronicMail <> '' THEN
                AddElement(CustomerContact, 'ElectronicMail', EInvHeader.CustElectronicMail, NamespaceURI_CBC, CurrNode);

        END;

        IF (EInvHeader.CustFirstName <> '') AND (EInvHeader.CustFamilyName <> '') THEN BEGIN

            AddElement(CustomerParty, 'Person', '', NamespaceURI_CAC, CustomerPerson);
            AddElement(CustomerPerson, 'FirstName', EInvHeader.CustFirstName, NamespaceURI_CBC, CurrNode);
            AddElement(CustomerPerson, 'FamilyName', EInvHeader.CustFamilyName, NamespaceURI_CBC, CurrNode);

        END;

        OnAfterXmlPhase4_Export(ActiveNode, AccountingCustomerParty);

    end;

    local procedure XmlPhase4_Standard(var Queue: Record "PRG_E-Invoice Queue"; var EInvHeader: Record "PRG_E-Invoice Header")
    var
        AccountingCustomerParty: XmlNode;
        Contact: XmlNode;
        Country: XmlNode;
        Party: XmlNode;
        PartyIdentification: XmlNode;
        PartyName: XmlNode;
        PartyTaxScheme: XmlNode;
        Person: XmlNode;
        PostalAddress: XmlNode;
        TaxScheme: XmlNode;
        BuyerCustomerParty: XmlNode;
    begin

        ActiveNode := RootNode.AsXmlNode();

        AddElement(ActiveNode, 'AccountingCustomerParty', '', NamespaceURI_CAC, AccountingCustomerParty);
        AddElement(AccountingCustomerParty, 'Party', '', NamespaceURI_CAC, Party);

        IF EInvHeader.CustWebsiteURI <> '' THEN BEGIN
            AddElement(Party, 'WebsiteURI', EInvHeader.CustWebsiteURI, NamespaceURI_CBC, CurrNode);
        END;

        AddElement(Party, 'PartyIdentification', '', NamespaceURI_CAC, PartyIdentification);
        AddElement(PartyIdentification, 'ID', EInvHeader.CustRegistrationNo, NamespaceURI_CBC, CurrNode);
        AddAttribute(CurrNode, 'schemeID', EInvHeader.CustTaxSchemeID);
        AddElement(Party, 'PartyName', '', NamespaceURI_CAC, PartyName);
        AddElement(PartyName, 'Name', EInvHeader.CustName, NamespaceURI_CBC, CurrNode);
        AddElement(Party, 'PostalAddress', '', NamespaceURI_CAC, PostalAddress);

        IF EInvHeader.CustStreetName <> '' THEN
            AddElement(PostalAddress, 'StreetName', EInvHeader.CustStreetName, NamespaceURI_CBC, CurrNode);

        IF EInvHeader.CustBuildingNumber <> '' THEN
            AddElement(PostalAddress, 'BuildingNumber', EInvHeader.CustBuildingNumber, NamespaceURI_CBC, CurrNode);

        AddElement(PostalAddress, 'CitySubdivisionName', EInvHeader.CustCitySubdivisionName, NamespaceURI_CBC, CurrNode);
        AddElement(PostalAddress, 'CityName', EInvHeader.CustCityName, NamespaceURI_CBC, CurrNode);

        IF EInvHeader.CustPostalZone <> '' THEN
            AddElement(PostalAddress, 'PostalZone', EInvHeader.CustPostalZone, NamespaceURI_CBC, CurrNode);

        AddElement(PostalAddress, 'Country', '', NamespaceURI_CAC, Country);
        AddElement(Country, 'Name', EInvHeader.CustCountryName, NamespaceURI_CBC, CurrNode);

        AddElement(Party, 'PartyTaxScheme', '', NamespaceURI_CAC, PartyTaxScheme);
        AddElement(PartyTaxScheme, 'TaxScheme', '', NamespaceURI_CAC, TaxScheme);
        AddElement(TaxScheme, 'Name', EInvHeader.CustTaxOfficeName, NamespaceURI_CBC, CurrNode);

        IF (EInvHeader.CustTelephone <> '') OR (EInvHeader.CustTelefax <> '') OR (EInvHeader.CustElectronicMail <> '') THEN begin
            AddElement(Party, 'Contact', '', NamespaceURI_CAC, Contact);

            IF EInvHeader.CustTelephone <> '' THEN
                AddElement(Contact, 'Telephone', EInvHeader.CustTelephone, NamespaceURI_CBC, CurrNode);

            IF EInvHeader.CustTelefax <> '' THEN
                AddElement(Contact, 'Telefax', EInvHeader.CustTelefax, NamespaceURI_CBC, CurrNode);

            IF EInvHeader.CustElectronicMail <> '' THEN
                AddElement(Contact, 'ElectronicMail', EInvHeader.CustElectronicMail, NamespaceURI_CBC, CurrNode);
        END;

        IF (EInvHeader.CustFirstName <> '') AND (EInvHeader.CustFamilyName <> '') THEN BEGIN
            AddElement(Party, 'Person', '', NamespaceURI_CAC, Person);
            AddElement(Person, 'FirstName', EInvHeader.CustFirstName, NamespaceURI_CBC, CurrNode);
            AddElement(Person, 'FamilyName', EInvHeader.CustFamilyName, NamespaceURI_CBC, CurrNode);
        END;

        OnAfterPartyIdentification_AccountingCustomerParty(Party, AccountingCustomerParty, Queue, EInvHeader);

        IF EInvHeader."Payee VKN" <> '' then begin

            Clear(PartyIdentification);
            Clear(PartyName);
            Clear(PostalAddress);
            Clear(Country);
            Clear(PartyTaxScheme);
            Clear(Contact);
            Clear(Person);

            AddElement(ActiveNode, 'BuyerCustomerParty', '', NamespaceURI_CAC, BuyerCustomerParty);
            AddElement(BuyerCustomerParty, 'Party', '', NamespaceURI_CAC, Party);

            IF EInvHeader.CustWebsiteURI <> '' THEN BEGIN
                AddElement(Party, 'WebsiteURI', EInvHeader.CustWebsiteURI, NamespaceURI_CBC, CurrNode);
            END;

            AddElement(Party, 'PartyIdentification', '', NamespaceURI_CAC, PartyIdentification);
            AddElement(PartyIdentification, 'ID', EInvHeader."Payee VKN", NamespaceURI_CBC, CurrNode);
            AddAttribute(CurrNode, 'schemeID', EInvHeader.CustTaxSchemeID);
            AddElement(Party, 'PartyName', '', NamespaceURI_CAC, PartyName);
            AddElement(PartyName, 'Name', EInvHeader.CustName, NamespaceURI_CBC, CurrNode);
            AddElement(Party, 'PostalAddress', '', NamespaceURI_CAC, PostalAddress);

            IF EInvHeader.CustStreetName <> '' THEN
                AddElement(PostalAddress, 'StreetName', EInvHeader.CustStreetName, NamespaceURI_CBC, CurrNode);

            IF EInvHeader.CustBuildingNumber <> '' THEN
                AddElement(PostalAddress, 'BuildingNumber', EInvHeader.CustBuildingNumber, NamespaceURI_CBC, CurrNode);

            AddElement(PostalAddress, 'CitySubdivisionName', EInvHeader.CustCitySubdivisionName, NamespaceURI_CBC, CurrNode);
            AddElement(PostalAddress, 'CityName', EInvHeader.CustCityName, NamespaceURI_CBC, CurrNode);

            IF EInvHeader.CustPostalZone <> '' THEN
                AddElement(PostalAddress, 'PostalZone', EInvHeader.CustPostalZone, NamespaceURI_CBC, CurrNode);

            AddElement(PostalAddress, 'Country', '', NamespaceURI_CAC, Country);
            AddElement(Country, 'Name', EInvHeader.CustCountryName, NamespaceURI_CBC, CurrNode);

            AddElement(Party, 'PartyTaxScheme', '', NamespaceURI_CAC, PartyTaxScheme);
            AddElement(PartyTaxScheme, 'TaxScheme', '', NamespaceURI_CAC, TaxScheme);
            AddElement(TaxScheme, 'Name', EInvHeader.CustTaxOfficeName, NamespaceURI_CBC, CurrNode);

            IF (EInvHeader.CustTelephone <> '') OR (EInvHeader.CustTelefax <> '') OR (EInvHeader.CustElectronicMail <> '') THEN begin
                AddElement(Party, 'Contact', '', NamespaceURI_CAC, Contact);

                IF EInvHeader.CustTelephone <> '' THEN
                    AddElement(Contact, 'Telephone', EInvHeader.CustTelephone, NamespaceURI_CBC, CurrNode);

                IF EInvHeader.CustTelefax <> '' THEN
                    AddElement(Contact, 'Telefax', EInvHeader.CustTelefax, NamespaceURI_CBC, CurrNode);

                IF EInvHeader.CustElectronicMail <> '' THEN
                    AddElement(Contact, 'ElectronicMail', EInvHeader.CustElectronicMail, NamespaceURI_CBC, CurrNode);
            END;

            IF (EInvHeader.CustFirstName <> '') AND (EInvHeader.CustFamilyName <> '') THEN BEGIN
                AddElement(Party, 'Person', '', NamespaceURI_CAC, Person);
                AddElement(Person, 'FirstName', EInvHeader.CustFirstName, NamespaceURI_CBC, CurrNode);
                AddElement(Person, 'FamilyName', EInvHeader.CustFamilyName, NamespaceURI_CBC, CurrNode);
            END;



        end;

        OnAfterXmlPhase4_Standard(ActiveNode, AccountingCustomerParty);
    END;

    local procedure XmlPhase5(var Queue: Record "PRG_E-Invoice Queue"; var EInvHeader: Record "PRG_E-Invoice Header")
    var
        ReferenceBuffer: Record "PRG_E-Invoice Reference Buffer";
        PaymentMeans: XmlNode;
        PricingExchangeRate: XmlNode;
        PayeeFinancialAccount: XmlNode;
        CurrNode: XmlNode;
    begin
        //Payment Means
        ActiveNode := RootNode.AsXmlNode();

        ReferenceBuffer.SETRANGE("Header Entry No.", EInvHeader."Entry No.");
        ReferenceBuffer.SETRANGE("Reference Type", ReferenceBuffer."Reference Type"::PaymentMethod);
        ReferenceBuffer.FINDFIRST();

        AddElement(ActiveNode, 'PaymentMeans', '', NamespaceURI_CAC, PaymentMeans);
        AddElement(PaymentMeans, 'PaymentMeansCode', ReferenceBuffer."Reference Text", NamespaceURI_CBC, CurrNode);
        AddElement(PaymentMeans, 'PaymentDueDate', Library.FormatDate(ReferenceBuffer."Reference Date"), NamespaceURI_CBC, CurrNode);

        //PayeeFinancialAccount
        IF EInvHeader.PaymentBankAccNo <> '' THEN BEGIN
            AddElement(PaymentMeans, 'PayeeFinancialAccount', '', NamespaceURI_CAC, PayeeFinancialAccount);
            AddElement(PayeeFinancialAccount, 'ID', EInvHeader.PaymentBankAccNo, NamespaceURI_CBC, CurrNode);
            AddElement(PayeeFinancialAccount, 'CurrencyCode', EInvHeader.PaymentBankCurrCode, NamespaceURI_CBC, CurrNode);
            IF EInvHeader.PaymentInstructionNote <> '' THEN
                AddElement(PayeeFinancialAccount, 'PaymentNote', EInvHeader.PaymentInstructionNote, NamespaceURI_CBC, CurrNode);
        END;

        //PricingExchangeRate
        AddElement(ActiveNode, 'PricingExchangeRate', '', NamespaceURI_CAC, PricingExchangeRate);

        AddElement(PricingExchangeRate, 'SourceCurrencyCode', EInvHeader.DocumentCurrencyCode, NamespaceURI_CBC, CurrNode);

        AddElement(PricingExchangeRate, 'TargetCurrencyCode', 'TRY', NamespaceURI_CBC, CurrNode);

        AddElement(PricingExchangeRate, 'CalculationRate', Library.FormatDec5Places(EInvHeader.DocumentCurrencyRate), NamespaceURI_CBC, CurrNode);

        AddElement(PricingExchangeRate, 'Date', Library.FormatDate(EInvHeader.IssueDate), NamespaceURI_CBC, CurrNode);

        OnAfterXmlPhase5(ActiveNode, PaymentMeans, PricingExchangeRate);

        CreateInvoiceTaxNodes(Queue, EInvHeader);
        CreateInvoiceWitholdingTaxNodes(Queue, EInvHeader);
        CreateLegalMonetaryTotalNodes(Queue, EInvHeader);
    end;

    local procedure XmlPhase6(var Queue: Record "PRG_E-Invoice Queue"; var EInvHeader: Record "PRG_E-Invoice Header")
    var
        Line: Record "PRG_E-Invoice Line";
        ChargeLine: Record "PRG_E-Invoice Line";
        TaxLine: Record "PRG_E-Invoice Tax Line";
        SalesInvHdr: Record "Sales Invoice Header";
        SalesInvLine: Record "Sales Invoice Line";
        PurchCRMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchCRMemoLine: Record "Purch. Cr. Memo Line";
        TempILE: Record "Item Ledger Entry" temporary;
        ItemCategory: Record "Item Category";
        ItemRecord: Record Item;
        ItemTrackDocMgt: Codeunit "Item Tracking Doc. Management";
        i: Integer;
        CarriageAmount: Decimal;
        InsuranceAmount: Decimal;
        IsHandled: Boolean;
        RecID: RecordId;
        RecRef: RecordRef;
        ActualPackage: XmlNode;
        AllowanceCharge: XmlNode;
        BuyersItemIdentification: XmlNode;
        Country: XmlNode;
        Delivery: XmlNode;
        DeliveryAddress: XmlNode;
        DeliveryTerms: XmlNode;
        GoodsItem: XmlNode;
        InvoiceLine: XmlNode;
        Item: XmlNode;
        ManufacturersItemIdentification: XmlNode;
        Price: XmlNode;
        SellersItemIdentification: XmlNode;
        Shipment: XmlNode;
        ShipmentStage: XmlNode;
        TaxCategory: XmlNode;
        TaxScheme: XmlNode;
        TaxSubtotal: XmlNode;
        TaxTotal: XmlNode;
        TransportHandlingUnit: XmlNode;
        AdditionalItemIdentification: XmlNode;
        Note: Text;
        MedicineLbl: Label '(GTIN)%1(BN)%2(SN)%3(XD)%4';
        MedicalDeviceLbl: Label '(UNO)%1(LNO)%2(SNO)%3(URT)%4';
    begin
        Line.SETRANGE("Header Entry No.", EInvHeader."Entry No.");
        Line.FINDFIRST();

        REPEAT

            ActiveNode := RootNode.AsXmlNode();

            AddElement(ActiveNode, 'InvoiceLine', '', NamespaceURI_CAC, InvoiceLine);

            AddElement(InvoiceLine, 'ID', FORMAT(Line."Line No."), NamespaceURI_CBC, CurrNode);

            OnAfterCreateInvoiceLineID(InvoiceLine, Line);

            OnBeforeCreateLineNote(EInvHeader, Line, Note);
            IF Note <> '' then
                AddElement(InvoiceLine, 'Note', Note, NamespaceURI_CBC, CurrNode);

            IF (Queue.ProfileID = EExportSetup."E-Export ProfileID") AND (Line."Package Brand" <> '') THEN
                AddElement(InvoiceLine, 'Note', StrSubstNo(Text001, Line."Package Brand"), NamespaceURI_CBC, CurrNode);

            AddElement(InvoiceLine, 'InvoicedQuantity', Library.FormatDec2Places(Line.Quantity), NamespaceURI_CBC, CurrNode);
            AddAttribute(CurrNode, 'unitCode', Line."Unit Of Measure Code");

            AddElement(InvoiceLine, 'LineExtensionAmount', Library.FormatDec2Places(Line."Line Extension Amount"), NamespaceURI_CBC, CurrNode);
            AddAttribute(CurrNode, 'currencyID', GetFunctionValue(4, Queue));

            //E-Export Information
            IF Queue.ProfileID = EExportSetup."E-Export ProfileID" THEN BEGIN
                if Queue.GLRegisterEntryNo <> 0 then begin
                    RecID := Queue.ERPRecordID;
                    RecRef := RecID.GetRecord();
                    case RecRef.NUMBER of
                        DATABASE::"Sales Invoice Header":
                            begin
                                RecRef.SetTable(SalesInvHdr);
                                SalesInvLine.SetRange("Document No.", SalesInvHdr."No.");
                                if SalesInvLine.FindFirst() then
                                    repeat
                                        if SalesInvLine."No." = EInvSetup."Default Carriage Item Charge" then begin
                                            CarriageAmount := SalesInvLine.Amount;
                                            ChargeLine.SetRange("Header Entry No.", EInvHeader."Entry No.");
                                            ChargeLine.SetRange("Sellers Item Identification", EInvSetup."Default Carriage Item Charge");
                                            if ChargeLine.FindFirst() then
                                                ChargeLine.Delete();
                                        end;
                                        if SalesInvLine."No." = EInvSetup."Default Insurance Item Charge" then begin
                                            InsuranceAmount := SalesInvLine.Amount;
                                            ChargeLine.Reset();
                                            ChargeLine.SetRange("Header Entry No.", EInvHeader."Entry No.");
                                            ChargeLine.SetRange("Sellers Item Identification", EInvSetup."Default Insurance Item Charge");
                                            if ChargeLine.FindFirst() then
                                                ChargeLine.Delete();
                                        end;
                                    until SalesInvLine.Next() = 0;
                            end;
                        DATABASE::"Purch. Cr. Memo Hdr.":
                            begin
                                RecRef.SetTable(PurchCRMemoHdr);
                                PurchCRMemoLine.SetRange("Document No.", PurchCRMemoHdr."No.");
                                if PurchCRMemoLine.FindFirst() then
                                    repeat
                                        if PurchCRMemoLine."No." = EInvSetup."Default Carriage Item Charge" then begin
                                            CarriageAmount := PurchCRMemoLine.Amount;
                                            ChargeLine.SetRange("Header Entry No.", EInvHeader."Entry No.");
                                            ChargeLine.SetRange("Sellers Item Identification", EInvSetup."Default Carriage Item Charge");
                                            if ChargeLine.FindFirst() then
                                                ChargeLine.Delete();
                                        end;
                                        if PurchCRMemoLine."No." = EInvSetup."Default Insurance Item Charge" then begin
                                            InsuranceAmount := PurchCRMemoLine.Amount;
                                            ChargeLine.Reset();
                                            ChargeLine.SetRange("Header Entry No.", EInvHeader."Entry No.");
                                            ChargeLine.SetRange("Sellers Item Identification", EInvSetup."Default Insurance Item Charge");
                                            if ChargeLine.FindFirst() then
                                                ChargeLine.Delete();
                                        end;
                                    until PurchCRMemoLine.Next() = 0;
                            end;
                    end;
                end;

                AddElement(InvoiceLine, 'Delivery', '', NamespaceURI_CAC, Delivery);
                AddElement(Delivery, 'DeliveryAddress', '', NamespaceURI_CAC, DeliveryAddress);
                AddElement(DeliveryAddress, 'StreetName', '', NamespaceURI_CBC, CurrNode);
                AddElement(DeliveryAddress, 'BuildingName', '', NamespaceURI_CBC, CurrNode);
                AddElement(DeliveryAddress, 'BuildingNumber', '', NamespaceURI_CBC, CurrNode);
                AddElement(DeliveryAddress, 'CitySubdivisionName', '', NamespaceURI_CBC, CurrNode);
                AddElement(DeliveryAddress, 'CityName', Line."Delivery City Name", NamespaceURI_CBC, CurrNode);
                AddElement(DeliveryAddress, 'PostalZone', '', NamespaceURI_CBC, CurrNode);
                AddElement(DeliveryAddress, 'Country', '', NamespaceURI_CAC, Country);
                AddElement(Country, 'Name', Line."Delivery Country Name", NamespaceURI_CBC, CurrNode);
                AddElement(Delivery, 'DeliveryTerms', '', NamespaceURI_CAC, DeliveryTerms);
                AddElement(DeliveryTerms, 'ID', Line."Delivery Terms", NamespaceURI_CBC, CurrNode);
                AddAttribute(CurrNode, 'schemeID', 'INCOTERMS');
                AddElement(Delivery, 'Shipment', '', NamespaceURI_CAC, Shipment);
                AddElement(Shipment, 'ID', '', NamespaceURI_CBC, CurrNode);
                AddElement(Shipment, 'GoodsItem', '', NamespaceURI_CAC, GoodsItem);
                AddElement(GoodsItem, 'DeclaredForCarriageValueAmount', Library.FormatDec2Places(CarriageAmount), NamespaceURI_CBC, CurrNode);
                AddAttribute(CurrNode, 'currencyID', GetFunctionValue(4, Queue));
                AddElement(GoodsItem, 'InsuranceValueAmount', Library.FormatDec2Places(InsuranceAmount), NamespaceURI_CBC, CurrNode);
                AddAttribute(CurrNode, 'currencyID', GetFunctionValue(4, Queue));
                AddElement(GoodsItem, 'RequiredCustomsID', Line."GTIP No.", NamespaceURI_CBC, CurrNode);
                AddElement(Shipment, 'ShipmentStage', '', NamespaceURI_CAC, ShipmentStage);
                AddElement(ShipmentStage, 'TransportModeCode', Line."Transport Mode Code", NamespaceURI_CBC, CurrNode);
                AddElement(Shipment, 'TransportHandlingUnit', '', NamespaceURI_CAC, TransportHandlingUnit);
                AddElement(TransportHandlingUnit, 'ActualPackage', '', NamespaceURI_CAC, ActualPackage);
                AddElement(ActualPackage, 'ID', '-', NamespaceURI_CBC, CurrNode);
                AddElement(ActualPackage, 'Quantity', Library.FormatDec2Places(Line."Actual Package Quantity"), NamespaceURI_CBC, CurrNode);
                AddElement(ActualPackage, 'PackagingTypeCode', Line."Packagin Type Code", NamespaceURI_CBC, CurrNode);

                OnAfterCreateExportLineInformation(InvoiceLine);

            END;

            OnBeforeAllowanceAndTaxForLines(InvoiceLine, EInvHeader, Line);

            IF (Line."Allowance Charge Indicator" <> '') OR (Library.FormatDec2Places(Line."Allowance Charge Rate") <> '') OR (Library.FormatDec2Places(Line."Allowance Charge Amount") <> '') THEN BEGIN

                AddElement(InvoiceLine, 'AllowanceCharge', '', NamespaceURI_CAC, AllowanceCharge);

                AddElement(AllowanceCharge, 'ChargeIndicator', Line."Allowance Charge Indicator", NamespaceURI_CBC, CurrNode);

                AddElement(AllowanceCharge, 'MultiplierFactorNumeric', Library.FormatDec4Places(Line."Allowance Charge Rate"), NamespaceURI_CBC, CurrNode);

                AddElement(AllowanceCharge, 'Amount', Library.FormatDec2Places(Line."Allowance Charge Amount"), NamespaceURI_CBC, CurrNode);
                AddAttribute(CurrNode, 'currencyID', GetFunctionValue(4, Queue));

            END;

            TaxLine.SETRANGE("Header Entry No.", EInvHeader."Entry No.");
            TaxLine.SETRANGE("Header Line No.", Line."Line No.");
            TaxLine.SETRANGE(Type, TaxLine.Type::Line);
            TaxLine.SETFILTER(TaxType, '<>%1', TaxLine.TaxType::Witholding);
            IF TaxLine.FINDFIRST() THEN
                REPEAT
                    AddElement(InvoiceLine, 'TaxTotal', '', NamespaceURI_CAC, TaxTotal);

                    AddElement(TaxTotal, 'TaxAmount', Library.FormatDec2Places(TaxLine.TaxAmount), NamespaceURI_CBC, CurrNode);
                    AddAttribute(CurrNode, 'currencyID', GetFunctionValue(4, Queue));

                    AddElement(TaxTotal, 'TaxSubtotal', '', NamespaceURI_CAC, TaxSubtotal);

                    AddElement(TaxSubtotal, 'TaxableAmount', Library.FormatDec2Places(TaxLine.TaxExclusiveAmount), NamespaceURI_CBC, CurrNode);
                    AddAttribute(CurrNode, 'currencyID', GetFunctionValue(4, Queue));

                    AddElement(TaxSubtotal, 'TaxAmount', Library.FormatDec2Places(TaxLine.TaxAmount), NamespaceURI_CBC, CurrNode);
                    AddAttribute(CurrNode, 'currencyID', GetFunctionValue(4, Queue));

                    AddElement(TaxSubtotal, 'Percent', Library.FormatDec2Places(TaxLine.TaxPercent), NamespaceURI_CBC, CurrNode);

                    AddElement(TaxSubtotal, 'TaxCategory', '', NamespaceURI_CAC, TaxCategory);

                    IF (TaxLine."TaxExemption Reason Code" <> '') AND (TaxLine."TaxExemption Reason Desc" <> '') THEN BEGIN

                        AddElement(TaxCategory, 'TaxExemptionReasonCode', TaxLine."TaxExemption Reason Code", NamespaceURI_CBC, CurrNode);

                        AddElement(TaxCategory, 'TaxExemptionReason', TaxLine."TaxExemption Reason Desc", NamespaceURI_CBC, CurrNode);

                    END;

                    AddElement(TaxCategory, 'TaxScheme', '', NamespaceURI_CAC, TaxScheme);

                    AddElement(TaxScheme, 'Name', TaxLine.TaxTypeName, NamespaceURI_CBC, CurrNode);

                    AddElement(TaxScheme, 'TaxTypeCode', TaxLine.TaxTypeCode, NamespaceURI_CBC, CurrNode);

                UNTIL TaxLine.NEXT() = 0;

            IF EInvSetup."Add Withholding Line to XML" then begin
                TaxLine.SETRANGE("Header Entry No.", EInvHeader."Entry No.");
                TaxLine.SETRANGE("Header Line No.", Line."Line No.");
                TaxLine.SETRANGE(Type, TaxLine.Type::Line);
                TaxLine.SETFILTER(TaxType, '%1', TaxLine.TaxType::Witholding);
                IF TaxLine.FINDFIRST() THEN
                    REPEAT
                        AddElement(InvoiceLine, 'WithholdingTaxTotal', '', NamespaceURI_CAC, TaxTotal);

                        AddElement(TaxTotal, 'TaxAmount', Library.FormatDec2Places(TaxLine.TaxAmount), NamespaceURI_CBC, CurrNode);
                        AddAttribute(CurrNode, 'currencyID', GetFunctionValue(4, Queue));

                        AddElement(TaxTotal, 'TaxSubtotal', '', NamespaceURI_CAC, TaxSubtotal);

                        AddElement(TaxSubtotal, 'TaxableAmount', Library.FormatDec2Places(TaxLine.TaxExclusiveAmount), NamespaceURI_CBC, CurrNode);
                        AddAttribute(CurrNode, 'currencyID', GetFunctionValue(4, Queue));

                        AddElement(TaxSubtotal, 'TaxAmount', Library.FormatDec2Places(TaxLine.TaxAmount), NamespaceURI_CBC, CurrNode);
                        AddAttribute(CurrNode, 'currencyID', GetFunctionValue(4, Queue));

                        AddElement(TaxSubtotal, 'Percent', Library.FormatDec2Places(TaxLine.TaxPercent), NamespaceURI_CBC, CurrNode);

                        AddElement(TaxSubtotal, 'TaxCategory', '', NamespaceURI_CAC, TaxCategory);

                        AddElement(TaxCategory, 'Name', 'KDV TEVKIFAT', NamespaceURI_CBC, CurrNode);

                        AddElement(TaxCategory, 'TaxScheme', '', NamespaceURI_CAC, TaxScheme);

                        AddElement(TaxScheme, 'Name', TaxLine.TaxTypeName, NamespaceURI_CBC, CurrNode);

                        AddElement(TaxScheme, 'TaxTypeCode', TaxLine.TaxTypeCode, NamespaceURI_CBC, CurrNode);

                    UNTIL TaxLine.NEXT() = 0;
            end;

            AddElement(InvoiceLine, 'Item', '', NamespaceURI_CAC, Item);

            AddElement(Item, 'Description', Line.Description, NamespaceURI_CBC, CurrNode);

            AddElement(Item, 'Name', Line."Item Name", NamespaceURI_CBC, CurrNode);

            OnBeforeCreateMedicalLine(Queue, EInvHeader, Line, Item, IsHandled);
            if not IsHandled then
                if EInvHeader.ProfileID = EInvHeader.ProfileID::Medical then begin
                    RecRef.GET(Line.LineRecordID);
                    RecRef.SETTABLE(SalesInvLine);
                    TempILE.DeleteAll();

                    if ItemRecord.Get(SalesInvLine."No.") then begin
                        ItemTrackDocMgt.RetrieveEntriesFromPostedInvoice(TempILE, SalesInvLine.RowID1());
                        ItemCategory.Get(SalesInvLine."Item Category Code");

                        TempILE.SetRange("Document Line No.", SalesInvLine."Line No.");
                        if (TempILE.FindSet()) then
                            repeat
                                AddElement(Item, 'AdditionalItemIdentification', '', NamespaceURI_CAC, AdditionalItemIdentification);
                                case ItemCategory."PRG_Medical E-Invoice Type" of
                                    ItemCategory."PRG_Medical E-Invoice Type"::Medicine:
                                        begin
                                            AddElement(AdditionalItemIdentification, 'ID', StrSubstNo(MedicineLbl, ItemRecord.GTIN, TempILE."Lot No.", TempILE."Serial No.", TempILE."Expiration Date"), NamespaceURI_CBC, CurrNode);
                                            AddAttribute(CurrNode, 'schemeID', 'ILAC');
                                        end;
                                    ItemCategory."PRG_Medical E-Invoice Type"::"Medical Device":
                                        begin
                                            AddElement(AdditionalItemIdentification, 'ID', StrSubstNo(MedicalDeviceLbl, ItemRecord.GTIN, TempILE."Lot No.", TempILE."Serial No.", TempILE."Posting Date"), NamespaceURI_CBC, CurrNode);
                                            AddAttribute(CurrNode, 'schemeID', 'TIBBICIHAZ');
                                        end;
                                    ItemCategory."PRG_Medical E-Invoice Type"::" ":
                                        begin
                                            AddElement(AdditionalItemIdentification, 'ID', '1111111111', NamespaceURI_CBC, CurrNode);
                                            AddAttribute(CurrNode, 'schemeID', 'DIGER');
                                        end;
                                end;
                            until TempILE.Next() = 0;

                    end;
                end;

            IF Line."Buyers Item Identification" <> '' THEN BEGIN

                AddElement(Item, 'BuyersItemIdentification', '', NamespaceURI_CAC, BuyersItemIdentification);
                // Item := BuyersItemIdentification;

                AddElement(BuyersItemIdentification, 'ID', Line."Buyers Item Identification", NamespaceURI_CBC, CurrNode);
                //BuyersItemIdentification := CurrNode;

            END;

            IF Line."Sellers Item Identification" <> '' THEN BEGIN

                AddElement(Item, 'SellersItemIdentification', '', NamespaceURI_CAC, SellersItemIdentification);
                //Item := SellersItemIdentification;

                AddElement(SellersItemIdentification, 'ID', Line."Sellers Item Identification", NamespaceURI_CBC, CurrNode);
                //SellersItemIdentification := CurrNode;
            END;

            IF Line."Manu. Item Identification" <> '' THEN BEGIN

                AddElement(Item, 'ManufacturersItemIdentification', '', NamespaceURI_CAC, ManufacturersItemIdentification);
                //Item := ManufacturersItemIdentification;

                AddElement(ManufacturersItemIdentification, 'ID', Line."Manu. Item Identification", NamespaceURI_CBC, CurrNode);
                //ManufacturersItemIdentification := CurrNode;

            END;

            OnAfterCreateItem_InvoiceLine(InvoiceLine, Item, Queue, Line);

            AddElement(InvoiceLine, 'Price', '', NamespaceURI_CAC, Price);

            AddElement(Price, 'PriceAmount', Library.FormatDec5Places(Line."Unit Price"), NamespaceURI_CBC, CurrNode);
            AddAttribute(CurrNode, 'currencyID', GetFunctionValue(4, Queue));

            OnAfterCreateInvoiceLine(ActiveNode, InvoiceLine, BuyersItemIdentification, SellersItemIdentification, ManufacturersItemIdentification);

        UNTIL Line.NEXT() = 0;
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCreateXmlDoc(XMLdoc: XmlDocument)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCreateHeaderTaxNode(var TaxTotal: XmlNode; var TaxSubtotal: XmlNode; var TaxScheme: XmlNode; var TaxCategory: XmlNode)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCreateHeaderWitholdingTaxNode(var WithholdingTaxTotal: XmlNode; var TaxSubtotal: XmlNode; var TaxScheme: XmlNode; var TaxCategory: XmlNode)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCreateLegalMonetaryTotalNode(var LegalMonetaryTotal: XmlNode)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeGetFunctionValue(FunctionNo: Integer; Queue: Record "PRG_E-Invoice Queue"; var CustomValue: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCreateInvoiceNotes(RootAsNode: XmlNode)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCreateDespatchNodes(RootAsNode: XmlNode)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCreateDespatchNodes(RootAsNode: XmlNode)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterXmlPhase2(ActiveNode: XmlNode)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterXmlPhase3(ActiveNode: XmlNode; var AccountingSupplierParty: XmlNode)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterXmlPhase4_Export(ActiveNode: XmlNode; var AccountingCustomerParty: XmlNode)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterXmlPhase4_Standard(ActiveNode: XmlNode; var AccountingCustomerParty: XmlNode)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterXmlPhase5(ActiveNode: XmlNode; var PaymentMeans: XmlNode; var PricingExchangeRate: XmlNode)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCreateInvoiceLineID(var InvoiceLine: XmlNode; var Line: Record "PRG_E-Invoice Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCreateExportLineInformation(var InvoiceLine: XmlNode)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeAllowanceAndTaxForLines(var InvoiceLine: XmlNode; EInvHeader: Record "PRG_E-Invoice Header"; Line: Record "PRG_E-Invoice Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCreateInvoiceLine(ActiveNode: XmlNode; InvoiceLine: XmlNode; BuyersItemIdentification: XmlNode; SellersItemIdentification: XmlNode; ManufacturersItemIdentification: XmlNode)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeInsertOrderReference(var OrderNo: Text[30]; var OrderDate: Date)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeInsertOrderReferenceXML(var OrderNo: Text[30]; var OrderDate: Date; var EInvHeader: Record "PRG_E-Invoice Header")
    begin
    end;

    [IntegrationEvent(true, false)]
    procedure OnBeforeCreateOutgoingXML(var Queue: Record "PRG_E-Invoice Queue")
    begin
    end;

    [IntegrationEvent(true, false)]
    procedure OnAfterCreateOutgoingXML(var Queue: Record "PRG_E-Invoice Queue")
    begin
    end;

    [IntegrationEvent(true, false)]
    procedure OnBeforeCreateLineNote(var EInvHeader: Record "PRG_E-Invoice Header"; var EInvLine: Record "PRG_E-Invoice Line"; var Note: Text)
    begin
    end;

    [IntegrationEvent(true, false)]
    procedure OnAfterPartyIdentification_AccountingSupplierParty(var PartyNode: XmlNode; var AccountingSupplierParty: XmlNode; var Queue: Record "PRG_E-Invoice Queue"; var EInvHeader: Record "PRG_E-Invoice Header")
    begin
    end;

    [IntegrationEvent(true, false)]
    procedure OnAfterPartyIdentification_AccountingCustomerParty(var PartyNode: XmlNode; var AccountingCustomerParty: XmlNode; var Queue: Record "PRG_E-Invoice Queue"; var EInvHeader: Record "PRG_E-Invoice Header")
    begin
    end;

    [IntegrationEvent(true, false)]
    procedure OnBeforeSupplierParty_CreateCustomizedXml(var RootAsNode: XmlNode; var ChildNode: XmlNode; var Queue: Record "PRG_E-Invoice Queue")
    begin
    end;

    [IntegrationEvent(true, false)]
    procedure OnAfterCreateItem_InvoiceLine(var InvoiceLine: XmlNode; var Item: XmlNode; var Queue: Record "PRG_E-Invoice Queue"; var Line: Record "PRG_E-Invoice Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    procedure OnBeforeCreateMedicalLine(var Queue: Record "PRG_E-Invoice Queue"; var EInvHeader: Record "PRG_E-Invoice Header"; var Line: Record "PRG_E-Invoice Line"; var Item: XmlNode; var IsHandled: Boolean)
    begin
    end;
}