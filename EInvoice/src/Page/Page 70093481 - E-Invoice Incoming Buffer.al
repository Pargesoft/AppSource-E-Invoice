page 70093481 "PRG_E-Invoice Incoming Buffer"
{
    Caption = 'E-Invoice Incoming Buffer';
    PageType = List;
    SourceTable = "PRG_E-Invoice Incoming Buffer";

    layout
    {
        area(content)
        {
            repeater(General)
            {
                Caption = 'General';
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    Caption = 'Entry No';
                    ToolTip = 'Specifies the value of the Entry No. field.';
                }
                field("Document ID"; Rec."Document ID")
                {
                    ApplicationArea = All;
                    Caption = 'Document ID';
                    ToolTip = 'Specifies the value of the Document ID field.';
                }
                field("Created By"; Rec."Created By")
                {
                    ApplicationArea = All;
                    Caption = 'Created By';
                    ToolTip = 'Specifies the value of the Created By field.';
                }
                field("Created DateTime"; Rec."Created DateTime")
                {
                    ApplicationArea = All;
                    Caption = 'Created DateTime';
                    ToolTip = 'Specifies the value of the Created DateTime field.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("&Functions")
            {
                Caption = '&Functions';

                group("Download File")
                {
                    Caption = 'Download File';
                    Image = Confirm;

                    action(Download)
                    {
                        ApplicationArea = All;
                        Caption = 'Download';
                        Image = Confirm;
                        ToolTip = 'Download Waiting File';

                        trigger OnAction()
                        var
                            Convert: Codeunit "Base64 Convert";
                            TempBlob: Codeunit "Temp Blob";
                            TempBlob2: Codeunit "Temp Blob";
                            IStr: InStream;
                            IStr2: InStream;
                            Text001: Label 'Request.xml';
                            OStr: OutStream;
                            FileText: Text;
                        begin

                            TempBlob.FromRecord(Rec, Rec.FieldNo("Invoice Value"));
                            TempBlob.CreateInStream(IStr, TextEncoding::UTF8);
                            TempBlob2.CreateOutStream(OStr, TextEncoding::UTF8);
                            IStr.Read(FileText);
                            Convert.FromBase64(FileText, OStr);
                            Tempblob2.CreateInStream(IStr2, TextEncoding::UTF8);
                            FileText := Text001;

                            DownloadFromStream(IStr2, 'Xml İndir', 'Xml İndir', 'Xml-File | *.xml', FileText);

                        end;
                    }
                }
            }
        }
    }
}

