page 70093473 "PRG_E-Invoice Code Mapping"
{
    ApplicationArea = All;
    Caption = 'E-Invoice Code Mapping';
    PageType = List;
    SourceTable = "PRG_E-Invoice Code Mapping";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                Caption = 'General';
                field(Type; Rec.Type)
                {
                    ApplicationArea = All;
                    Caption = 'Type';
                    ToolTip = 'Specifies the value of the Type field.';
                }
                field("Source Code"; Rec."Source Code")
                {
                    ApplicationArea = All;
                    Caption = 'Source Code';
                    ToolTip = 'Specifies the value of the Source Code field.';
                }
                field("Destination Code"; Rec."Destination Code")
                {
                    ApplicationArea = All;
                    Caption = 'Destination Code';
                    ToolTip = 'Specifies the value of the Destination Code field.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Description';
                    ToolTip = 'Specifies the value of the Description field.';
                }
            }
        }
    }

    actions
    {
    }
}

