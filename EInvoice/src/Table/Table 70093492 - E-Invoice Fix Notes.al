table 70093492 "PRG_E-Invoice Fix Notes"
{
    DataClassification = CustomerContent;
    Caption = 'E-Invoice Fix Notes';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(2; "Fix Note"; Text[250])
        {
            Caption = 'Fix Note';
            DataClassification = CustomerContent;
        }
        field(3; "For Sales"; Boolean)
        {
            Caption = 'For Sales';
            DataClassification = CustomerContent;
        }
        field(4; "For Purchase"; Boolean)
        {
            Caption = 'For Purchase';
            DataClassification = CustomerContent;
        }
        field(5; "For Service"; Boolean)
        {
            Caption = 'For Service';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }

}