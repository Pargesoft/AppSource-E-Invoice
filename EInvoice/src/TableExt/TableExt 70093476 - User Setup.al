tableextension 70093476 "PRG_EINV_UserSetup" extends "User Setup"
{
    fields
    {
        field(70093471; "PRG_E-Invoice No. Series"; Code[20])
        {
            Caption = 'E-Invoice No. Series';
            DataClassification = CustomerContent;
            TableRelation = "No. Series";
        }
        field(70093472; "PRG_E-Archive No. Series"; Code[20])
        {
            Caption = 'E-Archive No. Series';
            DataClassification = CustomerContent;
            TableRelation = "No. Series";
        }
    }
}