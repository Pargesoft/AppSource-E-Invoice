page 70093479 "PRG_E-Invoice Tax Lines"
{
    AutoSplitKey = true;
    Caption = 'E-Invoice Tax Lines';
    PageType = List;
    SourceTable = "PRG_E-Invoice Tax Line";

    layout
    {
        area(content)
        {
            repeater(EInvoiceTaxLine)
            {
                Caption = 'EInvoiceTaxLine';
                field(Type; Rec.Type)
                {
                    ApplicationArea = All;
                    Caption = 'Type';
                    ToolTip = 'Specifies the value of the Type field.';
                }
                field("Header Line No."; Rec."Header Line No.")
                {
                    ApplicationArea = All;
                    Caption = 'Header Line No.';
                    ToolTip = 'Specifies the value of the Header Line No. field.';
                }
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = All;
                    Caption = 'Line No.';
                    ToolTip = 'Specifies the value of the Line No. field.';
                }
                field(TaxType; Rec.TaxType)
                {
                    ApplicationArea = All;
                    Caption = 'Tax Type';
                    ToolTip = 'Specifies the value of the Tax Type field.';
                }
                field(TaxTypeCode; Rec.TaxTypeCode)
                {
                    ApplicationArea = All;
                    Caption = 'Tax Type Code';
                    ToolTip = 'Specifies the value of the Tax Type Code field.';
                }
                field(TaxTypeName; Rec.TaxTypeName)
                {
                    ApplicationArea = All;
                    Caption = 'Tax Type Name';
                    ToolTip = 'Specifies the value of the Tax Type Name field.';
                }
                field(TaxPercent; Rec.TaxPercent)
                {
                    ApplicationArea = All;
                    Caption = 'Tax Percent';
                    ToolTip = 'Specifies the value of the Tax Percent field.';
                }
                field(TaxAmount; Rec.TaxAmount)
                {
                    ApplicationArea = All;
                    Caption = 'Tax Amount';
                    ToolTip = 'Specifies the value of the Tax Amount field.';
                }
                field(TaxExclusiveAmount; Rec.TaxExclusiveAmount)
                {
                    ApplicationArea = All;
                    Caption = 'Tax Exclusive Amount';
                    ToolTip = 'Specifies the value of the Tax Exclusive Amount field.';
                }
                field(TaxInclusiveAmount; Rec.TaxInclusiveAmount)
                {
                    ApplicationArea = All;
                    Caption = 'Tax Inclusive Amount';
                    ToolTip = 'Specifies the value of the Tax Inclusive Amount field.';
                }
                field("TaxExemption Reason Desc"; Rec."TaxExemption Reason Desc")
                {
                    ApplicationArea = All;
                    Caption = 'TaxExemption Reason Desc';
                    ToolTip = 'Specifies the value of the TaxExemption Reason Desc field.';
                }
                field("TaxExemption Reason Code"; Rec."TaxExemption Reason Code")
                {
                    ApplicationArea = All;
                    Caption = 'Tax Exemption Reason Code';
                    ToolTip = 'Specifies the value of the Tax Exemption Reason Code field.';
                }
                field(CalculationSequenceNumeric; Rec.CalculationSequenceNumeric)
                {
                    ApplicationArea = All;
                    Caption = 'Calculation Sequence Numeric';
                    ToolTip = 'Specifies the value of the Calculation Sequence Numeric field.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnModifyRecord(): Boolean
    Var
        CheckFunctions: Codeunit "PRG_E-Invoice Check Functions";
    begin
        CheckFunctions.CheckIfEditable();
    end;
}

