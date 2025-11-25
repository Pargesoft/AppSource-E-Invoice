pageextension 70093499 "PRG_Customer List" extends "Customer List"
{
    trigger OnOpenPage()
    begin
        Message('App published: Hello world');
    end;
}
