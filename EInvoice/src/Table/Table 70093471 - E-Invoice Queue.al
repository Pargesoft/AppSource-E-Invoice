table 70093471 "PRG_E-Invoice Queue"
{
    Caption = 'E-Invoice Queue';
    DataClassification = CustomerContent;
    Permissions = TableData "G/L Register" = rm;

    fields
    {
        field(10; EntryNo; Integer)
        {
            Caption = 'Entry No';
            DataClassification = CustomerContent;
            Editable = true;
        }
        field(20; Type; Option)
        {
            Caption = 'Type';
            DataClassification = CustomerContent;
            Editable = true;
            OptionCaption = ' ,Inbox,Outbox';
            OptionMembers = " ",Inbox,Outbox;
        }
        field(30; "Queue Status"; Option)
        {
            Caption = 'Status';
            DataClassification = CustomerContent;
            OptionCaption = ' ,New,Sent To Service,Completed,Replied,Cancelled,Out of Scope,Failed,Declined,Approved';
            OptionMembers = " ",New,SentToService,Completed,Replied,Cancelled,OutofScope,Failed,Declined,Approved;
        }
        field(40; ProfileID; Option)
        {
            Caption = 'ProfileID';
            DataClassification = CustomerContent;
            Editable = true;
            OptionCaption = ' ,Commercial,Basic,E-Archive,E-Export,Medical';
            OptionMembers = " ",Commercial,Basic,EArchive,EExport,Medical;
        }
        field(50; ERPRecordID; RecordID)
        {
            Caption = 'ERPRecordID';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(60; UniqueIdentifier; Guid)
        {
            Caption = 'UniqueIdentifier';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(70; InvoiceType; Option)
        {
            Caption = 'InvoiceType';
            DataClassification = CustomerContent;
            Editable = true;
            OptionCaption = ' ,Sales,SalesCr,Purch,PurchCr,Withholding,Exception,Specific Base,Exported';
            OptionMembers = " ",Sales,SalesCr,Purch,PurchCr,Withholding,Exception,SpecificBase,Exported;
        }
        field(71; InvoiceID; Code[20])
        {
            Caption = 'InvoiceID';
            DataClassification = CustomerContent;
            Editable = true;
        }
        field(72; IssueDate; Date)
        {
            Caption = 'Issue Date';
            DataClassification = CustomerContent;
            Editable = true;
        }
        field(80; CreationDateTime; DateTime)
        {
            Caption = 'CreationDateTime';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(81; CreatedBy; Text[50])
        {
            Caption = 'CreatedBy';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(82; GLRegisterEntryNo; Integer)
        {
            Caption = 'G/L Register Entry No.';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "G/L Register";
        }
        field(100; Description; Text[250])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        field(110; ResultStatusCode; Code[20])
        {
            Caption = 'ResultStatusCode';
            DataClassification = CustomerContent;
            Editable = true;
            TableRelation = "PRG_E-Invoice Status Code";

            trigger OnValidate()
            begin
                IF ResultStatusCode <> '' THEN begin
                    EInvSetup.GET();
                    EInvSetup.TESTFIELD("Success Status Code");
                    IF ResultStatusCode = EInvSetup."Success Status Code" THEN
                        "Queue Status" := "Queue Status"::Completed;
                end;

            end;
        }
        field(111; ResultStatusDescription; Text[250])
        {
            Caption = 'Result Status Description';
            DataClassification = CustomerContent;
        }
        field(140; TaxExclusiveAmount; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'TaxExclusiveAmount';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(141; TaxInclusiveAmount; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'TaxInclusiveAmount';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(300; CVNo; Code[20])
        {
            Caption = 'CVNo';
            DataClassification = CustomerContent;
            TableRelation = IF (InvoiceType = FILTER(Sales)) Customer
            ELSE
            IF (InvoiceType = FILTER(Purch)) Vendor;

            trigger OnValidate()
            var
                Cust: Record "Customer";
                Vend: Record "Vendor";
            begin
                IF CVNo <> xRec.CVNo THEN BEGIN
                    CVName := '';
                    IF CVNo <> '' THEN BEGIN
                        TESTFIELD(InvoiceType);
                        CASE InvoiceType OF
                            InvoiceType::Sales, InvoiceType::SalesCr:
                                IF Cust.GET(CVNo) THEN
                                    CVName := Cust.Name;
                            InvoiceType::Purch, InvoiceType::PurchCr:
                                IF Vend.GET(CVNo) THEN
                                    CVName := Vend.Name;
                        END;
                    END;
                END;
            end;
        }
        field(301; CVName; Text[250])
        {
            Caption = 'CVName';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(302; CVRegistrationNo; Text[30])
        {
            Caption = 'CVRegistrationNo';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(303; CVType; Option)
        {
            Caption = 'CV Type';
            DataClassification = CustomerContent;
            OptionCaption = ' ,Customer,Vendor';
            OptionMembers = " ",Cust,Vend;
        }
        field(350; DepartmentCode; Code[20])
        {
            Caption = 'DepartmentCode';
            DataClassification = CustomerContent;
        }
        field(409; "Dest. Document Type"; Option)
        {
            Caption = 'Dest. Document Type';
            DataClassification = CustomerContent;
            OptionCaption = ' ,Purch. Invoice,Sales Cr. Memo,Purch. Order,Sales Return Order';
            OptionMembers = " ",PurchInvoice,SalesCrMemo,PurchOrder,SalesReturnOrder;
        }
        field(410; "Dest. Document Status"; Option)
        {
            Caption = 'Dest. Document Status';
            DataClassification = CustomerContent;
            OptionCaption = ' ,Created,Posted,Failed';
            OptionMembers = " ",Created,Posted,Failed;
        }
        field(700; IntegrationType; Option)
        {
            Caption = 'IntegrationType';
            DataClassification = CustomerContent;
            OptionCaption = 'E-Invoice,E-Archive';
            OptionMembers = EInvoice,EArchive;
        }
        field(950; "Invoice Blob Value"; Blob)
        {
            Caption = 'Invoice Blob Value';
            DataClassification = CustomerContent;

        }
        field(960; "Response Invoice Blob Value"; Blob)
        {
            Caption = 'Response Invoice Blob Value';
            DataClassification = CustomerContent;

        }
        field(970; "Send/Get Result Value"; Blob)
        {
            Caption = 'Send/Get Result Value';
            DataClassification = CustomerContent;
        }
        field(980; "Approval Status"; enum "PRG_E-Invoice Approval Status")
        {
            Caption = 'Approval Status';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; EntryNo)
        {
        }
        key(Key2; GLRegisterEntryNo)
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        Log: Record "PRG_E-Invoice Queue Log";
    begin
        Log.SETRANGE("Header Entry No.", EntryNo);
        Log.DELETEALL();
    end;

    var
        EInvSetup: Record "PRG_E-Invoice Setup";
        EInvMgt: Codeunit "PRG_E-Invoice Management";
        Text001: Label 'Status set to failed manually.';
        Text002: LABEL 'Result is not valid for this action. Please contact your system administrator';

    procedure SetStatusFailed()
    var
        GLReg: Record "G/L Register";
    begin
        IF ResultStatusCode <> '' THEN
            IF ResultStatusCode <> '1230' THEN
                ERROR(Text002);
        GLReg.GET(GLRegisterEntryNo);
        GLReg."PRG_E-Invoice Status" := GLReg."PRG_E-Invoice Status"::Failed;
        GLReg.MODIFY();
        "Queue Status" := "Queue Status"::Failed;
        ResultStatusCode := '';
        MODIFY();
        EInvMgt.InsertQueueLog(EntryNo, "Queue Status"::Failed, Text001)
    end;
}