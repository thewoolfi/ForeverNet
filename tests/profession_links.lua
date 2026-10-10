local F,L=ForeverNet,ForeverNet.ProfessionLinks
local links={ [1]='|cffffffff|Henchant:1|h[Recipe One]|h|r', [2]='|cffffffff|Henchant:2|h[Recipe Two]|h|r' }
C_TradeSkillUI={GetRecipeLink=function(id) return links[id] end}
local function node(id)
    return {GetData=function() return id and {recipeInfo={recipeID=id}} or {categoryInfo={name='Category'}} end}
end
local function row(id)
    local r=CreateFrame('Button'); r:SetSize(250,20)
    r.Label=r:CreateFontString(); r.Label:SetWidth(220)
    r.Count=r:CreateFontString(); r.Count:SetWidth(20); r.Count:Show()
    function r.Count:GetStringWidth() return 20 end
    r.SkillUps=CreateFrame('Frame'); r.SkillUps:SetWidth(14)
    r.LockedIcon=CreateFrame('Button'); r.LockedIcon:SetWidth(18); r.LockedIcon:Hide()
    r.node=node(id); function r:GetElementData() return self.node end
    return r
end
local first,category=row(1),row(nil)
local box={rows={first,category}}
function box:ForEachFrame(callback) for _,r in ipairs(self.rows) do callback(r,r.node) end end
local registered=0
ScrollUtil.AddInitializedFrameCallback=function(scrollBox,callback,owner,existing)
    assert(scrollBox==box and owner==L and existing==false)
    registered=registered+1; box.callback=callback
end
ProfessionsFrame={CraftingPage={RecipeList={ScrollBox=box}}}
assert(L.Attach() and L.Attach() and registered==1)
local button=first.foreverNetRecipeLink
assert(button and button:IsShown() and button:IsEnabled() and not category.foreverNetRecipeLink)
assert(first.Label:GetWidth()==182 and button.point[2]==first)
local width=first.Label:GetWidth(); L.Refresh(); L.Refresh()
assert(first.Label:GetWidth()==width) -- Retry events do not progressively shrink labels.

local inserted,opened={},{}
local active=true
ChatFrameUtil={GetActiveWindow=function() return active end,
    InsertLink=function(link) inserted[#inserted+1]=link; return true end,
    OpenChat=function(link) opened[#opened+1]=link end}
function SendChatMessage() error('A link button must never send a chat message') end
button.scripts.OnClick(button)
assert(inserted[1]==links[1] and #opened==0)
active=false; button.scripts.OnClick(button)
assert(opened[1]==links[1] and #inserted==1)
active=true
ChatFrameUtil.InsertLink=function() return false end
assert(not L.Insert(links[1]) and #opened==1) -- A full active draft is not overwritten.
ChatFrameUtil.InsertLink=function(link) inserted[#inserted+1]=link; return true end

-- Resolve the recycled row's current data even before another layout callback.
first.node=node(2); button.scripts.OnClick(button)
assert(inserted[2]==links[2])
first.Label:SetWidth(220); first.LockedIcon:Show(); box.callback(L,first,first.node)
assert(first.foreverNetRecipeLink==button and first.Label:GetWidth()==164)
assert(button.point[2]==first.LockedIcon)
first.node=node(nil); box.callback(L,first,first.node)
assert(not button:IsShown())
first.node=node(3); first.Label:SetWidth(220); box.callback(L,first,first.node)
assert(button:IsShown() and not button:IsEnabled())
links[3]='|cffffffff|Hspell:3|h[Enchant recipe]|h|r'; L.Refresh()
assert(button:IsEnabled()); button.scripts.OnClick(button); assert(inserted[3]==links[3])
C_TradeSkillUI.GetRecipeLink=function() error('data not available') end
assert(L.Link(3)==nil); L.Refresh(); assert(not button:IsEnabled())
assert(not L.Insert('plain recipe name'))

-- Use the highest learned variant shown by the native recipe list.
C_TradeSkillUI.GetRecipeLink=function(id) return links[id] end
Professions={GetHighestLearnedRecipe=function() return {recipeID=2} end}
first.node=node(1); button.scripts.OnClick(button); assert(inserted[4]==links[2])
Professions=nil
ChatFrameUtil=nil
ChatEdit_InsertLink=function(link) inserted[#inserted+1]=link; return true end
assert(L.Insert(links[1]) and inserted[5]==links[1])
ChatEdit_InsertLink=nil
ChatFrame_OpenChat=function(link) opened[#opened+1]=link end
assert(L.Insert(links[2]) and opened[2]==links[2])
ChatFrame_OpenChat=nil; assert(not L.Insert(links[1]))
for _,language in ipairs(F.LocaleOrder) do
    F.db.settings.locale=language
    clientLocale=language
    for _,key in ipairs({'RECIPE_CHAT_LINK','RECIPE_CHAT_LINK_HELP','RECIPE_CHAT_LINK_UNAVAILABLE'}) do
        assert(F.Locales[language][key] and F.L(key)~=key,language..':'..key)
    end
end
clientLocale=nil
-- Load-on-demand attachment is retried through events, without adding duplicate buttons.
local event=L.frame.scripts.OnEvent
event(L.frame,'ADDON_LOADED','Blizzard_Professions')
assert(registered==1 and first.foreverNetRecipeLink==button)

assert(ForeverLink==nil and ForeverNetDB==F.db and SlashCmdList.FOREVERNET)
assert(L.Link(0)==nil and L.Link('1')==nil and L.Link(0/0)==nil)
F.db.settings.locale='ruRU'; button.scripts.OnEnter(button)
assert(F.Theme.tooltip:IsShown() and F.Theme.tooltip.title:GetText()==F.L('RECIPE_CHAT_LINK'))
button.scripts.OnLeave(button); assert(not F.Theme.tooltip:IsShown())
L.Start(); assert(L.frame and registered==1)

-- Optional native APIs and a missing row label must remain harmless.
local api=C_TradeSkillUI; C_TradeSkillUI=nil
assert(not L.Link(1)); C_TradeSkillUI=api
local noLabel=CreateFrame('Button'); L.UpdateRow(noLabel,node(1),true)
assert(not noLabel.foreverNetRecipeLink)
-- A late-loaded independent link provider takes over without two buttons or
-- retaining the Net reservation as its original native label width.
local foreign=CreateFrame('Button',nil,first)
first.foreverLinkRecipeLink=foreign; first.foreverLinkLinkLabelWidth=first.Label:GetWidth()
local refreshes=0
ForeverLink={Link=function() end,Refresh=function()
    refreshes=refreshes+1
    first.Label:SetWidth(first.foreverLinkLinkLabelWidth-38)
end}
L.frame.scripts.OnEvent(L.frame,'ADDON_LOADED','ForeverLink')
assert(not button:IsShown() and foreign:IsShown() and first.foreverLinkLinkLabelWidth==220)
assert(refreshes==1); L.Refresh(); assert(refreshes==1)
first.Label:SetWidth(200); box.callback(L,first,first.node)
assert(first.Label:GetWidth()==200 and not button:IsShown())
