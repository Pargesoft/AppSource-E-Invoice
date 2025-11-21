pageextension 70093472 "PRG_EINV_VendorCard" extends "Vendor Card"
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
                Caption = 'Alias';
                ToolTip = 'Specifies the value of the Alias field.';
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
                Caption = 'Profile ID';
                ToolTip = 'Specifies the value of the PRG_Profile ID field.';
            }
            field("PRG_County"; Rec.County)
            {
                ApplicationArea = All;
                Caption = 'County';
                ToolTip = 'Specifies the state, province or county as a part of the address.';
            }
        }
    }
}