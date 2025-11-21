report 70093471 "PRG_Create E-Invoice Outbox"
{
    Caption = 'Create E-Invoice Outbox';
    ProcessingOnly = true;

    dataset
    {
        dataitem("G/L Register"; "G/L Register")
        {
            RequestFilterFields = "No.", SystemCreatedAt, "PRG_E-Invoice Status", "User ID";

            trigger OnAfterGetRecord()
            var
                IsHandled: Boolean;
            begin
                OnAfterGetRecordGlRegister("G/L Register", IsHandled);
                if IsHandled then
                    CurrReport.Skip();

                EInvMgt.InsertQueue("G/L Register", RecreateExisting, IncludeCancelledInv, FALSE);
            end;

            trigger OnPreDataItem()
            begin
                IF NOT UseGLReg THEN
                    CurrReport.BREAK();

                OnPreDataItemGlRegister("G/L Register");

            end;
        }
        dataitem(Customer; Customer)
        {
            RequestFilterFields = "No.";
            dataitem(CustLedgEntry; "Cust. Ledger Entry")
            {
                RequestFilterFields = "Posting Date";

                trigger OnAfterGetRecord()
                var
                    IsHandled: Boolean;
                begin

                    OnAfterGetRecordCustLedgEntry(CustLedgEntry, IsHandled);
                    if IsHandled then
                        CurrReport.Skip();

                    FindGLReg("Entry No.");

                    EInvMgt.InsertQueue(GLReg, RecreateExisting, IncludeCancelledInv, FALSE);
                end;

                trigger OnPreDataItem()
                begin
                    SETCURRENTKEY("Document Type", "Customer No.", "Posting Date", "Currency Code");
                    //SETRANGE("Document Type", "Document Type"::Invoice);
                    SETFILTER("Document Type", '%1|%2', CustLedgEntry."Document Type"::Invoice, CustLedgEntry."Document Type"::"Finance Charge Memo");
                    SETRANGE("Customer No.", Customer."No.");

                    OnPreDataItemCustLedgEntry(CustLedgEntry);
                end;
            }

            trigger OnPreDataItem()
            begin
                IF NOT UseCust THEN
                    CurrReport.BREAK();
            end;
        }
        dataitem(Vendor; Vendor)
        {
            RequestFilterFields = "No.";
            dataitem(VendLedgEntry; "Vendor Ledger Entry")
            {
                RequestFilterFields = "Posting Date";

                trigger OnAfterGetRecord()
                var
                    IsHandled: Boolean;
                begin
                    OnAfterGetRecordVendLedgEntry(VendLedgEntry, IsHandled);
                    if IsHandled then
                        CurrReport.Skip();

                    FindGLReg("Entry No.");

                    EInvMgt.InsertQueue(GLReg, RecreateExisting, IncludeCancelledInv, FALSE);
                end;

                trigger OnPreDataItem()
                begin
                    SETCURRENTKEY("Document Type", "Vendor No.", "Posting Date", "Currency Code");
                    SETRANGE("Document Type", "Document Type"::"Credit Memo");
                    SETRANGE("Vendor No.", Vendor."No.");

                    OnPreDataItemVendLedgEntry(VendLedgEntry);
                end;
            }

            trigger OnPreDataItem()
            begin
                IF NOT UseVend THEN
                    CurrReport.BREAK();
            end;
        }
        dataitem(ServiceInvHeader; "Service Invoice Header")
        {
            RequestFilterFields = "No.";

            trigger OnAfterGetRecord()
            var
                IsHandled: Boolean;
                ServiceLedEntry: Record "Service Ledger Entry";
                GLEntry: Record "G/L Entry";
                FirstEntryNo: Integer;
                LastEntryNo: Integer;
            begin
                OnAfterGetRecordServiceInvHeader(ServiceInvHeader, IsHandled);
                if IsHandled then
                    CurrReport.Skip();

                GLEntry.SetRange("Document No.", ServiceInvHeader."No.");
                GLEntry.SetRange("Posting Date", ServiceInvHeader."Posting Date");
                GLEntry.SetAscending("Entry No.", true);
                IF GLEntry.FindFirst() then
                    FirstEntryNo := GLEntry."Entry No.";

                GLEntry.SetAscending("Entry No.", false);
                IF GLEntry.FindFirst() then
                    LastEntryNo := GLEntry."Entry No.";

                GLReg.SETFILTER("From Entry No.", '<=%1', FirstEntryNo);
                GLReg.SETFILTER("To Entry No.", '>=%1', LastEntryNo);
                GLReg.FINDFIRST();

                EInvMgt.InsertQueue(GLReg, RecreateExisting, IncludeCancelledInv, FALSE);
            end;

            trigger OnPreDataItem()
            begin
                IF NOT UseService THEN
                    CurrReport.BREAK();
            end;
        }

    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group("Document Source")
                {
                    Caption = 'Options';
                    field(UseGLReg; UseGLReg)
                    {
                        ApplicationArea = All;
                        Caption = 'Use G/L Register';
                        ToolTip = 'Specifies the value of the Use G/L Register field.';
                    }
                    field(UseCust; UseCust)
                    {
                        ApplicationArea = All;
                        Caption = 'Use Cust. Entry';
                        ToolTip = 'Specifies the value of the Use Cust. Entry field.';
                    }
                    field(UseVend; UseVend)
                    {
                        ApplicationArea = All;
                        Caption = 'Use Vend. Entry';
                        ToolTip = 'Specifies the value of the Use Vend. Entry field.';
                    }
                    field(UseService; UseService)
                    {
                        ApplicationArea = All;
                        Caption = 'Use Service Inv. Header';
                        ToolTip = 'Specifies the value of the Use Service Inv. Header field.';
                    }
                    field(RecreateExisting; RecreateExisting)
                    {
                        ApplicationArea = All;
                        Caption = 'Allow Recreation';
                        ToolTip = 'Specifies the value of the Allow Recreation field.';
                    }
                    field(IncludeCancelledInv; IncludeCancelledInv)
                    {
                        ApplicationArea = All;
                        Caption = 'Include Cancelled Invoices';
                        ToolTip = 'Specifies the value of the Include Cancelled Invoices field.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        IF NOT UseGLReg AND NOT UseCust AND NOT UseVend AND NOT UseService THEN
            ERROR(Text001);
    end;

    var
        GLReg: Record "G/L Register";
        EInvMgt: Codeunit "PRG_E-Invoice Management";
        IncludeCancelledInv: Boolean;
        RecreateExisting: Boolean;
        UseCust: Boolean;
        UseGLReg: Boolean;
        UseVend: Boolean;
        UseService: Boolean;
        Text001: Label 'At least 1 option must be choosed';

    procedure FindGLReg(pEntryNo: Integer)
    begin
        GLReg.SETFILTER("From Entry No.", '<=%1', pEntryNo);
        GLReg.SETFILTER("To Entry No.", '>=%1', pEntryNo);
        GLReg.FINDFIRST();
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPreDataItemGlRegister(var GlReg: Record "G/L Register")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPreDataItemCustLedgEntry(var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPreDataItemVendLedgEntry(var VendLedgEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterGetRecordGlRegister(GlReg: Record "G/L Register"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterGetRecordCustLedgEntry(CustLedgEntry: Record "Cust. Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterGetRecordVendLedgEntry(VendLedgEntry: Record "Vendor Ledger Entry"; var IsHandled: Boolean)
    begin
    end;


    [IntegrationEvent(true, false)]
    local procedure OnAfterGetRecordServiceInvHeader(ServiceInvHeader: Record "Service Invoice Header"; var IsHandled: Boolean)
    begin
    end;

}