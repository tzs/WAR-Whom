<?xml version="1.0" encoding="UTF-8"?>
<ModuleFile xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <UiMod name="tzs" version="1.0" date="19/10/2009" >
        
        <Author name="tzs" email="tzs@tzs.net" />
        <Description text="test add on" />
        
        <Dependencies>
            <Dependency name="EA_ChatWindow"/>
            <Dependency name="LibSlash" />
        </Dependencies>
        
        <Files>
            <File name="tzs.lua" />
        </Files>
        
        <OnInitialize>
            <CallFunction name="tzs.Initialize" />
        </OnInitialize>
        <OnUpdate/>
        <OnShutdown/>
    </UiMod>
</ModuleFile>
