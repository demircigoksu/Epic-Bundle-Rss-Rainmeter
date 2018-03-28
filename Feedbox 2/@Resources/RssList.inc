[1RSS]
Meter=String
MeterStyle=ListStyle
Text=#1Name#
LeftMouseUpAction=[!WriteKeyValue Variables Logo "#1Logo#"][!WriteKeyValue RssFetcher URL "#1RSS#"][!CommandMeasure ConvertImage Kill][!CommandMeasure ParseArticles "timing5=19;pulloutDir=-1;feedChanged=true;randomposition=[#Currentsection#:Y]"][!WriteKeyValue Variables AllMode false]"
[1]
Meter=String
MeterStyle=DelStyle

[2RSS]
Meter=String
MeterStyle=ListStyle
Text=#2Name#
LeftMouseUpAction=[!WriteKeyValue Variables Logo "#2Logo#"][!WriteKeyValue RssFetcher URL "#2RSS#"][!CommandMeasure ConvertImage Kill][!CommandMeasure ParseArticles "timing5=19;pulloutDir=-1;feedChanged=true;randomposition=[#Currentsection#:Y]"][!WriteKeyValue Variables AllMode false]"
[2]
Meter=String
MeterStyle=DelStyle

