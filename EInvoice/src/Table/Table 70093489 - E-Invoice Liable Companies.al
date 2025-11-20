table 70093489 "PRG_E-Invoice Liable Companies"
{
    Caption = 'E-Invoice Liable Companies';
    DataClassification = CustomerContent;
    DrillDownPageId = "PRG_E-Invoice Liable Companies";
    LookupPageId = "PRG_E-Invoice Liable Companies";

    fields
    {
        field(10; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = CustomerContent;
        }
        field(20; Identifier; Text[250])
        {
            Caption = 'Identifier';
            DataClassification = CustomerContent;
        }
        field(30; Alias; Text[250])
        {
            Caption = 'Alias';
            DataClassification = CustomerContent;
        }
        field(40; Title; Text[250])
        {
            Caption = 'Title';
            DataClassification = CustomerContent;
        }
        field(50; Type; Text[50])
        {
            Caption = 'Type';
            DataClassification = CustomerContent;
        }
        field(60; FirstCreationTime; Text[50])
        {
            Caption = 'FirstCreationTime';
            DataClassification = CustomerContent;
        }
        field(100; "Count In Customer"; Boolean)
        {
            CalcFormula = Exist(Customer WHERE("VAT Registration No." = FIELD(Identifier)));
            Caption = 'Count In Customer';
            Editable = false;
            FieldClass = FlowField;
        }
        field(200; "Count In Vendor"; Boolean)
        {
            CalcFormula = Exist(Vendor WHERE("VAT Registration No." = FIELD(Identifier)));
            Caption = 'Count In Vendor';
            Editable = false;
            FieldClass = FlowField;
        }
        field(500; "Number Of Occurrence"; Integer)
        {
            CalcFormula = Count("PRG_E-Invoice Liable Companies" WHERE(Identifier = FIELD(Identifier)));
            Caption = 'Number Of Occurrence';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
        }
        key(Key2; Identifier)
        {
        }
        key(Key3; Identifier, Alias)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; Identifier, Alias, Title)
        {

        }
        fieldgroup(Brick; Identifier, Alias, Title)
        {

        }
    }
}

