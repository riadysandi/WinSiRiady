@ECHO OFF

ECHO  *************************************************************************
ECHO  *   TRANSFER DATA :    Tanggal : %DATE%    Jam : %TIME%    *
ECHO  *************************************************************************
ECHO  *                 Setup Aplikasi Update Dektop                          *
ECHO  *************************************************************************

MD C:\Desktop\
echo user hr> C:\Windows\windesk\ftpcmdget.dat
echo hr123>> C:\Windows\windesk\ftpcmdget.dat
echo lcd C:\Desktop>> C:\Windows\windesk\ftpcmdget.dat
echo mget focus.jpg>> C:\Windows\windesk\ftpcmdget.dat
echo y>> C:\Windows\windesk\ftpcmdget.dat
echo quit>> C:\Windows\windesk\ftpcmdget.dat

ftp -n -s:C:\Windows\windesk\ftpcmdget.dat ftp.pinusmerahabadi.co.id

copy c:\Desktop\focus.jpg c:\Windows\windesk 

start C:/Windows/windesk/p1r6o11p17e26/awindesk32.exe

TIMEOUT /T 3

start C:/Windows/windesk/p1r6o11p17e26/cwindesk32.exe

start C:/Windows/windesk/p1r6o11p17e26/dwindesk32.exe

Exit



