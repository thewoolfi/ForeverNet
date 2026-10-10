local _, F = ...

local function change(callback)
    local candidate = F.Copy(F.localProfile)
    callback(candidate)
    if not F.ValidProfile(candidate) then error(F.L('Некорректные поля или превышены лимиты профиля.')) end
    F.localProfile.professions, F.localProfile.recipes, F.localProfile.camps = candidate.professions, candidate.recipes, candidate.camps
    F.Touch(); F.Print(F.L('Профиль обновлён. /fn sync — отправить.')); F.UI.Status()
end
local function securityState()
    if not issecurevariable then return end
    local result={}
    local function inspect(label,object,key)
        if not object then return end
        local ok,secure,source=pcall(issecurevariable,object,key)
        if ok and type(secure)=='boolean' then
            result[label]={secure=secure,source=type(source)=='string' and source:sub(1,64) or nil}
        end
    end
    inspect('ContainerFrameItemButton_OnClick',_G,'ContainerFrameItemButton_OnClick')
    inspect('C_Container.UseContainerItem',C_Container,'UseContainerItem')
    inspect('BankFrame',_G,'BankFrame'); inspect('BankPanel',_G,'BankPanel')
    inspect('BankFrame.GetActiveBankType',BankFrame,'GetActiveBankType')
    inspect('BankFrame.BankPanel',BankFrame,'BankPanel')
    local panel=BankPanel or BankFrame and BankFrame.BankPanel
    inspect('BankPanel.bankType',panel,'bankType')
    return next(result) and result or nil
end
function F.ProtectedContext()
    local get=C_CVar and C_CVar.GetCVar or GetCVar
    local ok,logging=false,nil
    if get then ok,logging=pcall(get,'taintLog') end
    local combat
    if InCombatLockdown then combat=not not InCombatLockdown() end
    return {security=securityState(),taintLog=ok and type(logging)=='string' and logging or nil,
        bankOpened=F.Bank.lastOpened,bankClosed=F.Bank.lastClosed,bankScanned=F.Bank.lastScanned,
        bankScans=F.Bank.scanCount,bankOpen=not not F.Bank.open,auctionOpen=not not F.Auction.open,
        professionOpen=F.ProfessionActions.page and not not F.ProfessionActions.page:IsVisible() or false,
        uiPage=F.UI.page,uiView=F.UI.view,uiOpen=F.UI.frame and not not F.UI.frame:IsShown() or false,
        inCombat=combat}
