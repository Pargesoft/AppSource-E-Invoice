table 70093480 "PRG_E-Invoice Tax Type Code"
{
    Caption = 'E-Invoice Tax Type Code';
    DataClassification = CustomerContent;
    DataPerCompany = false;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            DataClassification = CustomerContent;
        }
        field(2; Description; Text[250])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        field(3; Type; Option)
        {
            Caption = 'Type';
            DataClassification = CustomerContent;
            OptionCaption = 'VAT,Witholding,Exception,Partial Exception,Specific Base,Exported,EArchiveException';
            OptionMembers = VAT,WitholdingCode,ExceptionCode,PartialExceptionCode,SpecificBaseCode,Exported,EArchiveException;
        }
        field(10; "Tax Rate"; Decimal)
        {
            Caption = 'Tax Rate';
            DataClassification = CustomerContent;
            DecimalPlaces = 2 : 2;
        }
        field(20; "Calculation Sequence Number"; Integer)
        {
            Caption = 'Calculation Sequence Number';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
        }
        key(Key2; "Calculation Sequence Number")
        {
        }
    }

    fieldgroups
    {
    }

    procedure GetTaxType(pTaxTypeCode: Code[10]): Integer
    var
        EInvTaxTypeCode: Record "PRG_E-Invoice Tax Type Code";
        TextTypeCode: Label 'There is not %1 %2 in the %3';
    begin
        IF NOT EInvTaxTypeCode.GET(pTaxTypeCode) THEN
            ERROR(TextTypeCode, EInvTaxTypeCode.FIELDCAPTION(EInvTaxTypeCode.Code), pTaxTypeCode, EInvTaxTypeCode.TABLECAPTION)
        ELSE
            EXIT(EInvTaxTypeCode.Type);
    end;
}

