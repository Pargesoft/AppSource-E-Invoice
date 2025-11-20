pageextension 70093498 "PRG_Item Category Card" extends "Item Category Card"
{
    layout
    {
        addlast(General)
        {
            field("PRG_Medical E-Invoice"; Rec."PRG_Medical E-Invoice Type")
            {
                ApplicationArea = All;
            }
        }
    }
}