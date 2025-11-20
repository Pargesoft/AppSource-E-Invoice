table 70093474 "PRG_E-Invoice Code Mapping"
{
    Caption = 'E-Invoice Code Mapping';
    DataClassification = CustomerContent;

    fields
    {
        field(10; Type; Option)
        {
            Caption = 'Type';
            DataClassification = CustomerContent;

            OptionCaption = ' ,Currency,Country,Channel,UOM,EInv. Pay. Method,EArch. Internet Pay. Method';
            OptionMembers = " ",Currency,Country,Channel,UOM,EInvPayMethod,EArchPayMethod;
        }
        field(20; "Source Code"; Code[20])
        {
            Caption = 'Source Code';
            DataClassification = CustomerContent;
            TableRelation = IF (Type = CONST(Currency)) Currency
            ELSE
            IF (Type = CONST(Country)) "Country/Region"
            ELSE
            IF (Type = CONST(UOM)) "Unit of Measure"
            ELSE
            IF (Type = CONST(EInvPayMethod)) "Payment Method"
            ELSE
            IF (Type = CONST(EArchPayMethod)) "Payment Method";

            trigger OnValidate()
            var
                PaymentMethod: Record "Payment Method";
            begin
                CASE Type OF
                    Type::EInvPayMethod, Type::EArchPayMethod:
                        BEGIN
                            IF xRec."Source Code" <> "Source Code" THEN BEGIN
                                IF "Source Code" = '' THEN
                                    Description := ''
                                ELSE
                                    IF PaymentMethod.GET("Source Code") THEN
                                        Description := COPYSTR(PaymentMethod.Description, 1, MAXSTRLEN(Description))
                                    ELSE
                                        Description := '';
                            END;
                        END;
                END;
            end;
        }
        field(30; "Destination Code"; Code[50])
        {
            Caption = 'Destination Code';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                CASE Type OF
                    Type::EArchPayMethod:
                        BEGIN
                            IF xRec."Destination Code" <> "Destination Code" THEN BEGIN

                                IF "Destination Code" = '' THEN BEGIN
                                    Description := '';
                                    EXIT;
                                END;
                                TESTFIELD(Description);
                            END;
                        END;
                END;
            end;
        }
        field(40; Description; Text[50])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; Type, "Source Code")
        {
        }
    }

    fieldgroups
    {
    }

}

