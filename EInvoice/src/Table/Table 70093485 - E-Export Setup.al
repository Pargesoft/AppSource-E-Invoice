table 70093485 "PRG_E-Export Setup"
{
    Caption = 'E-Export Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(10; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = CustomerContent;
        }
        field(15; Activated; Boolean)
        {
            Caption = 'Activated';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                IF NOT CONFIRM(Text000) THEN
                    ERROR(Text001);


                "Default Exemption Tax Code" := Text002;
                "Default Exemption Tax Desc" := Text003;
                "Default Delivery Terms ID" := Text004;
                "Ministry VKN" := Text005;
                "Ministry Party Name" := Text006;
                "Ministry Adress" := Text007;
                "Ministry City Subdivision Name" := Text008;
                "Ministry CityName" := Text009;
                "Ministry PostalZone" := Text010;
                "Ministry CountryName" := Text011;
                "Ministry Party Tax Scheme" := Text012;
                "Ministry Web Adress" := Text013;
                "Ministry Building Number" := Text014;
                "Ministry TaxScheme" := Text015;
                "Ministry Party Tax Scheme" := Text016;
                "Ministry Mail Adress" := Text017;
                "Ministry Telephone" := Text018;
                "Ministry Telefax" := Text019;
                "Ministry URN" := Text020;
                "E-Export ProfileID" := "E-Export ProfileID"::EExport;
            end;
        }
        field(20; "Ministry VKN"; Code[10])
        {
            Caption = 'Ministry Tax Registration No';
            DataClassification = CustomerContent;
            Description = 'Ministry Of Customs And Trade';
        }
        field(30; "Ministry Party Name"; Code[100])
        {
            Caption = 'Ministry Name';
            DataClassification = CustomerContent;
            Description = 'Ministry Of Customs And Trade';
        }
        field(40; "Ministry Adress"; Text[250])
        {
            Caption = 'Ministry Adress';
            DataClassification = CustomerContent;
            Description = 'Ministry Of Customs And Trade';
        }
        field(50; "Ministry City Subdivision Name"; Text[30])
        {
            Caption = 'Ministry Subdivision';
            DataClassification = CustomerContent;
            Description = 'Ministry Of Customs And Trade';
        }
        field(60; "Ministry CityName"; Text[30])
        {
            Caption = 'Ministry City';
            DataClassification = CustomerContent;
            Description = 'Ministry Of Customs And Trade';
        }
        field(70; "Ministry PostalZone"; Text[30])
        {
            Caption = 'Ministry Postal Zone';
            DataClassification = CustomerContent;
            Description = 'Ministry Of Customs And Trade';
        }
        field(80; "Ministry CountryName"; Text[30])
        {
            Caption = 'Ministry Country';
            DataClassification = CustomerContent;
            Description = 'Ministry Of Customs And Trade';
            TableRelation = "Country/Region";
        }
        field(81; "Ministry Party Tax Scheme"; Text[30])
        {
            Caption = 'Ministry Party Tax Scheme';
            DataClassification = CustomerContent;
            Description = 'Ministry Of Customs And Trade';
        }
        field(100; "E-Export Starting Date"; Date)
        {
            Caption = 'E-Export Starting Date';
            DataClassification = CustomerContent;
            Description = 'General';

            trigger OnValidate()
            begin
                IF "E-Export Starting Date" <> 0D THEN
                    VALIDATE(Activated, TRUE)
                ELSE
                    VALIDATE(Activated, FALSE);
            end;
        }
        field(110; "E-Export No. Series"; Code[20])
        {
            Caption = 'E-Export No. Series';
            DataClassification = CustomerContent;
            Description = 'General';
            TableRelation = "No. Series";
        }
        field(130; "Company Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            DataClassification = CustomerContent;
            Description = 'General';
            TableRelation = "Country/Region";
        }
        field(140; "Default Exemption Tax Code"; Code[10])
        {
            Caption = 'Default Exemption Type Code';
            DataClassification = CustomerContent;
            Description = 'Tax Exemption';
            TableRelation = "PRG_E-Invoice Tax Type Code";
        }
        field(150; "Default Exemption Tax Desc"; Text[100])
        {
            Caption = 'Default Tax Exemption Reason Description';
            DataClassification = CustomerContent;
            Description = 'Tax Exemption';
        }
        field(170; "Default Party Identification"; Text[20])
        {
            Caption = 'Default Party Identification';
            DataClassification = CustomerContent;
            Description = 'General';
        }
        field(180; "Ministry Web Adress"; Text[30])
        {
            Caption = 'Ministry Web Adress';
            DataClassification = CustomerContent;
            Description = 'Ministry Of Customs And Trade';
        }
        field(190; "Ministry Building Number"; Text[10])
        {
            Caption = 'Ministry Building Number';
            DataClassification = CustomerContent;
            Description = 'Ministry Of Customs And Trade';
        }
        field(200; "Ministry TaxScheme"; Text[30])
        {
            Caption = 'Ministry TaxScheme';
            DataClassification = CustomerContent;
            Description = 'Ministry Of Customs And Trade';
        }
        field(210; "Ministry Mail Adress"; Text[50])
        {
            Caption = 'Ministry Mail Adress';
            DataClassification = CustomerContent;
            Description = 'Ministry Of Customs And Trade';
        }
        field(220; "Ministry Telephone"; Text[20])
        {
            Caption = 'Ministry Telephone';
            DataClassification = CustomerContent;
            Description = 'Ministry Of Customs And Trade';
        }
        field(230; "Ministry Telefax"; Text[20])
        {
            Caption = 'Ministry Telefax';
            DataClassification = CustomerContent;
            Description = 'Ministry Of Customs And Trade';
        }
        field(240; "Ministry URN"; Text[50])
        {
            Caption = 'GTB E-Invoice Mail Address';
            DataClassification = CustomerContent;
            Description = 'Ministry Of Customs And Trade';
        }
        field(250; "E-Export ProfileID"; Option)
        {
            Caption = 'ProfileID';
            DataClassification = CustomerContent;
            Editable = true;
            OptionCaption = ' ,Commercial,Basic,E-Archive,E-Export';
            OptionMembers = " ",Commercial,Basic,EArchive,EExport;
        }
        field(260; "Default Delivery Terms ID"; Text[20])
        {
            Caption = 'Default Delivery Terms ID';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
        }
    }

    fieldgroups
    {
    }

    var
        Text000: Label 'Do you want to activate E-Export Module?';
        Text001: Label 'Activation stopped!';
        Text002: Label '301', Locked = true;
        Text003: Label '11/1-a Mal ihracatı', Locked = true;
        Text004: Label 'INCOTERMS', Locked = true;
        Text005: Label '1460415308', Locked = true;
        Text006: Label 'Gümrük ve Ticaret Bakanlığı Gümrükler Genel Müdürlüğü', Locked = true;
        Text007: Label 'Dumlupınar Bulvarı No: 151 Eskişehir Yolu', Locked = true;
        Text008: Label 'Çankaya', Locked = true;
        Text009: Label 'Ankara', Locked = true;
        Text010: Label '6530', Locked = true;
        Text011: Label 'TR', Locked = true;
        Text012: Label 'TR', Locked = true;
        Text013: Label 'https://www.gtb.gov.tr', Locked = true;
        Text014: Label '151', Locked = true;
        Text015: Label 'Ulus', Locked = true;
        Text016: Label 'VKN', Locked = true;
        Text017: Label 'basin@gtb.gov.tr', Locked = true;
        Text018: Label '3124491000', Locked = true;
        Text019: Label '3124491000', Locked = true;
        Text020: Label 'urn:mail:ihracatpk@gtb.gov.tr', Locked = true;

}

