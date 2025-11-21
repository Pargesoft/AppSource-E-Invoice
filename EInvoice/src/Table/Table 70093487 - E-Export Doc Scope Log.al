table 70093487 "PRG_E-Export Doc. Scope Log"
{
    Caption = 'E-Export Doc. Scope Log';
    DataClassification = CustomerContent;
    fields
    {
        field(10; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(20; "Document Type"; Option)
        {
            Caption = 'Document Type';
            DataClassification = CustomerContent;
            OptionCaption = ' ,Sale,Purchase';
            OptionMembers = " ",Sale,Purchase;
        }
        field(30; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = CustomerContent;
        }
        field(40; "CV Type"; Option)
        {
            Caption = 'CV Type';
            DataClassification = CustomerContent;
            OptionCaption = ' ,Customer,Vendor';
            OptionMembers = " ",Customer,Vendor;
        }
        field(50; "CV No."; Code[20])
        {
            Caption = 'CV No.';
            DataClassification = CustomerContent;
            TableRelation = IF ("CV Type" = CONST(Customer)) Customer
            ELSE
            IF ("CV Type" = CONST(Vendor)) Vendor;
        }
        field(60; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = CustomerContent;
        }
        field(70; "Old Value"; Text[30])
        {
            Caption = 'Old Value';
            DataClassification = CustomerContent;
        }
        field(80; "New Value"; Text[30])
        {
            Caption = 'New Value';
            DataClassification = CustomerContent;
        }
        field(90; "Created By"; Code[50])
        {
            Caption = 'Created By';
            DataClassification = CustomerContent;
            Editable = false;

        }
        field(100; "Creation Date"; Date)
        {
            Caption = 'Creation Date';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(110; "Creation Time"; Time)
        {
            Caption = 'Creation Time';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        "Created By" := USERID;
        "Creation Date" := TODAY;
        "Creation Time" := TIME;
    end;
}

