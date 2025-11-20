page 70093477 "PRG_E-Invoice Header"
{
    Caption = 'E-Invoice Header';
    DataCaptionFields = "Invoice ID";
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "PRG_E-Invoice Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    Caption = 'Entry No.';
                    ToolTip = 'Specifies the value of the Entry No. field.';
                }
                field(InvoiceType; Rec.InvoiceType)
                {
                    ApplicationArea = All;
                    Caption = 'InvoiceType';
                    ToolTip = 'Specifies the value of the InvoiceType field.';
                }
                field("Invoice ID"; Rec."Invoice ID")
                {
                    ApplicationArea = All;
                    Caption = 'Invoice ID';
                    ToolTip = 'Specifies the value of the Invoice ID field.';
                }
                field(IssueDate; Rec.IssueDate)
                {
                    ApplicationArea = All;
                    Caption = 'IssueDate';
                    ToolTip = 'Specifies the value of the IssueDate field.';
                }
                field(IssueTime; Rec.IssueTime)
                {
                    ApplicationArea = All;
                    Caption = 'IssueTime';
                    ToolTip = 'Specifies the value of the IssueTime field.';
                }
                field(CustNo; Rec.CustNo)
                {
                    ApplicationArea = All;
                    Caption = 'Customer No.';
                    ToolTip = 'Specifies the value of the Customer No. field.';
                }
                field(CustName; Rec.CustName)
                {
                    ApplicationArea = All;
                    Caption = 'CustName';
                    ToolTip = 'Specifies the value of the CustName field.';
                }
                field(DocumentCurrencyCode; Rec.DocumentCurrencyCode)
                {
                    ApplicationArea = All;
                    Caption = 'DocumentCurrencyCode';
                    ToolTip = 'Specifies the value of the DocumentCurrencyCode field.';
                }
                field(DocumentCurrencyRate; Rec.DocumentCurrencyRate)
                {
                    ApplicationArea = All;
                    Caption = 'DocumentCurrencyRate';
                    ToolTip = 'Specifies the value of the DocumentCurrencyRate field.';
                }
                field(UUID; Rec.UUID)
                {
                    ApplicationArea = All;
                    Caption = 'UUID';
                    ToolTip = 'Specifies the value of the UUID field.';
                }
                field(SalesType; Rec.SalesType)
                {
                    ApplicationArea = All;
                    Caption = 'SalesType';
                    ToolTip = 'Specifies the value of the SalesType field.';
                }
                field(IntegrationType; Rec.IntegrationType)
                {
                    ApplicationArea = All;
                    Caption = 'IntegrationType';
                    ToolTip = 'Specifies the value of the IntegrationType field.';
                }
            }
            part(EInvoiceSubForm; "PRG_E-Invoice Subform")
            {
                ApplicationArea = All;
                Caption = 'E-Invoice Subform';
                SubPageLink = "Header Entry No." = FIELD("Entry No.");
            }
            group(Customer)
            {
                Caption = 'Customer';
                field(CustRegistrationNo; Rec.CustRegistrationNo)
                {
                    ApplicationArea = All;
                    Caption = 'CustRegistrationNo';
                    ToolTip = 'Specifies the value of the CustRegistrationNo field.';
                }
                field(CustTaxSchemeID; Rec.CustTaxSchemeID)
                {
                    ApplicationArea = All;
                    Caption = 'CustTaxSchemeID';
                    ToolTip = 'Specifies the value of the CustTaxSchemeID field.';
                }
                field(CustFirstName; Rec.CustFirstName)
                {
                    ApplicationArea = All;
                    Caption = 'CustFirstName';
                    ToolTip = 'Specifies the value of the CustFirstName field.';
                }
                field(CustFamilyName; Rec.CustFamilyName)
                {
                    ApplicationArea = All;
                    Caption = 'CustFamilyName';
                    ToolTip = 'Specifies the value of the CustFamilyName field.';
                }
                field(CustTaxOfficeName; Rec.CustTaxOfficeName)
                {
                    ApplicationArea = All;
                    Caption = 'CustTaxOfficeName';
                    ToolTip = 'Specifies the value of the CustTaxOfficeName field.';
                }
                field(CustTelephone; Rec.CustTelephone)
                {
                    ApplicationArea = All;
                    Caption = 'CustTelephone';
                    ToolTip = 'Specifies the value of the CustTelephone field.';
                }
                field(CustTelefax; Rec.CustTelefax)
                {
                    ApplicationArea = All;
                    Caption = 'CustTelefax';
                    ToolTip = 'Specifies the value of the CustTelefax field.';
                }
                field(CustElectronicMail; Rec.CustElectronicMail)
                {
                    ApplicationArea = All;
                    Caption = 'CustElectronicMail';
                    ToolTip = 'Specifies the value of the CustElectronicMail field.';
                }
                field(CustWebsiteURI; Rec.CustWebsiteURI)
                {
                    ApplicationArea = All;
                    Caption = 'CustWebsiteURI';
                    ToolTip = 'Specifies the value of the CustWebsiteURI field.';
                }
                field(CustPostalZone; Rec.CustPostalZone)
                {
                    ApplicationArea = All;
                    Caption = 'CustPostalZone';
                    ToolTip = 'Specifies the value of the CustPostalZone field.';
                }
                field(CustStreetName; Rec.CustStreetName)
                {
                    ApplicationArea = All;
                    Caption = 'CustStreetName';
                    ToolTip = 'Specifies the value of the CustStreetName field.';
                }
                field(CustBuildingNumber; Rec.CustBuildingNumber)
                {
                    ApplicationArea = All;
                    Caption = 'CustBuildingNumber';
                    ToolTip = 'Specifies the value of the CustBuildingNumber field.';
                }
                field(CustCitySubdivisionName; Rec.CustCitySubdivisionName)
                {
                    ApplicationArea = All;
                    Caption = 'CustCitySubdivisionName';
                    ToolTip = 'Specifies the value of the CustCitySubdivisionName field.';
                }
                field(CustCityName; Rec.CustCityName)
                {
                    ApplicationArea = All;
                    Caption = 'CustCityName';
                    ToolTip = 'Specifies the value of the CustCityName field.';
                }
                field(CustCountryName; Rec.CustCountryName)
                {
                    ApplicationArea = All;
                    Caption = 'CustCountryName';
                    ToolTip = 'Specifies the value of the CustCountryName field.';
                }
                field(CustIdentifier; Rec.CustIdentifier)
                {
                    ApplicationArea = All;
                    Caption = 'CustIdentifier';
                    ToolTip = 'Specifies the value of the CustIdentifier field.';
                }
                field(OrderNo; Rec.OrderNo)
                {
                    ApplicationArea = All;
                    Caption = 'OrderNo';
                    ToolTip = 'Specifies the value of the OrderNo field.';
                }
                field(OrderDate; Rec.OrderDate)
                {
                    ApplicationArea = All;
                    Caption = 'OrderDate';
                    ToolTip = 'Specifies the value of the OrderDate field.';
                }
            }
            group(Invoice)
            {
                Caption = 'Invoice';
                field(PaymentMethodCode; Rec.PaymentMethodCode)
                {
                    ApplicationArea = All;
                    Caption = 'PaymentMethodCode';
                    ToolTip = 'Specifies the value of the PaymentMethodCode field.';
                }
                field("Payee VKN"; Rec."Payee VKN")
                {
                    ApplicationArea = All;
                    Caption = 'Payee VKN';
                    ToolTip = 'Specifies the value of the Payee VKN field.';
                }
                field(PaymentChannelCode; Rec.PaymentChannelCode)
                {
                    ApplicationArea = All;
                    Caption = 'PaymentTermsNote';
                    ToolTip = 'Specifies the value of the PaymentTermsNote field.';
                }
                field(PaymentBankAccNo; Rec.PaymentBankAccNo)
                {
                    ApplicationArea = All;
                    Caption = 'Payment Bank Acc. No.';
                    ToolTip = 'Specifies the value of the Payment Bank Acc. No. field.';
                }
                field(PaymentBankCurrCode; Rec.PaymentBankCurrCode)
                {
                    ApplicationArea = All;
                    Caption = 'Payment Bank Curr. Code';
                    ToolTip = 'Specifies the value of the Payment Bank Curr. Code field.';
                }
                field(PaymentInstructionNote; Rec.PaymentInstructionNote)
                {
                    ApplicationArea = All;
                    Caption = 'PaymentInstructionNote';
                    ToolTip = 'Specifies the value of the PaymentInstructionNote field.';
                }
                field(PaymentMethodNote; Rec.PaymentMethodNote)
                {
                    ApplicationArea = All;
                    Caption = 'PaymentMethodNote';
                    ToolTip = 'Specifies the value of the PaymentMethodNote field.';
                }
                field(PaymentDueDate; Rec.PaymentDueDate)
                {
                    ApplicationArea = All;
                    Caption = 'PaymentDueDate';
                    ToolTip = 'Specifies the value of the PaymentDueDate field.';
                }
                field(PaymentTermsNote; Rec.PaymentTermsNote)
                {
                    ApplicationArea = All;
                    Caption = 'PaymentTermsNote';
                    ToolTip = 'Specifies the value of the PaymentTermsNote field.';
                }
                field(AllowanceChargeIndicator; Rec.AllowanceChargeIndicator)
                {
                    ApplicationArea = All;
                    Caption = 'AllowanceChargeIndicator';
                    ToolTip = 'Specifies the value of the AllowanceChargeIndicator field.';
                }
                field(AllowanceChargeRate; Rec.AllowanceChargeRate)
                {
                    ApplicationArea = All;
                    Caption = 'AllowanceChargeRate';
                    ToolTip = 'Specifies the value of the AllowanceChargeRate field.';
                }
                field(AllowanceChargeAmtLine; Rec.AllowanceChargeAmtLine)
                {
                    ApplicationArea = All;
                    Caption = 'AllowanceChargeAmtLine';
                    ToolTip = 'Specifies the value of the AllowanceChargeAmtLine field.';
                }
                field(LineExtensionAmount; Rec.LineExtensionAmount)
                {
                    ApplicationArea = All;
                    Caption = 'LineExtensionAmount';
                    ToolTip = 'Specifies the value of the LineExtensionAmount field.';
                }
                field(TaxExclusiveAmount; Rec.TaxExclusiveAmount)
                {
                    ApplicationArea = All;
                    Caption = 'TaxExclusiveAmount';
                    ToolTip = 'Specifies the value of the TaxExclusiveAmount field.';
                }
                field(VATAmount; Rec.VATAmount)
                {
                    ApplicationArea = All;
                    Caption = 'VATAmount';
                    ToolTip = 'Specifies the value of the VATAmount field.';
                }
                field(TaxAmount; Rec.TaxAmount)
                {
                    ApplicationArea = All;
                    Caption = 'TaxAmount';
                    ToolTip = 'Specifies the value of the TaxAmount field.';
                }
                field(TaxInclusiveAmount; Rec.TaxInclusiveAmount)
                {
                    ApplicationArea = All;
                    Caption = 'TaxInclusiveAmount';
                    ToolTip = 'Specifies the value of the TaxInclusiveAmount field.';
                }
                field(PayableAmount; Rec.PayableAmount)
                {
                    ApplicationArea = All;
                    Caption = 'PayableAmount';
                    ToolTip = 'Specifies the value of the PayableAmount field.';
                }
                field("Related Invoice No."; Rec."Related Invoice No.")
                {
                    ApplicationArea = All;
                    Caption = 'Related Invoice No.';
                    ToolTip = 'Specifies the value of the Related Invoice No. field.';
                }
                field("Related Invoice Date"; Rec."Related Invoice Date")
                {
                    ApplicationArea = All;
                    Caption = 'Related Invoice Date';
                    ToolTip = 'Specifies the value of the Related Invoice Date field.';
                }
            }
            group("Add. Fields")
            {
                Caption = 'Add. Fields';
                field("Carrier RegistrationNo"; Rec."Carrier RegistrationNo")
                {
                    ApplicationArea = All;
                    Caption = 'Carrier RegistrationNo';
                    ToolTip = 'Specifies the value of the Carrier RegistrationNo field.';
                }
                field("Carrier Name"; Rec."Carrier Name")
                {
                    ApplicationArea = All;
                    Caption = 'Carrier Name';
                    ToolTip = 'Specifies the value of the Carrier Name field.';
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = All;
                    Caption = 'Country/Region Code';
                    ToolTip = 'Specifies the value of the Country/Region Code field.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&E-Invoice")
            {
                Caption = '&E-Invoice';

            }
        }
        area(processing)
        {
            action("Tax Lines")
            {
                ApplicationArea = All;
                Caption = 'Tax Lines';
                Image = TaxDetail;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "PRG_E-Invoice Tax Lines";
                RunPageLink = "Header Entry No." = FIELD("Entry No.");
                ToolTip = 'Executes the Tax Lines action.';
            }
            action(References)
            {
                ApplicationArea = All;
                Caption = 'References';
                Image = Relationship;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "PRG_E-Invoice References";
                RunPageLink = "Header Entry No." = FIELD("Entry No.");
                ToolTip = 'Executes the References action.';
            }
            action("&Navigate")
            {
                ApplicationArea = All;
                Caption = '&Navigate';
                Image = Navigate;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Executes the &Navigate action.';
                trigger OnAction()
                var
                    EInvMgt: Codeunit "PRG_E-Invoice Management";
                begin
                    EInvMgt.Navigate(Rec."G/L Register Entry No.");
                end;
            }
            action(UpdatLines)
            {
                ApplicationArea = All;
                Caption = 'Update Lines';
                Image = UpdateDescription;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Executes the Update Lines action.';
                trigger OnAction()
                var
                    IncDocMgt: Codeunit "PRG_E-Invoice Inc. Doc. Mgt.";
                    Queue: Record "PRG_E-Invoice Queue";
                    EInvLine: Record "PRG_E-Invoice Line";
                begin
                    Queue.SetRange(UniqueIdentifier, Rec.UUID);
                    Queue.FindFirst();

                    EInvLine.SetRange("Header Entry No.", Rec."Entry No.");
                    IF EInvLine.FindSet() THEN
                        repeat
                            IncDocMgt.FindMappingInvoiceLines(EInvLine, Queue);
                        until EInvLine.Next() = 0;

                    CurrPage.Update();
                end;
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    begin
        IF Rec.FIND(Which) THEN BEGIN
            Rec.SETRANGE("G/L Register Entry No.");
            EXIT(TRUE)
        END ELSE BEGIN
            Rec.SETRANGE("Entry No.");
            EXIT(Rec.FIND(Which));
        END;
    end;

    trigger OnModifyRecord(): Boolean
    Var
        CheckFunctions: Codeunit "PRG_E-Invoice Check Functions";
    begin
        CheckFunctions.CheckIfEditable();
    end;
}

