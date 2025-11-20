page 70093475 "PRG_E-Invoice Queue Log"
{
    Caption = 'E-Invoice Queue Log';
    Editable = false;
    PageType = ListPart;
    SourceTable = "PRG_E-Invoice Queue Log";
    layout
    {
        area(content)
        {
            repeater(General)
            {
                Caption = 'General';
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Caption = 'Status';
                    ToolTip = 'Specifies the value of the Status field.';
                }
                field("Creation DateTime"; Rec."Creation DateTime")
                {
                    ApplicationArea = All;
                    Caption = 'Creation DateTime';
                    ToolTip = 'Specifies the value of the Creation DateTime field.';
                }
                field("Created By"; Rec."Created By")
                {
                    ApplicationArea = All;
                    Caption = 'Created By';
                    ToolTip = 'Specifies the value of the Created By field.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Description';
                    ToolTip = 'Specifies the value of the Description field.';
                }
                field("Result Status Code"; Rec."Result Status Code")
                {
                    ApplicationArea = All;
                    Caption = 'Result Status Code';
                    ToolTip = 'Specifies the value of the Result Status Code field.';
                }
            }
        }
    }

    actions
    {
    }
}

