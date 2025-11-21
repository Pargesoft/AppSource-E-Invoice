table 70093482 "PRG_Service Error Log"
{
    Caption = 'Service Error Log';
    DataClassification = CustomerContent;

    fields
    {
        field(1; LogID; Integer)
        {
            AutoIncrement = true;
            Caption = 'Log ID';
            DataClassification = CustomerContent;
        }
        field(2; LogDate; DateTime)
        {
            Caption = 'Log Date';
            DataClassification = CustomerContent;
        }
        field(3; Module; Text[50])
        {
            Caption = 'Module';
            DataClassification = CustomerContent;
        }
        field(4; EnvelopeID; Text[50])
        {
            Caption = 'Envelope ID';
            DataClassification = CustomerContent;
        }
        field(5; InvoiceID; Text[50])
        {
            Caption = 'Invoice ID';
            DataClassification = CustomerContent;
        }
        field(6; UUID; Text[50])
        {
            Caption = 'UUID';
            DataClassification = CustomerContent;
        }
        field(7; Stage; Text[50])
        {
            Caption = 'Stage';
            DataClassification = CustomerContent;
        }
        field(8; ErrorCode; Text[30])
        {
            Caption = 'Error Code';
            DataClassification = CustomerContent;
        }
        field(9; ErrorMessage; Text[250])
        {
            Caption = 'Error Message';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; LogID)
        {
        }
    }

    fieldgroups
    {
    }
}

