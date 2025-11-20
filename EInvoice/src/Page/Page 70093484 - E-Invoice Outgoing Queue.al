page 70093484 "PRG_E-Invoice Outgoing Queue"
{
    ApplicationArea = All;
    Caption = 'E-Invoice Outgoing Queue';
    DeleteAllowed = false;
    InsertAllowed = false;
    DelayedInsert = false;
    Editable = false;
    PageType = List;
    Permissions = TableData "G/L Register" = rm;
    PromotedActionCategories = 'New,Process,Reports,Send,General,Misc';
    SourceTable = "PRG_E-Invoice Queue";
    SourceTableView = WHERE(Type = CONST(Outbox));
    UsageCategory = Lists;
    CardPageId = "PRG_E-Invoice Qeue Card";

    layout
    {
        area(content)
        {
            repeater(General)
            {
                Caption = 'General';
                field(EntryNo; Rec.EntryNo)
                {
                    ApplicationArea = All;
                    Caption = 'Entry No';
                    ToolTip = 'Specifies the value of the Entry No field.';
                }
                field(IntegrationType; Rec.IntegrationType)
                {
                    ApplicationArea = All;
                    Caption = 'IntegrationType';
                    ToolTip = 'Specifies the value of the IntegrationType field.';
                }
                field("Queue Status"; Rec."Queue Status")
                {
                    ApplicationArea = All;
                    Caption = 'Status';
                    ToolTip = 'Specifies the value of the Status field.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = All;
                    Caption = 'Type';
                    ToolTip = 'Specifies the value of the Type field.';
                }
                field(InvoiceType; Rec.InvoiceType)
                {
                    ApplicationArea = All;
                    Caption = 'InvoiceType';
                    ToolTip = 'Specifies the value of the InvoiceType field.';
                }
                field(InvoiceID; Rec.InvoiceID)
                {
                    ApplicationArea = All;
                    Caption = 'InvoiceID';
                    ToolTip = 'Specifies the value of the InvoiceID field.';
                }
                field(IssueDate; Rec.IssueDate)
                {
                    ApplicationArea = All;
                    Caption = 'Issue Date';
                    ToolTip = 'Specifies the value of the Issue Date field.';
                }
                field(TaxExclusiveAmount; Rec.TaxExclusiveAmount)
                {
                    ApplicationArea = All;
                    Caption = 'TaxExclusiveAmount';
                    ToolTip = 'Specifies the value of the TaxExclusiveAmount field.';
                }
                field(TaxInclusiveAmount; Rec.TaxInclusiveAmount)
                {
                    ApplicationArea = All;
                    Caption = 'TaxInclusiveAmount';
                    ToolTip = 'Specifies the value of the TaxInclusiveAmount field.';
                }
                field(CVNo; Rec.CVNo)
                {
                    ApplicationArea = All;
                    Caption = 'CVNo';
                    ToolTip = 'Specifies the value of the CVNo field.';
                }
                field(CVName; Rec.CVName)
                {
                    ApplicationArea = All;
                    Caption = 'CVName';
                    ToolTip = 'Specifies the value of the CVName field.';
                }
                field(CVRegistrationNo; Rec.CVRegistrationNo)
                {
                    ApplicationArea = All;
                    Caption = 'CVRegistrationNo';
                    ToolTip = 'Specifies the value of the CVRegistrationNo field.';
                }
                field(GLRegisterEntryNo; Rec.GLRegisterEntryNo)
                {
                    ApplicationArea = All;
                    Caption = 'G/L Register Entry No.';
                    ToolTip = 'Specifies the value of the G/L Register Entry No. field.';
                }
                field(UniqueIdentifier; Rec.UniqueIdentifier)
                {
                    ApplicationArea = All;
                    Caption = 'UniqueIdentifier';
                    ToolTip = 'Specifies the value of the UniqueIdentifier field.';
                }
                field(ResultStatusCode; Rec.ResultStatusCode)
                {
                    ApplicationArea = All;
                    Caption = 'ResultStatusCode';
                    ToolTip = 'Specifies the value of the ResultStatusCode field.';
                }
                field(ResultStatusDescription; Rec.ResultStatusDescription)
                {
                    ApplicationArea = All;
                    Caption = 'Result Status Description';
                    ToolTip = 'Specifies the value of the Result Status Description field.';
                }
                field(CreationDateTime; Rec.CreationDateTime)
                {
                    ApplicationArea = All;
                    Caption = 'CreationDateTime';
                    ToolTip = 'Specifies the value of the CreationDateTime field.';
                }

                field(DepartmentCode; Rec.DepartmentCode)
                {
                    ApplicationArea = All;
                    Caption = 'DepartmentCode';
                    ToolTip = 'Specifies the value of the DepartmentCode field.';
                }
                field(CreatedBy; Rec.CreatedBy)
                {
                    ApplicationArea = All;
                    Caption = 'CreatedBy';
                    ToolTip = 'Specifies the value of the CreatedBy field.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&E-invoice")
            {
                Caption = '&E-invoice';
                action(Card)
                {
                    ApplicationArea = All;
                    Caption = 'Card';
                    Image = EditLines;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Executes the Card action.';
                    trigger OnAction()
                    var
                        EInv: Record "PRG_E-Invoice Header";
                        EInvCard: Page "PRG_E-Invoice Header";
                    begin
                        EInv.SETFILTER(UUID, Rec.UniqueIdentifier);
                        EInvCard.SETTABLEVIEW(EInv);
                        EInvCard.RUNMODAL();
                        CLEAR(EInvCard);
                    end;
                }
                action("&Navigate")
                {
                    ApplicationArea = All;
                    Caption = '&Navigate';
                    Image = Navigate;
                    Promoted = true;
                    PromotedCategory = Category5;
                    ToolTip = 'Executes the &Navigate action.';
                    trigger OnAction()
                    begin
                        EInvMgt.Navigate(Rec.GLRegisterEntryNo);
                    end;
                }
                action("G/L Register")
                {
                    ApplicationArea = All;
                    Caption = 'G/L Register';
                    Image = GLRegisters;
                    RunObject = Page "G/L Registers";
                    RunPageLink = "No." = FIELD(GLRegisterEntryNo);
                    ToolTip = 'Executes the G/L Register action.';
                }
                action("Queue Log")
                {
                    ApplicationArea = All;
                    Caption = 'Queue Log';
                    Image = Log;
                    RunObject = Page "PRG_E-Invoice Queue Log";
                    RunPageLink = "Header Entry No." = FIELD(EntryNo);
                    ToolTip = 'Executes the Queue Log Action.';
                }
            }
            group("&Functions")
            {
                Caption = '&Functions';
                Image = Receivables;
                action("Create Outbox")
                {
                    ApplicationArea = All;
                    Caption = 'Create Outbox';
                    Image = Export;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    ShortCutKey = 'F7';
                    ToolTip = 'Executes the Create Outbox action.';
                    trigger OnAction()
                    begin
                        REPORT.RUNMODAL(REPORT::"PRG_Create E-Invoice Outbox");
                        CurrPage.UPDATE(FALSE);
                    end;
                }
                action(Send)
                {
                    ApplicationArea = All;
                    Caption = 'Send';
                    Image = SendElectronicDocument;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    ShortCutKey = 'F9';
                    ToolTip = 'Executes the Send action.';
                    trigger OnAction()
                    var
                        Queue: Record "PRG_E-Invoice Queue";
                    begin
                        CurrPage.SETSELECTIONFILTER(Queue);
                        EInvMgt.SendInvoice(Queue, FALSE);
                    end;
                }
                action(ReCreateGuid)
                {
                    ApplicationArea = All;
                    Caption = 'ReCreate GUID';
                    Image = ElectronicNumber;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    ToolTip = 'Executes the ReCreate GUID action.';
                    trigger OnAction()
                    begin
                        Library.RecreateGUID(Rec);
                        CurrPage.Update();
                    end;
                }

                action(DownloadPDF)
                {
                    ApplicationArea = All;
                    Caption = 'Download PDF';
                    Image = SendAsPDF;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    ToolTip = 'Executes the Download PDF action.';

                    trigger OnAction()
                    var
                        ConnectorMgt: Codeunit "PRG_E-Invoice Connector Mgt.";
                    begin
                        ConnectorMgt.DownloadOutgoingPdf(Rec.UniqueIdentifier);
                    end;
                }
                action(PriviewPDF)
                {
                    ApplicationArea = All;
                    Caption = 'Priview PDF';
                    Image = SendAsPDF;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    ToolTip = 'Executes the Priview PDF action.';

                    trigger OnAction()
                    var
                        ConnectorMgt: Codeunit "PRG_E-Invoice WB Connector";
                    begin
                        ConnectorMgt.PDFPriview(Rec.EntryNo);
                    end;
                }
                action("Query Status")
                {
                    ApplicationArea = All;
                    Caption = 'Query Status';
                    Image = Status;
                    Promoted = true;
                    PromotedCategory = Category4;
                    ToolTip = 'Executes the Query Status action.';
                    trigger OnAction()
                    var
                        Queue: Record "PRG_E-Invoice Queue";
                        ConnectorMgt: Codeunit "PRG_E-Invoice Connector Mgt.";
                    begin
                        CurrPage.SetSelectionFilter(Queue);
                        ConnectorMgt.BatchProcessOutboxStatus(Queue);
                        CurrPage.Update();
                    end;
                }
                action("Download Xml")
                {
                    ApplicationArea = All;
                    Caption = 'Download Xml';
                    Image = Status;
                    Promoted = true;
                    PromotedCategory = Category4;
                    ToolTip = 'Executes the Download Xml action.';
                    trigger OnAction()
                    begin
                        EInvMgt.DownloadXml(Rec.EntryNo);
                    end;
                }
                action(Archive)
                {
                    ApplicationArea = All;
                    Caption = 'Archive';
                    Image = Archive;
                    ToolTip = 'Executes the Archive action.';
                    trigger OnAction()
                    var
                        Queue: Record "PRG_E-Invoice Queue";
                    begin
                        CurrPage.SETSELECTIONFILTER(Queue);
                        EInvMgt.ArchiveQueue(Queue);
                        CurrPage.UPDATE(FALSE);
                    end;
                }
                action("Set Status to Failed")
                {
                    ApplicationArea = All;
                    Caption = 'Set Status to Failed';
                    Image = Replan;
                    ToolTip = 'Executes the Set Status to Failed action.';

                    trigger OnAction()
                    begin
                        Rec.SetStatusFailed();
                    end;
                }
                action(Cancel)
                {
                    ApplicationArea = All;
                    Caption = 'Cancel';
                    Image = Cancel;
                    ToolTip = 'Executes the Cancel action.';

                    trigger OnAction()
                    var
                        Queue: Record "PRG_E-Invoice Queue";
                        CancelEInv: Report "PRG_Cancel E-Invoice";
                    begin
                        CurrPage.SETSELECTIONFILTER(Queue);
                        CancelEInv.SETTABLEVIEW(Queue);
                        CancelEInv.RUNMODAL();
                    end;
                }
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    begin
        IF Rec.FIND(Which) THEN
            EXIT(TRUE)
        ELSE BEGIN
            Rec.SETRANGE(EntryNo);
            EXIT(Rec.FIND(Which));
        END;
    end;

    trigger OnOpenPage()
    begin
        IF GUIALLOWED THEN
            CurrPage.EDITABLE(FALSE);
    end;

    var
        Library: Codeunit "PRG_E-Invoice Library";
        EInvMgt: Codeunit "PRG_E-Invoice Management";
}

