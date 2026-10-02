unit UnitMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ComCtrls, IniFiles, ShellApi, Types, IOUtils,
  xmldom, XMLIntf, msxmldom, XMLDoc;

type
  TfrmMain = class(TForm)
    edtJarPath: TLabeledEdit;
    btnMake: TButton;
    edtExportPath: TLabeledEdit;
    lvJarList: TListBox;
    Label1: TLabel;
    btnLoadConfig: TButton;
    cbxOpenDir: TCheckBox;
    btnOpenConfig: TButton;
    btnOpenFolder: TButton;
    btnOpenJarFolder: TButton;
    btnOpenExportFolder: TButton;
    Label2: TLabel;
    Label3: TLabel;
    lblClassPath: TLabel;
    XMLDocument1: TXMLDocument;
    Label4: TLabel;
    lblStatus: TLabel;
    pbProgress: TProgressBar;
    memoLog: TMemo;
    cbxBuild: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure btnLoadConfigClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnMakeClick(Sender: TObject);
    procedure cbxOpenDirClick(Sender: TObject);
    procedure btnOpenConfigClick(Sender: TObject);
    procedure btnOpenFolderClick(Sender: TObject);
    procedure btnOpenExportFolderClick(Sender: TObject);
    procedure btnOpenJarFolderClick(Sender: TObject);
    procedure lvJarListDblClick(Sender: TObject);
    procedure cbxBuildClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
    FRunning    : Boolean;
    FSilent     : Boolean;
    FSrcEncoding: string;
    FSrcLevel   : string;
    FDebugOpt   : string;

    function  BaseDir: string;
    procedure Log(const Msg: string);
    procedure SetStatus(const Msg: string);
    procedure SetRunning(Value: Boolean);
    procedure WriteConfigBool(const Key: string; Value: Boolean);
    procedure ReadEclipsePrefs;
    procedure UpdateClassPathLabel;
    procedure ShowFailDialog;
    procedure UpdateJarPathColor;
    function  RunProcess(const CmdLine, WorkDir: string; out ExitCode: DWORD): Boolean;
    function  CompileSources(const ClassesDir: string): Boolean;
    function  ArchiveJars(const ClassesDir, ExportPath: string): Boolean;
    function  MakeJar: Boolean;
  public
    List      : TStringList;
    mList     : TStringList;
    ClassPath : string;
    SrcPaths  : TStringList;
    LibPaths  : TStringList;

    function MakeJarSilent: Boolean;
  end;

var
  frmMain: TfrmMain;

Function SlashCon(Const s1, s2: String; NORMAL: Boolean = false): String;

implementation

{$R *.dfm}

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

// javac(JDK8) 는 UTF-8 BOM 을 컴파일 오류로 처리한다 (Eclipse 는 허용)
function HasUtf8Bom(const FileName: string): Boolean;
var
   FS : TFileStream;
   B  : array[0..2] of Byte;
begin
   Result := False;
   FS := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
   try
      if FS.Read(B, 3) = 3 then
         Result := (B[0] = $EF) and (B[1] = $BB) and (B[2] = $BF);
   finally
      FS.Free;
   end;
end;

