page 70093487 "PRG_E-Export Packaging Types"
{
    ApplicationArea = All;
    Caption = 'Export Packaging Type Code';
    PageType = List;
    SourceTable = "PRG_E-Export Packaging Types";
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
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    Caption = 'Name';
                    ToolTip = 'Specifies the value of the Name field.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Description';
                    ToolTip = 'Specifies the value of the Description field.';
                }
                field("Numeric Code"; Rec."Numeric Code")
                {
                    ApplicationArea = All;
                    Caption = 'Numeric Code';
                    ToolTip = 'Specifies the value of the Numeric Code field.';
                }
            }
        }
    }

    actions
    {
    }
}

