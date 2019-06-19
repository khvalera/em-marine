unit images_list;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, LazFileUtils, LazUTF8;

var ImageStrList_menu, ImageStrList_tray: TStringList;
    ImageList_menu, ImageList_tray: TImageList;

function LoadBitmapFromFile(ImageFile: string): TCustomBitmap;
procedure AddAllFileImageList(var ImageListCurrent: TImageList; var StrList: TStringList; Dir: String; Width: Word = 16; Height: Word = 16);
procedure AddFileImageList(var ImageList: TImageList; var StrList: TStringList; StrFile, Dir: string);
function ReturnIndexImageList(StrList: TStringList; NameFile: String): integer;

implementation


//========================================================
function ReturnIndexImageList(StrList: TStringList; NameFile: String): integer;
var Index : Integer;
begin
  Index:= StrList.IndexOf(NameFile);
  Result := Index
end;

//===========================================
procedure AddAllFileImageList(var ImageListCurrent: TImageList; var StrList: TStringList; Dir: String; Width: Word = 16; Height: Word = 16);
var
    SearchFile: TSearchRec;
begin
   StrList := TStringList.Create;
   ImageListCurrent := TImageList.Create(Nil);
   ImageListCurrent.Width  := Width;
   ImageListCurrent.Height := Height;
   if FindFirstUTF8(IncludeTrailingPathDelimiter(Dir) + '*.png',
                   faAnyFile, SearchFile) = 0 then
   repeat
     if (SearchFile.Attr and faDirectory) = 0 then
        begin
          AddFileImageList(ImageListCurrent, StrList, SearchFile.Name, Dir);
        end;
   until FindNextUTF8(SearchFile) <> 0;
   FindCloseUTF8(SearchFile);
end;

//===========================================
function ReturnDirectoryPoints(Dir: String): String;
var i : Integer;
    LastDir: String;
begin
 if Copy(Dir, Length(Dir)-1, Length(Dir)) <> '..' then
   begin
    Result := Dir;
    Exit;
   end;
 Delete(Dir, Length(Dir)-2, Length(Dir));
 LastDir:= Dir;
 for i:= 0 to Length(Dir) do
 begin
   if Length(Copy(LastDir, pos(DirectorySeparator, LastDir) + 1, Length(LastDir))) = 0 Then
       Break;
   begin
     LastDir := Copy(LastDir, pos(DirectorySeparator, LastDir) + 1, Length(LastDir));
   end;
 end;
 Result:= Copy(Dir, 1, Length(Dir)- Length(LastDir));
end;

//===========================================
function ReturnFullPath(Dir: String; FileName: String):String;
begin
 if Dir  = '' then
    Result:= DirectorySeparator + FileName;
 Dir:= ReturnDirectoryPoints(Dir);
 if Copy(Dir, Length(Dir), Length(Dir)) <> DirectorySeparator then
    Result:= Dir + DirectorySeparator + FileName
 else
    Result:= Dir + FileName;
end;

//========================================================
function LoadBitmapFromFile(ImageFile: string): TCustomBitmap;
var
  Stream: TStream;
  GraphicClass: TGraphicClass;
begin
  Result := nil;
  Stream := nil;
 if FileExistsUTF8(ImageFile) = False then
    Exit;
  try
    Stream := TFileStream.Create(UTF8ToSys(ImageFile), fmOpenRead or fmShareDenyNone);
    GraphicClass := GetGraphicClassForFileExtension(ExtractFileExt(ImageFile));
    if (GraphicClass <> nil) and (GraphicClass.InheritsFrom(TCustomBitmap)) then
    begin
      Result := TCustomBitmap(GraphicClass.Create);
      Result.LoadFromStream(Stream);
    end;
  finally
    Stream.Free;
  end;
end;

//========================================================
procedure AddFileImageList(var ImageList: TImageList; var StrList: TStringList; StrFile, Dir: string);
var
  Png: TCustomBitmap;
begin
  if FileExistsUTF8(ReturnFullPath(Dir, StrFile)) = False then
    Exit;
  Png := LoadBitmapFromFile(ReturnFullPath(Dir, StrFile));
  if Png <> nil then
  begin
    ImageList.Add(Png, nil);
    StrList.Add(StrFile);
  end;
  Png.Free;
end;

end.

