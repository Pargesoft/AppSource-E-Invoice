table 70093477 "PRG_E-Invoice Status Code"
{
    Caption = 'E-Invoice Status Code';
    DataClassification = CustomerContent;
    DataPerCompany = false;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            DataClassification = CustomerContent;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        field(3; "Error Code"; Boolean)
        {
            Caption = 'Error Code';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
        }
        key(Key2; Description)
        {
        }
    }
}

