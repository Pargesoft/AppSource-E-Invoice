page 70093483 "PRG_E-Invoice Incoming Queue"
{
    ApplicationArea = All;
    Caption = 'E-Invoice Incoming Queue';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    Editable = false;
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Invoice,Management,Display';
    SourceTable = "PRG_E-Invoice Queue";
    SourceTableView = WHERE(Type = CONST(Inbox));
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
                field("Queue Status"; Rec."Queue Status")
                {
                    ApplicationArea = All;
                    Caption = 'Status';
                    ToolTip = 'Specifies the value of the Status field.';
                }
                field("Approval Status"; Rec."Approval Status")
                {
                    ApplicationArea = All;
                    Caption = 'Approval Status';
                    ToolTip = 'Specifies the value of the Approval Status field.';
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
                field(CVType; Rec.CVType)
                {
                    ApplicationArea = All;
                    Caption = 'CV Type';
                    ToolTip = 'Specifies the value of the CV Type field.';
                }
                field(CVNo; Rec.CVNo)
                {
                    ApplicationArea = All;
                    Caption = 'CVNo';
                    Editable = false;
                    ToolTip = 'Specifies the value of the CVNo field.';
                }
                field(CVName; Rec.CVName)
                {
                    ApplicationArea = All;
                    Caption = 'CVName';
                    Editable = false;
                    ToolTip = 'Specifies the value of the CVName field.';
                }
                field(CVRegistrationNo; Rec.CVRegistrationNo)
                {
                    ApplicationArea = All;
                    Caption = 'CVRegistrationNo';
                    Editable = false;
                    ToolTip = 'Specifies the value of the CVRegistrationNo field.';
                }
                field("Dest. Document Status"; Rec."Dest. Document Status")
                {
                    ApplicationArea = All;
                    Caption = 'Dest. Document Status';
                    ToolTip = 'Specifies the value of the Dest. Document Status field.';
                }
                field("Dest. Document Type"; Rec."Dest. Document Type")
                {
                    ApplicationArea = All;
                    Caption = 'Dest. Document Type';
                    ToolTip = 'Specifies the value of the Dest. Document Type field.';
                }
                field(ERPRecordID; FORMAT(Rec.ERPRecordID))
                {
                    ApplicationArea = All;
                    Caption = 'ERP Record ID';
                    ToolTip = 'Specifies the value of the ERP Record ID field.';
                    trigger OnAssistEdit()
                    var
                        PurchHeader: Record "Purchase Header";
                        PurchInv: Page "Purchase Invoice";
                        SalesHeader: Record "Sales Header";
                        SalesCreditMemo: Page "Sales Credit Memo";
                        SalesCRMemoHeader: Record "Sales Cr.Memo Header";
                        PostedSalesCR: Page "Posted Sales Credit Memo";
                        PurchInvHeader: Record "Purch. Inv. Header";
                        PostedPurch: Page "Posted Purchase Invoice";
                        RecRef: RecordRef;
                    begin
                        if not RecRef.GET(Rec.ERPRecordID) then
                            Error('Record is not found!');

                        case Rec.ERPRecordID.TableNo of
                            Database::"Purchase Header":
                                begin
                                    RecRef.SetTable(PurchHeader);
                                    PurchInv.SetTableView(PurchHeader);
                                    PurchInv.SetRecord(PurchHeader);
                                    PurchInv.RunModal();
                                end;
                            Database::"Purch. Inv. Header":
                                begin
                                    RecRef.SetTable(PurchInvHeader);
                                    PostedPurch.SetTableView(PurchInvHeader);
                                    PostedPurch.SetRecord(PurchInvHeader);
                                    PostedPurch.RunModal();
                                end;
                            Database::"Sales Header":
                                begin
                                    RecRef.SetTable(SalesHeader);
                                    SalesCreditMemo.SetTableView(SalesHeader);
                                    SalesCreditMemo.SetRecord(SalesHeader);
                                    SalesCreditMemo.RunModal();
                                end;
                            Database::"Sales Cr.Memo Header":
                                begin
                                    RecRef.SetTable(SalesCRMemoHeader);
                                    PostedSalesCR.SetTableView(SalesCRMemoHeader);
                                    PostedSalesCR.SetRecord(SalesCRMemoHeader);
                                    PostedSalesCR.RunModal();
                                end;
                        end;
                    end;
                }
                field(UniqueIdentifier; Rec.UniqueIdentifier)
                {
                    ApplicationArea = All;
                    Caption = 'UniqueIdentifier';
                    ToolTip = 'Specifies the value of the UniqueIdentifier field.';
                    Visible = false;
                }
                field(DepartmentCode; Rec.DepartmentCode)
                {
                    ApplicationArea = All;
                    Caption = 'DepartmentCode';
                    ToolTip = 'Specifies the value of the DepartmentCode field.';
                }
                field(CreationDateTime; Rec.CreationDateTime)
                {
                    ApplicationArea = All;
                    Caption = 'CreationDateTime';
                    ToolTip = 'Specifies the value of the CreationDateTime field.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Get Invoice - Integrator")
            {
                ApplicationArea = All;
                Caption = 'Get Invoice - Integrator';
                Image = Import;
                Promoted = true;
                PromotedCategory = Category5;
                ToolTip = 'Executes the Get Invoice action.Retrieves Documents From Integrator';

                trigger OnAction()
                var
                    ConnectorMgt: Codeunit "PRG_E-Invoice Connector Mgt.";
                begin
                    ConnectorMgt.GetIncomingInvoiceList();
                end;
            }
            action("Get Invoice")
            {
                ApplicationArea = All;
                Caption = 'Get Invoice';
                Image = CreateForm;
                Promoted = true;
                PromotedCategory = Category5;
                ToolTip = 'Executes the Get Invoice action.Creates ERP Records';

                trigger OnAction()
                var
                    IncomingDocMgt: Codeunit "PRG_E-Invoice Inc. Doc. Mgt.";
                begin
                    IncomingDocMgt.ExecuteWaitingQueue();
                end;
            }
            action(ApproveInvoice)
            {
                ApplicationArea = All;
                Caption = 'Approve';
                Image = Approve;
                Promoted = true;
                PromotedCategory = Category5;
                ToolTip = 'Executes the Approve action.';
                trigger OnAction()
                var
                    Queue: Record "PRG_E-Invoice Queue";
                    Status: Enum "PRG_E-Invoice Approval Status";
                    ConnectorMgt: Codeunit "PRG_E-Invoice Connector Mgt.";
                    StatusDescription: Text[250];
                begin
                    CurrPage.SetSelectionFilter(Queue);
                    ConnectorMgt.SendApprovalStatus(Queue, Status::Approved, StatusDescription);
                    CurrPage.UPDATE();
                end;
            }
            action(DeclineInvoice)
            {
                ApplicationArea = All;
                Caption = 'Decline';
                Image = Cancel;
                Promoted = true;
                PromotedCategory = Category5;
                ToolTip = 'Executes the Decline action.';
                trigger OnAction()
                var
                    Queue: Record "PRG_E-Invoice Queue";
                    Status: Enum "PRG_E-Invoice Approval Status";
                    ConnectorMgt: Codeunit "PRG_E-Invoice Connector Mgt.";
                    StatusDescription: Text[250];
                    DialogPage: Page "PRG_Text Input Dialog";
                    ProcessErr: Label 'Process is cancelled.', Comment = 'This message is used when the process is cancelled by the user.';
                begin
                    if DialogPage.RunModal <> Action::OK then
                        Error(ProcessErr);

                    StatusDescription := DialogPage.GetText();

                    CurrPage.SetSelectionFilter(Queue);
                    ConnectorMgt.SendApprovalStatus(Queue, Status::Declined, StatusDescription);
                    CurrPage.UPDATE();
                end;
            }
            action("Import Buffer")
            {
                ApplicationArea = All;
                Caption = 'Import Buffer';
                Image = BreakRulesOff;
                Promoted = true;
                PromotedCategory = Category5;
                RunObject = page "PRG_E-Invoice Incoming Buffer";
                ToolTip = 'Shows Buffer Queue';
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
                    ConnectorMgt.DownloadIncomingPdf(Rec.UniqueIdentifier);
                end;
            }
            action(Archive)
            {
                ApplicationArea = All;
                Caption = 'Archive';
                Image = Archive;
                Promoted = true;
                PromotedCategory = Category5;
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
            action("Queue Log")
            {
                ApplicationArea = All;
                Caption = 'Queue Log';
                Image = Log;
                RunObject = Page "PRG_E-Invoice Queue Log";
                RunPageLink = "Header Entry No." = FIELD(EntryNo);
                ToolTip = 'Executes the Queue Log Action.';
            }
            action(CreateDocument)
            {
                ApplicationArea = All;
                Caption = 'Create Document';
                Image = CreateDocument;
                Promoted = true;
                PromotedCategory = Category5;
                ToolTip = 'Creates Incoming Document';

                trigger OnAction()
                var
                    Queue: Record "PRG_E-Invoice Queue";
                    IncomingDocMgt: Codeunit "PRG_E-Invoice Inc. Doc. Mgt.";
                begin
                    CurrPage.SETSELECTIONFILTER(Queue);
                    IncomingDocMgt.CreateDestinationDoc(Queue);
                end;
            }
            action(Card)
            {
                ApplicationArea = All;
                Caption = 'Card';
                Image = EditLines;
                Promoted = true;
                PromotedCategory = Category6;
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
            action(CVNoUpdate)
            {
                ApplicationArea = All;
                Caption = 'CV No. Update';
                Image = UpdateXML;
                Promoted = true;
                PromotedCategory = Category5;
                PromotedIsBig = true;
                ToolTip = 'Executes the CV No. Update action.';
                trigger OnAction()
                var
                    Queue: Record "PRG_E-Invoice Queue";
                    Customer: Record Customer;
                    Vendor: Record Vendor;
                    Counter: Integer;
                begin

                    Queue.SetRange(Type, Queue.Type::Inbox);
                    Queue.SetRange(CVNo, '');
                    if Queue.FindSet() then
                        repeat
                            case Queue.CVType of
                                Queue.CVType::Cust:
                                    begin
                                        Customer.SetRange("VAT Registration No.", Queue.CVRegistrationNo);
                                        if Customer.FindFirst() then begin
                                            Queue."CVNo" := Customer."No.";
                                            Queue."CVName" := Customer.Name;
                                            Queue.Modify();
                                            Counter += 1;
                                        end
                                    end;
                                Queue.CVType::Vend:
                                    begin
                                        Vendor.SetRange("VAT Registration No.", Queue.CVRegistrationNo);
                                        if Vendor.FindFirst() then begin
                                            Queue."CVNo" := Vendor."No.";
                                            Queue."CVName" := Vendor.Name;
                                            Queue.Modify();
                                            Counter += 1;
                                        end
                                    end;
                            end;
                        until Queue.Next() = 0;

                    Message('CV No. Updated for %1 records', Counter);

                end;
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

    var
        EInvMgt: Codeunit "PRG_E-Invoice Management";
}

