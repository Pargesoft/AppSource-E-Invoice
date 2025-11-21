codeunit 70093479 "PRG_E-Invoice Number Reader"
{
    trigger OnRun()
    begin
    end;

    var
        Currency: Record Currency;
        GLSetup: Record "General Ledger Setup";
        EInvSetup: Record "PRG_E-Invoice Setup";
        Text1: Label 'One ';
        Text001: Label 'Attention : The number that will be written in text is equal or higher than 1 trillion. This number can not be written in text.';
        Text2: Label 'Two ';
        Text002: Label 'and ';
        Text3: Label 'Three ';
        Text003: Label '%1 %2 %3 %4 %5 %6';
        Text4: Label 'Four ';
        Text5: Label 'Five ';
        Text005: Label '%1 %2 %3';
        Text6: Label 'Six ';
        Text7: Label 'Seven ';
        Text8: Label 'Eight ';
        Text9: Label 'Nine ';
        Text10: Label 'Ten ';
        Text20: Label 'Twenty ';
        Text30: Label 'Thirty ';
        Text40: Label 'Forty';
        Text50: Label 'Fifty ';
        Text60: Label 'Sixty ';
        Text70: Label 'Seventy ';
        Text80: Label 'Eighty ';
        Text90: Label 'Ninety ';
        Text100: Label 'Hundred ';
        Text1000: Label 'Thousand ';
        Text1443: Label 'Million ';
        Text1443000: Label 'Billion ';
        Text1443000000: Label 'Trillion ';
        PrecisionCode: Text[30];

    procedure EnglishText(aNumber: Integer): Text[9]
    begin
        case aNumber of
            1:
                EXIT('one');
            2:
                EXIT('two');
            3:
                EXIT('three');
            4:
                EXIT('four');
            5:
                EXIT('five');
            6:
                EXIT('six');
            7:
                EXIT('seven');
            8:
                EXIT('eight');
            9:
                EXIT('nine');
            10:
                EXIT('ten');
            11:
                EXIT('eleven');
            12:
                EXIT('twelve');
            13:
                EXIT('thirteen');
            14:
                EXIT('fourteen');
            15:
                EXIT('fifteen');
            16:
                EXIT('sixteen');
            17:
                EXIT('seventeen');
            18:
                EXIT('eighteen');
            19:
                EXIT('nineteen');
            20:
                EXIT('twenty');
            30:
                EXIT('thirty');
            40:
                EXIT('forty');
            50:
                EXIT('fifty');
            60:
                EXIT('sixty');
            70:
                EXIT('seventy');
            80:
                EXIT('eighty');
            90:
                EXIT('ninety');
            100:
                EXIT('hundred');
            1000:
                EXIT('thousand');
            1000000:
                EXIT('million');
            1000000000:
                EXIT('billion');
        end;
    end;

    procedure GetWords(String: Text[20]; TheNumber: Decimal; CurrencyCode: Code[20]): Text[200]
    var
        LocText001: label '%1 setup not installed';
        NumberWord1: Text[100];
        NumberWord2: Text[100];
    begin

        NumberWord1 := Format(Round(TheNumber, 1, '<'));
        NumberWord2 := Format(Round(TheNumber, 1, '>') - TheNumber);

        IF GLSetup.Get() then
            GLSetup.TestField("LCY Code")
        else
            exit(StrSubstNo(LocText001, GLSetup.TableCaption));
        if (CurrencyCode = GLSetup."LCY Code") or
          (CurrencyCode = '') then begin
            IF EInvSetup.Get() then
                EInvSetup.TestField("LCY Piastre Identifier")
            else
                exit(StrSubstNo(LocText001, GLSetup.TableCaption));

            PrecisionCode := EInvSetup."LCY Piastre Identifier";
            if CurrencyCode = '' then
                CurrencyCode := GLSetup."LCY Code";
        end else begin
            Currency.Get(CurrencyCode);
            Currency.TestField("PRG_E-Inv. Piastre Identifier");
            PrecisionCode := Currency."PRG_E-Inv. Piastre Identifier";
        end;

        if GlobalLanguage = 1033 then begin //ENU
            ReadEnglishNumber(TheNumber, NumberWord1, NumberWord2);
            if NumberWord2 <> '' then
                exit(StrSubstNo(NumberWord1 + ' ' + CurrencyCode + ' and ' + NumberWord2 + ' ' + PrecisionCode))
            else
                exit(StrSubstNo(NumberWord1 + ' ' + CurrencyCode));
        end;
        if NumberWord2 <> '0' then
            NumberWord2 := Format(100 * (1 - (Round(TheNumber, 1, '>') - TheNumber)));
        if (NumberWord1 <> '0') and (NumberWord2 <> '0') then
            exit(StrSubstNo(Text003, String, NumberLet(NumberWord1), CurrencyCode, Text002, NumberLet(NumberWord2), PrecisionCode))

        else
            if (NumberWord1 <> '0') then
                exit(StrSubstNo(Text005, String, NumberLet(NumberWord1), CurrencyCode));
    end;

    procedure NumberLet(TheNumber: Text[250]) TheNumberInLetters: Text[150]
    var
        i: Integer;
        NumberOfGroupsOfThree: Integer;
        PlaceToStart: Integer;
        TheNumberAsString: Text[30];
    begin
        TheNumberAsString := TheNumber;
        for i := 1 to StrLen(TheNumberAsString) do
            if ((CopyStr(TheNumberAsString, i, 1) < '0') or (CopyStr(TheNumberAsString, i, 1) > '9')) then
                if i = 1 then
                    TheNumberAsString := CopyStr(TheNumberAsString, 2)
                else
                    if i = StrLen(TheNumberAsString) then
                        TheNumberAsString := CopyStr(TheNumberAsString, 1, StrLen(TheNumberAsString) - 1)
                    else
                        TheNumberAsString := CopyStr(TheNumberAsString, 1, i - 1) + CopyStr(TheNumberAsString, i + 1);

        while StrLen(TheNumberAsString) mod 3 <> 0 do
            TheNumberAsString := '0' + TheNumberAsString;

        NumberOfGroupsOfThree := StrLen(TheNumberAsString) div 3;

        if NumberOfGroupsOfThree > 5 then
            TheNumberInLetters := Text001
        else begin
            TheNumberInLetters := '';
            for i := NumberOfGroupsOfThree downto 1 do begin
                PlaceToStart := StrLen(TheNumberAsString) - (i * 3) + 1;
                TheNumberInLetters := TheNumberInLetters + ThreeDigitsLet(CopyStr(TheNumberAsString, PlaceToStart, 3));
                if CopyStr(TheNumberAsString, PlaceToStart, 3) <> '000' then
                    case i of
                        1:
                            TheNumberInLetters := TheNumberInLetters + '';
                        2:
                            if TheNumberInLetters = Text1 then
                                TheNumberInLetters := Text1000
                            else
                                TheNumberInLetters := TheNumberInLetters + Text1000;
                        3:
                            TheNumberInLetters := TheNumberInLetters + Text1443;
                        4:
                            TheNumberInLetters := TheNumberInLetters + Text1443000;
                        5:
                            TheNumberInLetters := TheNumberInLetters + Text1443000000;
                    end;
            end;
        end;
    end;

    procedure ReadEnglishBelowBillion(aNumber: Integer): Text[1024]
    var
        BelowMillion: Integer;
        Millions: Integer;
        BelowMillionText: Text[1024];
    begin
        IF aNumber > 999999999 THEN
            EXIT('');

        Millions := ROUND(aNumber / 1000000, 1, '<');
        BelowMillion := aNumber - Millions * 1000000;

        IF Millions > 0 THEN BEGIN
            BelowMillionText := ReadEnglishBelowMillion(BelowMillion);
            IF BelowMillionText <> '' THEN
                EXIT(ReadEnglishBelowThousand(Millions) + ' ' + EnglishText(1000000) + ', ' + BelowMillionText)
            ELSE
                EXIT(ReadEnglishBelowThousand(Millions) + ' ' + EnglishText(1000000));
        END ELSE
            EXIT(ReadEnglishBelowMillion(BelowMillion));
    end;

    procedure ReadEnglishBelowHundred(aNumber: Integer): Text[100]
    var
        BelowTen: Integer;
        BelowTenText: Text[100];
    begin
        IF aNumber > 99 THEN
            EXIT('');

        IF aNumber < 20 THEN
            EXIT(EnglishText(aNumber))
        ELSE BEGIN
            BelowTen := aNumber - ROUND(aNumber, 10, '<');
            BelowTenText := EnglishText(BelowTen);
            IF BelowTenText <> '' THEN
                EXIT(EnglishText(ROUND(aNumber, 10, '<')) + ' ' + BelowTenText)
            ELSE
                EXIT(EnglishText(ROUND(aNumber, 10, '<')))
        END;
    end;

    procedure ReadEnglishBelowMillion(aNumber: Integer): Text[1020]
    var
        BelowThousand: Integer;
        Thousands: Integer;
        BelowThousandText: Text[1024];
    begin
        IF aNumber > 999999 THEN
            EXIT('');

        Thousands := ROUND(aNumber / 1000, 1, '<');
        BelowThousand := aNumber - Thousands * 1000;

        IF Thousands > 0 THEN BEGIN
            BelowThousandText := ReadEnglishBelowThousand(BelowThousand);
            IF BelowThousandText <> '' THEN
                EXIT(ReadEnglishBelowThousand(Thousands) + ' ' + EnglishText(1000) + ', ' + BelowThousandText)
            ELSE
                EXIT(ReadEnglishBelowThousand(Thousands) + ' ' + EnglishText(1000));
        END ELSE
            EXIT(ReadEnglishBelowThousand(BelowThousand));

    end;

    procedure ReadEnglishBelowThousand(aNumber: Integer): Text[100]
    var
        BelowHundred: Integer;
        Hundreds: Integer;
        BelowHundredText: Text[100];
    begin
        IF aNumber > 999 THEN
            EXIT('');

        Hundreds := ROUND(aNumber / 100, 1, '<');
        BelowHundred := aNumber - Hundreds * 100;

        IF Hundreds > 0 THEN BEGIN
            BelowHundredText := ReadEnglishBelowHundred(BelowHundred);
            IF BelowHundredText <> '' THEN
                EXIT(EnglishText(Hundreds) + ' ' + EnglishText(100) + ' and ' + BelowHundredText)
            ELSE
                EXIT(EnglishText(Hundreds) + ' ' + EnglishText(100));
        END ELSE
            EXIT(ReadEnglishBelowHundred(BelowHundred));

    end;

    Procedure ReadEnglishNumber(aNumber: Decimal; var aWholeNumberRead: Text[1024]; var aDecimalNumberRead: Text[1024])
    var
        DecimalBelowBillion: Decimal;
        DecimalBillions: Decimal;
        WholeNumber: Decimal;
        BelowBillion: Integer;
        Billions: Integer;
        DecimalNumber: Integer;
        BelowBillionText: Text[1024];

    begin
        IF aNumber > 999999999999.99 THEN BEGIN
            aWholeNumberRead := 'The number cannot be read';
            aDecimalNumberRead := '';
            EXIT;
        END;

        aWholeNumberRead := '';
        aDecimalNumberRead := '';

        WholeNumber := ROUND(aNumber, 1, '<');
        DecimalNumber := ROUND((aNumber - WholeNumber), 0.01, '<') * 100;

        DecimalBillions := ROUND(WholeNumber / 1000000000, 1, '<');
        Billions := DecimalBillions;
        DecimalBelowBillion := WholeNumber - DecimalBillions * 1000000000;
        BelowBillion := DecimalBelowBillion;

        IF Billions > 0 THEN BEGIN
            BelowBillionText := ReadEnglishBelowBillion(BelowBillion);
            IF BelowBillionText <> '' THEN
                aWholeNumberRead := ReadEnglishBelowThousand(Billions) + ' ' + EnglishText(1000000000) + ', ' + BelowBillionText
            ELSE
                aWholeNumberRead := ReadEnglishBelowThousand(Billions) + ' ' + EnglishText(1000000000);
        END ELSE
            aWholeNumberRead := ReadEnglishBelowBillion(BelowBillion);

        IF DecimalNumber <> 0 THEN
            aDecimalNumberRead := ReadEnglishBelowHundred(DecimalNumber);
    end;

    local procedure HundredsDigitLet(Digit: Char) TextOfDigit: Text[15]
    begin
        case Digit of
            '0':
                TextOfDigit := '';
            '1':
                TextOfDigit := Text100;
            '2' .. '9':
                TextOfDigit := UnitDigitLet(Digit) + Text100;
        end;
    end;

    local procedure TensDigitLet(Digit: Char) TextOfDigit: Text[10]
    begin
        case Digit of
            '0':
                TextOfDigit := '';
            '1':
                TextOfDigit := Text10;
            '2':
                TextOfDigit := Text20;
            '3':
                TextOfDigit := Text30;
            '4':
                TextOfDigit := Text40;
            '5':
                TextOfDigit := Text50;
            '6':
                TextOfDigit := Text60;
            '7':
                TextOfDigit := Text70;
            '8':
                TextOfDigit := Text80;
            '9':
                TextOfDigit := Text90;
        end;
    end;

    local procedure ThreeDigitsLet(ThreeDigit: Text[3]) TextOfNumber: Text[50]
    begin
        TextOfNumber := HundredsDigitLet(ThreeDigit[1]) + TensDigitLet(ThreeDigit[2]) + UnitDigitLet(ThreeDigit[3]);
    end;


    local procedure UnitDigitLet(Digit: Char) TextOfDigit: Text[10]
    begin
        case Digit of
            '0':
                TextOfDigit := '';
            '1':
                TextOfDigit := Text1;
            '2':
                TextOfDigit := Text2;
            '3':
                TextOfDigit := Text3;
            '4':
                TextOfDigit := Text4;
            '5':
                TextOfDigit := Text5;
            '6':
                TextOfDigit := Text6;
            '7':
                TextOfDigit := Text7;
            '8':
                TextOfDigit := Text8;
            '9':
                TextOfDigit := Text9;
        end;
    end;
}