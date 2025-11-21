page 70093489 "PRG_E-Invoice Liable Companies"
{
    ApplicationArea = All;
    Caption = 'E-Invoice Liable Companies';
    PageType = List;
    SourceTable = "PRG_E-Invoice Liable Companies";
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                Caption = 'General';
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    Caption = 'Entry No.';
                    ToolTip = 'Specifies the value of the Entry No. field.';
                }
                field(Identifier; Rec.Identifier)
                {
                    ApplicationArea = All;
                    Caption = 'Identifier';
                    ToolTip = 'Specifies the value of the Identifier field.';
                }
                field(Alias; Rec.Alias)
                {
                    ApplicationArea = All;
                    Caption = 'Alias';
                    ToolTip = 'Specifies the value of the Alias field.';
                }
                field(Title; Rec.Title)
                {
                    ApplicationArea = All;
                    Caption = 'Title';
                    ToolTip = 'Specifies the value of the Title field.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = All;
                    Caption = 'Type';
                    ToolTip = 'Specifies the value of the Type field.';
                }
                field(FirstCreationTime; Rec.FirstCreationTime)
                {
                    ApplicationArea = All;
                    Caption = 'FirstCreationTime';
                    ToolTip = 'Specifies the value of the FirstCreationTime field.';
                }
                field("Count In Customer"; Rec."Count In Customer")
                {
                    ApplicationArea = All;
                    Caption = 'Count In Customer';
                    ToolTip = 'Specifies the value of the Count In Customer field.';
                }
                field("Count In Vendor"; Rec."Count In Vendor")
                {
                    ApplicationArea = All;
                    Caption = 'Count In Vendor';
                    ToolTip = 'Specifies the value of the Count In Vendor field.';
                }
                field("Number Of Occurrence"; Rec."Number Of Occurrence")
                {
                    ApplicationArea = All;
                    Caption = 'Number Of Occurrence';
                    ToolTip = 'Specifies the value of the Number Of Occurrence field.';
                }
            }
        }
    }
    actions
    {
        area(processing)
        {
            group(Information)
            {
                Caption = 'Process';
                action("Upate User List")
                {
                    ApplicationArea = All;
                    Caption = 'Update User List';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Executes the Update User List action.';
                    trigger OnAction();
                    var
                        ConnectorMgt: Codeunit "PRG_E-Invoice Connector Mgt.";
                    begin
                        ConnectorMgt.GetUserList();
                    end;
                }
                action("Upate User List From CV")
                {
                    ApplicationArea = All;
                    Caption = 'Update User List By Date';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Executes the Update User List By Date action.';
                    trigger OnAction();
                    var
                        WBConnector: Codeunit "PRG_E-Invoice WB Connector";
                    begin
                        WBConnector.QueryUpdateEInvoiceList();
                    end;
                }
            }
        }
    }
}