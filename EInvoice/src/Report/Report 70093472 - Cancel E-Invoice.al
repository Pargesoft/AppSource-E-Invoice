report 70093472 "PRG_Cancel E-Invoice"
{
    Caption = 'Cancel E-Invoice';
    Permissions = TableData "G/L Register" = rm,
                  TableData "PRG_E-Invoice Queue" = rd;
    ProcessingOnly = true;

    dataset
    {
        dataitem(EInvoiceQueue; "PRG_E-Invoice Queue")
        {
            DataItemTableView = WHERE("Queue Status" = CONST(New));

            trigger OnAfterGetRecord()
            var
                GLReg: Record "G/L Register";
            begin
                EInvMgt.InsertQueueLog(EntryNo, QueueLog.Status::Cancelled, Text006);
                EInvMgt.ArchiveQueue(EInvoiceQueue, true);
                GLReg.Get(GLRegisterEntryNo);
                GLReg."PRG_E-Invoice Status" := GLReg."PRG_E-Invoice Status"::Cancelled;
                GLReg.Modify();
            end;

            trigger OnPostDataItem()
            begin

                Message(Text004);
            end;

            trigger OnPreDataItem()
            begin
                if not Confirm(StrSubstNo(Text001, Count)) then
                    Error('');

                if ReasonCode = '' then
                    Error(Text002);

                if CancelDesc = '' then
                    Error(Text003);
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(ReasonCode; ReasonCode)
                    {
                        ApplicationArea = All;
                        Caption = 'Cancel Reason Code';
                        TableRelation = "Reason Code";
                        ToolTip = 'Specifies the value of the Cancel Reason Code field.';

                        trigger OnValidate()
                        begin
                            if ReasonCode <> '' then
                                if CancelDesc = '' then
                                    if ReasonCodeTable.Get(ReasonCode) then
                                        CancelDesc := ReasonCodeTable.Description;
                        end;
                    }
                    field(CancelDesc; CancelDesc)
                    {
                        ApplicationArea = All;
                        Caption = 'Cancel Description';
                        ToolTip = 'Specifies the value of the Cancel Description field.';
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

    var
        QueueLog: Record "PRG_E-Invoice Queue Log";
        ReasonCodeTable: Record "Reason Code";
        EInvMgt: Codeunit "PRG_E-Invoice Management";
        ReasonCode: Code[10];
        Text001: Label '%1 registration will be cancelled. Do you want to continue?';
        Text002: Label 'Cancel Reason Code must be full!';
        Text003: Label 'Cancel Description must be full!';
        Text004: Label 'Cancellation completed.';
        Text006: Label 'Record is cancelled.';
        CancelDesc: Text[50];
}

