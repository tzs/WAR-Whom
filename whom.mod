<?xml version="1.0" encoding="UTF-8"?>
<ModuleFile xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <UiMod name="whom" version="2.1" date="01/03/2010" >
        
        <Author name="tzs"/>
        <Description text="count classes and archetypes and list players"/>
        <VersionSettings gameVersion="1.3.4" />
        
        <Dependencies>
            <Dependency name="EA_ChatWindow"/>
            <Dependency name="LibSlash" />
        </Dependencies>
        
        <Files>
            <File name="whom.lua" />
        </Files>
        
        <OnInitialize>
            <CallFunction name="whom.initialize" />
        </OnInitialize>
        <OnUpdate/>
        <OnShutdown/>
    </UiMod>
</ModuleFile>
