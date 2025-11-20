table 70093488 "PRG_E-Invoice Integrator Setup"
{
    Caption = 'E-Invoice Integrator Setup';
    DataClassification = CustomerContent;
    PasteIsValid = false;

    fields
    {
        field(10; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = CustomerContent;
        }
        field(20; "E-Invoice Integrator"; Option)
        {
            Caption = 'E-Invoice Integrator';
            DataClassification = CustomerContent;
            OptionCaption = 'OwnSystem,Idea,Bimsa,Innova,Veriban,Uyumsoft,Isis,Efinans,Netle,Logo,FIT,Foriba';
            OptionMembers = OwnSystem,Idea,Bimsa,Innova,Veriban,Uyumsoft,Isis,Efinans,Netle,Logo,FIT,Foriba;
        }
        field(21; "E-Invoice Output Type"; Option)
        {
            Caption = 'E-Invoice Output Type';
            DataClassification = CustomerContent;
            OptionCaption = 'Standart,Customized';
            OptionMembers = Standart,Customized;
        }
        field(22; "E-Archive Output Type"; Option)
        {
            Caption = 'E-Archive Output Type';
            DataClassification = CustomerContent;
            OptionCaption = 'Standart,Customized';
            OptionMembers = Standart,Customized;
        }
        field(30; "E-Archive Integrator"; Option)
        {
            Caption = 'E-Archive Integrator';
            DataClassification = CustomerContent;
            OptionCaption = 'OwnSystem,Idea,Bimsa,Innova,Veriban,Uyumsoft,Isis,Efinans,Netle,Logo,FIT,Foriba';
            OptionMembers = OwnSystem,Idea,Bimsa,Innova,Veriban,Uyumsoft,Isis,Efinans,Netle,Logo,FIT,Foriba;
        }
        field(40; "E-Invoice Integrator URL"; Text[100])
        {
            Caption = 'E-Invoice Integrator URL';
            DataClassification = CustomerContent;
        }
        field(50; "E-Archive Integrator URL"; Text[100])
        {
            Caption = 'E-Archive Integrator URL';
            DataClassification = CustomerContent;
        }
        field(60; "E-Invoice Web Service UserName"; Text[50])
        {
            Caption = 'E-Invoice Web Service UserName';
            DataClassification = CustomerContent;
        }
        field(70; "E-Archive Web Service UserName"; Text[50])
        {
            Caption = 'E-Archive Web Service UserName';
            DataClassification = CustomerContent;
        }
        field(80; "E-Invoice Web Service Password"; Text[30])
        {
            Caption = 'E-Invoice Web Service Password';
            DataClassification = CustomerContent;
        }
        field(90; "E-Archive Web Service Password"; Text[30])
        {
            Caption = 'E-Archive Web Service Password';
            DataClassification = CustomerContent;
        }
        field(110; "E-Invoice Int. Auth. URL"; Text[100])
        {
            Caption = 'E-Invoice Int. Auth. URL';
            DataClassification = CustomerContent;
        }
        field(120; "E-Archive Int. Auth. URL"; Text[100])
        {
            Caption = 'E-Archive Int. Auth. URL';
            DataClassification = CustomerContent;
        }
        field(130; "E-Invoice Integration Type"; Text[20])
        {
            Caption = 'E-Invoice Integration Type';
            DataClassification = CustomerContent;
            Description = 'idea';
        }
        field(140; "E-Invoice Integration Version"; Text[5])
        {
            Caption = 'E-Invoice Integration Version';
            DataClassification = CustomerContent;
            Description = 'idea';
        }
        field(150; "E-Invoice Active Company"; Text[10])
        {
            Caption = 'E-Invoice Active Company';
            DataClassification = CustomerContent;
            Description = 'idea';
        }
        field(160; "E-Invoice Active Branch"; Text[10])
        {
            Caption = 'E-Invoice Active Branch';
            DataClassification = CustomerContent;
            Description = 'idea';
        }
        field(200; "Created By"; Code[50])
        {
            Caption = 'Created By';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(210; "Creation DateTime"; DateTime)
        {
            Caption = 'Creation DateTime';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(220; "Last Modified By"; Code[50])
        {
            Caption = 'Last Modified By';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(230; "Last Modification DateTime"; DateTime)
        {
            Caption = 'Last Modification DateTime';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(240; "Company Code"; Text[10])
        {
            Caption = 'Company Code';
            DataClassification = CustomerContent;
            Description = 'efinans';
        }
        field(250; "Document Type"; Text[10])
        {
            Caption = 'Document Type';
            DataClassification = CustomerContent;
            Description = 'efinans';
        }
        field(260; "Document Type Version"; Text[5])
        {
            Caption = 'Document Type Version';
            DataClassification = CustomerContent;
            Description = 'efinans';
        }
        field(270; "Document Request"; Text[10])
        {
            Caption = 'Document Request';
            DataClassification = CustomerContent;
            Description = 'efinans';
        }
        field(280; "Document Version"; Text[5])
        {
            Caption = 'Document Version';
            DataClassification = CustomerContent;
            Description = 'efinans';
        }
        field(290; "Language Code"; Text[5])
        {
            Caption = 'Language Code';
            DataClassification = CustomerContent;
            Description = 'efinans';
        }
        field(300; "Sending Type"; Option)
        {
            Caption = 'Sent to Draft';
            DataClassification = CustomerContent;
            Description = 'veriban';
            OptionCaption = ' ,To Receiver,To Draft';
            OptionMembers = " ",Live,Draft;
        }
        field(310; "E-Invoice Sending Method"; Option)
        {
            Caption = 'Sending Method';
            OptionMembers = Zip,Draft;
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

