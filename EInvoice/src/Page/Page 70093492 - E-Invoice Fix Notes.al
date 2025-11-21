page 70093492 "PRG_E-Invoice Fix Notes"
{
    PageType = List;
    SourceTable = "PRG_E-Invoice Fix Notes";
    Caption = 'E-Invoice Fix Notes';

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Fix Note"; Rec."Fix Note")
                {
                    ApplicationArea = All;
                    Caption = 'Fix Note';
                    ToolTip = 'Specifies the value of the Fix Note field.';
                }
                field("For Sales"; Rec."For Sales")
                {
                    ApplicationArea = All;
                    Caption = 'For Sales';
                    ToolTip = 'Specifies the value of the For Sales field.';
                }
                field("For Purchase"; Rec."For Purchase")
                {
                    ApplicationArea = All;
                    Caption = 'For Purchase';
                    ToolTip = 'Specifies the value of the For Purchase field.';
                }
                field("For Service"; Rec."For Service")
                {
                    ApplicationArea = All;
                    Caption = 'For Service';
                    ToolTip = 'Specifies the value of the For Service field.';
                }
            }
        }
    }
}