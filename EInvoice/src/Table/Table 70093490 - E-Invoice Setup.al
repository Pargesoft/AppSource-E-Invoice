table 70093490 "PRG_E-Invoice Setup"
{
    Caption = 'E-Invoice Setup';
    DataClassification = CustomerContent;
    PasteIsValid = false;

    fields
    {
        field(10; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = CustomerContent;
        }
        field(20; Activated; Boolean)
        {
            Caption = 'Activated';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(80; "E-Invoice No. Series"; Code[20])
        {
            Caption = 'E-Invoice No. Series';
            DataClassification = CustomerContent;
            TableRelation = "No. Series";
        }
        field(81; "E-Archive No. Series"; Code[20])
        {
            Caption = 'E-Archive No. Series';
            DataClassification = CustomerContent;
            TableRelation = "No. Series";
        }
        field(82; "Internet Sales No. Series"; Code[20])
        {
            Caption = 'Internet Sales No. Series';
            DataClassification = CustomerContent;
            TableRelation = "No. Series";
        }
        field(140; "Default Unit of Measure Code"; Code[10])
        {
            Caption = 'Default Unit of Measure Code';
            DataClassification = CustomerContent;
            TableRelation = "Unit of Measure";
        }
        field(190; "Default Item No."; Code[20])
        {
            Caption = 'Default Item No.';
            DataClassification = CustomerContent;
        }
        field(191; "Default Item Name"; Text[100])
        {
            Caption = 'Default Item Name';
            DataClassification = CustomerContent;
        }
        field(200; "Success Status Code"; Code[20])
        {
            Caption = 'Success Status Code';
            DataClassification = CustomerContent;
            TableRelation = "PRG_E-Invoice Status Code";
        }
        field(250; "UBL Version ID"; Text[10])
        {
            Caption = 'UBL Version ID';
            DataClassification = CustomerContent;
        }
        field(251; "Customisation ID"; Text[10])
        {
            Caption = 'Customisation ID';
            DataClassification = CustomerContent;
        }
        field(400; "Item Name Source"; Option)
        {
            Caption = 'Item Name Source';
            DataClassification = CustomerContent;
            OptionCaption = 'Line Description,Account Name';
            OptionMembers = LineDescription,AccName;
        }
        field(450; "Branch Empty E-Mail Control"; Option)
        {
            Caption = 'Branch Empty E-mail Addr. Control';
            DataClassification = CustomerContent;
            OptionCaption = 'CopyFromCustVend,Warn,Block';
            OptionMembers = CopyFromCV,Warn,Block;
        }
        field(500; "Supplier Tax Registration No."; Code[20])
        {
            Caption = 'Supplier Tax Registration No.';
            DataClassification = CustomerContent;
        }
        field(501; "Supplier Trade Register No."; Code[30])
        {
            Caption = 'Supplier Trade Register No.';
            DataClassification = CustomerContent;
        }
        field(502; "Supplier Party Name"; Text[250])
        {
            Caption = 'Supplier Party Name';
            DataClassification = CustomerContent;
        }
        field(503; "Supplier Party Tax Scheme"; Text[30])
        {
            Caption = 'Supplier Party Tax Scheme';
            DataClassification = CustomerContent;
        }
        field(504; "Supplier Country"; Text[20])
        {
            Caption = 'Supplier Country';
            DataClassification = CustomerContent;
        }
        field(505; "Supplier City Name"; Text[20])
        {
            Caption = 'SupplierCityName';
            DataClassification = CustomerContent;
        }
        field(506; "Supplier City Subdivision Name"; Text[50])
        {
            Caption = 'Supplier City Subdivision Name';
            DataClassification = CustomerContent;
        }
        field(507; "Supplier Phone"; Text[30])
        {
            Caption = 'Supplier Phone';
            DataClassification = CustomerContent;
        }
        field(508; "Supplier Fax No."; Text[30])
        {
            Caption = 'Supplier Fax No.';
            DataClassification = CustomerContent;
        }
        field(509; "Supplier E-mail"; Text[100])
        {
            Caption = 'Supplier E-mail';
            DataClassification = CustomerContent;
        }
        field(510; "Supplier Address"; Text[100])
        {
            Caption = 'Supplier Address';
            DataClassification = CustomerContent;
        }
        field(512; RegistrationNoType; Text[30])
        {
            Caption = 'RegistrationNoType';
            DataClassification = CustomerContent;
        }
        field(513; "Supplier Web Address"; Text[100])
        {
            Caption = 'Supplier Web Address';
            DataClassification = CustomerContent;
        }
        field(514; "Supplier Mersis No."; Text[30])
        {
            Caption = 'Supplier Mersis No. ';
            DataClassification = CustomerContent;
        }
        field(700; "Line Grp.Type For Jnl. Entry"; Option)
        {
            OptionMembers = VATPostingGroup,GMIncomeLine;
            OptionCaption = 'VAT Entry,G/L Income Line';
            DataClassification = CustomerContent;
        }
        field(720; "VAT Tax Type Code"; Code[10])
        {
            Caption = 'VAT Tax Type Code';
            DataClassification = CustomerContent;
            TableRelation = "PRG_E-Invoice Tax Type Code";
        }
        field(740; "Sales Exemption Tax Code"; Code[10])
        {
            Caption = 'Sales Exemption Tax Code';
            DataClassification = CustomerContent;
            TableRelation = "PRG_E-Invoice Tax Type Code";
        }
        field(900; "Allow E-Invoice Change"; Boolean)
        {
            Caption = 'Allow E-Invoice Change';
            DataClassification = CustomerContent;
        }
        field(1021; "E-Invoice Starting Date"; Date)
        {
            Caption = 'Company E-Invoice Date';
            DataClassification = CustomerContent;
        }
        field(1022; "E-Invoice Addres"; Option)
        {
            Caption = 'E-Invoice Addres';
            DataClassification = CustomerContent;
            OptionCaption = 'Bill-to Code,Ship-to Code';
            OptionMembers = "Fatura Adresi","Sevk Adres Kodu";
        }
        field(1023; "Rejection Day Limit"; Integer)
        {
            Caption = 'Rejection Day Limit';
            DataClassification = CustomerContent;
        }
        field(1900; "Created By"; Code[50])
        {
            Caption = 'Created By';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(1910; "Creation DateTime"; DateTime)
        {
            Caption = 'Creation DateTime';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(1920; "Last Modified By"; Code[50])
        {
            Caption = 'Last Modified By';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(1930; "Last Modification DateTime"; DateTime)
        {
            Caption = 'Last Modification DateTime';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(1940; "LCY Piastre Identifier"; Text[30])
        {
            Caption = 'LCY Piastre Identifier';
            DataClassification = CustomerContent;
        }
        field(2021; "E-Archive Starting Date"; Date)
        {
            Caption = 'E-Archive Starting Date';
            DataClassification = CustomerContent;
        }
        field(2040; "Exception Control in Posting"; Option)
        {
            Caption = 'E-Invoice Tax Code Control in Posting';
            DataClassification = CustomerContent;
            OptionCaption = 'Not Allow,Warning,Allow';
            OptionMembers = NotAllow,Warning,Allow;
        }
        field(2050; "Control TaxTypeCode for P&SCr."; Boolean)
        {
            Caption = 'Control Tax Type Code for Documents that are not E-Invoices';
            DataClassification = CustomerContent;
        }
        field(3010; "Incoming Inv. Mapping Type"; Option)
        {
            Caption = 'Incoming Inv. Mapping Type';
            DataClassification = CustomerContent;
            OptionCaption = ' ,Header,HeaderLine,NotEnabled';
            OptionMembers = " ",Header,HeaderLine,NotEnabled;
        }
        field(3020; "Document Mapping Control Type"; Option)
        {
            Caption = 'Document Mapping Control Type';
            DataClassification = CustomerContent;
            OptionMembers = Allow,Warning,"Not Allow";
            OptionCaption = 'Allow,Warning,Not Allow';
        }
        field(3030; "Mapping Adding Type"; Option)
        {
            Caption = 'Mapping Adding Type';
            DataClassification = CustomerContent;
            OptionMembers = "Not Add","Related CV","All CV";
            OptionCaption = 'Not Add,Related Customer/Vendor,All Customer/Vendor';
        }
        field(3240; "Default ProfileID"; Option)
        {
            Caption = 'Default ProfileID';
            DataClassification = CustomerContent;
            OptionCaption = ' ,Commercial,Basic,E-Archive,E-Export';
            OptionMembers = " ",Commercial,Basic,EArchive,EExport;
        }
        field(3250; "Default Carriage Item Charge"; Code[20])
        {
            Caption = 'Default Carriage Item Charge';
            DataClassification = CustomerContent;
            TableRelation = "Item Charge";
        }
        field(3260; "Default Insurance Item Charge"; Code[20])
        {
            Caption = 'Default Insurance Item Charge';
            DataClassification = CustomerContent;
            TableRelation = "Item Charge";
        }
        field(4000; "Company Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            DataClassification = CustomerContent;
            Description = 'General';
            TableRelation = "Country/Region";

        }
        field(4020; "Send ERP Doc. Number As Note"; Boolean)
        {
            Caption = 'Send ERP Document Number As Note';
            DataClassification = CustomerContent;
        }
        field(4050; "Add Withholding Line to XML"; Boolean)
        {
            Caption = 'Add Withholding Line to XML';
            DataClassification = CustomerContent;
        }
        field(4100; "Payee Financial Account"; Text[50])
        {
            Caption = 'Payee Financial Account';
            DataClassification = CustomerContent;
        }
        field(4110; "Payee Currency Code"; Code[10])
        {
            Caption = 'Payee Currency Code';
            DataClassification = CustomerContent;
        }
        field(4120; "Payee Payment Note"; Code[10])
        {
            Caption = 'Payee Payment Note';
            DataClassification = CustomerContent;
        }
        field(4200; "XSLT File"; Blob)
        {
            Caption = 'E-Invoice XSLT File';
            DataClassification = CustomerContent;
        }
        field(4300; "E-Archive XSLT File"; Blob)
        {
            Caption = 'E-Archive XSLT File';
            DataClassification = CustomerContent;
        }
        field(4410; "Export to Service Type"; Option)
        {
            Caption = 'Export to Service Type';
            OptionMembers = Manual,Automatic;
            OptionCaption = 'Manual,Automatic';
            DataClassification = CustomerContent;
        }
        field(4450; "Active Medical E-Invoice"; Boolean)
        {
            Caption = 'Medical E-Invoice';
            DataClassification = CustomerContent;
        }
        field(4460; "Inc. Doc. Posting Date Type"; Option)
        {
            Caption = 'Incoming Document Posting Date Type';
            OptionMembers = "Incoming Document Date","Creation Date";
            OptionCaption = 'Incoming Document Date,Creation Date';
            DataClassification = CustomerContent;
        }
        field(4500; "Last Updated E-Inv. User List"; DateTime)
        {
            Caption = 'Last Updated Date E-Invoice User List';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(4510; "Note Info. Source"; Enum "PRG_Note Info. Source")
        {
            Caption = 'Note Info. Source';
            DataClassification = CustomerContent;
        }
        field(4520; "Posting Amount Control"; Enum "PRG_Posting Control")
        {
            Caption = 'Posting Amount Control';
            DataClassification = CustomerContent;
        }
        field(4530; "Different Amount Range"; Decimal)
        {
            Caption = 'Different Amount Range';
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

    trigger OnInsert()
    begin
        "Created By" := USERID;
        "Creation DateTime" := CURRENTDATETIME;
        "Last Modified By" := USERID;
        "Last Modification DateTime" := CURRENTDATETIME;
    end;

    trigger OnModify()
    begin
        "Last Modified By" := USERID;
        "Last Modification DateTime" := CURRENTDATETIME;
    end;

}