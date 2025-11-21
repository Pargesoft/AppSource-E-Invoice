codeunit 70093482 "PRG_Upgrade Codeunit"
{
    Subtype = Upgrade;

    trigger OnValidateUpgradePerCompany()
    begin
        SetActiveEInvoiceSetup();
        UpdateEInvLines();
    end;

    trigger OnUpgradePerCompany()
    begin
    end;

    //E-Fatura Kurulumu Aktif Etme
    local procedure SetActiveEInvoiceSetup()
    var
        EInvSetup: Record "PRG_E-Invoice Setup";
    begin
        if not EInvSetup.Get() then
            exit;

        if EInvSetup.Activated then
            exit;

        EInvSetup.Activated := true;
        EInvSetup.Modify();
    end;

    //E-Fatura Satırlarında UUID Güncelleme
    local procedure UpdateEInvLines()
    var
        EInvHeader: Record "PRG_E-Invoice Header";
        EInvLine: Record "PRG_E-Invoice Line";
    begin
        if EInvHeader.FindSet() then
            repeat
                EInvLine.SetRange("Header Entry No.", EInvHeader."Entry No.");
                EInvLine.ModifyAll(UUID, EInvHeader.UUID);
            until EInvHeader.Next() = 0;
    end;
}