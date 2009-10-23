<?xml version="1.0" encoding="UTF-8"?>
<ModuleFile xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <UiMod name="whom" version="1.0" date="22/10/2009" >
        
        <Author name="tzs"/>
        <Description text="count classes and archetypes"/>
        <VersionSettings gameVersion="1.3.2" />
        
        <Dependencies>
            <Dependency name="EA_ChatWindow"/>
            <Dependency name="LibSlash" />
        </Dependencies>
        
        <Files>
            <File name="whom.lua" />
        </Files>
        
        <OnInitialize>
            <CallFunction name="whom.Initialize" />
        </OnInitialize>
        <OnUpdate/>
        <OnShutdown/>
    </UiMod>
</ModuleFile>
