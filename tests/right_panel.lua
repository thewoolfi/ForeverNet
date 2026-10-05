local F,U=ForeverNet,ForeverNet.UI
C_Item={GetItemInfo=function(id) return 'Material '..id end,GetItemCount=function() return 0 end}
local recipe={name='Target item',output='item:1',quantity=1,profession='skill:171',blueprint=true,reagents={['item:2']=1,['item:3']=2,['item:4']=3,['item:5']=4},stations={}}
F.localProfile.recipes.test=recipe
local peer=F.NewProfile(); peer.recipes.test=F.Copy(recipe); F.db.profiles['Peer-Realm']=peer
for _,locale in ipairs(F.LocaleOrder) do
    F.db.settings.locale=locale; U.Navigate('recipes'); U.Select(U.entries[1])
    assert(U.blocks[1].text:GetText():find(string.format(F.L('RECIPE_OVERVIEW'),1,0,1,1),1,true))
    assert(not U.blocks[1].title:IsShown())
    assert(U.blocks[2].title:GetText()==F.L('AVAILABLE_CRAFTERS'))
    assert(not U.blocks[2].text:GetText():find('Target item',1,true)) -- No repeated item name for every master.
    assert(not U.blocks[1].text:GetText():find(F.L('RECIPE_NEXT'),1,true)) -- Available on the plan button.
    assert(U.cards[1].point[2]==0 and U.cards[2].point[2]==222)
    local overviewBottom=-U.blocks[1].text.point[3]+U.blocks[1].text:GetStringHeight()
    assert(-U.cards[1].point[3]>=overviewBottom+8, 'Material cards overlap the recipe calculation')
    assert(U.cards[1].point[3]==U.cards[2].point[3] and U.cards[3].point[3]<U.cards[1].point[3])
    assert(U.cards[1]:GetWidth()==212 and U.cards[1]:GetHeight()==U.cards[2]:GetHeight())
    local bottom=0
    for i=1,4 do
        local card=U.cards[i]; assert(card:IsShown())
        assert(card:GetHeight()>=-card.detail.point[3]+card.detail:GetStringHeight()+8)
        bottom=math.max(bottom,-card.point[3]+card:GetHeight())
    end
    assert(-U.blocks[2].title.point[3]>=bottom)
    U.Show(''); U.ShowCards({{item='item:2',title='A',text='0 / 0 / 1'},{item='item:3',title='B',text='0 / 0 / 1'},
        {item='item:4',title='C',text='0 / 0 / 1'},{item='item:5',title='D',text='0 / 0 / 1'}})
    local total=-U.cards[4].point[3]+U.cards[4]:GetHeight()+6
    assert(total<=136) -- Four ordinary cards used at least 272 units as a single column.
    U.ShowCards({{item='item:2',title=string.rep('Long material ',20),text=string.rep('Bank and market state ',12)}})
    assert(not U.cards[2]:IsShown() and U.cards[1]:GetHeight()>=U.cards[1].title:GetStringHeight()+U.cards[1].detail:GetStringHeight()+20)
    U.ShowSourceRows({{item='item:2',title='Leather',text='Bags: 3 / Bank: 2'}})
    local row=U.sourceRows[1]
    assert(row.backdrop==nil and row.divider:IsShown() and row.icon:GetWidth()==26)
    assert(row.detail.point[2]>row.title.point[2] and row:GetHeight()<=40)
    U.ShowSourceRows({{item='item:2',title='Leather',text='Price unknown\nBank: 2',actions={{text='Compare',run=function() end}}}})
    assert(row.backdrop~=nil and not row.divider:IsShown() and row.icon:GetWidth()==36)
    assert(-row.buttons[1].point[3]>=-row.detail.point[3]+row.detail:GetStringHeight())
    U.ShowBlocks({{title='A',text='First'},{title='B',text='Second'}})
    U.ShowBlocks({{text='Reused'}}); assert(not U.blocks[2].text:IsShown() and not U.blocks[1].title:IsShown())
    local overviewEnd=U.ShowBlocks({{text=string.rep(F.L('RECIPE_OVERVIEW')..' ',20)}},17)
    local measuredBottom=-U.blocks[1].text.point[3]+U.blocks[1].text:GetStringHeight()
    assert(type(overviewEnd)=='number' and overviewEnd>=measuredBottom+8)
    local cardsEnd=U.ShowCards({{item='item:2',title='Leather',text='0 / 0 / 1'}},overviewEnd)
    assert(-U.cards[1].point[3]>=measuredBottom+8)
    local mastersEnd=U.ShowBlocks({{title=F.L('AVAILABLE_CRAFTERS'),text='You / Peer'}},cardsEnd,true)
    assert(-U.blocks[2].title.point[3]>=-U.cards[1].point[3]+U.cards[1]:GetHeight()+6)
    assert(mastersEnd>=-U.blocks[2].text.point[3]+U.blocks[2].text:GetStringHeight()+8)
    assert(U.body:GetHeight()>=mastersEnd)
    -- The same composition must work without any material cards.
    local emptyCardsEnd=U.ShowCards({},overviewEnd)
    assert(emptyCardsEnd==overviewEnd and not U.cards[1]:IsShown())
    U.ShowBlocks({{title=F.L('AVAILABLE_CRAFTERS'),text='You / Peer'}},emptyCardsEnd,true)
    assert(-U.blocks[3].title.point[3]>=measuredBottom+8)
end
F.db.settings.locale='enUS'
F.db.profiles['Peer-Realm']=nil
C_Item.GetItemCount=function() return 100 end
U.Navigate('recipes'); U.Select(U.entries[1])
assert(U.blockCount==1) -- One owner is already identified in the header.
for i=1,4 do assert(not U.cards[i].detail:GetText():find(F.L('MARKET_UNKNOWN'),1,true)) end
F.Queue.Add('item:1',1,F.me,'test'); U.Navigate('queue')
local goal,tools
for i,entry in ipairs(U.chainRows) do
    if entry.extraAction then goal=i end
    if entry.title==F.L('SETS_TITLE') then tools=i end
end
assert(goal and tools and goal<tools)
local stock
for _,entry in ipairs(U.chainRows) do if entry.title==F.L('CHAIN_STOCK') then stock=entry end end
assert(stock and not U.showQueueStock)
stock.actions[1].run(); assert(U.showQueueStock)
local found=false
for _,entry in ipairs(U.chainRows) do if entry.text==string.format(F.L('STOCK_CARD'),1,0) then found=true end end
assert(found)
