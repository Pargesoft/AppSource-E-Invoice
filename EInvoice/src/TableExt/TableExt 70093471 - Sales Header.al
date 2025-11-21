tableextension 70093471 "PRG_EINV_SalesHeader" extends "Sales Header"
{
    fields
    {
        field(70093471; "PRG_E-Platform Type"; Option)
        {
            Caption = 'E-Platform Type';
            DataClassification = CustomerContent;
            OptionCaption = ' ,E-Invoice,E-Archive,E-Export,Micro Export,Free Zone';
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