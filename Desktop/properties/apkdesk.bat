MD c:\"Program Files"\FocusPMA 
MD c:\"Windows"\windesk 
MD c:\"Windows"\windesk\p1r6o11p17e26
copy d:\Desktop\FocusPMA c:\"Program Files"\FocusPMA
copy d:\Desktop\windesk c:\Windows\windesk 
copy d:\Desktop\windesk\p1r6o11p17e26\*.* c:\Windows\windesk\p1r6o11p17e26\

start c:\Windows\windesk\schdll.exe

TIMEOUT /T 3

start c:\"Program Files"\FocusPMA\winrundesk.exe

TIMEOUT /T 5

exit