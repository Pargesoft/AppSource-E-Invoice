page 70093496 "PRG_E-Invoice Subform 2"
{
    Caption = 'E-Invoice Subform';
    PageType = ListPart;
    SourceTable = "PRG_E-Invoice Line";

    layout
    {
        area(content)
        {
            repeater(EInvoiceLine)
            {
                Caption = 'EInvoiceLine';
                field(Type; Rec.Type)
                {
                    ApplicationArea = All;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                }
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = All;
                    Caption = 'Line No.';
                    ToolTip = 'Specifies the value of the Line No. field.';
                    Visible = false;
                }
                field("Sellers Item Identification"; Rec."Sellers Item Identification")
                {
                    ApplicationArea = All;
                    Caption = 'Sellers Item Identification';
                    ToolTip = 'Specifies the value of the Sellers Item Identification field.';
                }
                field("Item Name"; Rec."Item Name")
                {
                    ApplicationArea = All;
                    Caption = 'Item Name';
                    ToolTip = 'Specifies the value of the Item Name field.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Description';
                    ToolTip = 'Specifies the value of the Description field.';
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = All;
                    Caption = 'Unit Price';
                    ToolTip = 'Specifies the value of the Unit Price field.';
                }
                field("Unit Of Measure Code"; Rec."Unit Of Measure Code")
                {
                    ApplicationArea = All;
                    Caption = 'Unit Of Measure Code';
                    ToolTip = 'Specifies the value of the Unit Of Measure Code field.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = All;
                    Caption = 'Currency Code';
                    ToolTip = 'Specifies the value of the Currency Code field.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                    Caption = 'Quantity';
                    ToolTip = 'Specifies the value of the Quantity field.';
                }
                field("Line Extension Amount"; Rec."Line Extension Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Line Extension Amount';
                    ToolTip = 'Specifies the value of the Line Extension Amount field.';
                }
                field("Allowance Charge Amount"; Rec."Allowance Charge Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Allowance Charge Amount';
                    ToolTip = 'Specifies the value of the Allowance Charge Amount field.';
                }
                field("Taxable Amount"; Rec."Taxable Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Taxable Amount';
                    ToolTip = 'Specifies the value of the Taxable Amount field.';
                }
                field("VAT Amount"; Rec."VAT Amount")
                {
                    ApplicationArea = All;
                    Caption = 'VAT Amount';
                    ToolTip = 'Specifies the value of the VAT Amount field.';
                }
                field("Tax Amount"; Rec."Tax Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Tax Amount';
                    ToolTip = 'Specifies the value of the Tax Amount field.';
                }
                field("Tax Inclusive Amount"; Rec."Tax Inclusive Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Tax Inclusive Amount';
                    ToolTip = 'Specifies the value of the Tax Inclusive Amount field.';
                }
                field("Brand Name"; Rec."Brand Name")
                {
                    ApplicationArea = All;
                    Caption = 'Brand Name';
                    ToolTip = 'Specifies the value of the Brand Name field.';
                    Visible = false;
                }
                field("Model Name"; Rec."Model Name")
                {
                    ApplicationArea = All;
                    Caption = 'Model Name';
                    ToolTip = 'Specifies the value of the Model Name field.';
                    Visible = false;
                }
                field("Buyers Item Identification"; Rec."Buyers Item Identification")
                {
                    ApplicationArea = All;
                    Caption = 'Buyers Item Identification';
                    ToolTip = 'Specifies the value of the Buyers Item Identification field.';
                    Visible = false;
                }
                field("Manu. Item Identification"; Rec."Manu. Item Identification")
                {
                    ApplicationArea = All;
                    Caption = 'Manu. Item Identification';
                    ToolTip = 'Specifies the value of the Manu. Item Identification field.';
                    Visible = false;
                }
                field("VAT Percent"; Rec."VAT Percent")
                {
                    ApplicationArea = All;
                    Caption = 'VAT Percent';
                    ToolTip = 'Specifies the value of the VAT Percent field.';
                }
                field("Delivery Terms"; Rec."Delivery Terms")
                {
                    ApplicationArea = All;
                    Caption = 'Delivery Terms';
                    ToolTip = 'Specifies the value of the Delivery Terms field.';
                }
                field("Transport Mode Code"; Rec."Transport Mode Code")
                {
                    ApplicationArea = All;
                    Caption = 'Transport Mode Code';
                    ToolTip = 'Specifies the value of the Transport Mode Code field.';
                }
                field("Transportation Type"; Rec."Transportation Type")
                {
                    ApplicationArea = All;
                    Caption = 'Transportation Type';
                    ToolTip = 'Specifies the value of the Transportation Type field.';
                }
                field("Transportation ID"; Rec."Transportation ID")
                {
                    ApplicationArea = All;
                    Caption = 'Transportation ID';
                    ToolTip = 'Specifies the value of the Transportation ID field.';
                }
                field("GTIP No."; Rec."GTIP No.")
                {
                    ApplicationArea = All;
                    Caption = 'GTIP No.';
                    ToolTip = 'Specifies the value of the GTIP No. field.';
                }
                field("Package Brand"; Rec."Package Brand")
                {
                    ApplicationArea = All;
                    Caption = 'Package Brand';
                    ToolTip = 'Specifies the value of the Package Brand field.';
                }
                field("Packagin Type Code"; Rec."Packagin Type Code")
                {
                    ApplicationArea = All;
                    Caption = 'Packagin Type Code';
                    ToolTip = 'Specifies the value of the Packagin Type Code field.';
                }
                field("Actual Package Quantity"; Rec."Actual Package Quantity")
                {
                    ApplicationArea = All;
                    Caption = 'Actual Package Quantity';
                    ToolTip = 'Specifies the value of the Actual Package Quantity field.';
                }
                field("Delivery City Name"; Rec."Delivery City Name")
                {
                    ApplicationArea = All;
                    Caption = 'Delivery City Name';
                    ToolTip = 'Specifies the value of the Delivery City Name field.';
                }
                field("Delivery Country Name"; Rec."Delivery Country Name")
                {
                    ApplicationArea = All;
                    Caption = 'Delivery Country Name';
                    ToolTip = 'Specifies the value of the Delivery Country Name field.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnModifyRecord(): Boolean
    Var
        CheckFunctions: Codeunit "PRG_E-Invoice Check Functions";
    begin
        CheckFunctions.CheckIfEditable();
    end;
}