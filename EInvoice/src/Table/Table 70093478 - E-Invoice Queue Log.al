table 70093478 "PRG_E-Invoice Queue Log"
{
    Caption = 'E-Invoice Queue';
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
            OptionCaption = ' ,New,Sent To Service,Result Received,Replied,Cancelled,Out of Scope,Failed,Sent To Response';
            OptionMembers = " ",New,SentToService,ResultReceived,Replied,Cancelled,OutofScope,Failed,SentToResponse;
        }
        field(80; "Creation DateTime"; DateTime)
        {
            Caption = 'Creation DateTime';
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

    trigger OnInsert()
    begin
        "Creation DateTime" := CURRENTDATETIME;
        "Created By" := USERID;
    end;
}

