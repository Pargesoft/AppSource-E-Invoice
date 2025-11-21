pageextension 70093481 "PRG_EINV_PostedSalesInvoice" extends "Posted Sales Invoice"
{
    layout
    {
        addlast(General)
        {
            field("PRG_Exclude in E-Invoice"; Rec."PRG_Exclude in E-Invoice")
            {
                Caption = 'Exclude in E-Invoice';
                ApplicationArea = All;
            }
            field("PRG_E-Platform Type"; Rec."PRG_E-Platform Type")
            {
                ApplicationArea = All;
                Caption = 'E-Platform Type';
                ToolTip = 'Specifies the value of the E-Platform Type field.';
            }
        }
    }
}