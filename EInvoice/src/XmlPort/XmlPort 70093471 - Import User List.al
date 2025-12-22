// Yorum satırı sahin 
xmlport 70093471 "PRG_E-Invoice Import User List"
{
    Format = Xml;
    Encoding = UTF8;
    XmlVersionNo = V10;
    Direction = Import;

    schema
    {
        textelement(UserList)
        {

            tableelement(User; "PRG_E-Invoice Liable Companies")
            {
                XmlName = 'User';

                fieldelement(Identifier; User.Identifier)
                {

                }
                fieldelement(Alias; User.Alias)
                {

                }
                textelement(Title)
                {

                }
                fieldelement(Type; User.Type)
                {

                }
                fieldelement(FirstCreationTime; User.FirstCreationTime)
                {

                }
                textelement(AliasCreationTime)
                {

                }
                textelement(AccountType)
                {

                }
                trigger OnBeforeInsertRecord()
                begin
                    EntryNo := EntryNo + 1;
                    User."Entry No." := EntryNo;
                    User.Title := CopyStr(Title, 1, MaxStrLen(User.Title));
                end;
            }
        }
    }
    trigger OnPreXmlPort()
    var
        InvoiceCompanies: Record "PRG_E-Invoice Liable Companies";
    begin
        EntryNo := 0;
        IF InvoiceCompanies.FindLast() then
            EntryNo := InvoiceCompanies."Entry No.";
    end;

    var
        EntryNo: Integer;
}
