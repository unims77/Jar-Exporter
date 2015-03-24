unit UnitMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, IniFiles, ShellApi, xmldom, XMLIntf, msxmldom,
  XMLDoc;

type
  TfrmMain = class(TForm)
    edtJarPath: TLabeledEdit;
    btnMake: TButton;
    edtExportPath: TLabeledEdit;
    lvJarList: TListBox;
    Label1: TLabel;
    btnLoadConfig: TButton;
    MemoTemp: TMemo;
    cbxLog: TCheckBox;
    cbxOpenDir: TCheckBox;
    btnOpenConfig: TButton;
    btnOpenFolder: TButton;
    btnOpenJarFolder: TButton;
    btnOpenExportFolder: TButton;
    Label2: TLabel;
    Label3: TLabel;
    lblClassPath: TLabel;
    XMLDocument1: TXMLDocument;
    procedure FormCreate(Sender: TObject);
    procedure btnLoadConfigClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnMakeClick(Sender: TObject);
    procedure cbxLogClick(Sender: TObject);
    procedure cbxOpenDirClick(Sender: TObject);
    procedure btnOpenConfigClick(Sender: TObject);
    procedure btnOpenFolderClick(Sender: TObject);
    procedure btnOpenExportFolderClick(Sender: TObject);
    procedure btnOpenJarFolderClick(Sender: TObject);
    procedure lvJarListDblClick(Sender: TObject);
  private
    procedure MakeJar;
  public
    List : TStringList;
    mList: TStringList;
    ClassPath : string;

    procedure MakeJarSilent;
  end;

var
  frmMain: TfrmMain;

Function SlashCon(Const s1, s2: String; NORMAL: Boolean = false): String;
Function ReadAllDirectory(Const ParentDirectory, FileFilter: String; FileList: TStrings; AllDir: Boolean = False): Integer;

implementation

{$R *.dfm}

Function ReadAllDirectory(Const ParentDirectory, FileFilter: String; FileList: TStrings; AllDir: Boolean): Integer;
Var
   BasePath                             : String;
   Ptr                                  : PChar;
   PtrFilter                            : Pchar;
   FCount                               : integer;

   Function SearchFile(Const ParentPath, FileFilter: String; FileList: TStrings): Integer;
   Var
      Status                            : Integer;
      SearchRec                         : TSearchRec;
   Begin

      Result := 0;
      Status := FindFirst(SlashCon(BasePath + ParentPath, FileFilter), faDirectory Or faHidden Or faSysFile, SearchRec);
      Try
         While Status = 0 Do
         Begin
            If (SearchRec.Name <> '.') And (SearchRec.Name <> '..') Then
               If (SearchRec.Attr And faDirectory) <> 0 Then Begin
                  If AllDir Then Begin
                     FileList.Add(SlashCon(SlashCon(ParentPath, SearchRec.Name), ''));
                     FCount := SearchFile(SlashCon(ParentPath, SearchRec.Name), FileFilter, FileList);
                     Result := Result + FCount;
                  End;
               End Else Begin
                  FileList.Add(SlashCon(ParentPath, SearchRec.Name));
                  Inc(Result);
               End;
            Status := FindNext(SearchRec);
         End;
      Finally
         FindClose(SearchRec);
      End;
   End;

