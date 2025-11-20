table 70093486 "PRG_E-Export Packaging Types"
{
    Caption = 'E-Export Packaging Types';
    DataClassification = CustomerContent;
    DrillDownPageID = "PRG_E-Export Packaging Types";
    LookupPageID = "PRG_E-Export Packaging Types";

    fields
    {
        field(10; "Code"; Code[10])
        {
            Caption = 'Code';
            DataClassification = CustomerContent;
        }
        field(20; Name; Text[30])
        {
            Caption = 'Name';
            DataClassification = CustomerContent;
        }
        field(30; Description; Text[50])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        field(40; "Numeric Code"; Integer)
        {
            Caption = 'Numeric Code';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
        }
    }

    fieldgroups
    {
    }
}

