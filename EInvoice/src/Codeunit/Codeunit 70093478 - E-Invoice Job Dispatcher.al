codeunit 70093478 "PRG_E-Invoice Job Dispatcher"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    begin
        case Rec."Parameter String" OF
            'UpdateEInvUser':
                ConnectorMgt.GetUserList();
            'GetIncomingInvoices':
                begin
                    ConnectorMgt.GetIncomingInvoiceList();
                    IncDocMgt.ExecuteWaitingQueue();
                end;
            'GetOutboxInvoices':
                EInvMgt.GetOutboxInvoice();
            'GetOutboxStatus':
                ConnectorMgt.BatchProcessOutboxStatus(Queue);
        end
    end;

    var
        Queue: Record "PRG_E-Invoice Queue";
        IncDocMgt: Codeunit "PRG_E-Invoice Inc. Doc. Mgt.";
        ConnectorMgt: Codeunit "PRG_E-Invoice Connector Mgt.";
        EInvMgt: Codeunit "PRG_E-Invoice Management";
}