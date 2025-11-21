pageextension 70093487 "PRG_Purchase Order Subform" extends "Purchase Order Subform"
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