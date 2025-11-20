pageextension 70093479 "PRG_EINV_GLRegisters" extends "G/L Registers"
{
    layout
    {
        addlast(Control1)
        {
            field("PRG_E-Invoice Status"; Rec."PRG_E-Invoice Status")
            {
                ApplicationArea = All;
                Caption = 'E-Invoice Status';
                ToolTip = 'Specifies the value of the E-Invoice Status field.';
            }
        }
    }
}