unit U_Saisie;

{$mode objfpc}{$H+}

interface

uses
  Windows,         // To handle the keys
  MMSystem,        // For the sounds
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls;        // For the timer

type

  { TForm1 }

  TForm1 = class(TForm)
    LabelSaisie: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Timer1: TTimer;
    Bevel1: TBevel;
    Label4: TLabel;
    Label5: TLabel;
    ImageSaisie: TImage;
    Label6: TLabel;
    Label7: TLabel;
    ImageDescription: TImage;
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure Timer1Timer(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
    procedure LoadFont(FontName : string);
    procedure SetPos(X, Y : Integer);
    procedure DrawCar(b: TCanvas; WhatCar : char; Couleur : TColor; Shadow : Boolean);
    procedure DrawText(b: Tcanvas; WhatText : String; X1, Y1 : Integer; Couleur : TColor; Shadow : Boolean);
    procedure VerifyCmd(s: string);
  end;

type
  Tcar = record
    TheCar : char;                     // le caractère
    ch : array [1..20,1..20] of byte;  // Maximum pour un car = 20x20 pixels
  end;

var
  Form1: TForm1;
  command : string;
  i,nbcar : integer;
  Tab_Alpha : array[0..96] of Tcar;  // Table des caractères (97 max)
  b : file;
  entete : array[0..15] of byte;
  FNTNBLigne, FNTNBColonne : integer;
  nbcarFont : integer;
  vide : array[0..12] of byte;
  pix : byte;
  PosX, PosY, OldPosX, OldPosY : Integer;
  Shadow, Inverse : Boolean;
  LargText : integer;

var Descr : string =
  ('YOU ARE STANDING AT THE SOUTH END OF'+#13+
   'SHERWOOD FOREST. WELL-CUT PATHS LEAD'+#13+
   'NORTH, EAST AND WEST.');

const
   entetefile : array[0..15] of byte =
           ($46,$54,$42,$02,$00,$A9,$32,$30,$30,$34,$20,$4E,$59,$43,$44,$00);

implementation

{$IFnDEF FPC}
  {$R *.dfm}
{$ELSE}
  {$R *.lfm}
{$ENDIF}

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

Procedure TForm1.SetPos(X, Y : Integer);
begin
  PosX := X*FNTNBColonne;     // Soit Colonne (0 à 79 ou moins ou plus)
  PosY := Y*FNTNBLigne;      // Soit Ligne   (0 à 23 pareil)
end;

Procedure TForm1.DrawCar(b : TCanvas; WhatCar : char; Couleur : TColor; Shadow : Boolean);
Var
  i,j,k,oldx : Integer;
Begin
asm
        NOP     // $51058654  //$51057A54
        NOP
        NOP
        NOP
        NOP
        NOP
end;
  for k := 1 to NbCarFont do
  if Tab_Alpha[k].TheCar = WhatCar then
    begin
    OldPosY := PosY;
    for i := 1 to FNTNBLigne do
      begin
        OldX := PosX;
        for j := 1 to FNTNBColonne do
          begin
            if Inverse then
              begin
                if (Tab_Alpha[k].ch[i,j]=0) then b.Pixels[PosX,PosY] := clWhite;
              end
            else
              begin
                if (Shadow) then
                  if Tab_Alpha[k].ch[i,j] = 1 then b.Pixels[PosX+1,PosY+1] := clBlack;
                if Tab_Alpha[k].ch[i,j] = 1 then b.Pixels[PosX,PosY] := couleur;
              end;
            inc(PosX);
          end;
          inc(PosY);
          PosX := OldX;
        end;
      PosY := OldPosY;
    end;
inc(PosX,FNTNBColonne);
end;

Procedure TForm1.DrawText(b: TCanvas; WhatText : String; X1, Y1 : Integer; Couleur : TColor; Shadow : Boolean);
var
  long : integer;
begin
PosX := (X1*FNTNBColonne)-FNTNBColonne;
PosY := Y1*FNTNBLigne;
for long := 0 to length(WhatText) do
  Begin
    if WhatText[long] = #13 then
      begin
        Inc(Y1);
        SetPos(X1,Y1);
      end
    else DrawCar(b,WhatText[long],couleur,Shadow);
  end;
end;

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

procedure TForm1.LoadFont(FontName : string);
var
  i, j, k : integer;
  cc : char;
begin
  // on charge la fonte de caractères (si elle existe)
  if FileExists(FontName+'.fth') then
    begin
      assignfile(b,FontName+'.fth');
      reset(b,1);
      blockread(b,entete,16);
      for i:=0 to 15 do
      if entete[i] <> entetefile[i] then
      begin
        if MessageDlg('La fonte de caractères "'+FontName+'.fth'+
           '" ne correspond pas à l''entête !!!'+#13#10+
           'Vous n''utilisez pas une fonte générée par FontMaker ][, ou celle-ci est'+#13#10+
           'défectueuse.'+#13#10+'Modifiez la fonte ou vérifiez votre programme.',
           mtError, [mbOk], 0) = mrOk then
          application.Terminate;
      end;
      blockread(b,FNTNBLigne,1);
      blockread(b,FNTNBColonne,1);
      blockread(b,nbcarFont,1);
      blockread(b,vide,13);

      // 1er car = espace
      for i := 1 to FNTNBLigne do
        for j := 1 to FNTNBColonne do
          Tab_Alpha[0].ch[i,j] := 0;
          Tab_Alpha[0].TheCar := ' ';

      for k := 1 to nbcarFont-1 do              // on commence à 1 car
        begin                                   // pas le car. espace
          blockread(b,cc,1);
          Tab_Alpha[k].TheCar := cc;
          for i := 1 to FNTNBLigne do
            for j := 1 to FNTNBColonne do
              begin
                blockread(b,pix,1);
                if pix = $D7 then Tab_Alpha[k].ch[i,j] := 1
                             else Tab_Alpha[k].ch[i,j] := 0;
              end;
        end;
      closefile(b);
      setpos(0,0);
    end
  else
    if MessageDlg('Le fichier "'+FontName+'.fth" n''existe pas !!!'+#13#10+
       'Modifiez votre programme pour ouvrir la bonne fonte.',
        mtError, [mbOk], 0) = mrOk then
        application.Terminate;
end;

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

procedure TForm1.Timer1Timer(Sender: TObject);
begin
Application.ProcessMessages; // on arrete pas le système pendant le timer
  case i of
    0 : begin
          LabelSaisie.Caption := Command+'_';
          i := 1;
        end;
    1 : begin
          LabelSaisie.Caption := Command+' ';
          i := 0;
        end;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  DoubleBuffered := true;
  i := 0;
  LargText := 39;  // Nb car maxi a taper
  nbcar := 0;
  command := '';
  LabelSaisie.Caption := '';
  Label3.Caption := '';
  KeyPreview := True; // obligatoire sinon on ne peut intervenir sur les touches
  Timer1.Interval := 125; // 1/8ème de sec.
  LoadFont('appleIIg'); //Sherwood;
  ImageSaisie.Width := (LargText+1) * FNTNBColonne;
  ImageDescription.Width := ImageSaisie.Width;
  ImageSaisie.Height := FNTNBLigne;
  ImageDescription.Height := 3 * ImageSaisie.Height; // + 3;
  ImageSaisie.Top := ImageDescription.Top + ImageDescription.Height;

  Label7.Caption := 'L:'+IntToStr(FNTNBLigne)+' '+
                    'C:'+IntToStr(FNTNBColonne)+' '+
                    'Nb:'+IntToStr(NBCarFont)+' '+
                    'Img:'+IntToStr(ImageSaisie.Width);

  ImageSaisie.Canvas.Brush.Style := bsSolid;
  ImageSaisie.Canvas.Brush.color := clBlack;
  ImageSaisie.Canvas.FillRect(rect(0,0,ImageSaisie.Width,ImageSaisie.Height));
  ImageDescription.Canvas.Brush.color := clBlack;
  ImageDescription.Canvas.FillRect(rect(0,0,ImageDescription.Width,ImageDescription.Height));
  DrawText(ImageDescription.Canvas,Descr,0,0,clWhite,false);
  DrawText(ImageSaisie.Canvas,'>'+chr(127),0,0,clWhite,true);
end;

procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if key = VK_ESCAPE then Application.terminate;
  if key = VK_BACK then //Touche BackDel
    if nbcar > 0 then
      begin
        delete(command,nbcar,1);
        dec(nbcar);
        ImageSaisie.Canvas.FillRect(rect(0,0,ImageSaisie.Width,ImageSaisie.Height));
        DrawText(ImageSaisie.Canvas,'>'+command+chr(127),0,0,clWhite,false);
      end;
  if key = VK_RETURN then
    begin
      VerifyCmd(command);
      label3.caption := Command;
      Command := '';
      nbcar := 0;
      ImageSaisie.Canvas.FillRect(rect(0,0,ImageSaisie.Width,ImageSaisie.Height));
      DrawText(ImageSaisie.Canvas,'>'+command+chr(127),0,0,clWhite,false);
    end;
  if key in [VK_SPACE,$41..$5A] then  // on ne peut taper que espace ou lettres
    begin                             // En majuscule automatiquement
      if nbcar < LargText-1 then
        begin
          command := command + chr(Key);
          inc(nbcar);
          LabelSaisie.Caption := command;
          ImageSaisie.Canvas.FillRect(rect(0,0,ImageSaisie.Width,ImageSaisie.Height));
          DrawText(ImageSaisie.Canvas,'>'+command+chr(127),0,0,clWhite,false);
        end
      else sndPlaySound('SH_Couic.WAV', SND_ASYNC or SND_FILENAME);
    end;

end;

procedure TForm1.VerifyCmd(s: string);
begin
  if s = 'QUIT' then Application.terminate;
  if s = 'FUCK' then
      Descr := 'TSK, TSK, TSK, NAUGHTY BOY OR GIRL !!!';

  ImageDescription.Canvas.FillRect(ImageDescription.Canvas.ClipRect);
  DrawText(ImageDescription.Canvas,Descr,0,0,clWhite,false);
end;

end.