function ToProjectPath(const Path: string): string;
begin
   Result := StringReplace(Path, '/', '\', [rfReplaceAll]);
end;

// <JDK>\bin\jar.exe 기준으로 <JDK>\release 의 JAVA_VERSION 을 읽는다 (알 수 없으면 '')
function JdkVersionOf(const JarPath: string): string;
var
   L : TStringList;
   F : string;
begin
   Result := '';
   if ExtractFilePath(JarPath) = '' then
      Exit;
   F := ExtractFilePath(ExcludeTrailingPathDelimiter(ExtractFilePath(JarPath))) + 'release';
   if not FileExists(F) then
      Exit;
   L := TStringList.Create;
   try
      L.LoadFromFile(F);
      Result := StringReplace(Trim(L.Values['JAVA_VERSION']), '"', '', [rfReplaceAll]);
   finally
      L.Free;
   end;
end;

// 서버 소스는 JDK 8 전용 API(sun.misc.BASE64* 등)를 써서 JDK 8 로만 컴파일된다
function IsJdk8(const Version: string): Boolean;
begin
   Result := Pos('1.8', Version) = 1;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
   List     := TStringList.Create;
   mList    := TStringList.Create;
   SrcPaths := TStringList.Create;
   LibPaths := TStringList.Create;
   memoLog.Clear;
   lblStatus.Caption := '대기';
   btnLoadConfigClick(nil);
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
   List.Free;
   mList.Free;
   SrcPaths.Free;
   LibPaths.Free;
end;

procedure TfrmMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
   CanClose := not FRunning;
end;

function TfrmMain.BaseDir: string;
begin
   Result := ExtractFilePath(Application.ExeName);
end;

procedure TfrmMain.Log(const Msg: string);
begin
   memoLog.Lines.Add(Msg);
   Application.ProcessMessages;
end;

procedure TfrmMain.SetStatus(const Msg: string);
begin
   lblStatus.Caption := Msg;
   Application.ProcessMessages;
end;

procedure TfrmMain.SetRunning(Value: Boolean);
begin
   FRunning := Value;
   btnMake.Enabled       := not Value;
   btnLoadConfig.Enabled := not Value;
   lvJarList.Enabled     := not Value;
   cbxBuild.Enabled      := not Value;
   if Value then
      Screen.Cursor := crAppStart
   else
      Screen.Cursor := crDefault;
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

//Make Jar - Silent Mode (전체 jar, 실패 시 False)
function TfrmMain.MakeJarSilent: Boolean;
begin
   Application.ShowMainForm := False;
   FSilent := True;
   mList.Assign(List);
   Result := MakeJar;
end;

// 자식 프로세스의 stdout/stderr 를 파이프로 받아 화면 로그에 실시간 출력
function TfrmMain.RunProcess(const CmdLine, WorkDir: string; out ExitCode: DWORD): Boolean;
var
   SA          : TSecurityAttributes;
   hRead       : THandle;
   hWrite      : THandle;
   SI          : TStartupInfo;
   PI          : TProcessInformation;
   Cmd         : string;
   Buf         : array[0..4095] of AnsiChar;
   Avail       : DWORD;
   ReadCount   : DWORD;
   Chunk       : AnsiString;
   Pending     : AnsiString;
   Done        : Boolean;

   procedure FlushLines(Final: Boolean);
   var
      I : Integer;
   begin
      I := 1;
      while I <= Length(Pending) do
      begin
         if Pending[I] = #10 then
         begin
            Log(TrimRight(string(Copy(Pending, 1, I - 1))));
            Delete(Pending, 1, I);
            I := 1;
         end else
            Inc(I);
      end;
      if Final and (Pending <> '') then
      begin
         Log(TrimRight(string(Pending)));
         Pending := '';
      end;
   end;

begin
   Result   := False;
   ExitCode := DWORD(-1);
   Pending  := '';

   FillChar(SA, SizeOf(SA), 0);
   SA.nLength        := SizeOf(SA);
   SA.bInheritHandle := True;
   if not CreatePipe(hRead, hWrite, @SA, 0) then
   begin
      Log('[오류] 파이프 생성 실패: ' + SysErrorMessage(GetLastError));
      Exit;
   end;
   try
      SetHandleInformation(hRead, HANDLE_FLAG_INHERIT, 0);

      FillChar(SI, SizeOf(SI), 0);
      SI.cb          := SizeOf(SI);
      SI.dwFlags     := STARTF_USESTDHANDLES or STARTF_USESHOWWINDOW;
      SI.wShowWindow := SW_HIDE;
      SI.hStdInput   := GetStdHandle(STD_INPUT_HANDLE);
      SI.hStdOutput  := hWrite;
      SI.hStdError   := hWrite;

      Cmd := CmdLine;
      UniqueString(Cmd);
      if not CreateProcess(nil, PChar(Cmd), nil, nil, True, CREATE_NO_WINDOW, nil,
                           PChar(WorkDir), SI, PI) then
      begin
         Log('[오류] 실행 실패: ' + SysErrorMessage(GetLastError) + ' : ' + CmdLine);
         CloseHandle(hWrite);
         Exit;
      end;
      // 자식만 쓰기 핸들을 갖도록 닫는다
      CloseHandle(hWrite);
      try
         repeat
            Done := WaitForSingleObject(PI.hProcess, 30) = WAIT_OBJECT_0;
            while PeekNamedPipe(hRead, nil, 0, nil, @Avail, nil) and (Avail > 0) do
            begin
               if Avail > SizeOf(Buf) then
                  Avail := SizeOf(Buf);
               if (not ReadFile(hRead, Buf, Avail, ReadCount, nil)) or (ReadCount = 0) then
                  Break;
               SetString(Chunk, PAnsiChar(@Buf[0]), ReadCount);
               Pending := Pending + Chunk;
               FlushLines(False);
            end;
            Application.ProcessMessages;
         until Done;
         FlushLines(True);
         GetExitCodeProcess(PI.hProcess, ExitCode);
         Result := True;
      finally
         CloseHandle(PI.hProcess);
         CloseHandle(PI.hThread);
      end;
   finally
      CloseHandle(hRead);
   end;
end;

// .classpath 의 src 폴더 전체를 build\classes 에 새로 컴파일 (Eclipse bin\ 은 건드리지 않음)
function TfrmMain.CompileSources(const ClassesDir: string): Boolean;
var
   BuildDir  : string;
   Root      : string;
   F         : string;
   Rel       : string;
   Dest      : string;
   Javac     : string;
   Cmd       : string;
   Files     : TStringDynArray;
   Sources   : TStringList;
   BomFiles  : TStringList;
   I         : Integer;
   ResCount  : Integer;
   Code      : DWORD;
   CheckBom  : Boolean;
   Ver       : string;
begin
   Result   := False;
   BuildDir := BaseDir + 'build';
   Javac    := ExtractFilePath(edtJarPath.Text) + 'javac.exe';
   CheckBom := SameText(FSrcEncoding, 'UTF-8');

   // 1. 소스 수집
   SetStatus('[1/3] 소스 수집 중...');
   Log('[1/3] 소스 수집');
   if TDirectory.Exists(BuildDir) then
      TDirectory.Delete(BuildDir, True);
   ForceDirectories(ClassesDir);

   Sources  := TStringList.Create;
   BomFiles := TStringList.Create;
   try
      ResCount := 0;
      for I := 0 to SrcPaths.Count - 1 do
      begin
         Root := IncludeTrailingPathDelimiter(BaseDir + ToProjectPath(SrcPaths[I]));
         if not DirectoryExists(Root) then
         begin
            Log('  [경고] 소스 폴더 없음: ' + Root);
            Continue;
         end;

         Files := TDirectory.GetFiles(Root, '*', TSearchOption.soAllDirectories);
         for F in Files do
         begin
            if Pos('\.svn\', F) > 0 then
               Continue;
            if SameText(ExtractFileExt(F), '.java') then
            begin
               Rel := Copy(F, Length(BaseDir) + 1, MaxInt);
               if CheckBom and HasUtf8Bom(F) then
                  BomFiles.Add(Rel);
               Sources.Add(StringReplace(Rel, '\', '/', [rfReplaceAll]));
            end else
            begin
               // .java 외 리소스는 Eclipse 처럼 출력 폴더로 복사
               Dest := IncludeTrailingPathDelimiter(ClassesDir) + Copy(F, Length(Root) + 1, MaxInt);
               ForceDirectories(ExtractFilePath(Dest));
               CopyFile(PChar(F), PChar(Dest), False);
               Inc(ResCount);
            end;
         end;
      end;

      if BomFiles.Count > 0 then
      begin
         for I := 0 to BomFiles.Count - 1 do
            Log('  ' + BomFiles[I]);
         Log(Format('[1/3] UTF-8 BOM 이 있는 소스 %d개 - BOM 제거 후 다시 실행 (javac 컴파일 불가)', [BomFiles.Count]));
         Exit;
      end;
      if Sources.Count = 0 then
      begin
         Log('[1/3] .java 소스가 없음 (.classpath 의 src 항목 확인)');
         Exit;
      end;

      Sources.SaveToFile(BuildDir + '\sources.txt');
      Log(Format('  소스 %d개, 리소스 %d개', [Sources.Count, ResCount]));
      pbProgress.StepIt;
   finally
      Sources.Free;
      BomFiles.Free;
   end;

   // 2. 컴파일
   SetStatus('[2/3] 컴파일 중...');
   Log('[2/3] 컴파일: ' + Javac);
   // JDK 8 이 아니면 컴파일하지 않는다
   I := memoLog.Lines.Count;
   if (not RunProcess('"' + Javac + '" -version', BaseDir, Code)) or (Code <> 0) then
   begin
      Log('[2/3] 컴파일 실패 - javac.exe 실행 불가 (jar.exe 와 같은 폴더에 JDK 8 의 javac.exe 가 있어야 함)');
      Exit;
   end;
   Ver := '';
   while I < memoLog.Lines.Count do
   begin
      if Pos('javac ', memoLog.Lines[I]) = 1 then
         Ver := Trim(Copy(memoLog.Lines[I], 7, MaxInt));
      Inc(I);
   end;
   if not IsJdk8(Ver) then
   begin
      Log('[2/3] 컴파일 실패 - JDK 8 이 아님 (javac ' + Ver + '). _JarUtil.ini 의 JarExe Path 를 JDK 8 로 지정');
      Exit;
   end;

   // 클래스패스는 .classpath 순서 그대로 (순서가 바뀌면 다른 jar 의 구버전 클래스가 잡힌다)
   // -XDignore.symbol.file : sun.* 내부 API 를 Eclipse 처럼 rt.jar 에서 직접 참조
   // 작업 디렉터리를 프로젝트 루트로 두고 상대경로만 써서 경로의 공백 문제를 피한다
   Cmd := '"' + Javac + '" -XDignore.symbol.file -nowarn -encoding ' + FSrcEncoding;
   if FSrcLevel <> '' then
      Cmd := Cmd + ' -source ' + FSrcLevel + ' -target ' + FSrcLevel;
   Cmd := Cmd + FDebugOpt + ' -d build/classes';
   if LibPaths.Count > 0 then
   begin
      LibPaths.Delimiter       := ';';
      LibPaths.StrictDelimiter := True;
      Cmd := Cmd + ' -cp "' + LibPaths.DelimitedText + '"';
   end;
   Cmd := Cmd + ' @build/sources.txt';

   pbProgress.Style := pbstMarquee;
   try
      if not RunProcess(Cmd, BaseDir, Code) then
         Exit;
   finally
      pbProgress.Style := pbstNormal;
   end;

   if Code <> 0 then
   begin
      Log(Format('[2/3] 컴파일 실패 (종료코드 %d) - jar 생성 중단', [Code]));
      Exit;
   end;
   Log('[2/3] 컴파일 성공');
   pbProgress.StepIt;
   Result := True;
end;

// [ExportConfig] 의 패키지 폴더를 jar 로 묶는다. 임시 파일에 만든 뒤 교체한다
function TfrmMain.ArchiveJars(const ClassesDir, ExportPath: string): Boolean;
var
   I        : Integer;
   JarName  : string;
   Pkg      : string;
   SrcBase  : string;
   Dst      : string;
   Tmp      : string;
   Code     : DWORD;
   Fail     : Integer;
begin
   Fail := 0;
   Log(Format('[3/3] jar %d개 생성 -> %s', [mList.Count, ExportPath]));
   for I := 0 to mList.Count - 1 do
   begin
      JarName := Trim(mList.Names[I]);
      Pkg     := Trim(mList.ValueFromIndex[I]);
      SetStatus(Format('[3/3] %s 생성 중 (%d/%d)', [JarName, I + 1, mList.Count]));

      if CompareText(Pkg, 'WebContent') = 0 then
         SrcBase := ExcludeTrailingPathDelimiter(BaseDir)
      else
         SrcBase := ClassesDir;

      if not DirectoryExists(SrcBase + '\' + ToProjectPath(Pkg)) then
      begin
         Log(Format('  [건너뜀] %s : 클래스 없음 %s', [JarName, SrcBase + '\' + Pkg]));
         Inc(Fail);
         pbProgress.StepIt;
         Continue;
      end;

      Dst := SlashCon(ExportPath, JarName);
      Tmp := Dst + '.tmp';
      if FileExists(Tmp) then
         DeleteFile(Tmp);

      if (not RunProcess('"' + edtJarPath.Text + '" cf "' + Tmp + '" -C "' + SrcBase + '" ' + Pkg, BaseDir, Code))
         or (Code <> 0) then
      begin
         Log(Format('  [실패] %s (종료코드 %d)', [JarName, Code]));
         DeleteFile(Tmp);
         Inc(Fail);
      end
      // 실행 중인 서버가 jar 를 잡고 있으면 여기서 실패한다
      else if not MoveFileEx(PChar(Tmp), PChar(Dst), MOVEFILE_REPLACE_EXISTING) then
      begin
         Log(Format('  [실패] %s : 덮어쓰기 불가 (사용 중?) %s', [JarName, SysErrorMessage(GetLastError)]));
         DeleteFile(Tmp);
         Inc(Fail);
      end else
         Log(Format('  %-24s <- %s (파일 %d개)', [JarName, Pkg,
            Length(TDirectory.GetFiles(SrcBase + '\' + ToProjectPath(Pkg), '*', TSearchOption.soAllDirectories))]));

      pbProgress.StepIt;
   end;

   if Fail > 0 then
      Log(Format('[3/3] jar %d/%d개 생성, %d건 실패', [mList.Count - Fail, mList.Count, Fail]))
   else
      Log(Format('[3/3] jar %d개 생성 완료', [mList.Count]));
   Result := Fail = 0;
end;

function TfrmMain.MakeJar: Boolean;
var
   ExportPath : string;
   ClassesDir : string;
   StartTick  : DWORD;
   LogFile    : string;
begin
   Result := False;
   if FRunning then
      Exit;

   if mList.Count = 0 then
   begin
      if not FSilent then
         MessageDlg('Export 목록이 비어 있습니다.', mtWarning, [mbOk], 0);
      Exit;
   end;

   LogFile   := BaseDir + '_JarUtil.log';
   StartTick := GetTickCount;
   SetRunning(True);
   try
      memoLog.Clear;
      pbProgress.Position := 0;
      pbProgress.State    := pbsNormal;
      lblStatus.Font.Color := clWindowText;
      Log('=== Jar Export ' + FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + ' ===');
      try
         ExportPath := edtExportPath.Text;
         if Not DirectoryExists(ExportPath) then
            ForceDirectories(ExportPath);

         if cbxBuild.Checked then
         begin
            ClassesDir := BaseDir + 'build\classes';
            pbProgress.Max := mList.Count + 2;
            Result := CompileSources(ClassesDir);
         end else
         begin
            ClassesDir := ExcludeTrailingPathDelimiter(BaseDir + ToProjectPath(ClassPath));
            pbProgress.Max := mList.Count;
            Log('[1/3][2/3] 컴파일 생략 - 기존 클래스로 jar 생성: ' + ClassesDir);
            Result := True;
         end;

         if Result then
            Result := ArchiveJars(ClassesDir, ExportPath);
      except
         on E: Exception do
         begin
            Log('[오류] ' + E.Message);
            Result := False;
         end;
      end;

      if Result then
         SetStatus(Format('완료 (%d초)', [(GetTickCount - StartTick) div 1000]))
      else
      begin
         // 어느 단계에서 실패했든 진행바 전체를 빨갛게 표시
         pbProgress.Position  := pbProgress.Max;
         pbProgress.State     := pbsError;
         lblStatus.Font.Color := clRed;
         SetStatus(Format('실패 (%d초) - 로그 확인', [(GetTickCount - StartTick) div 1000]));
      end;
      Log(lblStatus.Caption);
      memoLog.Lines.SaveToFile(LogFile, TEncoding.UTF8);
   finally
      SetRunning(False);
   end;

   if not FSilent then
   begin
      if cbxOpenDir.Checked and Result then
         ShellExecute(handle, 'open', PChar(ExportPath), '', nil, SW_NORMAL);

      if not Result then
         ShowFailDialog;
   end;
end;

// jar.exe 를 찾지 못하면 경로를 빨갛게 표시한다 (경로 없이 이름만 있으면 PATH 에서 찾는다)
procedure TfrmMain.UpdateJarPathColor;
var
   Found : Boolean;
   Ver   : string;
begin
   if ExtractFilePath(edtJarPath.Text) = '' then
      Found := FileSearch(edtJarPath.Text, GetEnvironmentVariable('PATH')) <> ''
   else
      Found := FileExists(edtJarPath.Text);
   Ver := JdkVersionOf(edtJarPath.Text);

   if not Found then
      edtJarPath.Hint := 'jar.exe 를 찾을 수 없습니다. _JarUtil.ini 의 JarExe Path 를 JDK 8 로 지정하세요.'
   else if (Ver <> '') and not IsJdk8(Ver) then
      edtJarPath.Hint := 'JDK ' + Ver + ' 입니다. 서버 빌드는 JDK 8 이 필요합니다. _JarUtil.ini 의 JarExe Path 를 확인하세요.'
   else
      edtJarPath.Hint := '';

   edtJarPath.ShowHint := edtJarPath.Hint <> '';
   if edtJarPath.ShowHint then
      edtJarPath.Font.Color := clRed
   else
      edtJarPath.Font.Color := clWindowText;
end;

// 실패 원인이 되는 로그 줄을 모아 경고 다이얼로그로 알린다
procedure TfrmMain.ShowFailDialog;
const
   MAX_LINES = 15;
var
   I     : Integer;
   Count : Integer;
   Line  : string;
   Msg   : string;
begin
   Msg   := '';
   Count := 0;
   // 마지막 줄은 상태 요약이라 제외
   for I := 0 to memoLog.Lines.Count - 2 do
   begin
      Line := memoLog.Lines[I];
      if (Pos('실패', Line) > 0) or (Pos('[오류]', Line) > 0) or (Pos('[건너뜀]', Line) > 0)
         or (Pos('[경고]', Line) > 0) or (Pos('BOM', Line) > 0)
         or (Pos(': error:', Line) > 0) or (Pos(': 오류:', Line) > 0) then
      begin
         Inc(Count);
         if Count <= MAX_LINES then
            Msg := Msg + #13#10 + Trim(Line);
      end;
   end;
   if Count > MAX_LINES then
      Msg := Msg + #13#10 + Format('... 외 %d줄', [Count - MAX_LINES]);

   Application.MessageBox(PChar('Jar Export ' + lblStatus.Caption + #13#10 + Msg + #13#10#13#10 +
      '자세한 내용은 로그를 확인하세요.'), 'Jar Export 오류', MB_OK or MB_ICONERROR);
end;

// .settings 의 소스 인코딩과 Java 소스 레벨
procedure TfrmMain.ReadEclipsePrefs;
var
   L : TStringList;
begin
   FSrcEncoding := 'UTF-8';
   FSrcLevel    := '';
   FDebugOpt    := '';
   L := TStringList.Create;
   try
      if FileExists(BaseDir + '.settings\org.eclipse.core.resources.prefs') then
      begin
         L.LoadFromFile(BaseDir + '.settings\org.eclipse.core.resources.prefs');
         if Trim(L.Values['encoding/<project>']) <> '' then
            FSrcEncoding := Trim(L.Values['encoding/<project>']);
      end;
      if FileExists(BaseDir + '.settings\org.eclipse.jdt.core.prefs') then
      begin
         L.LoadFromFile(BaseDir + '.settings\org.eclipse.jdt.core.prefs');
         FSrcLevel := Trim(L.Values['org.eclipse.jdt.core.compiler.source']);
         // Eclipse 와 같은 디버그 정보 (javac 기본값은 lines,source 뿐이라 지역변수 정보가 빠진다)
         if L.Values['org.eclipse.jdt.core.compiler.debug.sourceFile'] = 'generate' then
            FDebugOpt := FDebugOpt + ',source';
         if L.Values['org.eclipse.jdt.core.compiler.debug.lineNumber'] = 'generate' then
            FDebugOpt := FDebugOpt + ',lines';
         if L.Values['org.eclipse.jdt.core.compiler.debug.localVariable'] = 'generate' then
            FDebugOpt := FDebugOpt + ',vars';
         if FDebugOpt = '' then
            FDebugOpt := ' -g:none'
         else
            FDebugOpt := ' -g:' + Copy(FDebugOpt, 2, MaxInt);
      end;
   finally
      L.Free;
   end;
end;

//Load Config
procedure TfrmMain.btnLoadConfigClick(Sender: TObject);
var
   Ini  : TIniFile;
   JavaPath : string;
   Kind : string;
   Path : string;

   LNodeElement: IXMLNode;
begin
   ini := TIniFile.Create(ChangeFileExt(Application.ExeName, '.ini'));
   try
      edtJarPath.Text := ini.ReadString('Config', 'JarExe Path', 'jar.exe');
      if not FileExists(edtJarPath.Text) then
      begin
         // 서버 소스는 JDK8 전용 API 를 쓰므로 JAVA8_HOME 을 먼저 본다
         JavaPath := GetEnvironmentVariable('JAVA8_HOME') + '\bin\jar.exe';
         if not FileExists(JavaPath) then
         begin
            JavaPath := GetEnvironmentVariable('JAVA_HOME') + '\bin\jar.exe';
            if not IsJdk8(JdkVersionOf(JavaPath)) then
               JavaPath := '';
         end;
         if (JavaPath <> '') and FileExists(JavaPath) then
            edtJarPath.Text := JavaPath;
      end;

      if Trim(edtJarPath.Text) = '' then
         edtJarPath.Text := 'jar.exe';
      UpdateJarPathColor;
      edtExportPath.Text := ini.ReadString('Config', 'Export Path', ExtractFilePath(Application.ExeName) + 'JarExport');
      if Trim(edtExportPath.Text) = '' then
         edtExportPath.Text := ExtractFilePath(Application.ExeName) + 'JarExport';
      cbxOpenDir.Checked :=  ini.ReadBool('Config', 'View Folder', True);
      cbxBuild.Checked :=  ini.ReadBool('Config', 'Build Before Export', True);

      List.Clear;
      Ini.ReadSectionValues('ExportConfig', List);
      lvJarList.Items.Clear;
      lvJarList.Items.Assign(List);

      //find class target path, source folders, libraries...
      ClassPath := 'bin';
      SrcPaths.Clear;
      LibPaths.Clear;
      if FileExists(BaseDir + '.classpath') then
      begin
         XMLDocument1.LoadFromFile(BaseDir + '.classpath');
         LNodeElement := XMLDocument1.ChildNodes.FindNode('classpath');
         if LNodeElement <> nil then
         begin
            LNodeElement := LNodeElement.ChildNodes.FindNode('classpathentry');
            while (LNodeElement <> nil) do
            begin
               if LNodeElement.NodeType = ntElement then
               begin
                  Kind := VarToStr(LNodeElement.Attributes['kind']);
                  Path := VarToStr(LNodeElement.Attributes['path']);
                  // '/' 로 시작하면 워크스페이스의 다른 프로젝트 참조라 제외
                  if (Path <> '') and (Path[1] <> '/') then
                  begin
                     if Kind = 'output' then
                        ClassPath := Path
                     else if Kind = 'src' then
                        SrcPaths.Add(Path)
                     else if Kind = 'lib' then
                        LibPaths.Add(Path);
                  end;
               end;
               LNodeElement := LNodeElement.NextSibling;
            end;
         end;
      end;
      if SrcPaths.Count = 0 then
         SrcPaths.Add('src');
      UpdateClassPathLabel;
      ReadEclipsePrefs;
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

procedure TfrmMain.WriteConfigBool(const Key: string; Value: Boolean);
var
   Ini  : TIniFile;
begin
   ini := TIniFile.Create(ChangeFileExt(Application.ExeName, '.ini'));
   try
      ini.WriteBool('Config', Key, Value);
   finally
      Ini.Free;
   end;
end;

procedure TfrmMain.cbxOpenDirClick(Sender: TObject);
begin
   WriteConfigBool('View Folder', cbxOpenDir.Checked);
end;

procedure TfrmMain.UpdateClassPathLabel;
begin
   if cbxBuild.Checked then
      lblClassPath.Caption := 'build\classes (컴파일 대상: ' + ToProjectPath(SrcPaths.CommaText) + ')'
   else
      lblClassPath.Caption := ToProjectPath(ClassPath) + ' (Eclipse 출력 폴더, 컴파일 안 함)';
end;

procedure TfrmMain.cbxBuildClick(Sender: TObject);
begin
   UpdateClassPathLabel;
   WriteConfigBool('Build Before Export', cbxBuild.Checked);
end;

end.
