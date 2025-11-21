page 70093472 "PRG_E-Invoice Archive"
{
    ApplicationArea = All;
    Caption = 'E-Invoice Archive';
    Editable = false;
    PageType = List;
    SourceTable = "PRG_E-Invoice Archive";
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(EInvoiceArchive)
            {
                Caption = 'EInvoiceArchive';
                field(EntryNo; Rec.EntryNo)
                {
                    ApplicationArea = All;
                    Caption = 'Entry No';
                    ToolTip = 'Specifies the value of the Entry No field.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = All;
                    Caption = 'Type';
                    ToolTip = 'Specifies the value of the Type field.';
                }
                field("Queue Status"; Rec."Queue Status")
                {
                    ApplicationArea = All;
                    Caption = 'Status';
                    ToolTip = 'Specifies the value of the Status field.';
                }
                field(ProfileID; Rec.ProfileID)
                {
                    ApplicationArea = All;
                    Caption = 'ProfileID';
                    ToolTip = 'Specifies the value of the ProfileID field.';
                }
                field(ERPRecordID; Rec.ERPRecordID)
                {
                    ApplicationArea = All;
                    Caption = 'ERPRecordID';
                    ToolTip = 'Specifies the value of the ERPRecordID field.';
                }
                field(UniqueIdentifier; Rec.UniqueIdentifier)
                {
                    ApplicationArea = All;
                    Caption = 'UniqueIdentifier';
                    ToolTip = 'Specifies the value of the UniqueIdentifier field.';
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
                field(CreationDateTime; Rec.CreationDateTime)
                {
                    ApplicationArea = All;
                    Caption = 'CreationDateTime';
                    ToolTip = 'Specifies the value of the CreationDateTime field.';
                }
                field(CreatedBy; Rec.CreatedBy)
                {
                    ApplicationArea = All;
                    Caption = 'CreatedBy';
                    ToolTip = 'Specifies the value of the CreatedBy field.';
                }
                field(GLRegisterEntryNo; Rec.GLRegisterEntryNo)
                {
                    ApplicationArea = All;
                    Caption = 'G/L Register Entry No.';
                    ToolTip = 'Specifies the value of the G/L Register Entry No. field.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Description';
                    ToolTip = 'Specifies the value of the Description field.';
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
                field(CVType; Rec.CVType)
                {
                    ApplicationArea = All;
                    Caption = 'CV Type';
                    ToolTip = 'Specifies the value of the CV Type field.';
                }
                field(CVRegistrationNo; Rec.CVRegistrationNo)
                {
                    ApplicationArea = All;
                    Caption = 'CVRegistrationNo';
                    ToolTip = 'Specifies the value of the CVRegistrationNo field.';
                }
                field("Dest. Document Type"; Rec."Dest. Document Type")
                {
                    ApplicationArea = All;
                    Caption = 'Dest. Document Type';
                    ToolTip = 'Specifies the value of the Dest. Document Type field.';
                }
                field("Dest. Document Status"; Rec."Dest. Document Status")
                {
                    ApplicationArea = All;
                    Caption = 'Dest. Document Status';
                    ToolTip = 'Specifies the value of the Dest. Document Status field.';
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
                    PromotedCategory = Process;
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
                    PromotedCategory = Process;
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
                action(MoveToQueue)
                {
                    ApplicationArea = All;
                    Caption = 'Move to Queue';
                    Image = MoveToNextPeriod;
                    ToolTip = 'Executes the Move to Queue action.';
                    Promoted = true;
                    PromotedCategory = Process;
                    trigger OnAction()
                    var
                        ArchiveEntry: Record "PRG_E-Invoice Archive";
                    begin
                        CurrPage.SETSELECTIONFILTER(ArchiveEntry);
                        EInvMgt.MoveArchiveToQueue(ArchiveEntry);
                        CurrPage.UPDATE(FALSE);
                    end;
                }
                action("Queue Log")
                {
                    ApplicationArea = All;
                    Caption = 'Queue Log';
                    Image = Log;
                    RunObject = Page "PRG_E-Invoice Log Archive";
                    RunPageLink = "Header Entry No." = FIELD(EntryNo);
                    ToolTip = 'Executes the Queue Log Action.';
                }
            }
        }
    }
    var
        EInvMgt: Codeunit "PRG_E-Invoice Management";
}