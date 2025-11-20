pageextension 70093471 "PRG_EINV_CustomerCard" extends "Customer Card"
{
    layout
    {
        addafter("VAT Registration No.")
        {
            field("PRG_Payee Firm"; Rec."PRG_Payee Firm")
            {
                ApplicationArea = All;
                Caption = 'Payee Firm';
                ToolTip = 'Specifies the value of the Payee Firm field.';
            }
            field("PRG_Alias"; Rec.PRG_Alias)
            {
                ApplicationArea = All;
                Caption = 'E-Invoice Alias';
                ToolTip = 'Specifies the value of the E-Invoice Alias field.';
            }
            field("PRG_Locked Alias"; Rec."PRG_Locked Alias")
            {
                ApplicationArea = All;
                Caption = 'Locked Alias';
                ToolTip = 'Specifies the value of the Locked Alias field.';
            }
            field("PRG_Profile ID"; Rec."PRG_Profile ID")
            {
                ApplicationArea = All;
                Caption = 'E-Invoice Profile ID';
                ToolTip = 'Specifies the value of the E-Invoice Profile ID field.';
            }
            field("PRG_County"; Rec.County)
            {
                ApplicationArea = All;
                Caption = 'County';
                ToolTip = 'Specifies the state, province or county as a part of the address.';
            }
            field("PRG_Exclude in E-Invoice"; Rec."PRG_Exclude in E-Invoice")
            {
                Caption = 'Exclude in E-Invoice';
                ApplicationArea = All;
            }
        }
    }
}