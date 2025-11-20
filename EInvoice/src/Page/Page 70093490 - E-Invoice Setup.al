page 70093490 "PRG_E-Invoice Setup"
{
    ApplicationArea = All;
    Caption = 'E-Invoice Setup';
    PageType = Card;
    SourceTable = "PRG_E-Invoice Setup";
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field(Activated; Rec.Activated)
                {
                    ApplicationArea = All;
                    Caption = 'Activated';
                    ToolTip = 'Specifies the value of the Activated field.';
                }
                field("E-Invoice Starting Date"; Rec."E-Invoice Starting Date")
                {
                    ApplicationArea = All;
                    Caption = 'Company E-Invoice Date';
                    ToolTip = 'Specifies the value of the Company E-Invoice Date field.';
                }
                field("E-Archive Starting Date"; Rec."E-Archive Starting Date")
                {
                    ApplicationArea = All;
                    Caption = 'E-Archive Starting Date';
                    ToolTip = 'Specifies the value of the E-Archive Starting Date field.';
                }
                field("Item Name Source"; Rec."Item Name Source")
                {
                    ApplicationArea = All;
                    Caption = 'Item Name Source';
                    ToolTip = 'Specifies the value of the Item Name Source field.';
                }
                field("Branch Empty E-Mail Control"; Rec."Branch Empty E-Mail Control")
                {
                    ApplicationArea = All;
                    Caption = 'Branch Empty E-mail Addr. Control';
                    ToolTip = 'Specifies the value of the Branch Empty E-mail Addr. Control field.';
                }
                field("Allow E-Invoice Change"; Rec."Allow E-Invoice Change")
                {
                    ApplicationArea = All;
                    Caption = 'Allow E-Invoice Change';
                    ToolTip = 'Specifies the value of the Allow E-Invoice Change field.';
                }
                field("E-Invoice No. Series"; Rec."E-Invoice No. Series")
                {
                    ApplicationArea = All;
                    Caption = 'E-Invoice No. Series';
                    ToolTip = 'Specifies the value of the E-Invoice No. Series field.';
                }
                field("E-Archive No. Series"; Rec."E-Archive No. Series")
                {
                    ApplicationArea = All;
                    Caption = 'E-Archive No. Series';
                    ToolTip = 'Specifies the value of the E-Archive No. Series field.';
                }
                field("Internet Sales No. Series"; Rec."Internet Sales No. Series")
                {
                    ApplicationArea = All;
                    Caption = 'Internet Sales No. Series';
                    ToolTip = 'Specifies the value of the Internet Sales No. Series field.';
                }
                field("Company Country/Region Code"; Rec."Company Country/Region Code")
                {
                    ApplicationArea = All;
                    Caption = 'Country/Region Code';
                    ToolTip = 'Specifies the value of the Country/Region Code field.';
                }
                field("LCY Piastre Identifier"; Rec."LCY Piastre Identifier")
                {
                    ApplicationArea = All;
                    Caption = 'LCY Piastre Identifier';
                    ToolTip = 'If there is Turkish characters in path.It usefull to use .Net option';
                }
                field("Line Grp.Type For Jnl. Entry"; Rec."Line Grp.Type For Jnl. Entry")
                {
                    Caption = 'Line Grouping Type';
                    ApplicationArea = All;
                }

                field("Export to Service Type"; Rec."Export to Service Type")
                {
                    Caption = 'Export to Service Type';
                    ApplicationArea = All;
                }
                field("Note Info. Source"; Rec."Note Info. Source")
                {
                    Caption = 'Note Info. Source';
                    ApplicationArea = All;
                }
                field("Last Updated E-Inv. User List"; Rec."Last Updated E-Inv. User List")
                {
                    ApplicationArea = All;
                    Caption = 'Last Updated Date E-Inv. User List';
                    ToolTip = 'Specifies the value of the Last Updated E-Inv. User List field.';
                    Editable = true;
                }
            }

            group(Company)
            {
                Caption = 'Company';
                field("Supplier Tax Registration No."; Rec."Supplier Tax Registration No.")
                {
                    ApplicationArea = All;
                    Caption = 'Supplier Tax Registration No.';
                    ToolTip = 'Specifies the value of the Supplier Tax Registration No. field.';
                }
                field(RegistrationNoType; Rec.RegistrationNoType)
                {
                    ApplicationArea = All;
                    Caption = 'Supplier RegistrationNoType';
                    ToolTip = 'Valid Options are VKN or TCKN';
                }
                field("Supplier Trade Register No."; Rec."Supplier Trade Register No.")
                {
                    ApplicationArea = All;
                    Caption = 'Supplier Trade Register No.';
                    ToolTip = 'Specifies the value of the Supplier Trade Register No. field.';
                }
                field("Supplier Party Name"; Rec."Supplier Party Name")
                {
                    ApplicationArea = All;
                    Caption = 'Supplier Party Name';
                    ToolTip = 'Specifies the value of the Supplier Party Name field.';
                }
                field("Supplier Party Tax Scheme"; Rec."Supplier Party Tax Scheme")
                {
                    ApplicationArea = All;
                    Caption = 'Supplier Party Tax Scheme';
                    ToolTip = 'Specifies the value of the Supplier Party Tax Scheme field.';
                }
                field("Supplier Country"; Rec."Supplier Country")
                {
                    ApplicationArea = All;
                    Caption = 'Supplier Country';
                    ToolTip = 'Specifies the value of the Supplier Country field.';
                }
                field("Supplier City Name"; Rec."Supplier City Name")
                {
                    ApplicationArea = All;
                    Caption = 'SupplierCityName';
                    ToolTip = 'Specifies the value of the SupplierCityName field.';
                }
                field("Supplier City Subdivision Name"; Rec."Supplier City Subdivision Name")
                {
                    ApplicationArea = All;
                    Caption = 'Supplier City Subdivision Name';
                    ToolTip = 'Specifies the value of the Supplier City Subdivision Name field.';
                }
                field("Supplier Address"; Rec."Supplier Address")
                {
                    ApplicationArea = All;
                    Caption = 'Supplier Address';
                    ToolTip = 'Specifies the value of the Supplier Address field.';
                }
                field("Supplier Phone"; Rec."Supplier Phone")
                {
                    ApplicationArea = All;
                    Caption = 'Supplier Phone';
                    ToolTip = 'Specifies the value of the Supplier Phone field.';
                }
                field("Supplier Fax No."; Rec."Supplier Fax No.")
                {
                    ApplicationArea = All;
                    Caption = 'Supplier Fax No.';
                    ToolTip = 'Specifies the value of the Supplier Fax No. field.';
                }
                field("Supplier E-mail"; Rec."Supplier E-mail")
                {
                    ApplicationArea = All;
                    Caption = 'Supplier E-mail';
                    ToolTip = 'Specifies the value of the Supplier E-mail field.';
                }
                field("Supplier Web Address"; Rec."Supplier Web Address")
                {
                    ApplicationArea = All;
                    Caption = 'Supplier Web Address';
                    ToolTip = 'Specifies the value of the Supplier Web Address field.';
                }
                field("Supplier Mersis No."; Rec."Supplier Mersis No.")
                {
                    ApplicationArea = All;
                    Caption = 'Supplier Mersis No. ';
                    ToolTip = 'Specifies the value of the Supplier Mersis No.  field.';
                }
            }
            group(Default)
            {
                Caption = 'Default';
                field("Success Status Code"; Rec."Success Status Code")
                {
                    ApplicationArea = All;
                    Caption = 'Success Status Code';
                    ToolTip = 'Specifies the value of the Success Status Code field.';
                }
                field("Default Item No."; Rec."Default Item No.")
                {
                    Caption = 'Default Item No.';
                    ApplicationArea = All;
                }
                field("Default Item Name"; Rec."Default Item Name")
                {
                    Caption = 'Default Item Name';
                    ApplicationArea = All;
                }
                field("Default Unit of Measure Code"; Rec."Default Unit of Measure Code")
                {
                    Caption = 'Default Unit of Measure Code';
                    ApplicationArea = All;
                }
                field("VAT Tax Type Code"; Rec."VAT Tax Type Code")
                {
                    ApplicationArea = All;
                    Caption = 'VAT Tax Type Code';
                    ToolTip = 'Specifies the value of the VAT Tax Type Code field.';
                }
                field("Sales Exemption Tax Code"; Rec."Sales Exemption Tax Code")
                {
                    ApplicationArea = All;
                    Caption = 'Sales Exemption Tax Code';
                    ToolTip = 'Specifies the value of the Sales Exemption Tax Code field.';
                }
                field("UBL Version ID"; Rec."UBL Version ID")
                {
                    ApplicationArea = All;
                    Caption = 'UBL Version ID';
                    ToolTip = 'Specifies the value of the UBL Version ID field.';
                }
                field("Customisation ID"; Rec."Customisation ID")
                {
                    ApplicationArea = All;
                    Caption = 'Customisation ID';
                    ToolTip = 'Specifies the value of the Customisation ID field.';
                }
                field("E-Invoice Addres"; Rec."E-Invoice Addres")
                {
                    ApplicationArea = All;
                    Caption = 'E-Invoice Addres';
                    ToolTip = 'Specifies the value of the E-Invoice Addres field.';
                }
                field("Rejection Day Limit"; Rec."Rejection Day Limit")
                {
                    ApplicationArea = All;
                    Caption = 'Rejection Day Limit';
                    ToolTip = 'Specifies the value of the Rejection Day Limit field.';
                }
                field("Exception Control in Posting"; Rec."Exception Control in Posting")
                {
                    ApplicationArea = All;
                    Caption = 'E-Invoice Tax Code Control in Posting';
                    ToolTip = 'Specifies the value of the E-Invoice Tax Code Control in Posting field.';
                }
                field("Control TaxTypeCode for P&SCr."; Rec."Control TaxTypeCode for P&SCr.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Control Tax Type Code for Documents that are not E-Invoices field.';
                    Caption = 'Control Tax Type Code for Documents that are not E-Invoices';
                }
                field("Default ProfileID"; Rec."Default ProfileID")
                {
                    ApplicationArea = All;
                    Caption = 'Default ProfileID';
                    ToolTip = 'Specifies the value of the Default ProfileID field.';
                }
                field("Default Carriage Item Charge"; Rec."Default Carriage Item Charge")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Default Carriage Item Charge field.';
                    Caption = 'Default Carriage Item Charge';
                }
                field("Default Insurance Item Charge"; Rec."Default Insurance Item Charge")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Default Insurance Item Charge field.';
                    Caption = 'Default Insurance Item Charge';
                }
                field("Add Withholding Line to XML"; Rec."Add Withholding Line to XML")
                {
                    ApplicationArea = All;
                    Caption = 'Add Withholding Line to XML';
                    ToolTip = 'Specifies the value of the Add Withholding Line to XML field.';
                }
                field("Active Medical E-Invoice"; Rec."Active Medical E-Invoice")
                {
                    ApplicationArea = All;
                    Caption = 'Active Medical E-Invoice';
                    ToolTip = 'Specifies the value of the Active Medical E-Invoice field.';
                }
            }
            group(Payee)
            {
                Caption = 'Payee';
                field("Payee Financial Account"; Rec."Payee Financial Account")
                {
                    ApplicationArea = All;
                    Caption = 'Payee Financial Account';
                    ToolTip = 'Specifies the value of the Payee Financial Account field.';
                }
                field("Payee Currency Code"; Rec."Payee Currency Code")
                {
                    ApplicationArea = All;
                    Caption = 'Payee Currency Code';
                    ToolTip = 'Specifies the value of the Payee Currency Code field.';
                }
                field("Payee Payment Note"; Rec."Payee Payment Note")
                {
                    ApplicationArea = All;
                    Caption = 'Payee Payment Note';
                    ToolTip = 'Specifies the value of the Payee Payment Note field.';
                }
            }
            group(IncomingDocMgt)
            {
                Caption = 'Incoming Doc. Mgt.';
                field("Incoming Inv. Mapping Type"; Rec."Incoming Inv. Mapping Type")
                {
                    ApplicationArea = All;
                    Caption = 'Incoming Inv. Mapping Type';
                    ToolTip = 'Specifies the value of the Incoming Inv. Mapping Type field.';
                }
                field("Document Mapping Control Type"; Rec."Document Mapping Control Type")
                {
                    Caption = 'Document Mapping Control Type';
                    ApplicationArea = All;
                }
                field("Mapping Adding Type"; Rec."Mapping Adding Type")
                {
                    Caption = 'Mapping Adding Type';
                    ApplicationArea = All;
                }
                field("Inc. Doc. Posting Date Type"; Rec."Inc. Doc. Posting Date Type")
                {
                    Caption = 'Incoming Document Posting Date Type';
                    ApplicationArea = All;
                }
                field("Posting Amount Control"; Rec."Posting Amount Control")
                {
                    Caption = 'Posting Amount Control';
                    ApplicationArea = All;
                }
                field("Different Amount Range"; Rec."Different Amount Range")
                {
                    Caption = 'Different Amount Range';
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            group(Setup)
            {
                Caption = 'Setup';
                action("Activate Company")
                {
                    ApplicationArea = All;
                    Caption = 'Activate Company';
                    Image = Approve;
                    ToolTip = 'Executes the Activate Company action.';

                    trigger OnAction()
                    begin
                        CurrPage.SaveRecord();
                        ActivateProduct();
                    end;
                }
                action("Set Document Values")
                {
                    ApplicationArea = All;
                    Caption = 'Set Document Values';
                    Image = Approve;
                    ToolTip = 'Executes the Set Document Values action.';

                    trigger OnAction()
                    var
                        Library: Codeunit "PRG_E-Invoice Library";
                    begin
                        Library.SetDocumentInitialValues();
                    end;
                }
                action("User Setup")
                {
                    ApplicationArea = All;
                    Caption = 'User Setup';
                    Image = UserSetup;
                    RunObject = page "User Setup";
                    ToolTip = 'Executes the User Setup action.';
                }
                action("Create No. Series")
                {
                    ApplicationArea = All;
                    Caption = 'Create No. Series';
                    Image = UserSetup;
                    RunObject = report "PRG_Create E-Inv. No. Series";
                    ToolTip = 'Executes the Create No. Series action.';
                }
                action("Fix Notes")
                {
                    ApplicationArea = All;
                    Caption = 'Fix Notes';
                    Image = Notes;
                    RunObject = page "PRG_E-Invoice Fix Notes";
                    ToolTip = 'Executes the E-Invoice Fix Notes action.';
                }
                action("Upload XSLT")
                {
                    ApplicationArea = All;
                    Caption = 'Upload E-Invoice XSLT';
                    Image = Import;
                    ToolTip = 'Executes the Upload E-Invoice XSLT action.';
                    trigger OnAction()
                    var
                        Instr: InStream;
                        OutStr: OutStream;
                        FilePath: Text;
                    begin
                        if UploadIntoStream('Select File...', '', '', FilePath, Instr) then begin
                            Rec."XSLT File".CreateOutStream(OutStr);
                            CopyStream(OutStr, Instr);
                            Rec.Modify();
                            Message('File Upload Successful.');
                        end;
                    end;
                }
                action("Upload E-Archive XSLT")
                {
                    ApplicationArea = All;
                    Caption = 'Upload E-Archive XSLT';
                    Image = Import;
                    ToolTip = 'Executes the Upload E-Archive XSLT action.';
                    trigger OnAction()
                    var
                        Instr: InStream;
                        OutStr: OutStream;
                        FilePath: Text;
                    begin
                        if UploadIntoStream('Select File...', '', '', FilePath, Instr) then begin
                            Rec."E-Archive XSLT File".CreateOutStream(OutStr);
                            CopyStream(OutStr, Instr);
                            Rec.Modify();
                            Message('File Upload Successful.');
                        end;
                    end;
                }
                action("Download XSLT")
                {
                    ApplicationArea = All;
                    Caption = 'Download XSLT';
                    Image = Export;
                    Enabled = false;
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'No need';
                    ToolTip = 'Executes the Download XSLT action.';
                    trigger OnAction()
                    var
                        Instr: InStream;
                        OutStr: OutStream;
                        FileName: Text;
                    begin
                        Rec.CalcFields("XSLT File");
                        if not Rec."XSLT File".HasValue then
                            Error('');

                        FileName := 'general.xslt';
                        Rec."XSLT File".CreateInStream(Instr);
                        DownloadFromStream(Instr, '', '', '', FileName);
                    end;
                }
            }
        }
    }
    local procedure ActivateProduct()

    begin
        if Rec.Activated then
            exit;

        Rec.TestField("Success Status Code");
        Rec.TestField("Supplier Tax Registration No.");
        Rec.TestField(RegistrationNoType);
        Rec.TestField("Supplier Trade Register No.");
        Rec.TestField("Supplier Party Name");
        Rec.TestField("Supplier Party Tax Scheme");
        Rec.TestField("Supplier Country");
        Rec.TestField("Supplier City Name");
        Rec.TestField("VAT Tax Type Code");
        Rec.Activated := true;
        Rec.Modify();
    end;
}
