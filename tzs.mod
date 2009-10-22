<?xml version="1.0" encoding="UTF-8"?>
<ModuleFile xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <UiMod name="whom" version="1.0" date="22/10/2009" >
        
        <Author name="tzs" email="tzs@tzs.net" />
        <Description text="count classes and archetypes" />
        
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
