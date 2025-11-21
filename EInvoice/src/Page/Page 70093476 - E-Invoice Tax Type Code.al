page 70093476 "PRG_E-Invoice Tax Type Code"
{
    ApplicationArea = All;
    Caption = 'E-Invoice Tax Type Code';
    PageType = List;
    SourceTable = "PRG_E-Invoice Tax Type Code";
    UsageCategory = Administration;
    layout
    {
        area(content)
        {
            repeater(General)
            {
                Caption = 'General';
                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                    Caption = 'Code';
                    ToolTip = 'Specifies the value of the Code field.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Description';
                    ToolTip = 'Specifies the value of the Description field.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = All;
                    Caption = 'Type';
                    ToolTip = 'Specifies the value of the Type field.';
                }
                field("Calculation Sequence Number"; Rec."Calculation Sequence Number")
                {
                    ApplicationArea = All;
                    Caption = 'Calculation Sequence Number';
                    ToolTip = 'Specifies the value of the Calculation Sequence Number field.';
                }
                field("Tax Rate"; Rec."Tax Rate")
                {
                    ApplicationArea = All;
                    Caption = 'Tax Rate';
                    ToolTip = 'Specifies the value of the Tax Rate field.';
                }
            }
        }
    }

    actions
    {
    }
}

