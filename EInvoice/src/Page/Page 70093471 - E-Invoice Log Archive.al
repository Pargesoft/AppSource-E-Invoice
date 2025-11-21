page 70093471 "PRG_E-Invoice Log Archive"
{
    Caption = 'E-Invoice Log Archive';
    PageType = ListPart;
    SourceTable = "PRG_E-Invoice Log Archive";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                Caption = 'Group';
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Caption = 'Status';
                    ToolTip = 'Specifies the value of the Status field.';
                }
                field("Creation DateTime"; Rec."Creation DateTime")
                {
                    ApplicationArea = All;
                    Caption = 'Creation Date Time';
                    ToolTip = 'Specifies the value of the Creation Date Time field.';
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
}

