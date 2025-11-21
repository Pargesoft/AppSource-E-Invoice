table 70093483 "PRG_E-Invoice Log Archive"
{
    Caption = 'E-Invoice Log Archive';
    DataClassification = CustomerContent;

    fields
    {
        field(10; "Header Entry No."; Integer)
        {
            Caption = 'Header Entry No.';
            DataClassification = CustomerContent;
        }
        field(11; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = CustomerContent;
        }
        field(30; Status; Option)
        {
            Caption = 'Status';
            DataClassification = CustomerContent;
            OptionCaption = ' ,New,Sent To Service,Result Received,Replied,Cancelled,Out of Scope,Failed';
            OptionMembers = " ",New,SentToService,ResultReceived,Replied,Cancelled,OutofScope,Failed;
        }
        field(80; "Creation DateTime"; DateTime)
        {
            Caption = 'Creation Date Time';
            DataClassification = CustomerContent;
        }
        field(81; "Created By"; Text[50])
        {
            Caption = 'Created By';
            DataClassification = CustomerContent;
        }
        field(100; Description; Text[250])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        field(110; "Result Status Code"; Code[20])
        {
            Caption = 'Result Status Code';
            DataClassification = CustomerContent;
            TableRelation = "PRG_E-Invoice Status Code";
        }
    }

    keys
    {
        key(Key1; "Header Entry No.", "Line No.")
        {
        }
    }

    fieldgroups
    {
    }
}

