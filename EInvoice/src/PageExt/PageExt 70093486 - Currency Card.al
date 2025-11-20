pageextension 70093486 "PRG_EINV_CurrencyCard" extends "Currency Card"
{
    layout
    {
        addlast(General)
        {
            field("PRG_E-Invoice Piastre Identifier"; Rec."PRG_E-Inv. Piastre Identifier")
            {
                ApplicationArea = All;
                Caption = 'E-Invoice Piastre Identifier';
                ToolTip = 'Specifies the value of the E-Invoice Piastre Identifier field.';
            }
        }
    }
}