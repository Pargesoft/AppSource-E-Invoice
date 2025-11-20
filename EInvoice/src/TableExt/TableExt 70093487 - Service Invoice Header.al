tableextension 70093487 "PRG_EINV_ServiceInvHeader" extends "Service Invoice Header"
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
    }
}