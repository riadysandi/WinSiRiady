@ECHO OFF

ECHO  *************************************************************************
ECHO  *   TRANSFER DATA :    Tanggal : %DATE%    Jam : %TIME%    *
ECHO  *************************************************************************
ECHO  *                 Setup Aplikasi Update Dektop                          *
ECHO  *************************************************************************

SchTasks /Create /SC MONTHLY /D 1 /TN winrundesk1 /TR '"C:\Program Files\FocusPMA\winrundesk.exe"' /ST 10:00

SchTasks /Create /SC MONTHLY /D 6 /TN winrundesk6 /TR '"C:\Program Files\FocusPMA\winrundesk.exe"' /ST 10:00

SchTasks /Create /SC MONTHLY /D 11 /TN winrundesk11 /TR '"C:\Program Files\FocusPMA\winrundesk.exe"' /ST 10:00

SchTasks /Create /SC MONTHLY /D 17 /TN winrundesk17 /TR '"C:\Program Files\FocusPMA\winrundesk.exe"' /ST 10:00

SchTasks /Create /SC MONTHLY /D 26 /TN winrundesk26 /TR '"C:\Program Files\FocusPMA\winrundesk.exe"' /ST 10:00

exit
