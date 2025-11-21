page 70093491 "PRG_E-Invoice CV Info."
{
    Caption = 'E-Invoice CV Info.';
    PageType = List;
    SourceTable = "PRG_E-Invoice CV Info.";


    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                Caption = 'GroupName';
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
                field("CV Name"; Rec."CV Name")
                {
                    ApplicationArea = All;
                    Caption = 'CV Name';
                    ToolTip = 'Specifies the value of the CV Name field.';
                }
                field("Integration Type"; Rec."Integration Type")
                {
                    ApplicationArea = All;
                    Caption = 'Integration Type';
                    ToolTip = 'Specifies the value of the Integration Type field.';
                }
                field("Profile ID"; Rec."Profile ID")
                {
                    ApplicationArea = All;
                    Caption = 'Profile ID';
                    ToolTip = 'Specifies the value of the Profile ID field.';
                }
                field("Tax Exemption Code"; Rec."Tax Exemption Code")
                {
                    ApplicationArea = All;
                    Caption = 'Tax Exemption Code';
                    ToolTip = 'Specifies the value of the Tax Exemption Code field.';
                }
                field("First Name"; Rec."First Name")
                {
                    ApplicationArea = All;
                    Caption = 'First Name';
                    ToolTip = 'Specifies the value of the First Name field.';
                }
                field("Family Name"; Rec."Family Name")
                {
                    ApplicationArea = All;
                    Caption = 'Family Name';
                    ToolTip = 'Specifies the value of the Family Name field.';
                }
                field("E-mail Address"; Rec."E-mail Address")
                {
                    ApplicationArea = All;
                    Caption = 'E-mail Address';
                    ToolTip = 'Specifies the value of the E-mail Address field.';
                }
                field("E-Invoice Starting Date"; Rec."E-Invoice Starting Date")
                {
                    ApplicationArea = All;
                    Caption = 'E-Invoice Starting Date';
                    ToolTip = 'Specifies the value of the E-Invoice Starting Date field.';
                }
                field("Tax Registration No."; Rec."Tax Registration No.")
                {
                    ApplicationArea = All;
                    Caption = 'Tax Registration No.';
                    ToolTip = 'Specifies the value of the Tax Registration No. field.';
                }
                field("Creation Datetime"; Rec."Creation Datetime")
                {
                    ApplicationArea = All;
                    Caption = 'Creation Datetime';
                    ToolTip = 'Specifies the value of the Creation Datetime field.';
                }
                field("Last Update Datetime"; Rec."Last Update Datetime")
                {
                    ApplicationArea = All;
                    Caption = 'Last Update Datetime';
                    ToolTip = 'Specifies the value of the Last Update Datetime field.';
                }
                field("TaxSchemeID Buffer"; Rec."TaxSchemeID Buffer")
                {
                    ApplicationArea = All;
                    Caption = 'TaxSchemeID Buffer';
                    ToolTip = 'Specifies the value of the TaxSchemeID Buffer field.';
                }
                field(Locked; Rec.Locked)
                {
                    ApplicationArea = All;
                    Caption = 'Locked';
                    ToolTip = 'Specifies the value of the Locked field.';
                }
                field("Created By"; Rec."Created By")
                {
                    ApplicationArea = All;
                    Caption = 'Created By';
                    ToolTip = 'Specifies the value of the Created By field.';
                }
                field("Last Modified By"; Rec."Last Modified By")
                {
                    ApplicationArea = All;
                    Caption = 'Last Modified By';
                    ToolTip = 'Specifies the value of the Last Modified By field.';
                }
            }
        }
        area(Factboxes)
        {

        }
    }

    actions
    {
        area(processing)
        {

            action(AllEntries)
            {
                ApplicationArea = All;
                Caption = 'All Registered Companies';
                Image = AllLines;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                RunObject = Page "PRG_E-Invoice Liable Companies";
                ToolTip = 'Executes the All Registered Companies action.';
            }
        }
    }
}