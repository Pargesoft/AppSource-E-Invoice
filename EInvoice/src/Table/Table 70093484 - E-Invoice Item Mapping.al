table 70093484 "PRG_E-Invoice Item Mapping"
{
    Caption = 'E-Invoice Item Mapping';
    DataClassification = CustomerContent;

    fields
    {
        field(10; "CV Type"; Option)
        {
            Caption = 'CV Type';
            DataClassification = CustomerContent;
            OptionCaption = ',Customer,Vendor';
            OptionMembers = ,Customer,Vendor;
        }
        field(20; "CV No."; Code[20])
        {
            Caption = 'CV No.';
            DataClassification = CustomerContent;
            TableRelation = IF ("CV Type" = CONST(Customer)) Customer
            ELSE
            IF ("CV Type" = CONST(Vendor)) Vendor;
        }
        field(30; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = CustomerContent;
        }
        field(40; "Mapping Type"; Option)
        {
            Caption = 'Mapping Type';
            DataClassification = CustomerContent;
            OptionCaption = ' ,Item Description,G/L Account Description,User Defined,Fixed Item,Fixed G/L';
            OptionMembers = " ","Item Description","G/L Account Description","User Defined","Fixed Item","Fixed G/L";
        }
        field(50; "Incoming Description Text"; Text[250])
        {
            Caption = 'Incoming Description Text';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                IF "Incoming Description Text" <> '' THEN
                    TESTFIELD("Mapping Type", "Mapping Type"::"User Defined");
            end;
        }
        field(60; "Dest. Line Type"; Option)
        {
            Caption = 'Dest. Line Type';
            DataClassification = CustomerContent;
            OptionCaption = ' ,G/L Account,Item,Charge (Item)';
            OptionMembers = " ","G/L Account",Item,"Charge (Item)";
            trigger OnValidate()
            begin
                Clear("Dest. Line No.");
            end;
        }
        field(70; "Dest. Line No."; Code[20])
        {
            Caption = 'Dest. No.';
            DataClassification = CustomerContent;
            TableRelation = IF ("Dest. Line Type" = CONST("G/L Account")) "G/L Account" WHERE("Direct Posting" = CONST(TRUE))
            ELSE
            IF ("Dest. Line Type" = CONST(Item)) Item
            else
            IF ("Dest. Line Type" = CONST("Charge (Item)")) "Item Charge";
        }
        field(80; Priority; Integer)
        {
            Caption = 'Priority';
            DataClassification = CustomerContent;
        }
        field(90; Enabled; Boolean)
        {
            Caption = 'Enabled';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                ItemMapping: Record "PRG_E-Invoice Item Mapping";
            begin

                /*
                IF Enabled THEN BEGIN
                    TESTFIELD("CV Type");
                    TESTFIELD("Mapping Type");
                    TESTFIELD("Dest. Line Type");
                    IF "Mapping Type" = "Mapping Type"::"User Defined" THEN
                        TESTFIELD("Dest. Line No.");

                    CASE "Mapping Type" OF
                        "Mapping Type"::"Item Description":
                            TESTFIELD("Incoming Description Text", '');
                        "Mapping Type"::"G/L Account Description":
                            TESTFIELD("Incoming Description Text", '');
                        "Mapping Type"::"User Defined":
                            TESTFIELD("Incoming Description Text");
                    END;

                    ItemMapping.SETRANGE("CV Type", "CV Type");
                    ItemMapping.SETRANGE("CV No.", "CV No.");
                    ItemMapping.SETRANGE(Enabled, TRUE);

                    IF "Mapping Type" <> "Mapping Type"::"User Defined" THEN BEGIN
                        ItemMapping.SETRANGE("Mapping Type", "Mapping Type");
                        IF NOT ItemMapping.ISEMPTY THEN
                            ERROR(Text001);
                    END ELSE BEGIN
                        ItemMapping.SETRANGE("Dest. Line No.", "Dest. Line No.");
                        ItemMapping.SETFILTER("Line No.", '<>%1', "Line No.");
                        IF NOT ItemMapping.ISEMPTY THEN
                            ERROR(STRSUBSTNO(Text002, FIELDCAPTION("Dest. Line No."), "Dest. Line No."));
                    END;
                END;
                */
            end;
        }
    }

    keys
    {
        key(Key1; "CV Type", "CV No.", "Line No.")
        {
        }
        key(Key2; "CV Type", "CV No.", Priority)
        {
        }
    }

    fieldgroups
    {
    }

    var
        Text001: Label 'You can define only ones Item Mapping for a Customer/Vendor.';
        Text002: Label 'Already exist %1 %2';
}