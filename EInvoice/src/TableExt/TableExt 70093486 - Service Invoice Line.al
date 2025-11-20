tableextension 70093486 "PRG_EINV_ServiceInvLine" extends "Service Invoice Line"
{
    fields
    {
        field(70093471; "PRG_E-Invoice Tax Type Code"; Code[20])
        {
            Caption = 'E-Invoice Tax Type Code';
            DataClassification = CustomerContent;
            TableRelation = "PRG_E-Invoice Tax Type Code";
        }
    }
    procedure GetServShptLines(VAR TempServShptLine: Record "Service Shipment Line" temporary)
    var
        ServShptLine: Record "Service Shipment Line";
        ItemLedgEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
    begin
        TempServShptLine.RESET();
        TempServShptLine.DELETEALL();

        IF Rec.Type <> Rec.Type::Item THEN
            exit;

        FilterPstdDocLineValueEntries(ValueEntry);
        IF ValueEntry.FINDSET() THEN
            REPEAT
                ItemLedgEntry.GET(ValueEntry."Item Ledger Entry No.");
                IF ItemLedgEntry."Document Type" = ItemLedgEntry."Document Type"::"Service Shipment" THEN
                    IF ServShptLine.GET(ItemLedgEntry."Document No.", ItemLedgEntry."Document Line No.") THEN BEGIN
                        TempServShptLine.INIT();
                        TempServShptLine := ServShptLine;
                        IF TempServShptLine.INSERT() THEN;
                    END;
            UNTIL ValueEntry.NEXT() = 0;
    end;
}