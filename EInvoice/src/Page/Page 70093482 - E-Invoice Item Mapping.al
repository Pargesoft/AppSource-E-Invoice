page 70093482 "PRG_E-Invoice Item Mapping"
{
    ApplicationArea = All;
    AutoSplitKey = true;
    Caption = 'E-Invoice Item Mapping';
    PageType = List;
    SourceTable = "PRG_E-Invoice Item Mapping";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                Caption = 'General';
                field("CV Type"; Rec."CV Type")
                {
                    ApplicationArea = All;
                    Caption = 'CV Type';
                    ToolTip = 'Specifies the value of the CV Type field.';
                }
                field("CV No."; Rec."CV No.")
                {
                    ApplicationArea = All;
                    Caption = 'CV No.';
                    ToolTip = 'Specifies the value of the CV No. field.';
                }
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = All;
                    Caption = 'Line No.';
                    ToolTip = 'Specifies the value of the Line No. field.';
                }
                field("Mapping Type"; Rec."Mapping Type")
                {
                    ApplicationArea = All;
                    Caption = 'Mapping Type';
                    ToolTip = 'Specifies the value of the Mapping Type field.';
                }
                field("Incoming Description Text"; Rec."Incoming Description Text")
                {
                    ApplicationArea = All;
                    Caption = 'Incoming Description Text';
                    ToolTip = 'Specifies the value of the Incoming Description Text field.';
                }
                field("Dest. Line Type"; Rec."Dest. Line Type")
                {
                    ApplicationArea = All;
                    Caption = 'Dest. Line Type';
                    ToolTip = 'Specifies the value of the Dest. Line Type field.';
                }
                field("Dest. Line No."; Rec."Dest. Line No.")
                {
                    ApplicationArea = All;
                    Caption = 'Dest. No.';
                    ToolTip = 'Specifies the value of the Dest. No. field.';
                }
                field(Priority; Rec.Priority)
                {
                    ApplicationArea = All;
                    Caption = 'Priority';
                    ToolTip = 'Specifies the value of the Priority field.';
                }
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                    Caption = 'Enabled';
                    ToolTip = 'Specifies the value of the Enabled field.';
                }
            }
        }
    }

    actions
    {
    }
}

