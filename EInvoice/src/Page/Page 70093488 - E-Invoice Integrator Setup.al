page 70093488 "PRG_E-Invoice Integrator Setup"
{
    ApplicationArea = All;
    Caption = 'E-Invoice Integrator Setup';
    PageType = Card;
    SourceTable = "PRG_E-Invoice Integrator Setup";
    UsageCategory = Administration;
    layout
    {
        area(content)
        {
            group("E-Fatura")
            {
                Caption = 'E-Invoice';
                field("E-Invoice Integrator"; Rec."E-Invoice Integrator")
                {
                    ApplicationArea = All;
                    Caption = 'E-Invoice Integrator';
                    ToolTip = 'Specifies the value of the E-Invoice Integrator field.';
                }
                field("E-Invoice Int. Auth. URL"; Rec."E-Invoice Int. Auth. URL")
                {
                    ApplicationArea = All;
                    Caption = 'E-Invoice Int. Auth. URL';
                    ToolTip = 'Specifies the value of the E-Invoice Int. Auth. URL field.';
                }
                field("E-Invoice Integrator URL"; Rec."E-Invoice Integrator URL")
                {
                    ApplicationArea = All;
                    Caption = 'E-Invoice Integrator URL';
                    ToolTip = 'Specifies the value of the E-Invoice Integrator URL field.';
                }
                field("E-Invoice Web Service UserName"; Rec."E-Invoice Web Service UserName")
                {
                    ApplicationArea = All;
                    Caption = 'E-Invoice Web Service UserName';
                    ToolTip = 'Specifies the value of the E-Invoice Web Service UserName field.';
                }
                field("E-Invoice Web Service Password"; Rec."E-Invoice Web Service Password")
                {
                    ApplicationArea = All;
                    Caption = 'E-Invoice Web Service Password';
                    ExtendedDatatype = Masked;
                    ToolTip = 'Specifies the value of the E-Invoice Web Service Password field.';
                }
                field("E-Invoice Integration Type"; Rec."E-Invoice Integration Type")
                {
                    ApplicationArea = All;
                    Caption = 'E-Invoice Integration Type';
                    ToolTip = 'Specifies the value of the E-Invoice Integration Type field.';
                    Visible = IdeaVisible;
                }
                field("E-Invoice Integration Version"; Rec."E-Invoice Integration Version")
                {
                    ApplicationArea = All;
                    Caption = 'E-Invoice Integration Version';
                    ToolTip = 'Specifies the value of the E-Invoice Integration Version field.';
                    Visible = IdeaVisible;
                }
                field("E-Invoice Active Company"; Rec."E-Invoice Active Company")
                {
                    ApplicationArea = All;
                    Caption = 'E-Invoice Active Company';
                    ToolTip = 'Specifies the value of the E-Invoice Active Company field.';
                    Visible = IdeaVisible;
                }
                field("E-Invoice Active Branch"; Rec."E-Invoice Active Branch")
                {
                    ApplicationArea = All;
                    Caption = 'E-Invoice Active Branch';
                    ToolTip = 'Specifies the value of the E-Invoice Active Branch field.';
                    Visible = IdeaVisible;
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = All;
                    Caption = 'Document Type';
                    ToolTip = 'Specifies the value of the Document Type field.';
                }
                field("Document Version"; Rec."Document Version")
                {
                    ApplicationArea = All;
                    Caption = 'Document Version';
                    ToolTip = 'Specifies the value of the Document Version field.';
                }
                field("Company Code"; Rec."Company Code")
                {
                    Caption = 'Company Code';
                    ToolTip = 'Specifies the value of the Company Code field.';
                    ApplicationArea = All;
                }
                field("Document Type Version"; Rec."Document Type Version")
                {
                    Caption = 'Document Type Version';
                    ToolTip = 'Specifies the value of the Document Type Version field.';
                    ApplicationArea = All;
                }
                field("E-Invoice Output Type"; Rec."E-Invoice Output Type")
                {
                    Caption = 'E-Invoice Output Type';
                    ApplicationArea = All;
                }
                field("Sending Method"; Rec."E-Invoice Sending Method")
                {
                    Caption = 'E-Invoice Sending Method';
                    ApplicationArea = All;
                }
            }
            group("E-Archive")
            {
                Caption = 'E-Archive';
                field("E-Archive Integrator"; Rec."E-Archive Integrator")
                {
                    ApplicationArea = All;
                    Caption = 'E-Archive Integrator';
                    ToolTip = 'Specifies the value of the E-Archive Integrator field.';
                }
                field("E-Archive Int. Auth. URL"; Rec."E-Archive Int. Auth. URL")
                {
                    ApplicationArea = All;
                    Caption = 'E-Archive Int. Auth. URL';
                    ToolTip = 'Specifies the value of the E-Archive Int. Auth. URL field.';
                }
                field("E-Archive Integrator URL"; Rec."E-Archive Integrator URL")
                {
                    ApplicationArea = All;
                    Caption = 'E-Archive Integrator URL';
                    ToolTip = 'Specifies the value of the E-Archive Integrator URL field.';
                }
                field("E-Archive Web Service UserName"; Rec."E-Archive Web Service UserName")
                {
                    ApplicationArea = All;
                    Caption = 'E-Archive Web Service UserName';
                    ToolTip = 'Specifies the value of the E-Archive Web Service UserName field.';
                }
                field("E-Archive Web Service Password"; Rec."E-Archive Web Service Password")
                {
                    ApplicationArea = All;
                    Caption = 'E-Archive Web Service Password';
                    ExtendedDatatype = Masked;
                    ToolTip = 'Specifies the value of the E-Archive Web Service Password field.';
                }
                field("E-Archive Output Type"; Rec."E-Archive Output Type")
                {
                    Caption = 'E-Archive Output Type';
                    ApplicationArea = All;
                }
            }

            group(Log)
            {
                Caption = 'Log Information';
                field("Created By"; Rec."Created By")
                {
                    ApplicationArea = All;
                    Caption = 'Created By';
                    ToolTip = 'Specifies the value of the Created By field.';
                }
                field("Creation DateTime"; Rec."Creation DateTime")
                {
                    ApplicationArea = All;
                    Caption = 'Creation DateTime';
                    ToolTip = 'Specifies the value of the Creation DateTime field.';
                }
                field("Last Modified By"; Rec."Last Modified By")
                {
                    ApplicationArea = All;
                    Caption = 'Last Modified By';
                    ToolTip = 'Specifies the value of the Last Modified By field.';
                }
                field("Last Modification DateTime"; Rec."Last Modification DateTime")
                {
                    ApplicationArea = All;
                    Caption = 'Last Modification DateTime';
                    ToolTip = 'Specifies the value of the Last Modification DateTime field.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            action("Import Tax Type")
            {
                ApplicationArea = All;
                Caption = 'Import Tax Type Code';
                Image = ImportCodes;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Executes the Import Tax Type Code action.';

                trigger OnAction()
                var
                    EInvMgt: Codeunit "PRG_E-Invoice Management";
                begin
                    EInvMgt.UpdateTaxCodeFromExcel();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.RESET();
        IF NOT Rec.GET() THEN BEGIN
            Rec.INIT();
            Rec.INSERT(TRUE);
        END;

        if Rec."E-Invoice Integrator" = Rec."E-Invoice Integrator"::Idea then
            IdeaVisible := true;
    end;

    var
        IdeaVisible: Boolean;
}