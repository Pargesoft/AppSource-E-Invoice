pageextension 70093485 "PRG_EINV_OrderAddress" extends "Order Address"
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