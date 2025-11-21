pageextension 70093491 "PRG_Posted Purch. Credit Memo" extends "Posted Purchase Credit Memo"
{
    layout
    {
        addlast(General)
        {
            field("PRG_Related Invoice No."; Rec."PRG_Related Invoice No.")
            {
                ApplicationArea = All;
                Caption = 'Related Invoice No.';
                ToolTip = 'Specifies the value of the Related Invoice No. field.';
            }
            field("PRG_Related Invoice Date"; Rec."PRG_Related Invoice Date")
            {
                ApplicationArea = All;
                Caption = 'Related Invoice Date';
                ToolTip = 'Specifies the value of the Related Invoice Date field.';
            }
        }
    }
}