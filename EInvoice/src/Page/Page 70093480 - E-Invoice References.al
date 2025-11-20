page 70093480 "PRG_E-Invoice References"
{
    AutoSplitKey = true;
    Caption = 'E-Invoice Reference Buffer';
    PageType = List;
    SourceTable = "PRG_E-Invoice Reference Buffer";

    layout
    {
        area(content)
        {
            repeater(EInvoiceReferanceBuffer)
            {
                Caption = 'EInvoiceReferanceBuffer';
                field("Source Line No."; Rec."Source Line No.")
                {
                    ApplicationArea = All;
                    Caption = 'Source Line No.';
                    ToolTip = 'Specifies the value of the Source Line No. field.';
                    Visible = false;
                }
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = All;
                    Caption = 'Line No.';
                    ToolTip = 'Specifies the value of the Line No. field.';
                }
                field("Source Type"; Rec."Source Type")
                {
                    ApplicationArea = All;
                    Caption = 'Source Type';
                    ToolTip = 'Specifies the value of the Source Type field.';
                }
                field("Reference Type"; Rec."Reference Type")
                {
                    ApplicationArea = All;
                    Caption = 'Reference Type';
                    ToolTip = 'Specifies the value of the Reference Type field.';
                }
                field("Reference Text"; Rec."Reference Text")
                {
                    ApplicationArea = All;
                    Caption = 'Reference Text';
                    ToolTip = 'Specifies the value of the Reference Text field.';
                }
                field("Reference Date"; Rec."Reference Date")
                {
                    ApplicationArea = All;
                    Caption = 'Reference Date';
                    ToolTip = 'Specifies the value of the Reference Date field.';
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

