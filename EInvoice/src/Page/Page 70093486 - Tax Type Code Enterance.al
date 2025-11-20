page 70093486 "PRG_Tax Type Code Enterance"
{
    Caption = 'Tax Type Code Enterance';
    PageType = StandardDialog;
    Permissions = tabledata "Purch. Cr. Memo Line" = rm,
                    tabledata "Sales Invoice Line" = rm;

    layout
    {
        area(content)
        {
            field(TaxTypeCode; TaxTypeCode)
            {
                ApplicationArea = All;
                Caption = 'Tax Type Code';
                TableRelation = "PRG_E-Invoice Tax Type Code";
                ToolTip = 'Specifies the value of the Tax Type Code field.';
            }
        }
    }

    var
        GlobDocNo: Code[20];
        TaxTypeCode: Code[20];
        GlobLineNo: Integer;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        SalesInvLine: Record "Sales Invoice Line";
    begin
        IF TaxTypeCode = '' then
            exit;

        IF (GlobDocNo <> '') and (GlobLineNo <> 0) then begin
            SalesInvLine.Reset();
            SalesInvLine.SetRange("Document No.", GlobDocNo);
            SalesInvLine.SetRange("Line No.", GlobLineNo);
            IF SalesInvLine.FindFirst() then begin
                SalesInvLine."PRG_E-Invoice Tax Type Code" := TaxTypeCode;
                SalesInvLine.Modify()
            end;
            PurchCrMemoLine.Reset();
            PurchCrMemoLine.SetRange("Document No.", GlobDocNo);
            PurchCrMemoLine.SetRange("Line No.", GlobLineNo);
            IF PurchCrMemoLine.FindFirst() then begin
                PurchCrMemoLine."PRG_E-Invoice Tax Type Code" := TaxTypeCode;
                PurchCrMemoLine.Modify()
            end;
        end
    end;

    procedure SetInvLine(DocNo: Code[20]; LineNo: Integer)
    begin
        GlobDocNo := DocNo;
        GlobLineNo := LineNo;
    end;
}
