tableextension 70093472 "PRG_EINV_SalesLine" extends "Sales Line"
{
    fields
    {
        field(70093471; "PRG_E-Invoice Tax Type Code"; Code[20])
        {
            Caption = 'E-Invoice Tax Type Code';
            DataClassification = CustomerContent;
            TableRelation = "PRG_E-Invoice Tax Type Code";
        }
        field(70093472; "PRG_Tariff Number"; Code[20])
        {
            Caption = 'Tariff Number';
            DataClassification = CustomerContent;
            TableRelation = "Tariff Number";
            ValidateTableRelation = false;
        }
        field(70093473; "PRG_Package Brand"; Code[20])
        {
            Caption = 'Package Brand';
            DataClassification = CustomerContent;
        }
        field(70093474; "PRG_Packagin Type Code"; Code[10])
        {
            Caption = 'Packagin Type Code';
            DataClassification = CustomerContent;
            TableRelation = "PRG_E-Export Packaging Types";
        }
        field(70093475; "PRG_Actual Package Quantity"; Decimal)
        {
            Caption = 'Actual Package Quantity';
            DataClassification = CustomerContent;
        }
        field(70093476; "PRG_Carriage Amount"; Decimal)
        {
            Caption = 'Carriage Amount';
            DataClassification = CustomerContent;
        }
        field(70093477; "PRG_Insurance Amount"; Decimal)
        {
            Caption = 'Insurance Amount';
            DataClassification = CustomerContent;
        }
    }
}