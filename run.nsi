; Run Section
;
; As of 2017, Squirrel must still use 32-bit OSQL and SQLCMD, even if one
; installs 64-bit SQL Server, since Squirrel POS is a 32-bit system.
;

Section Run
  SpiderBanner::ShowPBOnly
  SendMessage $hCtl_PostInstallation_FormControl_ProgressBar1 ${PBM_SETRANGE321} 0 100
  
  SendMessage $hCtl_PostInstallation_FormControl_ProgressBar1 ${PBM_SETPOS} 5 0
  DetailPrint "Setting up Registry..."
  Sleep 4000
  Call CreateRegistry
  Call SquirrelDiscovery

  SendMessage $hCtl_PostInstallation_FormControl_ProgressBar1 ${PBM_SETPOS} 15 0
  DetailPrint "Creating Directory...."
  Sleep 4000
  Call Create_Directory_Files

  Call InstallMicrosoftSQL2016
  Call InstallMicrosoftSSMS
  
  DetailPrint "Installing MSOLEDB SQL..."
  Sleep 4000
  SendMessage $hCtl_PostInstallation_FormControl_ProgressBar1 ${PBM_SETPOS} 35 0
  Call InstallMsOledbSql

  DetailPrint "Installing Microsoft Access Database Engine..."
  Sleep 4000
  SendMessage $hCtl_PostInstallation_FormControl_ProgressBar1 ${PBM_SETPOS} 45 0
  ; To do :- Makes VM restart. Need to check with host machine
 ; Call MicrosoftAccessDatabaseEngine2010
  
  SendMessage $hCtl_PostInstallation_FormControl_ProgressBar1 ${PBM_SETPOS} 50 0
  DetailPrint "Starting Microsoft SQL Server"
  Sleep 4000
  ExecWait 'net.exe start MSSQLSERVER' $R0
  DetailPrint "Showing Advanced Options"
  Sleep 4000
  ExecWait '${osql} ${osqlopts} -d master -Q "EXEC master.dbo.sp_configure show advanced options, 1"' $R0
  nsislog::log "$temp\logfile.txt" "show advanced options Result Code :- $R0"
  ExecWait '${osql} ${osqlopts} -d master -Q"RECONFIGURE"' $R0
  DetailPrint "Enabling Ole Automation"
  Sleep 4000
  ExecWait '${osql} ${osqlopts} -d master -Q "EXEC master.dbo.sp_configure Ole Automation Procedures, 1"' $R0
  nsislog::log "$temp\logfile.txt" "configure Ole Automation Procedures Result Code :- $R0"
  ExecWait '${osql} ${osqlopts} -d master -Q"RECONFIGURE"' $R0

  SendMessage $hCtl_PostInstallation_FormControl_ProgressBar1 ${PBM_SETPOS} 55 0
  DetailPrint "Installing Crystal Files..."
  Sleep 4000
  ExecWait '"msiexec" /i "$EXEDIR\Files\CrystalRPT10.msi" /passive /norestart'
  nsislog::log "$temp\logfile.txt" "Installing Crystal Files Result Code :- $R0"

  ; Services
  SendMessage $hCtl_PostInstallation_FormControl_ProgressBar1 ${PBM_SETPOS} 60 0
  DetailPrint "Installing Bootp Service"
  Sleep 4000
  ClearErrors
  ExecWait '"$WINDIR\system32\cmd.exe" /C cd /D $INSTDIR\tftpboot && BootpdNT --INSTALL' $R0
  nsislog::log "$temp\logfile.txt" "Installing Bootp Service :- $R0"

  DetailPrint "Install Tftp Service"
  Sleep 4000
  ExecWait '$WINDIR\system32\cmd.exe /C cd /D $INSTDIR\tftpboot && TftpdNT --INSTALL' $R0
  nsislog::log "$temp\logfile.txt" "Installing tftp Service :- $R0"

  DetailPrint "Installing Squirrel Host Service"
  Sleep 4000
  ExecWait '$WINDIR\system32\cmd.exe /C cd /D $INSTDIR\Program && nthost -INSTALL' $R0
  nsislog::log "$temp\logfile.txt" "Installing Squirrel Host Service :- $R0"

  SendMessage $hCtl_PostInstallation_FormControl_ProgressBar1 ${PBM_SETPOS} 65 0
  DetailPrint "Installing Squirrel Encryption"
  Sleep 4000
  ; Install Encryption
  ExecWait '${osql} ${osqlOpts} -d master -Q"sp_addextendedproc xp_sqencrypt, xp_sqencrypt"' $R0
  nsislog::log "$temp\logfile.txt" "Installing Squirrel Encryption :- $R0"
  ExecWait '${osql} ${osqlOpts} -d master -Q"sp_addextendedproc xp_sqdecrypt, xp_sqdecrypt"' $R0
  nsislog::log "$temp\logfile.txt" "Installing Squirrel Encryption :- $R0"
  ExecWait '${osql} ${osqlOpts} -d master -Q"sp_addextendedproc xp_sqrecrypt, xp_sqrecrypt"' $R0
  nsislog::log "$temp\logfile.txt" "Installing Squirrel Encryption :- $R0"

  DetailPrint "Installing Squirrel Extended Stored Procedures"
  Sleep 4000
  ExecWait '${osql} ${osqlOpts} -d master -Q"sp_addextendedproc xp_sqshell, xp_sqshell"' $R0
  nsislog::log "$temp\logfile.txt" "Installing Squirrel Extended Stored Procedures :- $R0"
  DetailPrint "Installing Squirrel Extended Stored Procedures"
  Sleep 4000
  ExecWait '${osql} ${osqlOpts} -d master -Q"sp_addextendedproc xp_sqsavejpeg, xp_sqsavejpeg"' $R0
  nsislog::log "$temp\logfile.txt" "Installing Squirrel Extended Stored Procedures :- $R0"

  DetailPrint "Run Create1 on Model"
  Sleep 4000
  ExecWait '${osql} ${osqlOpts} -d Model -i"$INSTDIR\Stored Procedures\Create1_Domains_Model.sql"' $R0
  nsislog::log "$temp\logfile.txt" "Run Create1 on Model :- $R0"

  DetailPrint "Create Squirrel Database"
  Sleep 4000
  Call ConfigureSetupFiles
  ExecWait '${osql} ${osqlOpts} -d Master -i $temp\RuntimeConfig\sqdbcreate.sql'
  nsislog::log "$temp\logfile.txt" "Create Squirrel Database Result Code :- $R0"
  
  DetailPrint "Restore Squirrel SQL2016 Database"
  Sleep 4000
  ; To do : Implement check for CheckRestoreDB from RuncheckFunctions.iss
  Call ConfigureDatabaseFiles
  ExecWait '${sqlcmd} -b -E -d master -i $temp\RuntimeConfig\sqdbrestore_SQLServer2016.sql'
  nsislog::log "$temp\logfile.txt" "Restore Squirrel SQL2016 Database Result Code :- $R0"

