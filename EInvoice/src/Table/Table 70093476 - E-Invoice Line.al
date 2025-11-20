table 70093476 "PRG_E-Invoice Line"
{
    Caption = 'E-Invoice Line';
    DataClassification = CustomerContent;

    fields
    {
        field(10; "Header Entry No."; Integer)
        {
            Caption = 'Header Entry No.';
            DataClassification = CustomerContent;
            TableRelation = "PRG_E-Invoice Header";
        }
        field(20; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = CustomerContent;
        }
        field(25; UUID; Guid)
        {
            DataClassification = CustomerContent;
        }
        field(40; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DataClassification = CustomerContent;
        }
        field(50; "Line Extension Amount"; Decimal)
        {
            Caption = 'Line Extension Amount';
            DataClassification = CustomerContent;
            DecimalPlaces = 2 : 5;
        }
        field(51; "Allowance Charge Indicator"; Text[10])
        {
            Caption = 'Allowance Charge Indicator';
            DataClassification = CustomerContent;
            InitValue = 'false';
        }
        field(52; "Allowance Charge Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Allowance Charge Amount';
            DataClassification = CustomerContent;
        }
        field(53; "Allowance Charge Rate"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Allowance Charge Rate';
            DataClassification = CustomerContent;
        }
        field(54; "Allowance Charge Reason"; Text[50])
        {
            AutoFormatType = 2;
            Caption = 'Allowance Charge Reason';
            DataClassification = CustomerContent;
        }
        field(60; "Taxable Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("PRG_E-Invoice Tax Line".TaxExclusiveAmount WHERE("Header Entry No." = FIELD("Header Entry No."),
                                                                             "Header Line No." = FIELD("Line No."),
                                                                             TaxType = FILTER(<> Witholding)));
            Caption = 'Taxable Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(61; "Tax Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("PRG_E-Invoice Tax Line".TaxAmount WHERE("Header Entry No." = FIELD("Header Entry No."),
                                                                    "Header Line No." = FIELD("Line No.")));
            Caption = 'Tax Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(64; "Tax Inclusive Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("PRG_E-Invoice Tax Line".TaxInclusiveAmount WHERE("Header Entry No." = FIELD("Header Entry No."),
                                                                             "Header Line No." = FIELD("Line No."),
                                                                             TaxType = FILTER(<> Witholding)));
            Caption = 'Tax Inclusive Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(65; "VAT Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("PRG_E-Invoice Tax Line".TaxAmount WHERE("Header Entry No." = FIELD("Header Entry No."),
                                                                    "Header Line No." = FIELD("Line No."),
                                                                    TaxType = CONST(VAT)));
            Caption = 'VAT Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(70; "Item Name"; Text[250])
        {
            Caption = 'Item Name';
            DataClassification = CustomerContent;
        }
        field(80; Description; Text[250])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        field(90; "Brand Name"; Text[30])
        {
            Caption = 'Brand Name';
            DataClassification = CustomerContent;
        }
        field(100; "Model Name"; Text[30])
        {
            Caption = 'Model Name';
            DataClassification = CustomerContent;
        }
        field(110; "Buyers Item Identification"; Text[100])
        {
            Caption = 'Buyers Item Identification';
            DataClassification = CustomerContent;
        }
        field(120; "Sellers Item Identification"; Text[20])
        {
            Caption = 'Sellers Item Identification';
            DataClassification = CustomerContent;
        }
        field(130; "Manu. Item Identification"; Text[100])
        {
            Caption = 'Manu. Item Identification';
            DataClassification = CustomerContent;
        }
        field(131; "Unit Price"; Decimal)
        {
            Caption = 'Unit Price';
            DataClassification = CustomerContent;
            DecimalPlaces = 2 : 5;
        }
        field(140; "Unit Of Measure Code"; Text[10])
        {
            Caption = 'Unit Of Measure Code';
            DataClassification = CustomerContent;
        }
        field(150; "VAT Percent"; Decimal)
        {
            CalcFormula = Lookup("PRG_E-Invoice Tax Line".TaxPercent WHERE("Header Entry No." = FIELD("Header Entry No."),
                                                                        "Header Line No." = FIELD("Line No.")));
            Caption = 'VAT Percent';
            FieldClass = FlowField;
        }
        field(160; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(180; "Delivery Terms"; Code[10])
        {
            Caption = 'Delivery Terms';
            DataClassification = CustomerContent;
            Description = 'E-Export';
            TableRelation = "Shipment Method";
        }
        field(190; "Transport Mode Code"; Code[10])
        {
            Caption = 'Transport Mode Code';
            DataClassification = CustomerContent;
            Description = 'E-Export';
            TableRelation = "Transport Method";
        }
        field(220; "Transportation Type"; Option)
        {
            Caption = 'Transportation Type';
            DataClassification = CustomerContent;
            Description = 'E-Export';
            OptionCaption = ' ,Air,Road,Rail,Maritime';
            OptionMembers = " ",Air,Road,Rail,Maritime;
        }
        field(260; "Transportation ID"; Text[30])
        {
            Caption = 'Transportation ID';
            DataClassification = CustomerContent;
            Description = 'E-Export';
        }
        field(270; "Package Brand"; Code[20])
        {
            Caption = 'Package Brand';
            DataClassification = CustomerContent;
        }
        field(280; "Packagin Type Code"; Code[10])
        {
            Caption = 'Packagin Type Code';
            DataClassification = CustomerContent;
            TableRelation = "PRG_E-Export Packaging Types";
        }
        field(290; "Actual Package Quantity"; Decimal)
        {
            Caption = 'Actual Package Quantity';
            DataClassification = CustomerContent;
        }
        field(300; "GTIP No."; Code[20])
        {
            Caption = 'GTIP No.';
            DataClassification = CustomerContent;
            Description = 'E-Export';
        }
        field(370; "Delivery City Name"; Text[50])
        {
            Caption = 'Delivery City Name';
            DataClassification = CustomerContent;
            Description = 'E-Export';
        }
        field(390; "Delivery Country Name"; Text[30])
        {
            Caption = 'Delivery Country Name';
            DataClassification = CustomerContent;
            Description = 'E-Export';
        }
        field(450; "Incoming Document Line No."; Integer)
        {
            Caption = 'Incoming Document Line No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(460; "Carriage Amount"; Decimal)
        {
            Caption = 'Carriage Amount';
            DataClassification = CustomerContent;
        }
        field(470; "Insurance Amount"; Decimal)
        {
            Caption = 'Insurance Amount';
            DataClassification = CustomerContent;
        }
        field(480; "Type"; Option)
        {
            Caption = 'Type';
            DataClassification = CustomerContent;
            OptionCaption = ' ,G/L Account,Item,Charge (Item)';
            OptionMembers = " ","G/L Account",Item,"Charge (Item)";
            trigger OnValidate()
            begin
                Clear("No.");
            end;
        }
        field(490; "No."; Code[20])
        {
            Caption = 'No.';
            DataClassification = CustomerContent;
            TableRelation = IF ("Type" = CONST("G/L Account")) "G/L Account" WHERE("Direct Posting" = CONST(TRUE))
            ELSE
            IF ("Type" = CONST(Item)) Item
            else
            IF ("Type" = CONST("Charge (Item)")) "Item Charge";
        }
        field(500; "Success Mapping"; Boolean)
        {
            Caption = 'Success Mapping';
            DataClassification = CustomerContent;
        }
        field(550; LineRecordId; RecordId)
        {
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; "Header Entry No.", "Line No.")
        {
            SumIndexFields = "Allowance Charge Amount", "Line Extension Amount";
        }
    }
}

