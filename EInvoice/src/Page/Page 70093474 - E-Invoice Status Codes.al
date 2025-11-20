page 70093474 "PRG_E-Invoice Status Codes"
{
    ApplicationArea = All;
    Caption = 'E-Invoice Status Codes';
    PageType = List;
    SourceTable = "PRG_E-Invoice Status Code";
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
                field("Error Code"; Rec."Error Code")
                {
                    ApplicationArea = All;
                    Caption = 'Error Code';
                    ToolTip = 'Specifies the value of the Error Code field.';
                }
            }
        }
    }

    actions
    {
    }
}

