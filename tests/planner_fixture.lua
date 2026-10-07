-- Synthetic graph data for tests only; excluded from runtime packages.
local F=ForeverNet
function F.TestProfiles()
    local a, b = F.NewProfile(), F.NewProfile()
    a.professions.engineering, b.professions.tailoring = 300, 300
    a.recipes['demo:engine'] = {name = 'Test engine', output = 'demo:engine', quantity = 1, profession = 'engineering',
        blueprint = true, reagents = {['demo:ore'] = 3}, stations = {}}
    b.recipes['demo:bag'] = {name = 'Test bag', output = 'demo:bag', quantity = 1, profession = 'tailoring',
        blueprint = true, reagents = {['demo:engine'] = 1, ['demo:cloth'] = 4}, stations = {['demo:workshop'] = true}}
    a.camps['demo:workshop'] = F.Now()
    return {['DemoEngineer-Realm'] = a, ['DemoTailor-Realm'] = b}
end
