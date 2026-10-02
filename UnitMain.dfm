object frmMain: TfrmMain
  Left = 0
  Top = 0
  ActiveControl = lvJarList
  Caption = 'Jar Export Util v1.3 (UNIMS)'
  ClientHeight = 640
  ClientWidth = 760
  Color = clBtnFace
  Constraints.MinHeight = 520
  Constraints.MinWidth = 640
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  Scaled = False
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  DesignSize = (
    760
    640)
  PixelsPerInch = 96
  TextHeight = 14
  object Label1: TLabel
    Left = 11
    Top = 124
    Width = 77
    Height = 14
    Caption = 'Jar Export List'
  end
  object Label2: TLabel
    Left = 11
    Top = 296
    Width = 295
    Height = 14
    Caption = 'If you want individual export, select and doubleclick...'
  end
  object Label3: TLabel
    Left = 12
    Top = 101
    Width = 84
    Height = 14
    Caption = 'class out path :'
  end
  object lblClassPath: TLabel
    Left = 101
    Top = 101
    Width = 25
    Height = 14
    Caption = 'path'
  end
  object Label4: TLabel
    Left = 11
    Top = 320
    Width = 46
    Height = 14
    Caption = 'Progress'
  end
  object lblStatus: TLabel
    Left = 72
    Top = 320
    Width = 677
    Height = 14
    Anchors = [akLeft, akTop, akRight]
    AutoSize = False
    Caption = 'Ready'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object edtJarPath: TLabeledEdit
    Left = 11
    Top = 24
    Width = 651
    Height = 22
    TabStop = False
    Anchors = [akLeft, akTop, akRight]
    EditLabel.Width = 68
    EditLabel.Height = 14
    EditLabel.Caption = 'Jar.exe Path'
    ImeName = 'Microsoft Office IME 2007'
    ReadOnly = True
    TabOrder = 0
  end
  object btnMake: TButton
    Left = 629
    Top = 606
    Width = 120
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Export All'
    TabOrder = 1
    OnClick = btnMakeClick
  end
  object edtExportPath: TLabeledEdit
    Left = 11
    Top = 70
    Width = 651
    Height = 22
    TabStop = False
    Anchors = [akLeft, akTop, akRight]
    EditLabel.Width = 92
    EditLabel.Height = 14
    EditLabel.Caption = 'Jar Export Folder'
    ImeName = 'Microsoft Office IME 2007'
    ReadOnly = True
    TabOrder = 2
  end
  object lvJarList: TListBox
    Left = 8
    Top = 142
    Width = 737
    Height = 148
    Anchors = [akLeft, akTop, akRight]
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Consolas'
    Font.Style = []
    ImeName = 'Microsoft Office IME 2007'
    ItemHeight = 14
    ParentFont = False
    TabOrder = 3
    OnDblClick = lvJarListDblClick
  end
  object btnLoadConfig: TButton
    Left = 549
    Top = 606
    Width = 80
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Load Config'
    TabOrder = 4
    OnClick = btnLoadConfigClick
  end
  object pbProgress: TProgressBar
    Left = 11
    Top = 338
    Width = 737
    Height = 17
    Anchors = [akLeft, akTop, akRight]
    Step = 1
    TabOrder = 5
  end
  object memoLog: TMemo
    Left = 11
    Top = 360
    Width = 737
    Height = 238
    Anchors = [akLeft, akTop, akRight, akBottom]
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Consolas'
    Font.Style = []
    ImeName = 'Microsoft Office IME 2007'
    ParentFont = False
    ReadOnly = True
    ScrollBars = ssBoth
    TabOrder = 6
    WordWrap = False
  end
  object cbxOpenDir: TCheckBox
    Left = 11
    Top = 610
    Width = 126
    Height = 17
    Anchors = [akLeft, akBottom]
    Caption = 'Open Export Folder'
    TabOrder = 8
    OnClick = cbxOpenDirClick
  end
  object cbxBuild: TCheckBox
    Left = 139
    Top = 610
    Width = 150
    Height = 17
    Anchors = [akLeft, akBottom]
    Caption = 'Compile before export'
    Checked = True
    State = cbChecked
    TabOrder = 9
    OnClick = cbxBuildClick
  end
  object btnOpenConfig: TButton
    Left = 469
    Top = 606
    Width = 80
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Open Config'
    TabOrder = 10
    OnClick = btnOpenConfigClick
  end
  object btnOpenFolder: TButton
    Left = 365
    Top = 606
    Width = 104
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Open Exe Folder'
    TabOrder = 11
    OnClick = btnOpenFolderClick
  end
  object btnOpenJarFolder: TButton
    Left = 671
    Top = 21
    Width = 77
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Open Folder'
    TabOrder = 12
    OnClick = btnOpenJarFolderClick
  end
  object btnOpenExportFolder: TButton
    Left = 671
    Top = 68
    Width = 77
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Open Folder'
    TabOrder = 13
    OnClick = btnOpenExportFolderClick
  end
  object XMLDocument1: TXMLDocument
    Left = 200
    Top = 96
    DOMVendorDesc = 'MSXML'
  end
end
