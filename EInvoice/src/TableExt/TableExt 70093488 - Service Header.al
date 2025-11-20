tableextension 70093488 "PRG_EINV_Service Header" extends "Service Header"
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
