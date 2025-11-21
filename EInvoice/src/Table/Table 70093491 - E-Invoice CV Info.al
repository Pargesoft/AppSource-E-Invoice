table 70093491 "PRG_E-Invoice CV Info."
{
    Caption = 'E-Invoice CV Info.';
    DataClassification = CustomerContent;
    LookupPageId = "PRG_E-Invoice CV Info.";

    fields
    {
        field(10; "CV Type"; Option)
        {
            Caption = 'Customer/Vendor Type';
            DataClassification = CustomerContent;
            OptionCaption = ' ,Customer,Vendor';
            OptionMembers = " ",Customer,Vendor;
        }
        field(20; "CV No."; Code[20])
        {
            Caption = 'Customer/Vendor No.';
            DataClassification = CustomerContent;
            NotBlank = true;
            TableRelation = IF ("CV Type" = CONST(Customer)) Customer
            ELSE
            IF ("CV Type" = CONST(Vendor)) Vendor;

            trigger OnValidate()
            var
                Cust: Record "Customer";
                Vend: Record "Vendor";
            begin
                CASE "CV Type" OF
                    "CV Type"::Customer:
                        BEGIN
                            Cust.GET("CV No.");
                            "CV Name" := Cust.Name;
                        END;
                    "CV Type"::Vendor:
                        BEGIN
                            Vend.GET("CV No.");
                            "CV Name" := Vend.Name;
                        END;
                END;
            end;
        }
        field(21; "CV Name"; Text[250])
        {
            Caption = 'Customer/Vendor Name';
            DataClassification = CustomerContent;
        }
        field(30; "Integration Type"; Option)
        {
            Caption = 'Integration Type';
            DataClassification = CustomerContent;
            OptionCaption = 'E-Invoice,E-Archive';
            OptionMembers = EInvoice,EArchive;
        }
        field(40; "Profile ID"; Option)
        {
            Caption = 'E-Invoice Profile ID';
            DataClassification = CustomerContent;
            OptionCaption = ' ,Commercial Invoice,Basic Invoice,E-Archive Invoice,E-Export Invoice,Medical Invoice';
            OptionMembers = " ",TICARIFATURA,TEMELFATURA,EARSIVFATURA,IHRACAT,MEDICAL;
        }
        field(50; "Tax Exemption Code"; Code[10])
        {
            Caption = 'VAT Tax Exemption';
            DataClassification = CustomerContent;
            TableRelation = "PRG_E-Invoice Tax Type Code";
        }
        field(60; "First Name"; Text[100])
        {
            Caption = 'First Name';
            DataClassification = CustomerContent;
        }
        field(70; "Family Name"; Text[100])
        {
            Caption = 'Family Name';
            DataClassification = CustomerContent;
        }
        field(80; "E-mail Address"; Text[100])
        {
            Caption = 'E-Invoice E-mail Address';
            DataClassification = CustomerContent;
        }
        field(90; "E-Invoice Starting Date"; Date)
        {
            Caption = 'E-Invoice Starting Date';
            DataClassification = CustomerContent;
        }
        field(100; "Tax Registration No."; Text[30])
        {
            Caption = 'Tax Reg. No. Buffer';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(110; "Creation Datetime"; DateTime)
        {
            Caption = 'Creation Datetime';
            DataClassification = CustomerContent;
        }
        field(111; "Last Update Datetime"; DateTime)
        {
            Caption = 'Last Update Datetime';
            DataClassification = CustomerContent;
        }
        field(150; "TaxSchemeID Buffer"; Text[5])
        {
            Caption = 'CustTaxSchemeID';
            DataClassification = CustomerContent;
        }
        field(170; Locked; Boolean)
        {
            Caption = 'Locked';
            DataClassification = CustomerContent;
        }
        field(180; "Created By"; Code[50])
        {
            Caption = 'Created By';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(190; "Last Modified By"; Code[50])
        {
            Caption = 'Last Modified By';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "CV Type", "CV No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        "Created By" := USERID;
        "Last Modified By" := USERID;
    end;

    trigger OnModify()
    begin
        "Last Update Datetime" := CURRENTDATETIME;
        "Last Modified By" := USERID;
    end;
}

