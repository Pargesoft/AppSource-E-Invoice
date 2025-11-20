pageextension 70093534 "PRG_SalesRelationshipMgrRC" extends "Sales & Relationship Mgr. RC"
{
    actions
    {
        addbefore(Action257)
        {
            group(PRG_EInvoice)
            {
                Caption = 'Pargesoft E-Invoice';
                Image = Travel;
                ToolTip = 'Manage Pargesoft Solutions';
                Group(PRG_Task)
                {

                    Caption = 'Task';
                    action(PRG_IncomingQueue)
                    {
                        ApplicationArea = All;
                        Caption = 'Incoming Queue';
                        RunObject = page "PRG_E-Invoice Incoming Queue";
                        ToolTip = 'Open E-Invoice Incoming Queue Page';
                    }
                    action(PRG_OutgoingQueue)
                    {
                        ApplicationArea = All;
                        Caption = 'Outgoing Queue';
                        RunObject = page "PRG_E-Invoice Outgoing Queue";
                        ToolTip = 'Open E-Invoice Outgoing Queue Page';
                    }
                    action("PRG_E-InvoiceArchive")
                    {
                        ApplicationArea = All;
                        Caption = 'E-Invoice Archive';
                        RunObject = page "PRG_E-Invoice Archive";
                        ToolTip = 'OpenE-Invoice Archive Page';
                    }


                }
                Group(PRG_Setuo)
                {
                    Caption = 'Setup';
                    action("PRG_E-InvoiceSetup")
                    {
                        ApplicationArea = All;
                        Caption = 'E-Invoice Setup';
                        RunObject = page "PRG_E-Invoice Setup";
                        ToolTip = 'Open E-Invoice Setup Page';
                    }
                    action("PRG_E-InvoiceIntegrationSetup")
                    {
                        ApplicationArea = All;
                        Caption = 'E-Invoice Integration Setup';
                        RunObject = page "PRG_E-Invoice Integrator Setup";
                        ToolTip = 'Open E-Invoice Integration Setup Page';
                    }
                    action("PRG_E-InvoiceCodeMapping")
                    {
                        ApplicationArea = All;
                        Caption = 'E-Invoice Code Mapping';
                        RunObject = page "PRG_E-Invoice Code Mapping";
                        ToolTip = 'Open E-Invoice Code Mapping Page';
                    }
                    action("PRG_E-InvoiceTaxTypeCode")
                    {
                        ApplicationArea = All;
                        Caption = 'E-Invoice Tax Type Code';
                        RunObject = page "PRG_E-Invoice Tax Type Code";
                        ToolTip = 'Open E-Invoice Tax Type Code Page';
                    }
                    action("PRG_E-InvoiceStatusCodes")
                    {
                        ApplicationArea = All;
                        Caption = 'E-Invoice Status Codes';
                        RunObject = page "PRG_E-Invoice Status Codes";
                        ToolTip = 'Open E-Invoice Status Codes Page';
                    }
                    action("PRG_E-InvoiceCVInfo.")
                    {
                        ApplicationArea = All;
                        Caption = 'E-Invoice Liable Companies';
                        RunObject = page "PRG_E-Invoice Liable Companies";
                        ToolTip = 'Open E-Invoice Liable Companies Page';
                    }
                    action("PRG_E-InvoiceItemMapping")
                    {
                        ApplicationArea = All;
                        Caption = 'E-Invoice Item Mapping';
                        RunObject = page "PRG_E-Invoice Item Mapping";
                        ToolTip = 'Open E-Invoice Item Mapping Page';
                    }
                    action("PRG_E-ExportSetup")
                    {
                        ApplicationArea = All;
                        Caption = 'E-Export Setup';
                        RunObject = page "PRG_E-Export Setup";
                        ToolTip = 'Open E-Export Setup Page';
                    }
                }

            }
        }
    }

}