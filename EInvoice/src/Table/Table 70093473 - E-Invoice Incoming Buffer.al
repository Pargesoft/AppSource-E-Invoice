table 70093473 "PRG_E-Invoice Incoming Buffer"
{
    Caption = 'E-Invoice Incoming Buffer';
    DataClassification = CustomerContent;

    fields
    {
        field(10; "Entry No."; Integer)
        {
            Caption = 'Entry No';
            DataClassification = CustomerContent;
        }
        field(20; "Invoice Value"; Blob)
        {
            Caption = 'Invoice Value';
            DataClassification = CustomerContent;
        }
        field(30; "Document ID"; Text[50])
        {
            Caption = 'Document ID';
            DataClassification = CustomerContent;
        }
        field(40; "Created By"; Code[50])
        {
            Caption = 'Created By';
            DataClassification = CustomerContent;
        }
        field(50; "Created DateTime"; DateTime)
        {
            Caption = 'Created DateTime';
            DataClassification = CustomerContent;
        }
    }

    trigger OnInsert()
    begin
        "Created By" := UserId;
        "Created DateTime" := CurrentDateTime;
    end;
}