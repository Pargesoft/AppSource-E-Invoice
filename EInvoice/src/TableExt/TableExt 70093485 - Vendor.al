tableextension 70093485 "PRG_EINV_Vendor" extends Vendor
{
    fields
    {
        field(70093471; "PRG_Alias"; Text[250])
        {
            Caption = 'Alias';
            DataClassification = CustomerContent;
            TableRelation = "PRG_E-Invoice Liable Companies".Alias where(Identifier = field("VAT Registration No."));
            ValidateTableRelation = false;
        }
        field(70093472; "PRG_Profile ID"; Option)
        {
            Caption = 'E-Invoice Profile ID';
            DataClassification = CustomerContent;
            OptionCaption = ' ,Commercial Invoice,Basic Invoice';
            OptionMembers = " ","Ticari Fatura","Temel Fatura";
        }
        field(70093473; "PRG_Payee Firm"; Boolean)
        {
            Caption = 'Payee Firm';
            DataClassification = CustomerContent;
        }
        field(70093474; "PRG_Locked Alias"; Boolean)
        {
            Caption = 'Locked Alias';
            DataClassification = CustomerContent;
        }
        field(70093475; "PRG_Exclude in E-Invoice"; Boolean)
        {
            Caption = 'Exclude in E-Invoice';
            DataClassification = CustomerContent;
        }
    }
}