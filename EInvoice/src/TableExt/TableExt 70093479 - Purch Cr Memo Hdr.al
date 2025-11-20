tableextension 70093479 "PRG_EINV_PurchCrMemoHdr" extends "Purch. Cr. Memo Hdr."
{
    fields
    {
        field(70093471; "PRG_E-Platform Type"; Option)
        {
            Caption = 'E-Platform Type';
            DataClassification = CustomerContent;
            OptionMembers = " ",EInvoice,EArchive,EExport,MicroExport,FreeZone;
        }
        field(70093472; "PRG_Related Invoice No."; Code[20])
        {
            Caption = 'Related Invoice No.';
            DataClassification = CustomerContent;
        }
        field(70093473; "PRG_Related Invoice Date"; Date)
        {
            Caption = 'Related Invoice Date';
            DataClassification = CustomerContent;
        }
        field(70093474; "PRG_Medical E-Invoice"; Boolean)
        {
            Caption = 'Medical E-Invoice';
            DataClassification = CustomerContent;
        }
    }
}