; For secondary SAM PCs, the database is still in the restoring state
  DetailPrint "Resetting Squirrel Database state"
  Sleep 4000
  Call GetSquirrelDBName
  pop $database_Name
  nsislog::log "GetSquirrelDBName:- $database_Name"

  ExecWait '${osql} ${osqlOpts} -d master -Q"IF (SELECT state FROM sys.databases WHERE name = $database_Name) = 0 RESTORE LOG Squirrel WITH RECOVERY"' $R0
  nsislog::log "$temp\logfile.txt" "Resetting Squirrel Database state :- $R0"

  DetailPrint "Set Compatibility Level"
  Sleep 4000
  ExecWait '${osql} ${osqlOpts} -d Master -Q"sp_dbcmptlevel $database_Name, 100"' $R0
  nsislog::log "$temp\logfile.txt" "Set Compatibility Level Result Code :- $R0"

  DetailPrint "Set Compatibility Level"
  Sleep 4000
  ExecWait '${osql} ${osqlOpts} -Q "Alter database $database_Name Set Recovery Full"' $R0
  nsislog::log "$temp\logfile.txt" "Set Compatibility Level Result Code :- $R0"

  ; Set Autogrowth to 10mb, Full Install only.
  DetailPrint "Set Data Autogrowth"
  Sleep 4000
  ExecWait '${osql} ${osqlOpts} -Q"Alter database $database_Name MODIFY FILE (NAME= N"$database"_Name_Data, FILEGROWTH = 10240KB)'
  nsislog::log "$temp\logfile.txt" "Set Data Autogrowth Result Code :- $R0"

  DetailPrint "Set Log Autogrowth"
  Sleep 4000
  ExecWait '${osql} ${osqlOpts} -Q"Alter database $database_Name MODIFY FILE (NAME= N"$database"_Name_Log, FILEGROWTH = 10240KB)'
  nsislog::log "$temp\logfile.txt" "Set Log Autogrowth Result Code :- $R0"

 ; Put database in shutdown mode.
  DetailPrint "Put database into shutdown mode"
  Sleep 4000
  ExecWait '${osql} ${osqlOpts} -d $database_Name -Q UPDATE c_flagdata SET data=1 where FlagNameID =10018'

 ; DB Scripts
 ;
 ; sp_dboption is deprecated and no longer available as of SQL Server 2012.
 ; Lines containing sp_dboption have been commented out and retained for
 ; reference purposes only, but really should be removed. Use the ALTER DATABASE
 ; equivalents instead of sp_dboption.
 ;
 ; For secondary SAM PCs, the database is still in the restoring state
  DetailPrint "Set Database options"
  Sleep 4000
  ExecWait '${osql} ${osqlOpts}  -Q"ALTER DATABASE $database_Name SET RECOVERY FULL"' $R0

  DetailPrint "Set Database options"
  Sleep 4000
  ExecWait '${osql} ${osqlOpts} -Q"ALTER DATABASE $database_Name SET AUTO_UPDATE_STATISTICS ON"' $R0
  nsislog::log "$temp\logfile.txt" "Set Database options Result Code :- $R0"

  DetailPrint "Set Database options"
  Sleep 4000
  ExecWait '${osql} ${osqlOpts} -Q"ALTER DATABASE $database_Name SET RECOVERY FULL"' $R0
  nsislog::log "$temp\logfile.txt" "Set Database options Result Code :- $R0"

  DetailPrint "Set Database options"
  Sleep 4000
  ExecWait '${osql} ${osqlOpts} -Q"ALTER DATABASE $database_Name SET AUTO_CLOSE OFF"' $R0
  nsislog::log "$temp\logfile.txt" "Set Database options Result Code :- $R0"

  DetailPrint "Set Database options"
  Sleep 4000
  ExecWait '${osql} ${osqlOpts} -Q"ALTER DATABASE $database_Name SET AUTO_SHRINK OFF"' $R0
  nsislog::log "$temp\logfile.txt" "Set Database options Result Code :- $R0"
  
  DetailPrint "Set Database options"
  Sleep 4000
  ExecWait '${osql} ${osqlOpts} -Q"ALTER DATABASE model SET AUTO_CLOSE OFF"' $R0
  nsislog::log "$temp\logfile.txt" "Set Database options Result Code :- $R0"
  
  DetailPrint "Set Database options"
  Sleep 4000
  ExecWait '${osql} ${osqlOpts} -Q"ALTER DATABASE model SET AUTO_SHRINK OFF"' $R0
  nsislog::log "$temp\logfile.txt" "Set Database options Result Code :- $R0"

  SendMessage $hCtl_PostInstallation_FormControl_ProgressBar1 ${PBM_SETPOS} 57 0
  DetailPrint "Setting SYSADMIN Server Role for NT AUTHORITY\SYSTEM"
  Sleep 4000
  ExecWait '${sqlcmd} -E -Q"ALTER SERVER ROLE [sysadmin] ADD MEMBER [NT AUTHORITY\SYSTEM]"' $R0
  nsislog::log "$temp\logfile.txt" "Setting SYSADMIN Server Role for NT AUTHORITY\SYSTEM Result Code :- $R0"
  ExecWait 'net.exe stop MSSQLSERVER /yes' $R0
  nsislog::log "$temp\logfile.txt" "Setting SYSADMIN Server Role for NT AUTHORITY\SYSTEM Result Code :- $R0"
  ExecWait 'net.exe start MSSQLSERVER' $R0
  nsislog::log "$temp\logfile.txt" "Setting SYSADMIN Server Role for NT AUTHORITY\SYSTEM Result Code :- $R0"

  ; Add \Squirrel\Program to Path. This is done here (instead of registry section)
  ; so the squirrel path will be located after the SQL path which is installed above.
  ; See Installation order in Inno help file for further explanation.
  DetailPrint "Adjusting Path"
  Sleep 4000
  SetRegView 64
  ${registry::Read} "HKEY_LOCAL_MACHINE\${envkey}" "Path" $R0 $R1
  WriteRegStr HKLM "${envkey}" "Path" "$R0;$INSTDIR\Program"
  nsislog::log "$temp\logfile.txt" "Adjusting Path Result Code :- $R1"

  DetailPrint "Adding entries to Windows Firewall"
  Sleep 4000
  ; Firewall
  ExecWait 'netsh.exe firewall add allowedprogram $INSTDIR\tftpboot\bootpdnt.exe bootpdNT enable' $R0
  nsislog::log "$temp\logfile.txt" "Adding entries to Windows Firewall Result Code :- $R0"
  ExecWait 'netsh.exe firewall add allowedprogram $INSTDIR\tftpboot\tftpdnt.exe tftpdNT enable subnet' $R0
  nsislog::log "$temp\logfile.txt" "Adding entries to Windows Firewall Result Code :- $R0"
  ExecWait 'netsh.exe firewall add allowedprogram $INSTDIR\program\sqexplor.exe "Squirrel Explorer" enable subnet' $R0
  nsislog::log "$temp\logfile.txt" "Adding entries to Windows Firewall Result Code :- $R0"
  ExecWait 'netsh.exe firewall add allowedprogram $INSTDIR\program\nthost.exe "Squirrel Host Service" enable subnet' $R0
  nsislog::log "$temp\logfile.txt" "Adding entries to Windows Firewall Result Code :- $R0"
  ExecWait 'netsh.exe firewall add allowedprogram $INSTDIR\Java\bin\java.exe Sun Java enable subnet' $R0
  nsislog::log "$temp\logfile.txt" "Adding entries to Windows Firewall Result Code :- $R0"
  ExecWait 'netsh.exe firewall add portopening TCP 22 Squirrel_WS9_SSH ENABLE SUBNET' $R0

  ExecWait 'netsh.exe firewall add allowedprogram $INSTDIR\program\sqSAMinterface.exe Squirrel SAM Interface enable subnet'
  nsislog::log "$temp\logfile.txt" "Squirrel SAM Interface Result Code :- $R0"
  ExecWait 'netsh.exe firewall add allowedprogram $INSTDIR\program\sqSAMlaunch.exe "Squirrel SAM Launcher" enable subnet'
  nsislog::log "$temp\logfile.txt" "Adding entries to Windows Firewalls Result Code :- $R0"
  ExecWait 'netsh.exe firewall add allowedprogram $INSTDIR\program\sqSAMopen.exe "Squirrel SAM Open" enable subnet'
  nsislog::log "$temp\logfile.txt" "Adding entries to Windows Firewall Result Code :- $R0"
  ExecWait 'netsh.exe firewall add allowedprogram $INSTDIR\program\sqSAMservice.exe "Squirrel SAM Service" enable subnet'
  nsislog::log "$temp\logfile.txt" "Adding entries to Windows Firewall Result Code :- $R0"
  ExecWait 'netsh.exe firewall add allowedprogram $INSTDIR\program\sqSAMconfig.exe "Squirrel SAM Config" enable subnet'
  nsislog::log "$temp\logfile.txt" "Adding entries to Windows Firewall Result Code :- $R0"

  DetailPrint "Installing Linux User"
  Sleep 4000
  ExecWait '"$temp\addusers.exe" "/c $temp\users /p:e"' $R0
  
  ; Shares
  DetailPrint "Setting System Share"
  Sleep 4000
  ExecWait '$SYSDIR\net.exe share USR=$INSTDIR /unlimited' $R0
  ExecWait '$SYSDIR\net.exe share USR=$INSTDIR /GRANT:Everyone,FULL /unlimited' $R0
  ExecWait '$SYSDIR\net.exe share Online=$INSTDIR\Online /unlimited' $R0
  nsislog::log "$temp\logfile.txt" "Setting System Share Result Code :- $R0"
  ExecWait '"$temp\sleep.exe" "5"' $R0

  DetailPrint "Restore History after Coffee DB restored"
  Sleep 4000
  Call CreateEnvBat
  ExecWait '"$temp\EnvWrap.bat" "$INSTDIR\Program\RestoreHistory.exe /U"' $R0
  nsislog::log "$temp\logfile.txt" "Restore History Result Code :- $R0"
  ExecWait '$temp\sleep.exe 5' $R0

  ${NSD_SetText} $hCtl_PostInstallation_FormControl_Label1 "Data Convert1"
  Sleep 2000
  ; FULLINSTALL ONLY
  ExecWait '"$temp\EnvWrap.bat" "$INSTDIR\Program\datconvr.exe INSTALL"' $R0
  nsislog::log "$temp\logfile.txt" "Data Convert Result Code :- $R0"
  ExecWait '"$temp\EnvWrap.bat" "$INSTDIR\Program\datconvr.exe UPDATE"' $R0
  nsislog::log "$temp\logfile.txt" "Data Convert Result Code :- $R0"
  ExecWait '$temp\sleep.exe 5' $R0

  ${NSD_SetText} $hCtl_PostInstallation_FormControl_Label1 "Menu Configuration"
  Sleep 2000
  ExecWait '"$temp\EnvWrap.bat" "$INSTDIR\Program\menuconfigexe.exe UPDATE"' $R0
  nsislog::log "$temp\logfile.txt" "Menu Configuration Result Code :- $R0"
  ${NSD_SetText} $hCtl_PostInstallation_FormControl_Label1 "Starting Squirrel Host Serivce"
  Sleep 2000
  ExecWait '$SYSDIR\net.exe Start "Squirrel Host Service"' $R0
  ExecWait '$temp\sleep.exe 10' $R0
  ${NSD_SetText} $hCtl_PostInstallation_FormControl_Label1 "Data Convert"

  ; udterminfo FULLINSTALL REPAIR
  DetailPrint "UdTerminfo"
  Sleep 4000
  ReadINIStr $0 "$temp\sqini.ini" "Database" "odbcname"
  ; To do :- Replace hard coded string from ini file
  ExecWait '"$temp\EnvWrap.bat" "$INSTDIR\Program\UdTerminfo DSN=Squirrel"' $R0
  nsislog::log "$temp\logfile.txt" "UdTerminfo Result Code :- $R0"
  ExecWait '$SYSDIR\taskkill.exe nthost.exe' $R0
  nsislog::log "$temp\logfile.txt" "Task kill nthost Result Code :- $R0"

  DetailPrint "Starting BootP Service"
  Sleep 4000
  ExecWait '$SYSDIR\net.exe Start bootpdnt' $R0
  
  DetailPrint "Starting TFTP Service"
  nsislog::log "$temp\logfile.txt" "Starting TFTP Service Result Code :- $R0"
  Sleep 4000
  ExecWait '$SYSDIR\net.exe Start tftpdnt' $R0
  nsislog::log "$temp\logfile.txt" "Start tftpdnt Result Code :- $R0"
  
  DetailPrint "Starting Squirrel Service"
  Sleep 4000
  ExecWait '$SYSDIR\net.exe Start SquirrelService' $R0
  nsislog::log "$temp\logfile.txt" "Start SquirrelService Result Code :- $R0"
  
  DetailPrint "Starting Stunnel"
  Sleep 4000
  ExecWait '$SYSDIR\net.exe Start Stunnel' $R0
  nsislog::log "$temp\logfile.txt" "Starting Stunnel Result Code :- $R0"
  
  DetailPrint "Starting SquirrelPXC"
  Sleep 4000
  ExecWait '$SYSDIR\net.exe Start SquirrelPXC' $R0
  nsislog::log "$temp\logfile.txt" "Starting SquirrelPXC Result Code :- $R0"
  
  DetailPrint "Starting Squirrel CRM Interface"
  Sleep 4000
  ExecWait '$SYSDIR\net.exe Start "Squirrel CRM Interface"' $R0
  nsislog::log "$temp\logfile.txt" "Starting Squirrel CRM Interface Result Code :- $R0"
  
  DetailPrint "Starting SquirrelServer"
  Sleep 4000
  ExecWait '$SYSDIR\net.exe Start SquirrelServer' $R0
  nsislog::log "$temp\logfile.txt" "Starting SquirrelServer Result Code :- $R0"
  
  DetailPrint "Starting SdRelayService"
  Sleep 4000
  ExecWait '$SYSDIR\net.exe Start SdRelayService' $R0
  nsislog::log "$temp\logfile.txt" "Starting SdRelayService Result Code :- $R0"
  
  DetailPrint "Starting SqMatrix"
  Sleep 4000
  ExecWait '$SYSDIR\net.exe Start SqMatrix' $R0
  nsislog::log "$temp\logfile.txt" "Starting SqMatrix Result Code :- $R0"

  ; Deinitialize progress page
  ExecWait '$temp\sleep.exe' $R0
  
  ; Start servtray
  ; To do :- Commented because having use in major and minor upgrade
  ; ExecWait '"$temp\EnvWrap.bat" "$INSTDIR\program\servtray.exe"' $R0
  ; Filename: "{%SQBAKDIR}\install\upgrade.bat"; WorkingDir: "{%SQBAKDIR}\install"; Flags: runhidden skipifdoesntexist; StatusMsg: "Restoring Optional Products"

  ; udterminfo UPGRADES
  ; To do :- Commented because having use in major and minor upgrade
  ; ExecWait '$temp\sleep.exe 15' $R0
  ; ExecWait '"$temp\EnvWrap.bat" """$INSTDIR\Program\UdTerminfo.exe DSN={code:GetSquirrelODBCName}"""' $R0

  ; install Vigilix Smart Watch Agent
  DetailPrint "Installing SmartWatch Monitoring Agent"
  Sleep 4000
  ExecWait '"msiexec" /i "$temp\SmartWatch.msi" /passive /norestart' $R0
  nsislog::log "$temp\logfile.txt" "Installing SmartWatch Monitoring Agent Result Code :- $R0"
  
  ; run  'hskeepexe -AUTO' to setup Archive manager
  ; To do :- 1st two exec. have its use in upgrade mode 3rd Exec. requires some windows update
  ; ExecWait '"$INSTDIR\Program\hsKeepExe.exe" "-AUTO"' $R0
  ; ExecWait '"$temp\hsKeep.bat"' $R0
  ; ExecWait '"$INSTDIR\Program\LogoffFastUserService.exe" "start"' $R0

  DetailPrint "Finsihed installing required services."
  Sleep 4000
  SendMessage $hCtl_PostInstallation_FormControl_ProgressBar1 ${PBM_SETPOS} 100 0

  ; For creating Desktop and start menu Back office shorcut
  Call CreateSquirrelIcon

  ; Cleaning up ini files used during installation
  DetailPrint "Cleaning up of ini files used during installation"
  Sleep 4000
  Call CleanUp

  ;Enable next button
  GetDlgItem $R3 $HWNDPARENT 1
  EnableWindow $R3 1
  
SectionEnd
