tableextension 70093475 "PRG_EINV_GLRegister" extends "G/L Register"
{
    fields
    {
        field(70093471; "PRG_E-Invoice Status"; Option)
        {
            Caption = 'E-Invoice Status';
            DataClassification = CustomerContent;
            OptionMembers = " ",SentToQueue,SentToSrvQueue,Completed,Replied,Cancelled,OutofScope,Failed;
        }

    }
}