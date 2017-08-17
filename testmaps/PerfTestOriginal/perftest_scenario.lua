version = 3
ScenarioInfo = {
    name = 'perftest',
    description = 'Performance Test Map',
    type = 'special',
    starts = true,
    preview = '',
    size = {1024, 1024},
    map = '/maps/perftest/perftest.scmap',
    save = '/maps/perftest/perftest_save.lua',
    script = '/maps/perftest/perftest_script.lua',
    Configurations = {
        ['standard'] = {
            teams = {
                { name = 'FFA', armies = {'Player','UEF','Aeon','Cybran_2','Aeon1',} },
            },
            customprops = {
            },
        },
    }}
