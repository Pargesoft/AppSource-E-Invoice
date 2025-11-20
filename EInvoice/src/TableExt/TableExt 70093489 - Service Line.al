tableextension 70093489 "PRG_EINV_Service Line" extends "Service Line"
{
    fields
    {    
        field(70093471; "PRG_E-Invoice Tax Type Code"; Code[20])
        {
            Caption = 'E-Invoice Tax Type Code';
            DataClassification = CustomerContent;
            TableRelation = "PRG_E-Invoice Tax Type Code";
        }
    }
}
