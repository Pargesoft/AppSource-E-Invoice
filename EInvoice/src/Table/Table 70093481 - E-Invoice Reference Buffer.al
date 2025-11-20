table 70093481 "PRG_E-Invoice Reference Buffer"
{
    Caption = 'E-Invoice Reference Buffer';
    DataClassification = CustomerContent;

    fields
    {
        field(10; "Header Entry No."; Integer)
        {
            Caption = 'Header Entry No.';
            DataClassification = CustomerContent;
        }
        field(20; "Source Line No."; Integer)
        {
            Caption = 'Source Line No.';
            DataClassification = CustomerContent;
        }
        field(30; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = CustomerContent;
        }
        field(40; "Reference Type"; Option)
        {
            Caption = 'Reference Type';
            DataClassification = CustomerContent;
            OptionCaption = ' ,Note,Despatch,Add. Doc. Ref.,Payment Method';
            OptionMembers = " ",Note,Despatch,AddDocRef,PaymentMethod;
        }
        field(50; "Reference Text"; Text[250])
        {
            Caption = 'Reference Text';
            DataClassification = CustomerContent;
        }
        field(51; "Reference Date"; Date)
        {
            Caption = 'Reference Date';
            DataClassification = CustomerContent;
        }
        field(60; "Source Type"; Option)
        {
            Caption = 'Source Type';
            DataClassification = CustomerContent;
            OptionCaption = ' ,Header,Line';
            OptionMembers = " ",Header,Line;
        }
    }

    keys
    {
        key(Key1; "Header Entry No.", "Source Line No.", "Line No.")
        {
        }
    }

    fieldgroups
    {
    }
}

