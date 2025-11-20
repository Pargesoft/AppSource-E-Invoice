pageextension 70093497 "PRG_Service Cr. Memo Subform" extends "Service Credit Memo Subform"
{
    layout
    {
        addlast(Control1)
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
