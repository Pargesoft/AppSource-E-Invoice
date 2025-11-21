pageextension 70093490 "PRG_Purch. Rtrn Order Subform" extends "Purchase Return Order Subform"
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
