page 70093493 "PRG_E-Invoice Qeue Card"
{
    ApplicationArea = All;
    Caption = 'E-Invoice Queue Card';
    PageType = Card;
    InsertAllowed = false;
    DeleteAllowed = false;
    SourceTable = "PRG_E-Invoice Queue";
    layout
    {
        area(Content)
        {
            part(header; "PRG_E-Invoice Header 2")
            {
                ShowFilter = false;
                SubPageLink = UUID = field(UniqueIdentifier);
            }
            part(line; "PRG_E-Invoice Subform 2")
            {
                ShowFilter = false;
                SubPageLink = UUID = field(UniqueIdentifier);
            }

        }
    }
    actions
    {
        area(Processing)
        {
            action(UpdatLines)
            {
                Caption = 'Update Lines';
                trigger OnAction()
                var
                    Header: Record "PRG_E-Invoice Header";
                    EInvLine: Record "PRG_E-Invoice Line";
                begin
                    Header.FindFirst();
                    repeat
                        EInvLine.SetRange("Header Entry No.", Header."Entry No.");
                        EInvLine.ModifyAll(UUID, Header.UUID);
                    until Header.Next() = 0;
                end;
            }
        }
    }
}