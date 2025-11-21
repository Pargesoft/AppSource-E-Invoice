pageextension 70093488 "PRG_Purch. Invoice Subform" extends "Purch. Invoice Subform"
{
    layout
    {
        addlast(PurchDetailLine)
        {
            field("PRG_E-Invoice Tax Type Code"; Rec."PRG_E-Invoice Tax Type Code")
            {
                ApplicationArea = All;
                Caption = 'E-Invoice Tax Type Code';
                ToolTip = 'Specifies the value of the E-Invoice Tax Type Code field.';
            }
        }
    }
}