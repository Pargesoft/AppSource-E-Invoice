pageextension 70093483 "PRG_EINV_PostedPurchCrMemoSub" extends "Posted Purch. Cr. Memo Subform"
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
            field("PRG_Tariff Number"; Rec."PRG_Tariff Number")
            {
                ApplicationArea = All;
                Caption = 'Tariff Number';
                ToolTip = 'Specifies the value of the Tariff Number field.';
            }
            field("PRG_Package Brand"; Rec."PRG_Package Brand")
            {
                ApplicationArea = All;
                Caption = 'Package Brand';
                ToolTip = 'Specifies the value of the Package Brand field.';
            }
            field("PRG_Packagin Type Code"; Rec."PRG_Packagin Type Code")
            {
                ApplicationArea = All;
                Caption = 'Packagin Type Code';
                ToolTip = 'Specifies the value of the Packagin Type Code field.';
            }
            field("PRG_Actual Package Quantity"; Rec."PRG_Actual Package Quantity")
            {
                ApplicationArea = All;
                Caption = 'Actual Package Quantity';
                ToolTip = 'Specifies the value of the Actual Package Quantity field.';
            }
        }
    }
    actions
    {
        addafter(Dimensions)
        {

            action("PRG_Tax Type Code Enterance")
            {
                ApplicationArea = All;
                Caption = 'Tax Type Code Enterance';
                Image = Statistics;
                ToolTip = 'Executes the Tax Type Code Enterance action.';
                trigger OnAction();
                var
                    TaxTypeCodeStdDialog: Page "PRG_Tax Type Code Enterance";
                begin
                    TaxTypeCodeStdDialog.SetInvLine(Rec."Document No.", Rec."Line No.");
                    TaxTypeCodeStdDialog.Run();
                    CurrPage.Update();
                end;
            }
        }
    }
}