table 70093475 "PRG_E-Invoice Header"
{
    Caption = 'E-Invoice Header';
    DataClassification = CustomerContent;

    fields
    {
        field(10; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(11; "Invoice ID"; Code[20])
        {
            Caption = 'Invoice ID';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(20; "G/L Register Entry No."; Integer)
        {
            Caption = 'G/L Register Entry No.';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "G/L Register";
        }
        field(30; CopyIndicator; Text[5])
        {
            Caption = 'CopyIndicator';
            DataClassification = CustomerContent;
        }
        field(40; UUID; Guid)
        {
            Caption = 'UUID';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(45; ProfileID; Option)
        {
            Caption = 'ProfileID';
            DataClassification = CustomerContent;
            OptionCaption = ' ,Commercial,Basic,E-Archive,E-Export,Medical';
            OptionMembers = " ",Commercial,Basic,EArchive,EExport,Medical;
        }
        field(50; IssueDate; Date)
        {
            Caption = 'IssueDate';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(60; IssueTime; Time)
        {
            Caption = 'IssueTime';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(65; "Line Count"; Integer)
        {
            CalcFormula = COUNT("PRG_E-Invoice Line" where("Header Entry No." = field("Entry No.")));
            Caption = 'Line Count';
            FieldClass = FlowField;
        }
        field(70; InvoiceType; Option)
        {
            Caption = 'InvoiceType';
            DataClassification = CustomerContent;
            Editable = true;
            OptionCaption = ' ,Sales,SalesCr,Purch,PurchCr,Withholding,Exception,Specific Base,Exported';
            OptionMembers = " ",Sales,SalesCr,Purch,PurchCr,Withholding,Exception,SpecificBase,Exported;
        }
        field(90; DocumentCurrencyCode; Code[10])
        {
            Caption = 'DocumentCurrencyCode';
            DataClassification = CustomerContent;
        }
        field(91; DocumentCurrencyRate; Decimal)
        {
            AutoFormatType = 2;
            BlankZero = true;
            Caption = 'DocumentCurrencyRate';
            DataClassification = CustomerContent;
        }
        field(110; OrderNo; Text[30])
        {
            Caption = 'OrderNo';
            DataClassification = CustomerContent;
        }
        field(111; OrderDate; Date)
        {
            Caption = 'OrderDate';
            DataClassification = CustomerContent;
        }
        field(150; CustWebsiteURI; Text[100])
        {
            Caption = 'CustWebsiteURI';
            DataClassification = CustomerContent;
        }
        field(160; CustRegistrationNo; Text[30])
        {
            Caption = 'CustRegistrationNo';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                IF CustRegistrationNo <> xRec.CustRegistrationNo THEN
                    CustNo := '';
            end;
        }
        field(161; CustNo; Code[20])
        {
            Caption = 'Customer No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(162; CustTaxSchemeID; Text[5])
        {
            Caption = 'CustTaxSchemeID';
            DataClassification = CustomerContent;
        }
        field(165; CustBranchCode; Text[30])
        {
            Caption = 'Cust Branch Code';
            DataClassification = CustomerContent;
            TableRelation = "Ship-to Address".Code WHERE("Customer No." = FIELD(CustNo));
            ValidateTableRelation = false;
        }
        field(170; CustName; Text[250])
        {
            Caption = 'CustName';
            DataClassification = CustomerContent;
        }
        field(171; CustFirstName; Text[100])
        {
            Caption = 'CustFirstName';
            DataClassification = CustomerContent;
        }
        field(172; CustFamilyName; Text[100])
        {
            Caption = 'CustFamilyName';
            DataClassification = CustomerContent;
        }
        field(190; CustBuildingNumber; Text[10])
        {
            Caption = 'CustBuildingNumber';
            DataClassification = CustomerContent;
        }
        field(200; CustCitySubdivisionName; Text[30])
        {
            Caption = 'CustCitySubdivisionName';
            DataClassification = CustomerContent;
        }
        field(210; CustCityName; Text[30])
        {
            Caption = 'CustCityName';
            DataClassification = CustomerContent;
        }
        field(220; CustPostalZone; Text[30])
        {
            Caption = 'CustPostalZone';
            DataClassification = CustomerContent;
        }
        field(230; CustCountryName; Text[30])
        {
            Caption = 'CustCountryName';
            DataClassification = CustomerContent;
        }
        field(235; CustStreetName; Text[155])
        {
            Caption = 'CustStreetName';
            DataClassification = CustomerContent;
        }
        field(240; CustTaxOfficeName; Text[50])
        {
            Caption = 'CustTaxOfficeName';
            DataClassification = CustomerContent;
        }
        field(250; CustTelephone; Text[30])
        {
            Caption = 'CustTelephone';
            DataClassification = CustomerContent;
        }
        field(260; CustTelefax; Text[30])
        {
            Caption = 'CustTelefax';
            DataClassification = CustomerContent;
        }
        field(270; CustElectronicMail; Text[100])
        {
            Caption = 'CustElectronicMail';
            DataClassification = CustomerContent;
        }
        field(271; CustIdentifier; Text[100])
        {
            Caption = 'CustIdentifier';
            DataClassification = CustomerContent;
            TableRelation = "PRG_E-Invoice Liable Companies".Alias WHERE(Identifier = FIELD(CustRegistrationNo));
            ValidateTableRelation = false;
        }
        field(280; PaymentMethodCode; Text[250])
        {
            CalcFormula = Lookup("PRG_E-Invoice Reference Buffer"."Reference Text" WHERE("Header Entry No." = FIELD("Entry No."),
                                                                                      "Reference Type" = CONST(PaymentMethod)));
            Caption = 'PaymentMethodCode';
            Editable = false;
            FieldClass = FlowField;
        }
        field(281; PaymentDueDate; Date)
        {
            Caption = 'PaymentDueDate';
            DataClassification = CustomerContent;
        }
        field(282; PaymentMethodNote; Text[30])
        {
            Caption = 'PaymentMethodNote';
            DataClassification = CustomerContent;
        }
        field(283; PaymentTermsNote; Text[30])
        {
            Caption = 'PaymentTermsNote';
            DataClassification = CustomerContent;
        }
        field(284; PaymentChannelCode; Text[20])
        {
            Caption = 'PaymentTermsNote';
            DataClassification = CustomerContent;
        }
        field(285; PaymentInstructionNote; Text[50])
        {
            Caption = 'PaymentInstructionNote';
            DataClassification = CustomerContent;
        }
        field(286; "PaymentBankAccNo"; Code[50])
        {
            Caption = 'PaymentBankAccNo';
            DataClassification = CustomerContent;
        }
        field(287; "PaymentBankCurrCode"; Code[5])
        {
            Caption = 'PaymentBankCurrCode';
            DataClassification = CustomerContent;
        }
        field(300; AllowanceChargeIndicator; Text[10])
        {
            Caption = 'AllowanceChargeIndicator';
            DataClassification = CustomerContent;
        }
        field(310; AllowanceChargeAmtLine; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = Sum("PRG_E-Invoice Line"."Allowance Charge Amount" WHERE("Header Entry No." = FIELD("Entry No.")));
            Caption = 'AllowanceChargeAmtLine';
            Editable = false;
            FieldClass = FlowField;
        }
        field(311; AllowanceChargeRate; Decimal)
        {
            AutoFormatType = 2;
            BlankZero = true;
            Caption = 'AllowanceChargeRate';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(312; AllowanceChargeReason; Text[20])
        {
            Caption = 'AllowanceChargeReason';
            DataClassification = CustomerContent;
            TableRelation = "Reason Code";
        }
        field(313; AllowanceChargeBase; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = Sum("PRG_E-Invoice Line"."Line Extension Amount" WHERE("Header Entry No." = FIELD("Entry No.")));
            Caption = 'AllowanceChargeBase';
            Editable = false;
            FieldClass = FlowField;
        }
        field(314; AllowanceChargeMultiplierFactr; Decimal)
        {
            AutoFormatType = 2;
            BlankZero = true;
            Caption = 'AllowanceChargeMultiplierFactr';
            DataClassification = CustomerContent;
        }
        field(315; AllowanceChargeAmtInvoice; Decimal)
        {
            Caption = 'AllowanceChargeAmtInvoice';
            DataClassification = CustomerContent;
            DecimalPlaces = 2 : 2;
            Editable = false;
        }
        field(350; TaxableAmount; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = Sum("PRG_E-Invoice Tax Line".TaxExclusiveAmount WHERE("Header Entry No." = FIELD("Entry No."),
                                                                             "Header Line No." = CONST(0)));
            Caption = 'TaxableAmount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(360; TaxAmount; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = Sum("PRG_E-Invoice Tax Line".TaxAmount WHERE("Header Entry No." = FIELD("Entry No."),
                                                                    "Header Line No." = CONST(0),
                                                                    TaxType = FILTER(<> Witholding)));
            Caption = 'TaxAmount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(370; VATAmount; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = Sum("PRG_E-Invoice Tax Line".TaxAmount WHERE("Header Entry No." = FIELD("Entry No."),
                                                                    Type = CONST(Header),
                                                                    TaxType = FILTER(VAT)));
            Caption = 'VATAmount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(380; LineExtensionAmount; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = Sum("PRG_E-Invoice Line"."Line Extension Amount" WHERE("Header Entry No." = FIELD("Entry No.")));
            Caption = 'LineExtensionAmount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(390; TaxExclusiveAmount; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = Sum("PRG_E-Invoice Tax Line".TaxExclusiveAmount WHERE("Header Entry No." = FIELD("Entry No."),
                                                                             "Header Line No." = CONST(0),
                                                                             TaxType = FILTER(<> Witholding & <> Other)));
            Caption = 'TaxExclusiveAmount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(400; PayableAmount; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'PayableAmount';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(420; TaxInclusiveAmount; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = Sum("PRG_E-Invoice Tax Line".TaxInclusiveAmount WHERE("Header Entry No." = FIELD("Entry No."),
                                                                             "Header Line No." = CONST(0),
                                                                             TaxType = FILTER(<> Witholding & <> Other)));
            Caption = 'TaxInclusiveAmount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(700; IntegrationType; Option)
        {
            Caption = 'IntegrationType';
            DataClassification = CustomerContent;
            OptionCaption = 'E-Invoice,E-Archive';
            OptionMembers = EInvoice,EArchive;
        }
        field(710; SalesType; Option)
        {
            Caption = 'SalesType';
            DataClassification = CustomerContent;
            OptionMembers = " ",Internet;
        }
        field(720; "Carrier RegistrationNo"; Text[30])
        {
            Caption = 'Carrier RegistrationNo';
            DataClassification = CustomerContent;
        }
        field(730; "Carrier Name"; Text[50])
        {
            Caption = 'Carrier Name';
            DataClassification = CustomerContent;
        }
        field(740; Type; Option)
        {
            Caption = 'Type';
            DataClassification = CustomerContent;
            Editable = true;
            OptionCaption = ' ,Inbox,Outbox';
            OptionMembers = " ",Inbox,Outbox;
        }
        field(750; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            DataClassification = CustomerContent;
            Description = 'E-Export';
            TableRelation = "Country/Region";
        }
        field(760; "Company ID"; Text[20])
        {
            Caption = 'Company ID';
            DataClassification = CustomerContent;
            Description = 'E-Export';
        }
        field(770; "Payee VKN"; Text[11])
        {
            Caption = 'Payee VKN';
            DataClassification = CustomerContent;
        }
        field(780; "Related Invoice No."; Code[20])
        {
            Caption = 'Related Invoice No.';
            DataClassification = CustomerContent;
        }
        field(790; "Related Invoice Date"; Date)
        {
            Caption = 'Related Invoice Date';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
        }
        key(Key2; "G/L Register Entry No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        EInvLine: Record "PRG_E-Invoice Line";
        RefLine: Record "PRG_E-Invoice Reference Buffer";
        TaxLine: Record "PRG_E-Invoice Tax Line";
    begin
        EInvLine.SETRANGE("Header Entry No.", "Entry No.");
        EInvLine.DELETEALL();

        TaxLine.SETRANGE("Header Entry No.", "Entry No.");
        TaxLine.DELETEALL();

        RefLine.SETRANGE("Header Entry No.", "Entry No.");
        RefLine.DELETEALL();
    end;

    trigger OnModify()
    var
        Queue: Record "PRG_E-Invoice Queue";
    begin
        Queue.SETFILTER(UniqueIdentifier, UUID);
        Queue.SETRANGE("Queue Status", Queue."Queue Status"::SentToService);
        IF NOT Queue.ISEMPTY THEN
            ERROR(Text001);
    end;

    var
        Text001: Label 'If record is sent to service. No change is allowed';
}

