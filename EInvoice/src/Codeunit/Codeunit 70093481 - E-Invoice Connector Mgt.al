codeunit 70093481 "PRG_E-Invoice Connector Mgt."
{
    procedure SendInvoice(XmlDoc: XmlDocument; UUID: GUID)
    begin
        GetIntSetup;

        case IntSetup."E-Invoice Integrator" OF
            IntSetup."E-Invoice Integrator"::Uyumsoft:
                if IntSetup."E-Invoice Sending Method" = IntSetup."E-Invoice Sending Method"::Zip then
                    UyumsoftConnector.SendInvoiceZip(XmlDoc, UUID)
                else if IntSetup."E-Invoice Sending Method" = IntSetup."E-Invoice Sending Method"::Draft then
                    UyumsoftConnector.SendInvoiceDraft(XmlDoc, UUID);
            IntSetup."E-Invoice Integrator"::Efinans:
                EFinansConnector.SendDocument(XmlDoc, UUID);
            IntSetup."E-Invoice Integrator"::Idea:
                IdeaConnector.SendInvoiceZip(XmlDoc, UUID);
        end;
    end;

    procedure GetIncomingInvoiceList()
    begin
        GetIntSetup;

        case IntSetup."E-Invoice Integrator" OF
            IntSetup."E-Invoice Integrator"::Uyumsoft:
                UyumsoftConnector.GetIncomingInvoiceList();
            IntSetup."E-Invoice Integrator"::Efinans:
                EFinansConnector.GetIncomingInvoiceList();
            IntSetup."E-Invoice Integrator"::Idea:
                IdeaConnector.GetIncomingInvoices();
        end;
    end;

    procedure GetUserList()
    begin
        GetIntSetup;

        case IntSetup."E-Invoice Integrator" OF
            IntSetup."E-Invoice Integrator"::Uyumsoft:
                UyumsoftConnector.QueryUpdateEInvoiceList();
            IntSetup."E-Invoice Integrator"::Efinans:
                EFinansConnector.GetUserList();
            IntSetup."E-Invoice Integrator"::Idea:
                IdeaConnector.GetUserList();
        end;
    end;

    procedure SendApprovalStatus(var Queue: Record "PRG_E-Invoice Queue"; Status: Enum "PRG_E-Invoice Approval Status"; StatusDescription: Text[250])
    begin
        GetIntSetup();

        case IntSetup."E-Invoice Integrator" of
            IntSetup."E-Invoice Integrator"::Uyumsoft:
                UyumsoftConnector.SendDocumentResponse(Queue, Status, StatusDescription);
        end;
    end;

    //Will be removed in future versions //TODO
    [Obsolete('This procedure is obsolete and will be removed in future versions.')]
    procedure GetSingleUser(vknTckn: Text; CV: Option Cust,Vend)
    begin
        GetIntSetup();

        case IntSetup."E-Invoice Integrator" of
            IntSetup."E-Invoice Integrator"::Efinans:
                EFinansConnector.GetSingleUser(vknTckn, CV);
        end;
    end;

    procedure GetSingleCustomer(var Cust: Record Customer)
    begin
        GetIntSetup();

        case IntSetup."E-Invoice Integrator" of
            IntSetup."E-Invoice Integrator"::Uyumsoft:
                UyumsoftConnector.GetSingleCustomer(Cust);
        end;
    end;

    procedure GetSingleVendor(var Vend: Record Vendor)
    begin
        GetIntSetup();

        case IntSetup."E-Invoice Integrator" of
            IntSetup."E-Invoice Integrator"::Uyumsoft:
                UyumsoftConnector.GetSingleVendor(Vend);
        end;
    end;

    procedure DownloadOutgoingPdf(UUID: Guid)
    begin
        GetIntSetup;

        case IntSetup."E-Invoice Integrator" OF
            IntSetup."E-Invoice Integrator"::Uyumsoft:
                UyumsoftConnector.GetOutboxPdf(UUID);
            IntSetup."E-Invoice Integrator"::Efinans:
                EFinansConnector.DownloadOutgoingDocument(UUID, 'PDF');
            IntSetup."E-Invoice Integrator"::Idea:
                IdeaConnector.GetOutboxPDF(UUID);
        end;
    end;

    procedure DownloadIncomingPdf(UUID: Guid)
    begin
        GetIntSetup;

        case IntSetup."E-Invoice Integrator" OF
            IntSetup."E-Invoice Integrator"::Uyumsoft:
                UyumsoftConnector.GetInboxPdf(UUID);
            IntSetup."E-Invoice Integrator"::Efinans:
                EFinansConnector.DownloadIncomingDocument(UUID, 'PDF');
            IntSetup."E-Invoice Integrator"::Idea:
                IdeaConnector.GetInboxPdf(UUID);
        end;
    end;

    procedure BatchProcessOutboxStatus(var Queue: Record "PRG_E-Invoice Queue")
    var
        Queue2: Record "PRG_E-Invoice Queue";
    begin
        Queue.SetRange(IssueDate, CalcDate('<-7D>', Today()), Today());
        Queue.SetRange("Queue Status", Queue."Queue Status"::SentToService);
        if not Queue.FindFirst() then
            exit;

        GetIntSetup;

        case IntSetup."E-Invoice Integrator" OF
            IntSetup."E-Invoice Integrator"::Uyumsoft:
                begin
                    repeat
                        Queue2.Get(Queue.EntryNo);
                        UyumsoftConnector.GetOutboxStatus(Queue2);
                        Queue2.Modify();
                        Commit();
                    until Queue.Next() = 0;
                end;
            IntSetup."E-Invoice Integrator"::Efinans:
                begin
                    repeat
                        Queue2.Get(Queue.EntryNo);
                        case Queue2.IntegrationType of
                            Queue2.IntegrationType::EInvoice:
                                EFinansConnector.GetOutboxStatus(Queue2);
                            Queue2.IntegrationType::EArchive:
                                EFinansConnector.GetEArchiveOutboxStatus(Queue2);
                        end;
                        Queue2.Modify();
                        Commit();
                    until Queue.Next() = 0;
                end;
            IntSetup."E-Invoice Integrator"::Idea:
                begin
                    repeat
                        Queue2.Get(Queue.EntryNo);
                        IdeaConnector.GetOutboxStatus(Queue2);
                        Queue2.Modify();
                        Commit();
                    until Queue.Next() = 0;
                end;
        end;

    end;

    procedure GetIntSetup()
    begin
        IF NOT GotSetup then begin
            IntSetup.get();
            GotSetup := true;
        end;
    end;

    procedure GetInvSetup()
    begin
        IF not GotInvSetup then begin
            EInvSetup.get();
            GotInvSetup := true;
        end;
    end;

    var
        GotSetup: Boolean;
        GotInvSetup: Boolean;
        IntSetup: Record "PRG_E-Invoice Integrator Setup";
        EInvSetup: Record "PRG_E-Invoice Setup";
        UyumsoftConnector: Codeunit "PRG_E-Invoice WB Connector";
        EFinansConnector: Codeunit "PRG_E-Invoice Efin. Connector";
        IdeaConnector: Codeunit "PRG_E-Invoice IDEA Connector";
}