pageextension 70093477 "PRG_EINV_PurchaseCreditMemo" extends "Purchase Credit Memo"
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
            field("PRG_E-Platform Type"; Rec."PRG_E-Platform Type")
            {
                ApplicationArea = All;
                Caption = 'E-Platform Type';
                ToolTip = 'Specifies the value of the E-Platform Type field.';
            }
        }
    }
}