Begin
   Result := 0;
   PtrFilter := PChar(FileFilter);
   While PtrFilter <> Nil Do Begin
      Ptr := StrScan(PtrFilter, ';');
      If Ptr <> Nil Then Ptr^ := #0;
      BasePath := SlashCon(ParentDirectory, '');
      Result := SearchFile('', PtrFilter, FileList);

      //unims Ãß°¡
      If Result = 0 Then Begin
         BasePath := ExtractFileName(ParentDirectory);
         FileList.Add('..\' + BasePath + '\');

      End;

      If ptr <> Nil Then Begin
         Ptr^ := ';';
         inc(ptr);
      End;
      PtrFilter := Ptr;
   End;
End;

Function SlashCon(Const s1, s2: String; NORMAL: Boolean): String;
Var
   SlashChar                            : String;
Begin
   If NORMAL Then SlashChar := '/'
   Else SLashChar := '\';
   If S1 = '' Then Begin
      Result := S2;
      Exit;
   End;
   If AnsiLastChar(S1)^ <> SLashChar Then
      Result := S1 + SLashChar + S2
   Else
      Result := S1 + S2;
End;

function FileSort(List: TStringList; Index1, Index2: Integer): Integer;
   function SlashCount(FileName : String) : Integer;
   var
      I : Integer;
   begin
      Result := 0;

      for I := 1 to Length(FileName) do
         if FileName[I] = '\' then
            Inc(Result);
   end;
begin
   Result := SlashCount(List.Strings[Index1]) - SlashCount(List.Strings[Index2]);
      if Result = 0 then
         Result := CompareStr(List.Strings[Index1], List.Strings[Index2]);
end;

function ExecAndWait(AProgram : string) : boolean;
var
  StartupInfo : TStartupInfo;
  ProcessInfo : TProcessInformation;
begin
  FillChar (StartupInfo, SizeOf(StartupInfo), 0);
  StartupInfo.cb := SizeOf(StartupInfo);
  Result := CreateProcess (
    nil,
    PChar(AProgram),
    nil,
    nil,
    FALSE,
    0,
    nil,
    nil,
    StartupInfo,
    ProcessInfo);
  if Result then begin
    WaitForSingleObject(ProcessInfo.hProcess, INFINITE);
    CloseHandle(ProcessInfo.hProcess);
    CloseHandle(ProcessInfo.hThread);
  end;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
   List := TStringList.Create;
   mList := TStringList.Create;
   btnLoadConfigClick(nil);
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
   List.Free;
   mList.Free;
end;

//Make Jar
procedure TfrmMain.btnMakeClick(Sender: TObject);
begin
   mList.Clear;
   mList.Assign(List);
   MakeJar;
end;

//Make Selected Jar
procedure TfrmMain.lvJarListDblClick(Sender: TObject);
begin
   if lvJarList.ItemIndex < 0 then
      Exit;

   mList.Clear;
   mList.Add(lvJarList.Items.Strings[lvJarList.ItemIndex]);
   MakeJar;
end;

//Make Jar - Silent Mode
procedure TfrmMain.MakeJarSilent;
begin
   Application.ShowMainForm := False;
   cbxLog.Checked           := False;
   cbxOpenDir.Checked       := False;
   MakeJar;
end;

procedure TfrmMain.MakeJar;
var
   I, J       : Integer;
   ExportPath : string;
   TempPath   : string;
   fileList   : TStringList;
   TmpStr     : string;
   Command    : string;
   Direction  : string;
   LogFile    : string;
begin
   if mList.Count = 0 then
   begin
      MessageDlg('"Export List" is empty...', mtWarning, [mbOk], 0);
      Exit;
   end;

   Direction  := '>>';
   MemoTemp.Clear;
   MemoTemp.Lines.Add(ExtractFileDrive(Application.ExeName));  
   MemoTemp.Lines.Add('cd "' + ExtractFilePath(Application.ExeName) + ClassPath + '"');

   LogFile    := '"' + ExtractFilePath(Application.ExeName) + '_JarUtil.log"';
   TempPath   := SlashCon(edtExportPath.Text, 'Temp');
   ExportPath := edtExportPath.Text;
   try
      if Not DirectoryExists(TempPath) then
         ForceDirectories(TempPath);
      if Not DirectoryExists(ExportPath) then
         ForceDirectories(ExportPath);

      fileList := TStringList.Create;
      try
         for I := 0 to mList.Count - 1 do
         begin
            fileList.Clear;

            if CompareText(Trim(mList.ValueFromIndex[I]), 'WebContent') = 0 then
               ReadAllDirectory(ExtractFilePath(Application.ExeName) + Trim(mList.ValueFromIndex[I]),
                   '*.*', fileList, True)
            else
               ReadAllDirectory(ExtractFilePath(Application.ExeName) + classPath + '\' + Trim(mList.ValueFromIndex[I]),
                   '*.*', fileList, True);

            //Delete Svn File
            for J := fileList.Count -1 downto 0 do
            begin
               fileList.Strings[J] := SlashCon(Trim(mList.ValueFromIndex[I]), fileList.Strings[J]);

               {
               if Pos('.svn', fileList.Strings[J]) > 0 then
                  fileList.Delete(J)
               else if fileList.Strings[J][Length(fileList.Strings[J])] <> '\' then
                  fileList.Delete(J)
               else
                  fileList.Strings[J] := SlashCon(fileList.Strings[J], '*.class');
               }
               if Pos('.svn', fileList.Strings[J]) > 0 then
                  fileList.Delete(J)
               else if Pos('.java', fileList.Strings[J]) > 0 then
                  fileList.Delete(J)
               else if fileList.Strings[J][Length(fileList.Strings[J])] = '\' then
                  fileList.Delete(J);
            end;

            {
            for J := fileList.Count -1 downto 0 do
            begin
               fileList.Strings[J] := '"' + ExtractFilePath(Application.ExeName) + fileList.Strings[J] + '"';
            end;
            }

            fileList.CustomSort(@FileSort);
            fileList.SaveToFile(SlashCon(TempPath,  Trim(mList.ValueFromIndex[I] + '.list')));

            TmpStr := '';
            for J := 0 to fileList.Count -1 do
               TmpStr := TmpStr + ' "' + fileList.Strings[j] + '"';


            Command := '"' + edtJarPath.Text + '" cvf "' + SlashCon(ExportPath, Trim(mList.Names[I])) + '" @"' +
               SlashCon(TempPath,  Trim(mList.ValueFromIndex[I] + '.list" ' + Direction + ' ' + LogFile ));
            MemoTemp.Lines.Add('@echo >> ' + LogFile);
            MemoTemp.Lines.Add('@echo ========================================================================================== >> ' + LogFile);
            MemoTemp.Lines.Add('@echo ' + SlashCon(ExportPath, Trim(mList.Names[I])) +' >> ' + LogFile);
            MemoTemp.Lines.Add('@echo ========================================================================================== >> ' + LogFile);
            MemoTemp.Lines.Add(Command);
         end;

         MemoTemp.Lines.Add('@echo ========================================================================================== >> ' + LogFile);         
         MemoTemp.Lines.SaveToFile(ChangeFileExt(Application.ExeName, 'MakeJar.bat'));

         if FileExists(ExtractFilePath(Application.ExeName) + '_JarUtil.log') then
            DeleteFile(ExtractFilePath(Application.ExeName) + '_JarUtil.log');

         ExecAndWait('"' + ExtractFilePath(Application.ExeName) + '_JarUtilMakeJar.bat"');

         if cbxLog.Checked then
            ShellExecute(handle, 'open', PChar(LogFile), '', nil, SW_NORMAL);

         if cbxOpenDir.Checked then
            ShellExecute(handle, 'open', PChar(ExportPath), '', nil, SW_NORMAL);

      finally
         fileList.Free;
      end;
   except
   //
   end;
end;

//Load Config
procedure TfrmMain.btnLoadConfigClick(Sender: TObject);
var
   Ini  : TIniFile;
   JavaPath : string;

   LNodeElement, LNode: IXMLNode;
begin
   ini := TIniFile.Create(ChangeFileExt(Application.ExeName, '.ini'));
   try
      edtJarPath.Text := ini.ReadString('Config', 'JarExe Path', 'jar.exe');
      if not FileExists(edtJarPath.Text) then
      begin
         JavaPath := GetEnvironmentVariable('JAVA_HOME') + '\bin\jar.exe';
         if FileExists(JavaPath) then
            edtJarPath.Text := JavaPath;
      end;
      
      if Trim(edtJarPath.Text) = '' then
         edtJarPath.Text := 'jar.exe';
      edtExportPath.Text := ini.ReadString('Config', 'Export Path', ExtractFilePath(Application.ExeName) + 'JarExport');
      if Trim(edtExportPath.Text) = '' then
         edtExportPath.Text := ExtractFilePath(Application.ExeName) + 'JarExport';
      cbxLog.Checked :=  ini.ReadBool('Config', 'View Log', True);
      cbxOpenDir.Checked :=  ini.ReadBool('Config', 'View Folder', True);

      List.Clear;
      Ini.ReadSectionValues('ExportConfig', List);
      lvJarList.Items.Clear;
      lvJarList.Items.Assign(List);

      //find class target path...
      ClassPath := 'bin';
      if FileExists('.classpath') then
      begin
         XMLDocument1.LoadFromFile('.classpath');
         LNodeElement := XMLDocument1.ChildNodes.FindNode('classpath');
         if LNodeElement <> nil then
         begin
            LNodeElement := LNodeElement.ChildNodes.FindNode('classpathentry');
            while (LNodeElement <> nil) do
            begin
                if LNodeElement.Attributes['kind'] = 'output' then
                begin
                  ClassPath := LNodeElement.Attributes['path'];
                end;
                LNodeElement := LNodeElement.NextSibling;
            end;
         end;
      end;
      lblClassPath.Caption := StringReplace(ClassPath, '/', '\', [rfReplaceAll]);
   finally
      Ini.Free;
   end;
end;

//Open Config
procedure TfrmMain.btnOpenConfigClick(Sender: TObject);
begin
   ShellExecute(handle, 'open', PChar(ChangeFileExt(Application.ExeName, '.ini')), '', nil, SW_NORMAL);
end;

//Open Folder
procedure TfrmMain.btnOpenFolderClick(Sender: TObject);
begin
   ShellExecute(handle, 'open', PChar(ExtractFilePath(Application.ExeName)), '', nil, SW_NORMAL);
end;

//Open Jar Folder
procedure TfrmMain.btnOpenJarFolderClick(Sender: TObject);
begin
   ShellExecute(handle, 'open', PChar(ExtractFilePath(edtJarPath.Text)), '', nil, SW_NORMAL);
end;

//Open Export Folder
procedure TfrmMain.btnOpenExportFolderClick(Sender: TObject);
begin
   ShellExecute(handle, 'open', PChar(edtExportPath.Text), '', nil, SW_NORMAL);
end;

procedure TfrmMain.cbxLogClick(Sender: TObject);
var
   Ini  : TIniFile;
begin
   ini := TIniFile.Create(ChangeFileExt(Application.ExeName, '.ini'));
   try
      ini.WriteBool('Config', 'View Log', cbxLog.Checked);
   finally
      Ini.Free;
   end;
end;

procedure TfrmMain.cbxOpenDirClick(Sender: TObject);
var
   Ini  : TIniFile;
begin
   ini := TIniFile.Create(ChangeFileExt(Application.ExeName, '.ini'));
   try
      ini.WriteBool('Config', 'View Folder', cbxOpenDir.Checked);
   finally
      Ini.Free;
   end;
end;

end.
