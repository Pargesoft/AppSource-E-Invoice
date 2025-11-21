table 70093472 "PRG_E-Invoice Archive"
{
    Caption = 'E-Invoice Archive';
    DataClassification = CustomerContent;

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
            OptionCaption = ' ,New,Sent To Service,Completed,Replied,Cancelled,Out of Scope,Failed';
            OptionMembers = " ",New,SentToService,Completed,Replied,Cancelled,OutofScope,Failed;
        }
        field(40; ProfileID; Option)
        {
            Caption = 'ProfileID';
            DataClassification = CustomerContent;
            Editable = true;
            OptionCaption = ' ,Commercial,Basic,E-Archive,E-Export';
            OptionMembers = " ",Commercial,Basic,EArchive,EExport;
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
        }
        field(111; ResultStatusDescription; Text[250])
        {
            Caption = 'Result Status Description';
            DataClassification = CustomerContent;
            Editable = false;
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
        field(200; "Cancel Reason Code"; Code[10])
        {
            Caption = 'Cancel Reason Code';
            DataClassification = CustomerContent;
        }
        field(201; "Cancel Description"; Text[100])
        {
            Caption = 'Cancel Description';
            DataClassification = CustomerContent;
        }
        field(202; "Cancellation Datetime"; DateTime)
        {
            Caption = 'Cancellation Datetime';
            DataClassification = CustomerContent;
        }
        field(203; "Cancelled By"; Text[50])
        {
            Caption = 'Cancelled By';
            DataClassification = CustomerContent;
        }
        field(300; CVNo; Code[20])
        {
            Caption = 'CVNo';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = IF (InvoiceType = FILTER(Sales)) Customer
            ELSE
            IF (InvoiceType = FILTER(Purch)) Vendor;
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
        field(340; OrderReferenceNo; Text[50])
        {
            Caption = 'OrderReferenceNo';
            DataClassification = CustomerContent;
        }
        field(350; DepartmentCode; Code[20])
        {
            Caption = 'DepartmentCode';
            DataClassification = CustomerContent;
        }
        field(400; Archived; Boolean)
        {
            Caption = 'Archived';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(409; "Dest. Document Type"; Option)
        {
            Caption = 'Dest. Document Type';
            DataClassification = CustomerContent;
            OptionCaption = ' ,Purch. Invoice,Sales Cr. Memo';
            OptionMembers = " ",PurchInvoice,SalesCrMemo;
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
        field(800; "Invoice Link"; Text[250])
        {
            Caption = 'Invoice Link';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; EntryNo)
        {
        }
    }

    fieldgroups
    {
    }
}

