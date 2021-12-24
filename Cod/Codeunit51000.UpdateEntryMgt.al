codeunit 51000 "Update Entry Mgt."
{
    trigger OnRun()
    begin

    end;

    var
        myInt: Integer;

    procedure TelUpdateBinContent()
    var
        BinContent: Record "Bin Content";
        BinConMod: Record "Bin Content";
        LotNo: Code[50];
    begin
        BinContent.SetCurrentKey("Lot No.");
        BinContent.SetFilter("Lot No.", '%1', '');
        if BinContent.FindSet(true, false) then
            repeat
                BinContent.CalcFields("Quantity (Base)");
                if BinContent."Quantity (Base)" <> 0 then
                    if BinConMod.Get(BinContent."Location Code", BinContent."Bin Code", BinContent."Item No.",
                            BinContent."Variant Code", BinContent."Unit of Measure Code") then begin
                        LotNo := GetLotNoFromWhseEntry(BinContent."Location Code", BinContent."Bin Code",
                                BinContent."Item No.", BinContent."Variant Code", BinContent."Unit of Measure Code");
                        if LotNo <> '' then begin
                            BinConMod.Validate("Lot No.", LotNo);
                            BinConMod.Modify();
                        end;
                    end;
            until BinContent.Next() = 0;
    end;

    local procedure GetLotNoFromWhseEntry(Location: Code[10]; BinCode: Code[20]; Item: Code[20]; VariantCode: Code[10]; UoMCode: Code[10]): Code[50];
    var
        WhseEntry: Record "Warehouse Entry";
    begin
        WhseEntry.SetCurrentKey("Entry No.", "Location Code", "Bin Code", "Item No.", "Variant Code", "Unit of Measure Code");
        WhseEntry.SetRange("Location Code", Location);
        WhseEntry.SetRange("Bin Code", BinCode);
        WhseEntry.SetRange("Item No.", Item);
        WhseEntry.SetRange("Variant Code", VariantCode);
        WhseEntry.SetRange("Unit of Measure Code", UoMCode);
        if WhseEntry.FindLast() then
            exit(WhseEntry."Lot No.");
        exit('');
    end;

    procedure TelClearLotNoIfBinContenpEmpty()
    var
        BinContent: Record "Bin Content";
        BinConMod: Record "Bin Content";
    begin
        BinContent.SetCurrentKey("Lot No.");
        BinContent.SetFilter("Lot No.", '<>%1', '');
        if BinContent.FindSet() then
            repeat
                BinContent.CalcFields("Quantity (Base)");
                if BinContent."Quantity (Base)" = 0 then
                    if BinConMod.Get(BinContent."Location Code", BinContent."Bin Code", BinContent."Item No.",
                            BinContent."Variant Code", BinContent."Unit of Measure Code") then begin
                        BinConMod.Validate("Lot No.", '');
                        BinConMod.Modify();
                    end;
            until BinContent.Next() = 0;
    end;
}