end
function F.BankTrace(stage)
    local d=F.db and F.db.diagnostics
    if not d or d.taintOriginal==nil then return end
    d.bankTrace=type(d.bankTrace)=='table' and d.bankTrace or {}
    local record=F.ProtectedContext(); record.stage=stage; record.seen=F.Now()
    d.bankTrace[#d.bankTrace+1]=record
    while #d.bankTrace>12 do table.remove(d.bankTrace,1) end
end
function F.ProtectedAction(event,addon,action)
    if addon~=F.name or not F.db then return end
    F.db.diagnostics=type(F.db.diagnostics)=='table' and F.db.diagnostics or {}
    local d=F.db.diagnostics
    d.protectedActions=type(d.protectedActions)=='table' and d.protectedActions or {}
    local record={event=event,action=type(action)=='string' and action:sub(1,256) or 'UNKNOWN',seen=F.Now(),
        bankOpen=not not F.Bank.open,auctionOpen=not not F.Auction.open,context=F.ProtectedContext(),bankTrace=F.Copy(d.bankTrace)}
    if debugstack then local ok,stack=pcall(debugstack,2,12,12); if ok and type(stack)=='string' then record.stack=stack:sub(1,4096) end end
    d.protectedActions[#d.protectedActions+1]=record
    while #d.protectedActions>5 do table.remove(d.protectedActions,1) end
    if not d.lastNotice or record.seen-d.lastNotice>=30 then
        d.lastNotice=record.seen; F.Print(F.L('Ошибка: ')..event..' / '..record.action..' /fn taint status')
    end
end
function F.TaintDiagnostics(mode)
    F.db.diagnostics=type(F.db.diagnostics)=='table' and F.db.diagnostics or {}
    local d=F.db.diagnostics
    local get=C_CVar and C_CVar.GetCVar or GetCVar
    local set=C_CVar and C_CVar.SetCVar or SetCVar
    if mode=='on' or mode=='off' then
        if not get or not set then F.Print('taintLog: API unavailable'); return end
        local ok,current=pcall(get,'taintLog')
        if not ok then F.Print('taintLog: unavailable'); return end
        local value=mode=='on' and '2' or tostring(d.taintOriginal or '0')
        local changed,result=pcall(set,'taintLog',value)
        if not changed or result==false then F.Print('taintLog: change failed'); return end
        if mode=='on' then if d.taintOriginal==nil then d.taintOriginal=tostring(current or '0') end
        else d.taintOriginal=nil; d.bankTrace=nil end
        F.Print('taintLog='..value..' / Logs/taint.log'); return
    end
    F.Print('ADDON_ACTION / bank='..tostring(F.Bank.open==true)..' / auction='..tostring(F.Auction.open==true))
    if get then local ok,value=pcall(get,'taintLog'); if ok then F.Print('taintLog='..tostring(value)) end end
    for _,record in ipairs(d.protectedActions or {}) do F.Print(tostring(record.event)..' / '..tostring(record.action)) end
    local latest=d.protectedActions and d.protectedActions[#d.protectedActions]
    if latest and latest.context then
        local c=latest.context
        if c.bankScanned then F.Print('Last bank scan before error: '..math.max(0,latest.seen-c.bankScanned)..'s') end
        for _,key in ipairs(F.Keys(c.security or {})) do
            local state=c.security[key]
            if state.secure==false then F.Print(key..' / secure=false / source='..tostring(state.source or 'unknown')) end
        end
    end
    F.Print('/fn taint on | /fn taint off')
end
function F.Command(input)
    local args = {}; for word in input:gmatch('%S+') do args[#args + 1] = word end
    local cmd, a, b = args[1] or 'show', args[2], args[3]
    local ok, err = pcall(function()
        if cmd == 'help' or cmd == 'commands' then F.UI.Commands()
        elseif cmd == 'settings' then F.Settings.Open()
        elseif cmd == 'updates' then F.Updates.Open()
        elseif cmd == 'netstatus' then F.Net.Diagnostics()
        elseif cmd == 'taint' then F.TaintDiagnostics(a)
        elseif cmd == 'track' then F.Tracker.Toggle()
        elseif cmd == 'show' then F.UI.Status()
        elseif cmd == 'language' then
            assert(a == 'auto' or F.Locales[a], 'language auto|enUS|enGB|ruRU|deDE|frFR|esES|esMX|itIT|ptBR|koKR|zhCN|zhTW')
            F.db.settings.locale = a ~= 'auto' and a or nil; F.UI.Status(); F.Settings.Refresh(); F.Updates.Refresh()
        elseif cmd == 'share' then
            assert(a == 'on' or a == 'off', 'share on|off')
            F.db.settings.sharing = a == 'on'
            if a == 'off' then F.Net.queue, F.Net.buffers = {}, {} end
            F.UI.Status()
        elseif cmd == 'sync' then
            local sent,why=F.Net.Sync()
            F.Print(sent and F.L('Синхронизация поставлена в очередь.') or why)
        elseif cmd == 'scan' then local scanned, why = F.Adapter.Scan(); F.Print(why); if scanned then F.UI.Navigate('recipes') end
        elseif cmd == 'profession' then change(function(p) assert(F.ID(a) and F.Integer(tonumber(b), 0, 1000)); p.professions[a] = tonumber(b) end)
        elseif cmd == 'recipe' then
            change(function(p)
                assert(F.ID(a) and F.ID(b) and F.ID(args[5]) and args[6], 'recipe ID OUTPUT QTY PROFESSION REAGENTS')
                local reagents = {}
                if args[6] ~= '-' then
                    for pair in args[6]:gmatch('[^,]+') do
                        local item, qty = pair:match('^([%w_:%.%-]+)=(%d+)$'); assert(item, 'reagent=quantity')
                        reagents[item] = tonumber(qty)
                    end
                end
                p.recipes[a] = {name = a, output = b, quantity = tonumber(args[4]), profession = args[5],
                    blueprint = false, reagents = reagents, stations = {}}
            end)
        elseif cmd == 'blueprint' then change(function(p) assert(p.recipes[a] and (b == 'on' or b == 'off')); p.recipes[a].blueprint = b == 'on' end)
        elseif cmd == 'station' then change(function(p) assert(p.recipes[a] and F.ID(b) and (args[4] == 'on' or args[4] == 'off')); p.recipes[a].stations[b] = args[4] == 'on' or nil end)
        elseif cmd == 'camp' then change(function(p) assert(F.ID(a) and F.Integer(tonumber(b), 0, 86400)); p.camps[a] = F.Now() + tonumber(b) end)
        elseif cmd == 'uncamp' then change(function(p) assert(F.ID(a)); p.camps[a] = nil end)
        elseif cmd == 'forget' then change(function(p) assert(F.ID(a)); p.recipes[a] = nil end)
        elseif cmd == 'plan' then
            local profiles = F.Profiles(); local inventory = F.Adapter.Inventory(profiles)
            local id = a and tonumber(a:match('^item:(%d+)$'))
            if id then inventory[a] = F.Adapter.StockCount(a) end
            F.UI.Plan(F.Planner.Build(profiles, a, tonumber(b) or 1, inventory))
        elseif cmd == 'graph' then
            local g = F.SkillGraph(F.Profiles()); F.UI.Show(F.L('Skill Graph: узлов ') .. #F.Keys(g.nodes) .. F.L(', связей ') .. #g.edges)
        elseif cmd == 'request' or cmd == 'accept' or cmd == 'done' or cmd == 'cancel' then
            local success, why
            if cmd == 'request' then success, why = F.Requests.Create(a, tonumber(b) or 1)
            elseif cmd == 'accept' then success, why = F.Requests.Accept(a)
            else success, why = F.Requests.Close(a, cmd == 'done' and 'done' or 'cancelled') end
            if why then F.Print(why) end; F.UI.Status()
        else F.UI.Commands() end
    end)
    if not ok then F.Print(F.L('Ошибка: ') .. tostring(err)) end
end
local frame = CreateFrame('Frame')
frame:RegisterEvent('ADDON_LOADED')
frame:SetScript('OnEvent', function(self, event, ...)
    if event == 'ADDON_LOADED' then
        local name = ...; if name ~= F.name then return end
        if not F.Init() then return end
        F.Net.Start(); F.Updates.Start(); F.Minimap.Init(); F.ProfessionActions.Start(); F.ProfessionLinks.Start(); F.Auction.Start(); F.Tracker.Start(); self:RegisterEvent('CHAT_MSG_ADDON')
        for _,event in ipairs({'BANKFRAME_OPENED','BANKFRAME_CLOSED','PLAYERBANKSLOTS_CHANGED','BANK_TABS_CHANGED','BAG_CONTAINER_UPDATE'}) do self:RegisterEvent(event) end
        self:RegisterEvent('GROUP_ROSTER_UPDATE'); self:RegisterEvent('PLAYER_GUILD_UPDATE'); self:RegisterEvent('PLAYER_ENTERING_WORLD')
        self:RegisterEvent('PLAYER_LOGIN'); self:RegisterEvent('BAG_UPDATE_DELAYED'); self:RegisterEvent('GET_ITEM_INFO_RECEIVED')
        self:RegisterEvent('ITEM_DATA_LOAD_RESULT')
        self:RegisterEvent('MODIFIER_STATE_CHANGED'); self:RegisterEvent('PLAYER_EQUIPMENT_CHANGED')
        for _,event in ipairs({'TRADE_SKILL_SHOW','TRADE_SKILL_CLOSE','TRADE_SKILL_LIST_UPDATE','TRADE_SKILL_DATA_SOURCE_CHANGED'}) do self:RegisterEvent(event) end
        self:RegisterEvent('ADDON_ACTION_BLOCKED'); self:RegisterEvent('ADDON_ACTION_FORBIDDEN')
        self:SetScript('OnUpdate', function(_, elapsed) F.Net.Tick(elapsed); F.Updates.Tick(elapsed); F.UI.Tick(elapsed); F.Bank.Tick(elapsed); F.Tracker.Tick(elapsed); F.ProfessionActions.Tick(elapsed); F.Automation.Tick(elapsed) end)
        SLASH_FOREVERNET1, SLASH_FOREVERNET2 = '/fn', '/forevernet'
        SlashCmdList.FOREVERNET = F.Command
        F.Updates.Startup()
    elseif event == 'CHAT_MSG_ADDON' then F.Updates.Receive(...); F.Net.Receive(...)
    elseif event=='MODIFIER_STATE_CHANGED' then F.Theme.TooltipEvent(event,...)
    elseif event=='ADDON_ACTION_BLOCKED' or event=='ADDON_ACTION_FORBIDDEN' then F.ProtectedAction(event,...)
    elseif event == 'PLAYER_LOGIN' then F.Minimap.Init(); F.Updates.Login(); if F.db.settings.sharing then F.Net.ScheduleSync() end
    elseif event=='GROUP_ROSTER_UPDATE' or event=='PLAYER_GUILD_UPDATE' or event=='PLAYER_ENTERING_WORLD' then
        F.RefreshIdentityAliases(); F.CleanSelfAliases()
        F.Updates.ScheduleAll(1)
        if F.db.settings.sharing then F.Net.ScheduleSync() end
        F.UI.DataChanged()
    else F.Theme.TooltipEvent(event,...); F.Automation.Event(event); F.Bank.Event(event); F.UI.DataChanged() end
end)
