pageextension 70093489 "PRG_Sales Cr. Memo Subform" extends "Sales Cr. Memo Subform"
{
    layout
    {
        addlast(Control1)
        {
            field("PRG_E-Invoice Tax Type Code"; Rec."PRG_E-Invoice Tax Type Code")
            {
                Caption = 'E-Invoice Tax Type Code';
                ApplicationArea = All;
            }
        }
    }
}