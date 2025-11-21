pageextension 70093484 "PRG_EINV_ShiptoAddress" extends "Ship-to Address"
{
    layout
    {
        addlast(General)
        {
            field("PRG_E-Invoice E-mail Address"; Rec."PRG_E-Invoice E-mail Address")
            {
                ApplicationArea = All;
                Caption = 'E-Invoice E-mail Address';
                ToolTip = 'Specifies the value of the E-Invoice E-mail Address field.';
            }
        }
    }
}