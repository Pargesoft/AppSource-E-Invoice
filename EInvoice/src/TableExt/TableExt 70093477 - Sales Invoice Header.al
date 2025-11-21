tableextension 70093477 "PRG_EINV_SalesInvoiceHeader" extends "Sales Invoice Header"
{
    fields
    {
        field(70093471; "PRG_E-Platform Type"; Option)
        {
            Caption = 'E-Platform Type';
            DataClassification = CustomerContent;
            OptionMembers = " ",EInvoice,EArchive,EExport,MicroExport,FreeZone;
        }
        field(70093472; "PRG_Exclude in E-Invoice"; Boolean)
        {
            Caption = 'Exclude in E-Invoice';
            DataClassification = CustomerContent;
        }
        field(70093473; "PRG_Medical E-Invoice"; Boolean)
        {
            Caption = 'Medical E-Invoice';
            DataClassification = CustomerContent;
        }
    }
}