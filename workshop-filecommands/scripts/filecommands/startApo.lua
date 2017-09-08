return {
  {cmd = 'TheWorld:PushEvent("ms_nextcycle")'},
  {cmd = 'TheWorld:PushEvent("ms_setclocksegs", {day = 4, dusk = 5, night = 7})', delay = 1},
  --day 0-4
  {cmd = 'spawnNearPlayer("randomTier1")', delay = TUNING.SEG_TIME*0.5},
  {cmd = 'spawnNearPlayer("randomTier1")', delay = TUNING.SEG_TIME*1},
  {cmd = 'spawnNearPlayer("randomTier1")', delay = TUNING.SEG_TIME*1.5},
  {cmd = 'spawnNearPlayer("randomTier1")', delay = TUNING.SEG_TIME*2},
  {cmd = 'spawnNearPlayer("randomTier2")', delay = TUNING.SEG_TIME*3},
  
  --dusk 4-9
  {cmd = 'playerEvent("lightningStrike")', delay = TUNING.SEG_TIME*4},
  {cmd = 'spawnNearPlayer("randomTier1")', delay = TUNING.SEG_TIME*4.5},
  {cmd = 'spawnNearPlayer("randomTier1")', delay = TUNING.SEG_TIME*5},
  {cmd = 'spawnNearPlayer("randomTier1")', delay = TUNING.SEG_TIME*5.5},
  {cmd = 'spawnNearPlayer("randomTier2")', delay = TUNING.SEG_TIME*6},
  {cmd = 'spawnNearPlayer("randomBossLight")', delay = TUNING.SEG_TIME*7},
  
  --night 9-16
  {cmd = 'readBook("brimstone")', delay = TUNING.SEG_TIME*9},
  {cmd = 'spawnNearPlayer("randomTier2")', delay = TUNING.SEG_TIME*10},
  {cmd = 'spawnNearPlayer("randomTier2")', delay = TUNING.SEG_TIME*11},
  {cmd = 'spawnNearPlayer("randomBossLight")', delay = TUNING.SEG_TIME*12},
  {cmd = 'spawnNearPlayer("randomBoss")', delay = TUNING.SEG_TIME*14},
}