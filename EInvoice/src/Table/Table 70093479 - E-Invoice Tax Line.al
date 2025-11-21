table 70093479 "PRG_E-Invoice Tax Line"
{
    Caption = 'E-Invoice Tax Line';
    DataClassification = CustomerContent;

    fields
    {
        field(10; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = CustomerContent;
        }
        field(15; TaxTypeName; Text[250])
        {
            Caption = 'Tax Type Name';
            DataClassification = CustomerContent;
        }
        field(20; TaxTypeCode; Code[50])
        {
            Caption = 'Tax Type Code';
            DataClassification = CustomerContent;
            TableRelation = "PRG_E-Invoice Tax Type Code";
        }
        field(21; TaxType; Option)
        {
            Caption = 'Tax Type';
            DataClassification = CustomerContent;
            OptionCaption = ' ,Tax,Other,Witholding,Exception,Partial Exception,Specific Base,Exported';
            OptionMembers = " ",VAT,Other,Witholding,Exception,PartialException,SpecificBase,Exported;
        }
        field(30; TaxPercent; Decimal)
        {
            Caption = 'Tax Percent';
            DataClassification = CustomerContent;
            DecimalPlaces = 3 : 2;
        }
        field(40; TaxAmount; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Tax Amount';
            DataClassification = CustomerContent;
        }
        field(50; TaxExclusiveAmount; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Tax Exclusive Amount';
            DataClassification = CustomerContent;
        }
        field(60; TaxInclusiveAmount; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Tax Inclusive Amount';
            DataClassification = CustomerContent;
        }
        field(70; "TaxExemption Reason Desc"; Text[250])
        {
            Caption = 'TaxExemption Reason Desc';
            DataClassification = CustomerContent;
        }
        field(71; "TaxExemption Reason Code"; Code[10])
        {
            Caption = 'Tax Exemption Reason Code';
            DataClassification = CustomerContent;
            TableRelation = "PRG_E-Invoice Tax Type Code";
        }
        field(80; CalculationSequenceNumeric; Integer)
        {
            Caption = 'Calculation Sequence Numeric';
            DataClassification = CustomerContent;
        }
        field(90; Type; Option)
        {
            Caption = 'Type';
            DataClassification = CustomerContent;
            OptionCaption = ' ,Header,Line';
            OptionMembers = " ",Header,Line;
        }
        field(100; "Header Entry No."; Integer)
        {
            Caption = 'Header Entry No.';
            DataClassification = CustomerContent;
        }
        field(110; "Header Line No."; Integer)
        {
            Caption = 'Header Line No.';
            DataClassification = CustomerContent;
        }
        field(120; HeaderInvoiceType; Option)
        {
            CalcFormula = Lookup("PRG_E-Invoice Header".InvoiceType WHERE("Entry No." = FIELD("Header Entry No.")));
            Caption = 'InvoiceType';
            Editable = false;
            FieldClass = FlowField;
            OptionCaption = ' ,Sales,SalesCr,Purch,PurchCr,Withholding,Exception,Specific Base,Exported';
            OptionMembers = " ",Sales,SalesCr,Purch,PurchCr,Withholding,Exception,SpecificBase,Exported;
        }
    }

    keys
    {
        key(Key1; "Header Entry No.", "Header Line No.", "Line No.")
        {
        }
        key(Key2; TaxType, Type, TaxTypeCode)
        {
            SumIndexFields = TaxAmount, TaxExclusiveAmount, TaxInclusiveAmount;
        }
        key(Key3; "Header Entry No.", "Header Line No.", CalculationSequenceNumeric)
        {
        }
    }

    fieldgroups
    {
    }
}

