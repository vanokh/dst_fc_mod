-- набор в {} через ,
-- если кол-во=1, то писать или так "hound" (кавычки обязательны), или так hound=1 (без кавычек)
return {
    randomTier1 = {
      {hound = 2},
      {"tallbird"},
      {"crawlingnightmare"},
      {"nightmarebeak"},
      {"icehound"},
      {frog=2},
      {spider=5},
      {"little_walrus"},
      {bat=3},
      {"slurper"},
    },
    randomTier2 = {
      {worm = 2},
      {firehound=1,icehound=2,hound=2},
      {spider_spitter=2, "spider_dropper", "spider_hider", "spider_warrior"},
      {killerbee=3, mosquito=3},
      {"walrus", icehound=2},
      {knight=2,"bishop","rook"},
      {knight=4},
      {bishop=3},
    },
    randomBossLight = {
      "spat","rook","warg","krampus","rocky"
    },
    randomBoss = {
      "leif","bearger","moose","spiderqueen","deerclops"
    },
    randomBossHard = {
      "minotaur","dragonfly","klaus","beequeen"
    },
}