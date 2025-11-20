pageextension 70093480 "PRG_EINV_UserSetup" extends "User Setup"
{
    layout
    {
        addlast(Control1)
        {
            field("PRG_E-Invoice No. Series"; Rec."PRG_E-Invoice No. Series")
            {
                ApplicationArea = All;
                Caption = 'E-Invoice No. Series';
                ToolTip = 'Specifies the value of the E-Invoice No. Series field.';
            }
            field("PRG_E-Archive No. Series"; Rec."PRG_E-Archive No. Series")
            {
                ApplicationArea = All;
                Caption = 'E-Archive No. Series';
                ToolTip = 'Specifies the value of the E-Archive No. Series field.';
            }
        }
    }
}